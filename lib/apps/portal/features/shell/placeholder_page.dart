import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/widgets/portal_header.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';

/// Temporary body for pages not built yet. Replace per feature.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.titleKey, required this.icon});
  final String titleKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PortalHeader(title: context.t(titleKey), showHistory: titleKey != 'hist'),
        const SizedBox(height: 22),
        TmCard(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: c.dim),
              const SizedBox(height: 12),
              Text(context.t('soon'), style: TextStyle(color: c.mute)),
            ],
          ),
        ),
      ],
    );
  }
}
