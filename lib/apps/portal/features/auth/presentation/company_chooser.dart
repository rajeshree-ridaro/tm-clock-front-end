import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/features/shell/company_switcher.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/data/models/models.dart';

/// "Choose a company" (prototype `coChooser`): shown in the sign-in panel when the login
/// belongs to several companies. Employee-only memberships are listed but disabled —
/// they use the crew app. Picking one calls `POST /auth/select-company`, and the router
/// then opens the dashboard.
class CompanyChooser extends StatefulWidget {
  const CompanyChooser({super.key});

  @override
  State<CompanyChooser> createState() => _CompanyChooserState();
}

class _CompanyChooserState extends State<CompanyChooser> {
  bool _remember = false;
  String? _busyId;

  Future<void> _pick(Membership m) async {
    final services = context.services;
    final messenger = ScaffoldMessenger.of(context);
    final done = '${context.t('coNowIn')} ${m.companyName} · ${context.t('role_${m.role.name}')}';
    setState(() => _busyId = m.companyId);
    try {
      await services.session.selectCompany(m, client: services.client, remember: _remember);
      messenger
        ..removeCurrentSnackBar() // don't queue behind an old sign-in message
        ..showSnackBar(SnackBar(content: Text(done)));
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _differentAccount() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.session.signOut();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    final companies = context.session.companies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.t('coTitle'), style: text.headlineMedium),
        const SizedBox(height: 6),
        Text(context.t('coSub'), style: text.bodyMedium?.copyWith(color: c.mute)),
        const SizedBox(height: 18),
        for (final m in companies) ...[
          _CompanyRow(
            membership: m,
            busy: _busyId == m.companyId,
            onTap: m.portalAllowed && _busyId == null ? () => _pick(m) : null,
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        MergeSemantics(
          child: Row(
            children: [
              Switch(value: _remember, onChanged: (v) => setState(() => _remember = v)),
              const SizedBox(width: 10),
              Flexible(
                child: GestureDetector(
                  onTap: () => setState(() => _remember = !_remember),
                  child: Text(context.t('coRemember'), style: text.titleSmall),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(context.t('coRoleNote'), style: text.bodySmall?.copyWith(color: c.mute)),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _busyId == null ? _differentAccount : null,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: c.g2),
            child: Text('← ${context.t('coBack')}'),
          ),
        ),
      ],
    );
  }
}

/// `.coitem.big`: gradient initials tile, name, "Role · City · Plan", crew-app-only note.
class _CompanyRow extends StatelessWidget {
  const _CompanyRow({required this.membership, required this.busy, this.onTap});
  final Membership membership;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final m = membership;
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    final crewOnly = !m.portalAllowed;
    final details = [
      context.t('role_${m.role.name}'),
      if (m.city.isNotEmpty) m.city,
      context.t('plan_${m.plan}'),
    ].join(' · ');

    return Opacity(
      opacity: crewOnly ? 0.6 : 1,
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          onTap: onTap,
          hoverColor: c.raise,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CompanyAvatar(membership: m, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.companyName,
                          style: text.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 1),
                        Text(details, style: text.bodySmall?.copyWith(color: c.mute)),
                        if (crewOnly) Text(context.t('coCrewOnly'), style: text.bodySmall?.copyWith(color: c.amber)),
                      ],
                    ),
                  ),
                  if (busy) const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
