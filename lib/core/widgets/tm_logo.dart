import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tm_clock/core/theme/tm_colors.dart';

/// TM Clock mark (open clock ring + hand + crown tick), drawn from the
/// brand SVG (viewBox 48x48) so it follows the light/dark logo colours.
class TmMark extends StatelessWidget {
  const TmMark({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(ring: c.logoRing, crown: c.logoCrown),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.ring, required this.crown});
  final Color ring, crown;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ring: r=14, dash 72.5 of 88 circumference, rotated -8°.
    const r = 14.0;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(23, 26), radius: r),
      -8 * math.pi / 180,
      72.5 / r,
      false,
      stroke
        ..color = ring
        ..strokeWidth = 5,
    );
    // Hand
    canvas.drawLine(
      const Offset(23, 26),
      const Offset(29.5, 19.5),
      stroke..strokeWidth = 3.2,
    );
    canvas.drawCircle(const Offset(23, 26), 3.4, Paint()..color = ring);
    // Crown tick (×)
    stroke.color = crown;
    canvas.drawLine(const Offset(35.2, 13.8), const Offset(39.6, 9.4), stroke);
    canvas.drawLine(const Offset(37.2, 7.4), const Offset(41.6, 11.8), stroke);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.ring != ring || old.crown != crown;
}

/// Mark + "TM Clock" wordmark (`.brand`).
class TmLogo extends StatelessWidget {
  const TmLogo({super.key, this.markSize = 38, this.fontSize = 20});
  final double markSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final style = GoogleFonts.ibmPlexSans(fontSize: fontSize, fontWeight: FontWeight.w700);
    return LayoutBuilder(
      builder: (context, box) {
        // Narrow phones: show just the mark rather than squeezing the wordmark.
        if (box.maxWidth < markSize + 10 + fontSize * 3) {
          return TmMark(size: markSize.clamp(0, box.maxWidth));
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TmMark(size: markSize),
            const SizedBox(width: 10),
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'TM ', style: style.copyWith(color: c.wordmarkTm)),
                  TextSpan(text: 'Clock', style: style.copyWith(color: c.wordmarkClock)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
