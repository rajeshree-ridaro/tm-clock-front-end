import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/features/dashboard/presentation/punch_edit_dialog.dart';
import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/apps/portal/widgets/formats.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/theme/tm_typography.dart';
import 'package:tm_clock/data/models/models.dart';
import 'package:tm_clock/data/models/timecards.dart';

/// "Punches on the map" (prototype `mapModal`). Returns true when something changed.
Future<bool> showDayMapDialog(
  BuildContext context, {
  required PayPeriod period,
  required TimecardRow row,
  required TimecardDay day,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => withPortal(context, _DayMapDialog(period: period, row: row, day: day)),
    ) ??
    false;

const _breakColor = Color(0xFF7FB2F0);
const _outColor = Color(0xFFF5B942);

class _DayMapDialog extends StatefulWidget {
  const _DayMapDialog({required this.period, required this.row, required this.day});
  final PayPeriod period;
  final TimecardRow row;
  final TimecardDay day;

  @override
  State<_DayMapDialog> createState() => _DayMapDialogState();
}

class _DayMapDialogState extends State<_DayMapDialog> {
  late Future<TimecardDayDetail> _detail = _fetch();
  bool _changed = false;
  bool _adding = false;
  TimeOfDay _outTime = const TimeOfDay(hour: 15, minute: 30);
  bool _saving = false;

  Future<TimecardDayDetail> _fetch() =>
      context.repos.timecards.day(widget.period.id, widget.row.user.id, widget.day.date);

  void _reload() => setState(() {
    _changed = true;
    _detail = _fetch();
  });

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Color _kindColor(BuildContext context, Punch p) {
    if (p.inside == false) return context.tm.red;
    return switch (p.kind) {
      PunchKind.clockIn => context.tm.ok,
      PunchKind.breakStart || PunchKind.breakEnd => _breakColor,
      PunchKind.clockOut => _outColor,
    };
  }

  Future<void> _edit(Punch p) async {
    final saved = await showPunchEditDialog(context, p);
    if (saved != null && mounted) {
      _toast(context.t('peSaved'));
      _reload();
    }
  }

  Future<void> _addOut(TimecardDayDetail d) async {
    final repo = context.repos.timecards;
    final done = context.t('tAddedOut');
    final at = Fmt.instant(context, widget.day.date, _outTime);
    setState(() => _saving = true);
    try {
      await repo.addClockOut(
        userId: widget.row.user.id,
        at: at,
        siteId: d.punches.isEmpty ? null : d.punches.first.site?.id,
      );
      _toast(done);
      _adding = false;
      _reload();
    } on Exception catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final date = widget.day.date;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: FutureBuilder<TimecardDayDetail>(
          future: _detail,
          builder: (context, snap) {
            final d = snap.data;
            final siteName = d?.siteName ?? widget.day.site?.name ?? '—';
            final dayLabel =
                '${Fmt.dayHeader(context, date).split(',').first.substring(0, 3)}, ${Fmt.date(context, date).split(',').first}';
            final header = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('mapTitle'),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink),
                      ),
                      Text(
                        '${widget.row.user.name} · $dayLabel · $siteName',
                        style: TextStyle(fontSize: 14, color: c.mute),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.t('peCancel'),
                  onPressed: () => Navigator.of(context).pop(_changed),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            );
            if (d == null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    header,
                    const SizedBox(height: 40),
                    snap.hasError
                        ? Text('${snap.error}', style: TextStyle(color: c.red))
                        : const CircularProgressIndicator(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            }
            final map = ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 600 / 340,
                child: CustomPaint(
                  painter: _MapPainter(
                    colors: c,
                    pins: [for (final p in d.punches) (_kindColor(context, p), p.inside == false)],
                    building: siteName.contains(' — ') ? siteName.split(' — ').last : siteName.split(' ').first,
                    farLabel: d.punches
                        .where((p) => p.inside == false)
                        .map((p) => Fmt.distance(p.distanceFt))
                        .firstOrNull,
                    scale: '${d.radiusFt} ${context.t('ft')}',
                  ),
                ),
              ),
            );
            final list = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < d.punches.length; i++) _punchRow(context, d.punches[i], i),
                if (d.missingOut) _missingOut(context, d),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.t('dayTotal'),
                          style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                        ),
                      ),
                      Text(
                        d.missingOut ? '? h' : '${(d.minutes / 60).toStringAsFixed(1)} h',
                        style: TmType.mono(c.ink, size: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _legend(context, context.t('geofence'), c.okBg, dashed: true),
                    _legend(context, context.t('k_in'), c.ok, round: true),
                    _legend(context, context.t('k_breakStart'), _breakColor, round: true),
                    _legend(context, context.t('k_out'), _outColor, round: true),
                    _legend(context, context.t('outBound'), c.red, round: true),
                  ],
                ),
              ],
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 16),
                  if (context.screenWidth < 900) ...[
                    map,
                    const SizedBox(height: 16),
                    list,
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: map),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: list),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(context.t('mapNote'), style: TextStyle(fontSize: 12, color: c.mute)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _punchRow(BuildContext context, Punch p, int i) {
    final c = context.tm;
    final color = _kindColor(context, p);
    final outside = p.inside == false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: c.raise, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '${i + 1}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16141F)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.t('k_${punchKindWire[p.kind]}')} · ${Fmt.clock(context, p.at)}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                ),
                Text(
                  '${context.t(outside ? 'outBound' : 'inBound')} · ${Fmt.distance(p.distanceFt)}',
                  style: TextStyle(fontSize: 13, color: outside ? c.red : c.ok),
                ),
                if (p.flags.contains('manual'))
                  Text(context.t('added'), style: TextStyle(fontSize: 12, color: c.amber))
                else if (p.edited != null)
                  Text(
                    [
                      context.t('edited'),
                      if (p.edited!.from != null) '${context.t('apWas')} ${Fmt.clock(context, p.edited!.from!)}',
                      if (p.edited!.by != null) p.edited!.by!.name,
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: c.amber),
                  ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.photo, borderRadius: BorderRadius.circular(8)),
            child: Text(
              p.flags.contains('manual') ? '—' : widget.row.user.initials,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.soft),
            ),
          ),
          IconButton(
            tooltip: '${context.t('peTitle')} ${i + 1}',
            onPressed: () => _edit(p),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _missingOut(BuildContext context, TimecardDayDetail d) {
    final c = context.tm;
    if (_adding) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.noBg, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('addOutTitle'),
              style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: _outTime);
                    if (t != null) setState(() => _outTime = t);
                  },
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(MaterialLocalizations.of(context).formatTimeOfDay(_outTime)),
                ),
                FilledButton(onPressed: _saving ? null : () => _addOut(d), child: Text(context.t('addOut'))),
                TextButton(
                  onPressed: _saving ? null : () => setState(() => _adding = false),
                  child: Text(context.t('peCancel')),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: c.noBg, borderRadius: BorderRadius.circular(10)),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text(
            '⚠ ${context.t('noOut')}',
            style: TextStyle(color: c.red, fontWeight: FontWeight.w600),
          ),
          OutlinedButton(
            onPressed: widget.period.isLocked ? null : () => setState(() => _adding = true),
            child: Text(context.t('addOut')),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, String label, Color color, {bool round = false, bool dashed = false}) {
    final c = context.tm;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: round ? BoxShape.circle : BoxShape.rectangle,
            border: dashed ? Border.all(color: c.ok, width: 2) : null,
            borderRadius: round ? null : BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: c.mute)),
      ],
    );
  }
}

/// Schematic street map (prototype SVG, viewBox 600×340): blocks, streets, the job-site
/// boundary, the building, numbered pins, an arrow to a far-away punch, and a scale bar.
/// TODO: a live map (Google Maps / Mapbox) with the real GPS points.
class _MapPainter extends CustomPainter {
  _MapPainter({required this.colors, required this.pins, required this.building, required this.scale, this.farLabel});
  final TmColors colors;
  final List<(Color, bool)> pins;
  final String building, scale;
  final String? farLabel;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 600, size.height / 340);
    final c = colors;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 600, 340), Paint()..color = c.map);
    final street = Paint()..color = c.street;
    for (final y in [60.0, 140.0, 250.0, 320.0]) {
      canvas.drawRect(Rect.fromLTWH(0, y - (y == 250 ? 7 : 4), 600, y == 250 ? 14 : 8), street);
    }
    for (final x in [90.0, 210.0, 420.0, 520.0]) {
      canvas.drawRect(Rect.fromLTWH(x - (x == 420 ? 7 : 4), 0, x == 420 ? 14 : 8, 340), street);
    }
    final block = Paint()..color = c.block;
    for (final b in const [
      [20, 80, 55, 45],
      [110, 80, 80, 45],
      [440, 150, 70, 85],
      [20, 270, 60, 40],
      [230, 270, 70, 35],
      [440, 270, 70, 40],
      [540, 150, 55, 85],
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(b[0].toDouble(), b[1].toDouble(), b[2].toDouble(), b[3].toDouble()),
          const Radius.circular(4),
        ),
        block,
      );
    }
    // Job-site boundary (dashed circle)
    const center = Offset(300, 175);
    canvas.drawCircle(center, 118, Paint()..color = c.fence);
    final dash = Paint()
      ..color = c.ok
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var a = 0.0; a < 2 * math.pi; a += 0.12) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: 118), a, 0.07, false, dash);
    }
    // Building
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(255, 140, 90, 70), const Radius.circular(6)),
      Paint()..color = c.photo,
    );
    _text(canvas, building, const Offset(300, 175), c.mute, 12);
    // Arrow + distance to a far-away punch
    if (farLabel != null) {
      final arrow = Paint()
        ..color = const Color(0xFFF28B96)
        ..strokeWidth = 2;
      for (var t = 0.0; t < 1; t += 0.08) {
        final p1 = Offset.lerp(const Offset(370, 140), const Offset(530, 78), t)!;
        final p2 = Offset.lerp(const Offset(370, 140), const Offset(530, 78), math.min(1, t + 0.04))!;
        canvas.drawLine(p1, p2, arrow);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(430, 96, 78, 24), const Radius.circular(6)),
        Paint()..color = c.noBg,
      );
      _text(canvas, farLabel!, const Offset(469, 108), c.red, 12, bold: true);
    }
    // Pins: inside ones spread around the building; outside ones out at the arrow's end.
    for (var i = 0; i < pins.length; i++) {
      final (color, far) = pins[i];
      final base = far
          ? Offset(540.0 + (i % 2) * 18, 92.0 + i * 6)
          : Offset(270.0 + (i % 3) * 30, 240.0 - (i ~/ 3) * 70 - (i % 2) * 10);
      canvas.drawLine(
        base,
        base - const Offset(0, 26),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
      canvas.drawCircle(base - const Offset(0, 30), 11, Paint()..color = color);
      canvas.drawCircle(
        base - const Offset(0, 30),
        11,
        Paint()
          ..color = const Color(0xFF16141F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _text(canvas, '${i + 1}', base - const Offset(0, 30), const Color(0xFF16141F), 12, bold: true);
    }
    // Scale bar
    final bar = Paint()
      ..color = c.mute
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(20, 312), const Offset(100, 312), bar);
    canvas.drawLine(const Offset(20, 307), const Offset(20, 317), bar);
    canvas.drawLine(const Offset(100, 307), const Offset(100, 317), bar);
    _text(canvas, scale, const Offset(130, 312), c.mute, 11);
  }

  void _text(Canvas canvas, String s, Offset center, Color color, double size, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 200);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.pins != pins || old.colors != colors || old.farLabel != farLabel;
}
