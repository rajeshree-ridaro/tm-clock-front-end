import 'package:flutter/material.dart';

import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/theme/tm_theme.dart';
import 'package:tm_clock/core/theme/tm_typography.dart';

/// `.card` — panel surface, 1px line border, 16px radius, 20px padding.
class TmCard extends StatelessWidget {
  const TmCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(TmTheme.radiusLg),
      ),
      child: child,
    );
  }
}

/// `.lbl` — small uppercase mono label.
class TmLabel extends StatelessWidget {
  const TmLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: TmType.label(context.tm.mute));
}

/// `.stat` — label over a big number, with optional hint line.
class TmStatTile extends StatelessWidget {
  const TmStatTile({super.key, required this.label, required this.value, this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(TmTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TmLabel(label),
          const SizedBox(height: 6),
          Text(value, style: TmType.statValue(c.ink), maxLines: 1),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

enum PillTone { ok, wait, no, brk }

/// `.pill.ok / .wait / .no / .brk` — rounded status pill with a dot.
class TmPill extends StatelessWidget {
  const TmPill(this.text, {super.key, this.tone = PillTone.ok});
  final String text;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final (bg, fg) = switch (tone) {
      PillTone.ok => (c.okBg, c.ok),
      PillTone.wait => (c.waitBg, c.amber),
      PillTone.no => (c.noBg, c.red),
      PillTone.brk => (c.breakBg, c.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.av` — 34px round avatar with initials.
class TmAvatar extends StatelessWidget {
  const TmAvatar(this.initials, {super.key, this.size = 34});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.line2, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w600, color: c.ink),
      ),
    );
  }
}

/// Page header row (`.top`): title + optional subtitle on the left, actions on the right.
class TmPageHeader extends StatelessWidget {
  const TmPageHeader({super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 12,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: text.headlineLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: text.bodyMedium?.copyWith(color: context.tm.mute)),
            ],
          ],
        ),
        if (actions.isNotEmpty) Wrap(spacing: 12, runSpacing: 12, children: actions),
      ],
    );
  }
}
