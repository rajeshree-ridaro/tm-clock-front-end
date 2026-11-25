import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/crew/features/auth/sign_in_page.dart';
import 'package:tm_clock/apps/crew/features/clock/clock_page.dart';
import 'package:tm_clock/apps/crew/features/company/pick_company_page.dart';
import 'package:tm_clock/apps/crew/features/crew/my_crew_page.dart';
import 'package:tm_clock/apps/crew/features/home/home_page.dart';
import 'package:tm_clock/apps/crew/features/hours/hours_page.dart';
import 'package:tm_clock/apps/crew/features/me/me_page.dart';
import 'package:tm_clock/apps/crew/features/safety/safety_page.dart';
import 'package:tm_clock/apps/crew/features/shell/crew_shell.dart';
import 'package:tm_clock/apps/crew/router/crew_routes.dart';
import 'package:tm_clock/core/app/app_scope.dart';

Page<void> _page(GoRouterState s, Widget child) => NoTransitionPage(key: s.pageKey, child: child);

GoRouter buildCrewRouter(AppServices services) {
  final session = services.session;
  return GoRouter(
    initialLocation: CrewRoutes.signIn,
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!session.signedIn) return loc == CrewRoutes.signIn ? null : CrewRoutes.signIn;
      if (!session.hasCompany) return loc == CrewRoutes.pickCompany ? null : CrewRoutes.pickCompany;
      if (loc == CrewRoutes.signIn || loc == CrewRoutes.pickCompany) return CrewRoutes.home;
      if (loc == CrewRoutes.crew && !session.isSupervisor) return CrewRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => CrewRoutes.signIn),
      GoRoute(path: CrewRoutes.signIn, pageBuilder: (_, s) => _page(s, const CrewSignInPage())),
      GoRoute(path: CrewRoutes.pickCompany, pageBuilder: (_, s) => _page(s, const PickCompanyPage())),
      ShellRoute(
        builder: (context, state, child) => CrewShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: CrewRoutes.home, pageBuilder: (_, s) => _page(s, const HomePage())),
          // Siblings, not children of /home: returning home rebuilds it so status is fresh.
          GoRoute(path: CrewRoutes.clockIn, pageBuilder: (_, s) => _page(s, const ClockPage(clockOut: false))),
          GoRoute(path: CrewRoutes.clockOut, pageBuilder: (_, s) => _page(s, const ClockPage(clockOut: true))),
          GoRoute(path: CrewRoutes.crew, pageBuilder: (_, s) => _page(s, const MyCrewPage())),
          GoRoute(path: CrewRoutes.safety, pageBuilder: (_, s) => _page(s, const SafetyPage())),
          GoRoute(path: CrewRoutes.hours, pageBuilder: (_, s) => _page(s, const HoursPage())),
          GoRoute(path: CrewRoutes.me, pageBuilder: (_, s) => _page(s, const MePage())),
        ],
      ),
    ],
  );
}
