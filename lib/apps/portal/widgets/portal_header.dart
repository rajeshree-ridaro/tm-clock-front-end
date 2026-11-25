import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/portal/router/portal_routes.dart';
import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/platform/print_page.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/theme/tm_typography.dart';
import 'package:tm_clock/core/widgets/theme_lang_controls.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';

/// Page header (`.top`): eyebrow + title on the left; Save as PDF, History, theme, EN/ES
/// and who's signed in on the right. Every portal page uses it.
class PortalHeader extends StatelessWidget {
  const PortalHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.eyebrowCaps = false,
    this.subtitle,
    this.showHistory = true,
    this.trailing = const [],
  });
  final String title;
  final String? eyebrow;

  /// Mono caps label (`.lbl`, e.g. "SUPERVISOR REVIEW") instead of plain small text.
  final bool eyebrowCaps;
  final String? subtitle;
  final bool showHistory;

  /// Page actions after the standard ones (e.g. "Approve all on site").
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null)
          Text(eyebrowCaps ? eyebrow!.toUpperCase() : eyebrow!,
              style: eyebrowCaps ? TmType.label(c.mute) : TextStyle(fontSize: 13, color: c.mute)),
        const SizedBox(height: 2),
        Text(title, style: text.headlineMedium?.copyWith(fontSize: context.isPhone ? 26 : 32, fontWeight: FontWeight.w700)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(subtitle!, style: TextStyle(fontSize: 14, color: c.mute)),
          ),
        ],
      ],
    );
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const _HeaderButton(kind: _HeaderAction.pdf),
        if (showHistory) const _HeaderButton(kind: _HeaderAction.history),
        if (!context.isCompact) ...[const ThemeToggleButton(), const LanguageSwitch()],
        const _WhoChip(),
        ...trailing,
      ],
    );
    return context.isCompact
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading, const SizedBox(height: 14), actions])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: heading), const SizedBox(width: 16), Flexible(child: actions)],
          );
  }
}

enum _HeaderAction { pdf, history }

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.kind});
  final _HeaderAction kind;

  void _onTap(BuildContext context) {
    switch (kind) {
      case _HeaderAction.pdf:
        if (!printPage()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('soon'))));
        }
      case _HeaderAction.history:
        context.go(Routes.history);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdf = kind == _HeaderAction.pdf;
    return Tooltip(
      message: context.t(pdf ? 'savePdfTip' : 'histTip'),
      child: OutlinedButton.icon(
        onPressed: () => _onTap(context),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 18)),
        icon: Icon(pdf ? Icons.file_download_outlined : Icons.history_rounded, size: 20),
        label: Text(context.t(pdf ? 'savePdf' : 'hist'), style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// `.who` — signed-in person and their role in this company.
class _WhoChip extends StatelessWidget {
  const _WhoChip();

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final me = context.portal.me;
    final session = context.session;
    final name = me?.userName ?? session.user?.name ?? '';
    final initials = me?.initials ?? session.user?.initials ?? '';
    final role = session.role;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TmAvatar(initials, size: 40),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_short(name), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink)),
            if (role != null) Text(context.t('role_${role.name}'), style: TextStyle(fontSize: 12, color: c.mute)),
          ],
        ),
      ],
    );
  }

  /// "Roque Rivera" → "Roque R." (prototype).
  static String _short(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    return parts.length < 2 ? name : '${parts.first} ${parts.last[0]}.';
  }
}
