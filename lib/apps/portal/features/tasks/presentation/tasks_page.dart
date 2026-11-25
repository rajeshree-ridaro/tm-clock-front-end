import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/features/shell/placeholder_page.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderPage(titleKey: 'tasks', icon: Icons.checklist_rounded);
}
