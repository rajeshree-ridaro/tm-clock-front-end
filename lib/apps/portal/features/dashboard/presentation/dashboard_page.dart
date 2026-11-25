import 'package:flutter/material.dart';

import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/async_view.dart';
import 'package:tm_clock/core/widgets/crew_status_row.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/models/models.dart';

/// Dashboard — counts + live crew board from `GET /dashboard`.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Dashboard> _future = context.repos.punches.dashboard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cols = context.isPhone ? 1 : (context.isCompact ? 2 : 4);
    final company = context.session.company?.companyName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TmPageHeader(
          title: context.t('dash'),
          subtitle: company,
          actions: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Save as PDF'),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add timecard'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AsyncView<Dashboard>(
          future: _future,
          onRetry: () => setState(() => _future = context.repos.punches.dashboard()),
          builder: (d) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: cols == 1 ? 3.2 : 2.0,
                children: [
                  TmStatTile(label: 'On the clock', value: '${d.onClockCount}', hint: 'of ${d.scheduled} scheduled'),
                  TmStatTile(label: 'On break', value: '${d.onBreak}'),
                  TmStatTile(label: 'Late', value: '${d.late}'),
                  TmStatTile(label: 'Photos to approve', value: '${d.toReview}'),
                ],
              ),
              const SizedBox(height: 22),
              TmCard(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Live crew board', style: text.titleLarge),
                    const SizedBox(height: 12),
                    for (final e in d.onClock)
                      DecoratedBox(
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.tm.line))),
                        child: CrewStatusRow(entry: e),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
