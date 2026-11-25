import 'package:flutter/material.dart';

import 'package:tm_clock/apps/crew/widgets/crew_widgets.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/models/models.dart';

/// "Choose a company" — shown when the login belongs to several companies.
class PickCompanyPage extends StatelessWidget {
  const PickCompanyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    final session = context.session;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CrewTopBar(),
            Expanded(
              child: CrewBody(
                children: [
                  Text('${context.t('signedInAs')} ${session.user?.name ?? ''}',
                      style: TextStyle(color: c.soft, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(context.t('pickTitle'), style: text.headlineLarge?.copyWith(fontSize: 28)),
                  const SizedBox(height: 12),
                  Text(context.t('pickSub'), style: text.bodyMedium?.copyWith(color: c.soft)),
                  const SizedBox(height: 20),
                  for (final m in session.companies) ...[
                    CompanyTile(membership: m, onTap: () => _pick(context, m)),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  TmCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('dataSeparate'), style: text.titleSmall),
                        const SizedBox(height: 4),
                        Text(context.t('dataSeparateSub'), style: TextStyle(color: c.soft, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, Membership m) async {
    final s = context.services;
    final messenger = ScaffoldMessenger.of(context);
    final nowWorking = context.t('nowWorking');
    await s.session.selectCompany(m, client: s.client);
    messenger.showSnackBar(SnackBar(content: Text('$nowWorking ${m.companyName}')));
  }
}

/// Company row: initials tile, name, city · role, last used.
class CompanyTile extends StatelessWidget {
  const CompanyTile({super.key, required this.membership, this.onTap, this.trailing});
  final Membership membership;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final m = membership;
    final c = context.tm;
    final last = m.lastActiveAt == null
        ? null
        : '${context.t('lastUsed')}: ${MaterialLocalizations.of(context).formatShortMonthDay(m.lastActiveAt!)}';
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.line)),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.raise, borderRadius: BorderRadius.circular(12)),
                child: Text(m.initials, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.companyName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17)),
                    Text('${m.city} · ${context.t('role_${m.role.name}')}',
                        style: TextStyle(color: c.soft, fontSize: 14)),
                    if (last != null) Text(last, style: TextStyle(color: c.mute, fontSize: 14)),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: c.mute),
            ],
          ),
        ),
      ),
    );
  }
}
