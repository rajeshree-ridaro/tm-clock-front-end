# TM Clock — front end (Flutter)

One Flutter codebase, two apps:

| App | Who | Platforms | Entry point | UI spec |
|---|---|---|---|---|
| **Portal** | owners, office admins, supervisors | web | `lib/main_portal.dart` | `tm-clock-web/prototype/index.html` |
| **Crew app** | crews and supervisors | iOS, Android | `lib/main_crew.dart` | `tm-clock-mobile/prototype/index.html` |

`lib/main.dart` picks automatically: web → portal, phone → crew app.

```powershell
flutter pub get
flutter run -d chrome -t lib/main_portal.dart      # portal
flutter run -t lib/main_crew.dart                  # crew app on a phone / emulator
flutter run -d chrome -t lib/main_crew.dart        # crew app in a browser (use phone size)
```

Both run on built-in sample data by default. Point them at the API with:

```powershell
flutter run -t lib/main_crew.dart --dart-define=USE_FAKE_DATA=false --dart-define=API_BASE_URL=http://localhost:8080/v1
```

### Real back end

`tm-clock-back-end` (FastAPI + MongoDB) serves `http://localhost:8080/v1`, the default `API_BASE_URL`, so `--dart-define=USE_FAKE_DATA=false` is all the apps need.
Its README has the setup and the demo logins. Endpoints it hasn't built yet answer 501 `NOT_IMPLEMENTED`; the mock below covers the whole spec.

### Mock API

`tool/mock_api.ps1` serves a mock of the whole API from `api/openapi.yaml` (Prism, needs Node.js 18+).
It checks every request against the spec, so it catches a wrong field name or missing header the way the real API would.
It returns random but valid data, so expect lorem-ipsum names and odd numbers.

```powershell
.\tool\mock_api.ps1
```

```powershell
flutter run -d chrome -t lib/main_crew.dart --dart-define=USE_FAKE_DATA=false --dart-define=API_BASE_URL=http://localhost:4010
```

The mock has no `/v1` prefix, so use `http://localhost:4010` as the base URL.
To check every repository call against a server (mock or real) in one go:

```powershell
dart run tool/check_api.dart http://localhost:4010
```

`api/openapi.yaml` is a copy of `tm-clock-api/api/openapi.yaml`; copy it again when the API team changes it.

## How the sharing works

Only screens and routing are per app. Everything below the screens is written once:

```
lib/
├── main.dart / main_portal.dart / main_crew.dart
├── core/                       ← shared by both apps
│   ├── app/                    TmApp (theme, EN/ES, session, repositories) + AppScope (context.repos, context.session)
│   ├── config/env.dart         API_BASE_URL, USE_FAKE_DATA
│   ├── session/                signed-in user, companies, current company/role
│   ├── settings/               light/dark + language
│   ├── theme/                  prototype tokens; TmFlavor.crew = brighter text + bigger type
│   ├── l10n/strings.dart       EN/ES → context.t('key')
│   ├── layout/                 breakpoints
│   └── widgets/                logo, card, pill, stat tile, avatar, AsyncView, CrewStatusRow…
├── data/                       ← shared by both apps
│   ├── api/                    ApiClient (Dio: bearer token, refresh on 401, Accept-Language, ApiException)
│   ├── models/                 Membership, Punch, MeStatus, Dashboard… (field names = openapi.yaml)
│   ├── repositories/           AuthRepository, PunchRepository (interface + HTTP implementation)
│   └── fake/                   sample-data implementations
└── apps/
    ├── portal/                 router + features (sign in, dashboard, approvals, timecards…)
    └── crew/                   router + features (sign in, pick company, home, clock in/out, crew, safety, hours, me)
```

**Adding an API call:** add a method to the repository interface → implement it in the HTTP repository (and the fake one) → call `context.repos.x.method()` from either app. Both apps get it.

Example already shared: `GET /dashboard` feeds both the portal's live crew board and the crew app's supervisor "My crew" tab, with the same `CrewStatusRow` widget.

## Theme

Use tokens, never raw hex: `context.tm.panel`, `context.tm.g` (TM Clock teal), `context.tm.mute`, etc.
Status colours come in pairs (`ok/okBg`, `amber/waitBg`, `red/noBg`, `blue/breakBg`) — use `TmPill`.
Every control is at least 44px tall; the crew app's main actions use `BigButton` (72px) for gloves.

## Not built yet

- Crew app: GPS (`geolocator`), camera + photo upload (`/files/upload-url`), offline punch queue (`/punches/batch`), ads, PIN / kiosk sign-in, safety briefing steps, timecard.
- Portal: company picker for multi-company admins, and the pages still marked "Coming soon".
- Tokens are kept in memory; use `flutter_secure_storage` on mobile before release (`lib/data/api/token_store.dart`).
