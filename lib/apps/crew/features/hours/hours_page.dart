import 'package:flutter/material.dart';

import 'package:tm_clock/apps/crew/widgets/crew_widgets.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/widgets/async_view.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/models/models.dart';

/// My hours — today and this week. TODO: daily timecard from `GET /me/timecard`.
class HoursPage extends StatefulWidget {
  const HoursPage({super.key});

  @override
  State<HoursPage> createState() => _HoursPageState();
}

class _HoursPageState extends State<HoursPage> {
  late final Future<MeStatus> _status = context.repos.punches.myStatus();

  @override
  Widget build(BuildContext context) {
    return CrewBody(
      children: [
        Text(context.t('myHours'), style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28)),
        const SizedBox(height: 16),
        AsyncView<MeStatus>(
          future: _status,
          builder: (s) => Row(
            children: [
              Expanded(child: TmStatTile(label: context.t('today'), value: formatMinutes(s.todayMinutes))),
              const SizedBox(width: 12),
              Expanded(child: TmStatTile(label: context.t('thisWeek'), value: formatMinutes(s.weekMinutes))),
            ],
          ),
        ),
      ],
    );
  }
}
