import 'package:flutter/material.dart';

import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/models/models.dart';

/// One crew member on the clock: avatar, name, site, since, status pill.
/// Shared by the portal dashboard and the crew app's "My crew" tab.
class CrewStatusRow extends StatelessWidget {
  const CrewStatusRow({super.key, required this.entry, this.onTap});
  final OnClockEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final (tone, label) = switch (entry.state) {
      _ when entry.photo == ReviewStatus.pending && entry.state == WorkState.working =>
        (PillTone.wait, 'Photo pending'),
      WorkState.working => (PillTone.ok, 'Working'),
      WorkState.late => (PillTone.wait, 'Late'),
      WorkState.onBreak => (PillTone.brk, 'On break'),
      WorkState.offSite => (PillTone.no, 'Off site'),
    };
    final since = TimeOfDay.fromDateTime(entry.since).format(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            TmAvatar(entry.user.initials),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    context.isPhone ? '${entry.site?.name ?? '—'} · $since' : entry.site?.name ?? '—',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!context.isPhone) ...[
              Text(since, style: TextStyle(color: c.soft)),
              const SizedBox(width: 16),
            ],
            TmPill(label, tone: tone),
          ],
        ),
      ),
    );
  }
}
