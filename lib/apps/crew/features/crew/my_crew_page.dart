import 'package:flutter/material.dart';

import 'package:tm_clock/apps/crew/widgets/crew_widgets.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/async_view.dart';
import 'package:tm_clock/core/widgets/crew_status_row.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/models/models.dart';

/// Supervisor "My crew" — same repository call and row widget as the portal dashboard.
/// TODO: clock crew members in, bulk edit punches, approve photos.
class MyCrewPage extends StatefulWidget {
  const MyCrewPage({super.key});

  @override
  State<MyCrewPage> createState() => _MyCrewPageState();
}

class _MyCrewPageState extends State<MyCrewPage> {
  late Future<Dashboard> _future = context.repos.punches.dashboard();

  @override
  Widget build(BuildContext context) {
    return CrewBody(
      children: [
        Text(context.t('myCrew'), style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28)),
        const SizedBox(height: 16),
        AsyncView<Dashboard>(
          future: _future,
          onRetry: () => setState(() => _future = context.repos.punches.dashboard()),
          builder: (d) => TmCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final (i, e) in d.onClock.indexed)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: i == 0 ? null : Border(top: BorderSide(color: context.tm.line)),
                    ),
                    child: CrewStatusRow(entry: e),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
