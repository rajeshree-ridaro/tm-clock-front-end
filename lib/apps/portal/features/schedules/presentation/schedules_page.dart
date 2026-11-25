import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/features/shell/placeholder_page.dart';

class SchedulesPage extends StatelessWidget {
  const SchedulesPage({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderPage(
    titleKey: 'sch',
    icon: Icons.calendar_month_outlined,
  );
}
