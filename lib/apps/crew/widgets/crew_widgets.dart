import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/theme_lang_controls.dart';
import 'package:tm_clock/core/widgets/tm_logo.dart';

/// `.big` — the one main action per screen: 72px tall, 18px radius, Plex 22 bold.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.outlined = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger, outlined, busy;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final bg = outlined ? c.panel : (danger ? c.red : c.g);
    final fg = outlined ? c.ink : (danger ? c.bg : c.gInk);
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 72),
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          disabledForegroundColor: fg,
          side: outlined ? BorderSide(color: c.line2, width: 2) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.ibmPlexSans(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        child: busy
            ? SizedBox.square(dimension: 26, child: CircularProgressIndicator(color: fg, strokeWidth: 3))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 26, color: fg), const SizedBox(width: 12)],
                  Flexible(child: Text(label, textAlign: TextAlign.center)),
                ],
              ),
      ),
    );
  }
}

/// Top bar on every crew screen: logo, role badge, theme toggle, EN/ES.
class CrewTopBar extends StatelessWidget {
  const CrewTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final role = context.session.role;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Flexible(child: TmLogo(markSize: 28, fontSize: 16)),
                if (role != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: c.accentBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      context.t('role_${role.name}'),
                      maxLines: 1,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.accent2),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          const LanguageSwitch(),
        ],
      ),
    );
  }
}

/// Card row with icon, title, subtitle and trailing chevron/pill (home links, Me rows).
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconBg,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconBg, iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBg ?? c.raise, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor ?? c.soft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(color: c.mute, fontSize: 14)),
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

/// Full-width scrolling body with the prototype's 16px gutters.
class CrewBody extends StatelessWidget {
  const CrewBody({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: children,
      );
}

String formatMinutes(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m m';
}
