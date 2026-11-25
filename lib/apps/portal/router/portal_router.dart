import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/portal/features/approvals/presentation/approvals_page.dart';
import 'package:tm_clock/apps/portal/features/auth/presentation/sign_in_page.dart';
import 'package:tm_clock/apps/portal/features/dashboard/presentation/dashboard_page.dart';
import 'package:tm_clock/apps/portal/features/employees/presentation/employees_page.dart';
import 'package:tm_clock/apps/portal/features/history/presentation/history_page.dart';
import 'package:tm_clock/apps/portal/features/reports/presentation/reports_page.dart';
import 'package:tm_clock/apps/portal/features/schedules/presentation/schedules_page.dart';
import 'package:tm_clock/apps/portal/features/settings/presentation/settings_page.dart';
import 'package:tm_clock/apps/portal/features/shell/app_shell.dart';
import 'package:tm_clock/apps/portal/features/sites/presentation/sites_page.dart';
import 'package:tm_clock/apps/portal/features/tasks/presentation/tasks_page.dart';
import 'package:tm_clock/apps/portal/features/timecards/presentation/timecards_page.dart';
import 'package:tm_clock/apps/portal/router/portal_routes.dart';
import 'package:tm_clock/core/app/app_scope.dart';

GoRouter buildPortalRouter(AppServices services) {
  /// No page transition — matches the prototype's instant view switching.
  /// Keyed by company: switching company (menu switcher) gives the page fresh state, so it
  /// reloads its data. It listens to the session itself because the router doesn't rebuild
  /// a page whose address didn't change.
  Page<void> page(GoRouterState state, Widget child) => NoTransitionPage(
    key: state.pageKey,
    child: ListenableBuilder(
      listenable: services.session,
      builder: (_, _) => KeyedSubtree(
        key: ValueKey(services.session.company?.companyId),
        child: child,
      ),
    ),
  );

  return GoRouter(
    initialLocation: Routes.signIn,
    refreshListenable: services.session,
    redirect: (context, state) {
      final atSignIn = state.matchedLocation == Routes.signIn;
      final ready = services.session.hasCompany;
      if (!ready && !atSignIn) return Routes.signIn;
      if (ready && atSignIn) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.signIn),
      GoRoute(
        path: Routes.signIn,
        pageBuilder: (_, s) => page(s, const SignInPage()),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            pageBuilder: (_, s) => page(s, const DashboardPage()),
          ),
          GoRoute(
            path: Routes.approvals,
            pageBuilder: (_, s) => page(s, const ApprovalsPage()),
          ),
          GoRoute(
            path: Routes.timecards,
            pageBuilder: (_, s) => page(s, const TimecardsPage()),
          ),
          GoRoute(
            path: Routes.tasks,
            pageBuilder: (_, s) => page(s, const TasksPage()),
          ),
          GoRoute(
            path: Routes.employees,
            pageBuilder: (_, s) => page(s, const EmployeesPage()),
          ),
          GoRoute(
            path: Routes.schedules,
            pageBuilder: (_, s) => page(s, const SchedulesPage()),
          ),
          GoRoute(
            path: Routes.sites,
            pageBuilder: (_, s) => page(s, const SitesPage()),
          ),
          GoRoute(
            path: Routes.reports,
            pageBuilder: (_, s) => page(s, const ReportsPage()),
          ),
          GoRoute(
            path: Routes.history,
            pageBuilder: (_, s) => page(s, const HistoryPage()),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (_, s) => page(s, const SettingsPage()),
          ),
        ],
      ),
    ],
  );
}
