import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/features/shell/placeholder_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderPage(titleKey: 'set', icon: Icons.settings_outlined);
}
