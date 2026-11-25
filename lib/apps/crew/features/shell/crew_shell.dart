import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/crew/router/crew_routes.dart';
import 'package:tm_clock/apps/crew/widgets/crew_widgets.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';

class _Tab {
  const _Tab(this.path, this.labelKey, this.icon, this.selectedIcon);
  final String path, labelKey;
  final IconData icon, selectedIcon;
}

const _home = _Tab(CrewRoutes.home, 'home', Icons.schedule_outlined, Icons.schedule);
const _crew = _Tab(CrewRoutes.crew, 'crewTab', Icons.groups_outlined, Icons.groups);
const _safety = _Tab(CrewRoutes.safety, 'safety', Icons.shield_outlined, Icons.shield);
const _hours = _Tab(CrewRoutes.hours, 'hours', Icons.receipt_long_outlined, Icons.receipt_long);
const _me = _Tab(CrewRoutes.me, 'me', Icons.person_outline, Icons.person);

/// Signed-in crew layout: top bar + page + fixed bottom tab bar.
/// Supervisors get the Crew tab; employees get four tabs.
class CrewShell extends StatelessWidget {
  const CrewShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tabs = [_home, if (context.session.isSupervisor) _crew, _safety, _hours, _me];
    final index = tabs.indexWhere((t) => location.startsWith(t.path)).clamp(0, tabs.length - 1);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CrewTopBar(),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.tm.line))),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(tabs[i].path),
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: context.t(t.labelKey),
              ),
          ],
        ),
      ),
    );
  }
}
