import 'package:flutter/material.dart';

import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/data/models/models.dart';

/// `.coav` — company initials on the brand gradient.
class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar({super.key, required this.membership, this.size = 34});
  final Membership membership;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.accent, c.g2]),
      ),
      child: Text(
        membership.initials,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

/// Company switcher in the portal menu (prototype `coSwitch`): shows the current company and
/// role; opens "Your companies". Picking another calls `POST /auth/select-company` and the
/// shell rebuilds the page, so everything reloads for the new company.
class CompanySwitcher extends StatefulWidget {
  const CompanySwitcher({super.key});

  @override
  State<CompanySwitcher> createState() => _CompanySwitcherState();
}

class _CompanySwitcherState extends State<CompanySwitcher> {
  final _menu = MenuController();
  String? _busyId;

  Future<void> _pick(Membership m) async {
    _menu.close();
    final services = context.services;
    if (m.companyId == services.session.company?.companyId) return;
    final messenger = ScaffoldMessenger.of(context);
    final done = '${context.t('coNowIn')} ${m.companyName} · ${context.t('role_${m.role.name}')}';
    setState(() => _busyId = m.companyId);
    try {
      await services.session.selectCompany(m, client: services.client);
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done)));
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final session = context.session;
    final current = session.company;
    if (current == null) return const SizedBox.shrink();

    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.panel),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: c.line),
          ),
        ),
        elevation: const WidgetStatePropertyAll(12),
      ),
      menuChildren: [
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                child: Text(
                  context.t('coYours').toUpperCase(),
                  style: TextStyle(fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: c.mute),
                ),
              ),
              for (final m in session.companies)
                _MenuItem(
                  membership: m,
                  current: m.companyId == current.companyId,
                  busy: _busyId == m.companyId,
                  onTap: m.portalAllowed && _busyId == null ? () => _pick(m) : null,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                child: Text(context.t('coOneLogin'), style: TextStyle(fontSize: 13, color: c.mute)),
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, _) => Semantics(
        button: true,
        label: context.t('coSwitch'),
        child: Material(
          color: c.raise,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.line),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    CompanyAvatar(membership: current),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            current.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink),
                          ),
                          Text(
                            '${context.t('role_${current.role.name}')} · ${context.t('plan_${current.plan}')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.mute),
                          ),
                        ],
                      ),
                    ),
                    if (_busyId != null)
                      const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Icon(Icons.expand_more_rounded, color: c.mute, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.coitem` (+ `.on` for the current company, disabled for crew-app-only memberships).
class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.membership, required this.current, required this.busy, this.onTap});
  final Membership membership;
  final bool current, busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final m = membership;
    final c = context.tm;
    final crewOnly = !m.portalAllowed;
    final details = [context.t('role_${m.role.name}'), if (m.city.isNotEmpty) m.city].join(' · ');
    return Opacity(
      opacity: crewOnly ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: current ? c.g2 : Colors.transparent),
          ),
          child: InkWell(
            onTap: onTap,
            hoverColor: c.raise,
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  CompanyAvatar(membership: m),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink),
                        ),
                        Text(details, style: TextStyle(fontSize: 12, color: c.mute)),
                        if (crewOnly) Text(context.t('coCrewOnly'), style: TextStyle(fontSize: 12, color: c.amber)),
                      ],
                    ),
                  ),
                  if (busy)
                    const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  else if (current)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: c.okBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        context.t('coCurrent'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.ok),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
