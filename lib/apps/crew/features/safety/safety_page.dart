import 'package:flutter/material.dart';

import 'package:tm_clock/apps/crew/widgets/crew_widgets.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';

/// Safety briefing (PTSA). TODO: 4 steps — task, hazards, PPE, signatures (`/briefings`).
class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return CrewBody(
      children: [
        Text(context.t('brief'), style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28)),
        const SizedBox(height: 16),
        TmCard(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(children: [
            Icon(Icons.shield_outlined, size: 40, color: c.dim),
            const SizedBox(height: 12),
            Text(context.t('soon'), style: TextStyle(color: c.mute)),
          ]),
        ),
      ],
    );
  }
}
