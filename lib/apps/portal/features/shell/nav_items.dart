import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/router/portal_routes.dart';

/// Side-menu entries, in prototype order. `labelKey` is a [StringsX.t] key.
class NavItem {
  const NavItem(this.path, this.labelKey, this.icon);
  final String path;
  final String labelKey;
  final IconData icon;
}

const navItems = <NavItem>[
  NavItem(Routes.dashboard, 'dash', Icons.grid_view_rounded),
  NavItem(Routes.approvals, 'appr', Icons.photo_camera_outlined),
  NavItem(Routes.timecards, 'tc', Icons.receipt_long_outlined),
  NavItem(Routes.tasks, 'tasks', Icons.checklist_rounded),
  NavItem(Routes.employees, 'emp', Icons.person_outline_rounded),
  NavItem(Routes.schedules, 'sch', Icons.calendar_month_outlined),
  NavItem(Routes.sites, 'sites', Icons.place_outlined),
  NavItem(Routes.reports, 'rep', Icons.bar_chart_rounded),
  NavItem(Routes.history, 'hist', Icons.history_rounded),
  NavItem(Routes.settings, 'set', Icons.settings_outlined),
];
