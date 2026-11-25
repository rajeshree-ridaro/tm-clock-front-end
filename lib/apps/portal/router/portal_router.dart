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

/// No page transition — matches the prototype's instant view switching.
Page<void> _page(GoRouterState state, Widget child) =>
    NoTransitionPage(key: state.pageKey, child: child);

GoRouter buildPortalRouter(AppServices services) => GoRouter(
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
          pageBuilder: (_, s) => _page(s, const SignInPage()),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: Routes.dashboard, pageBuilder: (_, s) => _page(s, const DashboardPage())),
            GoRoute(path: Routes.approvals, pageBuilder: (_, s) => _page(s, const ApprovalsPage())),
            GoRoute(path: Routes.timecards, pageBuilder: (_, s) => _page(s, const TimecardsPage())),
            GoRoute(path: Routes.tasks, pageBuilder: (_, s) => _page(s, const TasksPage())),
            GoRoute(path: Routes.employees, pageBuilder: (_, s) => _page(s, const EmployeesPage())),
            GoRoute(path: Routes.schedules, pageBuilder: (_, s) => _page(s, const SchedulesPage())),
            GoRoute(path: Routes.sites, pageBuilder: (_, s) => _page(s, const SitesPage())),
            GoRoute(path: Routes.reports, pageBuilder: (_, s) => _page(s, const ReportsPage())),
            GoRoute(path: Routes.history, pageBuilder: (_, s) => _page(s, const HistoryPage())),
            GoRoute(path: Routes.settings, pageBuilder: (_, s) => _page(s, const SettingsPage())),
          ],
        ),
      ],
    );
