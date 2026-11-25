import 'package:flutter/material.dart';

import 'package:tm_clock/apps/crew/features/company/pick_company_page.dart';
import 'package:tm_clock/apps/crew/widgets/crew_widgets.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/settings/app_settings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/models/models.dart';

/// Me — profile, company details, switch company, sign out.
class MePage extends StatelessWidget {
  const MePage({super.key});

  Future<void> _switch(BuildContext context, Membership m) async {
    final s = context.services;
    final messenger = ScaffoldMessenger.of(context);
    final blocked = context.t('switchBlocked');
    final nowWorking = context.t('nowWorking');
    final status = await s.repos.punches.myStatus();
    if (status.state != ClockState.out) {
      messenger.showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    await s.session.selectCompany(m, client: s.client);
    messenger.showSnackBar(SnackBar(content: Text('$nowWorking ${m.companyName}')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    final session = context.session;
    final user = session.user;
    final company = session.company;
    final lang = AppSettingsScope.of(context).locale.languageCode == 'es' ? 'Español' : 'English';

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Text(k, style: TextStyle(color: c.soft)),
            const Spacer(),
            Flexible(child: Text(v, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
        );

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => CrewBody(
        children: [
          Text(context.t('profile'), style: text.headlineLarge?.copyWith(fontSize: 28)),
          const SizedBox(height: 16),
          TmCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              TmAvatar(user?.initials ?? '', size: 52),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name ?? '', style: text.titleMedium?.copyWith(fontSize: 18)),
                if (company != null)
                  Text(context.t('role_${company.role.name}'), style: TextStyle(color: c.soft)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          TmCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(children: [
              row(context.t('company'), company?.companyName ?? ''),
              row(context.t('role'), company == null ? '' : context.t('role_${company.role.name}')),
              row(context.t('language'), lang),
            ]),
          ),
          if (session.companies.length > 1) ...[
            const SizedBox(height: 20),
            Text(context.t('myCompanies'), style: text.titleSmall),
            const SizedBox(height: 10),
            for (final m in session.companies) ...[
              CompanyTile(
                membership: m,
                onTap: m.companyId == company?.companyId ? null : () => _switch(context, m),
                trailing: m.companyId == company?.companyId
                    ? TmPill(context.t('current'))
                    : Text(context.t('switchCo'), style: TextStyle(color: c.g2, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: session.signOut,
            icon: Icon(Icons.logout_rounded, color: c.red),
            label: Text(context.t('signOut'), style: TextStyle(color: c.red)),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}
