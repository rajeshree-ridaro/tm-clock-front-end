import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/portal/features/shell/company_switcher.dart';
import 'package:tm_clock/apps/portal/features/shell/nav_items.dart';
import 'package:tm_clock/apps/portal/router/portal_routes.dart';
import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/apps/portal/widgets/formats.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/theme/tm_typography.dart';
import 'package:tm_clock/core/widgets/theme_lang_controls.dart';
import 'package:tm_clock/core/widgets/tm_logo.dart';

/// Signed-in layout: side menu + content on desktop; the menu becomes a
/// scrolling top bar under [Breakpoints.tablet] (prototype `nav.side`).
/// Owns the [PortalStore] every page and the menu share.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PortalStore _store = PortalStore(context.services);

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _Content(child: widget.child);
    return PortalScope(
      store: _store,
      child: Scaffold(
        body: context.isCompact
            ? Column(children: [_TopBar(location: widget.location), Expanded(child: content)])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_SideNav(location: widget.location), Expanded(child: content)],
              ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pad = context.isPhone ? const EdgeInsets.fromLTRB(16, 20, 16, 40) : const EdgeInsets.fromLTRB(36, 32, 36, 48);
    return SingleChildScrollView(
      padding: pad,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
          child: child,
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Container(
      width: Breakpoints.sideNavWidth + 40,
      decoration: BoxDecoration(color: c.panel, border: Border(right: BorderSide(color: c.line))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Align(alignment: Alignment.centerLeft, child: TmLogo()),
          ),
          const SizedBox(height: 22),
          const CompanySwitcher(),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: [
                for (final item in navItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _MenuLink(item: item, selected: location == item.path),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _PlanCard(),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Container(
      decoration: BoxDecoration(color: c.panel, border: Border(bottom: BorderSide(color: c.line))),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                TmLogo(markSize: 30, fontSize: 17),
                Spacer(),
                LanguageSwitch(),
                SizedBox(width: 8),
                ThemeToggleButton(),
              ],
            ),
            const SizedBox(height: 8),
            const CompanySwitcher(),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in navItems) _MenuLink(item: item, selected: location == item.path, dense: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.menu a` / `.menu a.on` (+ `.n` count badge on Photo approvals).
class _MenuLink extends StatelessWidget {
  const _MenuLink({required this.item, required this.selected, this.dense = false});
  final NavItem item;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final badge = item.path == Routes.approvals ? context.portal.pending : 0;
    return Material(
      color: selected ? c.raise : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(item.path),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 8 : 12),
          child: Row(
            mainAxisSize: dense ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(item.icon, size: 20, color: selected ? c.g2 : c.soft),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  context.t(item.labelKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: selected ? c.strong : c.soft,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (badge > 0) ...[
                if (!dense) const Spacer() else const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 26),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: c.amber, borderRadius: BorderRadius.circular(999)),
                  child: Text('$badge',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.bg)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.plan` — plan, history kept, seats used, remove-ads link and Sign out.
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final store = context.portal;
    final me = store.me;
    final tier = me?.planTier ?? 'free';
    final used = me?.seatsUsed ?? 0;
    final limit = me?.seats ?? 0;
    final planLabel = tier == 'free' ? context.t('plan') : context.t('plan_$tier');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.raise, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tf('planHist', {'plan': planLabel, 'days': Fmt.retention(context, me?.retentionDays ?? 90)}).toUpperCase(),
            style: TmType.label(c.mute),
          ),
          const SizedBox(height: 6),
          Text(context.tf('planSeats', {'n': used, 'max': limit}),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: limit == 0 ? 0 : (used / limit).clamp(0, 1), minHeight: 6),
          ),
          if (store.isFree) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => context.go(Routes.settings),
              child: Text(
                context.tf('adPlansShort', {
                  'pro': '${store.plan('pro')?.yearlyDollars ?? '—'}',
                  'biz': '${store.plan('business')?.yearlyDollars ?? '—'}',
                }),
                style: TextStyle(fontSize: 13, height: 1.35, color: c.g2),
              ),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _signOut(context),
            child: Text(context.t('signout'), style: TextStyle(fontSize: 13, color: c.mute)),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.session.signOut();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
