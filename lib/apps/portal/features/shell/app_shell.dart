import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/apps/portal/router/portal_routes.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/theme_lang_controls.dart';
import 'package:tm_clock/core/widgets/tm_logo.dart';
import 'package:tm_clock/apps/portal/features/shell/nav_items.dart';

/// Signed-in layout: side menu + content on desktop; the menu becomes a
/// scrolling top bar under [Breakpoints.tablet] (prototype `nav.side`).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final content = _Content(child: child);
    if (compact) {
      return Scaffold(
        body: Column(
          children: [
            _TopBar(location: location),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SideNav(location: location),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pad = context.isPhone
        ? const EdgeInsets.fromLTRB(16, 20, 16, 40)
        : const EdgeInsets.fromLTRB(32, 28, 32, 48);
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
      width: Breakpoints.sideNavWidth,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(right: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Align(alignment: Alignment.centerLeft, child: TmLogo()),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ListView(
              children: [
                for (final item in navItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _MenuLink(item: item, selected: location == item.path),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _PlanCard(),
          const SizedBox(height: 12),
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            children: [LanguageSwitch(), ThemeToggleButton()],
          ),
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
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in navItems)
                    _MenuLink(item: item, selected: location == item.path, dense: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.menu a` / `.menu a.on`
class _MenuLink extends StatelessWidget {
  const _MenuLink({required this.item, required this.selected, this.dense = false});
  final NavItem item;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Material(
      color: selected ? c.raise : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(item.path),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 8 : 11),
          child: Row(
            mainAxisSize: dense ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(item.icon, size: 20, color: selected ? c.g2 : c.soft),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  context.t(item.labelKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: selected ? c.strong : c.soft,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.plan` — plan usage card at the bottom of the side menu.
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    const used = 18, limit = 50;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.raise, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('plan'), style: text.titleSmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(value: used / limit, minHeight: 6),
          ),
          const SizedBox(height: 8),
          Text('$used / $limit ${context.t('planUse')}', style: text.bodySmall),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => context.go(Routes.settings),
            child: Text(
              context.t('upgrade'),
              style: text.labelMedium?.copyWith(color: c.g2),
            ),
          ),
        ],
      ),
    );
  }
}
