/// App models for the shapes both apps use. Field names follow
/// tm-clock-api/api/openapi.yaml so `fromJson` maps 1:1.
library;

enum Role { owner, admin, supervisor, employee }

enum ClockState { out, clockedIn, onBreak }

enum PunchKind { clockIn, breakStart, breakEnd, clockOut }

enum ReviewStatus { pending, approved, rejected, retake }

/// `onClock[].state` on the dashboard.
enum WorkState { working, late, onBreak, offSite }

T _enum<T extends Enum>(List<T> values, Object? raw, T fallback, [Map<String, T> alias = const {}]) {
  if (raw is! String) return fallback;
  return alias[raw] ?? values.firstWhere((v) => v.name == raw, orElse: () => fallback);
}

ClockState clockStateFrom(Object? raw) =>
    _enum(ClockState.values, raw, ClockState.out, {'in': ClockState.clockedIn});

const punchKindWire = {
  PunchKind.clockIn: 'in',
  PunchKind.breakStart: 'breakStart',
  PunchKind.breakEnd: 'breakEnd',
  PunchKind.clockOut: 'out',
};

PunchKind punchKindFrom(Object? raw) => punchKindWire.entries
    .firstWhere((e) => e.value == raw, orElse: () => punchKindWire.entries.first)
    .key;

/// `UserRef`
class UserRef {
  const UserRef({required this.id, required this.name, required this.initials});
  final String id, name, initials;

  factory UserRef.fromJson(Map<String, dynamic> j) => UserRef(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        initials: j['initials'] as String? ?? '',
      );
}

/// `SiteRef`
class SiteRef {
  const SiteRef({required this.id, required this.name, this.colorIndex = 0});
  final String id, name;
  final int colorIndex;

  factory SiteRef.fromJson(Map<String, dynamic> j) => SiteRef(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        colorIndex: j['colorIndex'] as int? ?? 0,
      );
}

/// `Membership` — one company this login belongs to.
class Membership {
  const Membership({
    required this.companyId,
    required this.companyName,
    required this.city,
    required this.role,
    this.portalAllowed = true,
    this.lastActiveAt,
    this.clockState = ClockState.out,
  });

  final String companyId, companyName, city;
  final Role role;
  final bool portalAllowed;
  final DateTime? lastActiveAt;
  final ClockState clockState;

  String get initials => companyName
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
        companyId: j['companyId'] as String,
        companyName: j['companyName'] as String? ?? '',
        city: j['city'] as String? ?? '',
        role: _enum(Role.values, j['role'], Role.employee),
        portalAllowed: j['portalAllowed'] as bool? ?? false,
        lastActiveAt: DateTime.tryParse(j['lastActiveAt'] as String? ?? ''),
        clockState: clockStateFrom(j['clockState']),
      );
}

/// `Tokens` response, minus the tokens themselves (kept in TokenStore).
class AuthResult {
  const AuthResult({required this.user, required this.needsCompany, required this.companies});
  final UserRef user;
  final bool needsCompany;
  final List<Membership> companies;

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        user: UserRef.fromJson(j['user'] as Map<String, dynamic>? ?? const {}),
        needsCompany: j['needsCompany'] as bool? ?? false,
        companies: [
          for (final m in (j['companies'] as List? ?? const [])) Membership.fromJson(m as Map<String, dynamic>),
        ],
      );
}

/// `Punch` (fields the apps show).
class Punch {
  const Punch({
    required this.id,
    required this.kind,
    required this.at,
    this.user,
    this.site,
    this.review = ReviewStatus.pending,
  });

  final String id;
  final PunchKind kind;
  final DateTime at;
  final UserRef? user;
  final SiteRef? site;
  final ReviewStatus review;

  factory Punch.fromJson(Map<String, dynamic> j) => Punch(
        id: j['id'] as String,
        kind: punchKindFrom(j['kind']),
        at: DateTime.parse(j['at'] as String).toLocal(),
        user: j['user'] == null ? null : UserRef.fromJson(j['user'] as Map<String, dynamic>),
        site: j['site'] == null ? null : SiteRef.fromJson(j['site'] as Map<String, dynamic>),
        review: _enum(ReviewStatus.values, (j['review'] as Map?)?['status'], ReviewStatus.pending),
      );
}

/// `GET /me/status` — crew app home.
class MeStatus {
  const MeStatus({
    required this.state,
    this.lastPunch,
    this.todayMinutes = 0,
    this.weekMinutes = 0,
    this.briefingToSign = false,
  });

  final ClockState state;
  final Punch? lastPunch;
  final int todayMinutes, weekMinutes;
  final bool briefingToSign;

  factory MeStatus.fromJson(Map<String, dynamic> j) => MeStatus(
        state: clockStateFrom(j['state']),
        lastPunch: j['lastPunch'] == null ? null : Punch.fromJson(j['lastPunch'] as Map<String, dynamic>),
        todayMinutes: j['todayMinutes'] as int? ?? 0,
        weekMinutes: j['weekMinutes'] as int? ?? 0,
        briefingToSign: j['briefingToSign'] != null,
      );
}

/// `POST /punches/check-location`
class LocationCheck {
  const LocationCheck({required this.site, required this.distanceFt, required this.inside});
  final SiteRef? site;
  final int distanceFt;
  final bool inside;

  factory LocationCheck.fromJson(Map<String, dynamic> j) => LocationCheck(
        site: j['site'] == null ? null : SiteRef.fromJson(j['site'] as Map<String, dynamic>),
        distanceFt: j['distanceFt'] as int? ?? 0,
        inside: j['inside'] as bool? ?? false,
      );
}

/// `GET /dashboard` → `onClock[]` row. Used by the portal dashboard
/// and the crew app's supervisor "My crew" tab.
class OnClockEntry {
  const OnClockEntry({
    required this.user,
    required this.site,
    required this.since,
    required this.state,
    this.todayMinutes = 0,
    this.photo = ReviewStatus.pending,
  });

  final UserRef user;
  /// null when the punch had no job site.
  final SiteRef? site;
  final DateTime since;
  final WorkState state;
  final int todayMinutes;
  final ReviewStatus photo;

  factory OnClockEntry.fromJson(Map<String, dynamic> j) => OnClockEntry(
        user: UserRef.fromJson(j['user'] as Map<String, dynamic>),
        site: j['site'] == null ? null : SiteRef.fromJson(j['site'] as Map<String, dynamic>),
        since: DateTime.parse(j['since'] as String).toLocal(),
        state: _enum(WorkState.values, j['state'], WorkState.working),
        todayMinutes: j['todayMinutes'] as int? ?? 0,
        photo: _enum(ReviewStatus.values, j['photo'], ReviewStatus.pending),
      );
}

/// `GET /dashboard`
class Dashboard {
  const Dashboard({
    required this.onClockCount,
    required this.scheduled,
    required this.onBreak,
    required this.late,
    required this.toReview,
    required this.onClock,
  });

  final int onClockCount, scheduled, onBreak, late, toReview;
  final List<OnClockEntry> onClock;

  factory Dashboard.fromJson(Map<String, dynamic> j) {
    final c = j['counts'] as Map<String, dynamic>? ?? const {};
    return Dashboard(
      onClockCount: c['onClock'] as int? ?? 0,
      scheduled: c['scheduled'] as int? ?? 0,
      onBreak: c['onBreak'] as int? ?? 0,
      late: c['late'] as int? ?? 0,
      toReview: c['toReview'] as int? ?? 0,
      onClock: [
        for (final e in (j['onClock'] as List? ?? const [])) OnClockEntry.fromJson(e as Map<String, dynamic>),
      ],
    );
  }
}
