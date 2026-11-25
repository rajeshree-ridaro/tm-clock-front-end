import 'package:flutter/material.dart';

import 'package:tm_clock/apps/crew/router/crew_router.dart';
import 'package:tm_clock/core/app/tm_app.dart';
import 'package:tm_clock/core/theme/tm_theme.dart';

/// iOS / Android app for crews and supervisors.
class CrewApp extends StatelessWidget {
  const CrewApp({super.key});

  @override
  Widget build(BuildContext context) => const TmApp(
        flavor: TmFlavor.crew,
        title: 'TM Clock',
        buildRouter: buildCrewRouter,
      );
}
