import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/portal/features/dashboard/presentation/dashboard_sections.dart';
import 'package:tm_clock/apps/portal/features/timecards/presentation/add_timecard_dialog.dart';
import 'package:tm_clock/apps/portal/features/timecards/presentation/day_map_dialog.dart';
import 'package:tm_clock/apps/portal/router/portal_routes.dart';
import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/apps/portal/widgets/portal_header.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/platform/print_page.dart';
import 'package:tm_clock/core/platform/save_file.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/theme/tm_typography.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/models/timecards.dart';

/// Timecards (prototype `timecards()`): one row per person with daily hours for the pay
/// period, totals, overtime by the company's rule, status, and the period actions.
class TimecardsPage extends StatefulWidget {
  const TimecardsPage({super.key});

  @override
  State<TimecardsPage> createState() => _TimecardsPageState();
}

class _TimecardsPageState extends State<TimecardsPage> {
  List<PayPeriod> _periods = const [];
  int _index = 0; // 0 = current period
  TimecardSheet? _sheet;
  Object? _error;
  bool _busy = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    final repo = context.repos.timecards;
    try {
      final periods = await repo.payPeriods(limit: 12);
      if (!mounted) return;
      setState(() => _periods = periods);
      await _loadSheet();
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadSheet() async {
    if (_periods.isEmpty) return;
    final repo = context.repos.timecards;
    try {
      final sheet = await repo.timecards(_periods[_index].id);
      if (!mounted) return;
      setState(() {
        _sheet = sheet;
        _error = null;
        _selected.retainWhere((id) => sheet.items.any((r) => r.user.id == id));
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _pick(int index) {
    if (index < 0 || index >= _periods.length || _periods[index].dataState == DataState.deleted) return;
    setState(() {
      _index = index;
      _sheet = null;
      _selected.clear();
    });
    _loadSheet();
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  // ---------------------------------------------------------------- actions

  Future<void> _addTimecard() async {
    final sheet = _sheet;
    if (sheet == null) return;
    final result = await showAddTimecardDialog(context, sheet: sheet);
    if (!mounted || result == null) return;
    switch (result) {
      case TimecardSaved():
        _toast(context.t('tcAddedOk'));
        await _loadSheet();
      case DayHasTime(:final user, :final date):
        _toast(context.tf('tcHasTime', {'name': user.name}));
        final row = sheet.items.firstWhere((r) => r.user.id == user.id);
        final day = row.days.firstWhere((d) => d.date == DateTime(date.year, date.month, date.day));
        await _openDay(row, day);
    }
  }

  Future<void> _openDay(TimecardRow row, TimecardDay day) async {
    final sheet = _sheet;
    if (sheet == null || !day.hasTime) return;
    final changed = await showDayMapDialog(context, period: sheet.period, row: row, day: day);
    if (changed && mounted) await _loadSheet();
  }

  /// Row click → the person's last day with time (prototype `data-dayrow`).
  void _openRow(TimecardRow row) {
    final day = row.days.lastWhere((d) => d.hasTime, orElse: () => row.days.first);
    _openDay(row, day);
  }

  void _pdfs() {
    // TODO: server-rendered timecard PDFs for the selected people (`POST /pdf`); the browser print dialog for now.
    if (!printPage()) _toast(context.t('soon'));
  }

  Future<void> _exportCsv() async {
    final sheet = _sheet;
    if (sheet == null) return;
    final repo = context.repos.timecards;
    final done = context.t('tCsvDone');
    setState(() => _busy = true);
    try {
      final (name, csv) = await repo.exportCsv(sheet.period.id);
      final saved = saveTextFile(name, csv, mimeType: 'text/csv');
      _toast(saved ? '$done · $name' : done);
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve({bool force = false}) async {
    final sheet = _sheet;
    if (sheet == null) return;
    final repo = context.repos.timecards;
    final done = context.t('tPeriod');
    setState(() => _busy = true);
    try {
      final period = await repo.approve(sheet.period.id, force: force);
      if (!mounted) return;
      setState(() => _periods = [for (final p in _periods) p.id == period.id ? period : p]);
      _toast(done);
      await _loadSheet();
    } on ApiException catch (e) {
      if (e.code == 'TIMECARDS_NEED_FIX' && mounted) {
        final n = (e.details?['count'] as int?) ?? 0;
        final anyway = await _confirmNeedFix(n);
        if (anyway == true && mounted) {
          setState(() => _busy = false);
          return _approve(force: true);
        }
      } else {
        _toast(e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmNeedFix(int n) {
    final canForce = PortalScope.read(context).me?.permissions.contains('payperiod.editLocked') ?? false;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('tcNeedFixTitle')),
        content: Text(ctx.tf('tcNeedFixBody', {'n': n})),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(ctx.t('tcFixFirst'))),
          if (canForce)
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(ctx.t('tcApproveAnyway'))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final sheet = _sheet;
    final period = _periods.isEmpty ? null : _periods[_index];
    final typeKey = switch (period?.type) {
      'biweekly' => 'tcBiweekly',
      'semimonthly' => 'tcSemimonthly',
      _ => 'tcWeekly',
    };
    final locked = period?.isLocked ?? false;

    final header = PortalHeader(
      eyebrow: '${context.t('tcPeriod')} · ${context.t(typeKey)}',
      eyebrowCaps: true,
      title: context.t('tc'),
      trailing: [
        if (_periods.isNotEmpty) _picker(context),
        FilledButton(
          onPressed: sheet == null || locked || _busy ? null : _addTimecard,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(context.t('tcAdd'), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Tooltip(
          message: _selected.isEmpty ? context.t('tcPdfsTip') : '',
          child: OutlinedButton(
            onPressed: _selected.isEmpty ? null : _pdfs,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text('${context.t('tcPdfs')} (${_selected.length})'),
          ),
        ),
        OutlinedButton(
          onPressed: sheet == null || _busy ? null : _exportCsv,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(context.t('tcCsv')),
        ),
        OutlinedButton(
          onPressed: () => _toast(context.t('tLedger')),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(context.t('tcLedger')),
        ),
        if (locked)
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: c.okBg, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 16, color: c.ok),
                const SizedBox(width: 6),
                Text(
                  context.t('tcLocked'),
                  style: TextStyle(color: c.ok, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )
        else
          FilledButton(
            onPressed: sheet == null || _busy ? null : () => _approve(),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(context.t('tcApprove'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
      ],
    );

    if (sheet == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 40),
          Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      Text(
                        _error is ApiException ? (_error as ApiException).message : '$_error',
                        style: TextStyle(color: c.red),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _loadPeriods, child: Text(context.t('retry'))),
                    ],
                  ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 20),
        if (locked && !(period?.current ?? false)) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.raise,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.line2),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: c.mute),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(context.t('tcLockBar'), style: TextStyle(color: c.soft)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const RetentionBanner(),
        if (!context.portal.bannerHidden) const SizedBox(height: 16),
        _otLine(context, sheet.rule),
        const SizedBox(height: 16),
        _stats(context, sheet),
        const SizedBox(height: 20),
        DashCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sheet.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(context.t('tcNone'), style: TextStyle(color: c.mute)),
                  ),
                )
              else
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: _table(context, sheet)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(context.t('tcNote'), style: TextStyle(fontSize: 13, color: c.mute)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// `.pp` — ‹ period list ›
  Widget _picker(BuildContext context) {
    final c = context.tm;
    String label(PayPeriod p) => [
      p.label,
      if (p.current) context.t('tcCurrent'),
      if (p.dataState == DataState.deleted) context.t('tcDeleted'),
      if (p.dataState == DataState.partlyDeleted) context.t('tcPartly'),
    ].join(' · ');
    return Container(
      height: 48,
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.t('tcPrev'),
            onPressed: _index < _periods.length - 1 ? () => _pick(_index + 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _index,
                isExpanded: true,
                items: [
                  for (var i = 0; i < _periods.length; i++)
                    DropdownMenuItem(
                      value: i,
                      enabled: _periods[i].dataState != DataState.deleted,
                      child: Text(
                        label(_periods[i]),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
                onChanged: (i) => i == null ? null : _pick(i),
              ),
            ),
          ),
          IconButton(
            tooltip: context.t('tcNext'),
            onPressed: _index > 0 ? () => _pick(_index - 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  /// `.otline` — "Overtime: Federal (FLSA) · 1.5× > 40 h/week  Change"
  Widget _otLine(BuildContext context, OvertimeRule r) {
    final c = context.tm;
    final parts = [
      if (r.dailyHours != null) '1.5× > ${r.dailyHours} h/${context.t('tcDay')}',
      if (r.doubleAfter != null) '2× > ${r.doubleAfter} h/${context.t('tcDay')}',
      '1.5× > ${r.weeklyHours} h/${context.t('tcWeek')}',
      if (r.seventhDay != null) context.t('tc7th'),
    ];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${context.t('tcOt')}: ',
                style: TextStyle(color: c.soft),
              ),
              TextSpan(
                text: context.isSpanish ? r.nameEs : r.nameEn,
                style: TextStyle(color: c.ink, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: ' · ${parts.join(' · ')}',
                style: TextStyle(color: c.soft),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.go(Routes.settings),
          style: TextButton.styleFrom(foregroundColor: c.g2, padding: const EdgeInsets.symmetric(horizontal: 4)),
          child: Text(context.t('tcChange'), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _stats(BuildContext context, TimecardSheet s) {
    final c = context.tm;
    final tiles = [
      (context.t('tcReg'), (s.regularMin / 60).toStringAsFixed(1), c.ink),
      (context.t('tcOt'), (s.overtimeMin / 60).toStringAsFixed(1), c.amber),
      (context.t('tcFlag'), '${s.flagged}', s.flagged > 0 ? c.red : c.ok),
      (context.t('tcApproved'), '${s.approved} / ${s.items.length}', c.ok),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth < 600 ? 2 : 4;
        const gap = 16.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, value, color) in tiles)
              SizedBox(
                width: w,
                child: DashCard(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 13, color: c.mute)),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _table(BuildContext context, TimecardSheet s) {
    final c = context.tm;
    final dates = s.period.dates;
    final double2x = s.rule.hasDouble;
    final allSelected = _selected.length == s.items.length && s.items.isNotEmpty;
    const empW = 220.0, dayW = 64.0, numW = 76.0, stW = 140.0, boxW = 48.0;
    final head = TmType.label(c.mute);

    Widget checkbox(bool on, VoidCallback tap, String label, {Key? key}) => SizedBox(
      key: key,
      width: boxW,
      child: Center(
        child: Semantics(
          checked: on,
          label: label,
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? c.g : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: on ? c.g : c.line2, width: 2),
              ),
              child: on ? Icon(Icons.check_rounded, size: 16, color: c.gInk) : null,
            ),
          ),
        ),
      ),
    );
    Widget numCell(String text, double w, {Color? color, bool bold = false}) => SizedBox(
      width: w,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TmType.mono(color ?? c.ink, size: 14).copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
      ),
    );
    (String, PillTone) status(TimecardStatus st) => switch (st) {
      TimecardStatus.ok || TimecardStatus.approved => (context.t('tcStOk'), PillTone.ok),
      TimecardStatus.needsReview => (context.t('tcStReview'), PillTone.wait),
      TimecardStatus.needsFix => (context.t('tcStFix'), PillTone.no),
    };

    final header = Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          checkbox(
            allSelected,
            () => setState(() {
              if (allSelected) {
                _selected.clear();
              } else {
                _selected.addAll(s.items.map((r) => r.user.id));
              }
            }),
            context.t('tcSelAll'),
            key: const ValueKey('tc-select-all'),
          ),
          SizedBox(
            width: empW,
            child: Text(context.t('cEmp').toUpperCase(), style: head),
          ),
          for (final d in dates)
            SizedBox(
              width: dayW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_weekday(context, d), style: head),
                  Text('${d.day}', style: TextStyle(fontSize: 10, color: c.mute)),
                ],
              ),
            ),
          numCell(context.t('tcTotal').toUpperCase(), numW, color: c.mute),
          SizedBox(
            width: numW,
            child: Text('${context.t('tcOt').toUpperCase()} 1.5×', textAlign: TextAlign.right, style: head),
          ),
          if (double2x)
            SizedBox(
              width: numW,
              child: Text('2×', textAlign: TextAlign.right, style: head),
            ),
          const SizedBox(width: 16),
          SizedBox(
            width: stW,
            child: Text(context.t('cStatus').toUpperCase(), style: head),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        for (final r in s.items)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openRow(r),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    checkbox(
                      _selected.contains(r.user.id),
                      () => setState(() {
                        _selected.contains(r.user.id) ? _selected.remove(r.user.id) : _selected.add(r.user.id);
                      }),
                      '${context.t('tcSel')} ${r.user.name}',
                      key: ValueKey('tc-select-${r.user.id}'),
                    ),
                    SizedBox(
                      width: empW,
                      child: Row(
                        children: [
                          TmAvatar(r.user.initials, size: 30),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              r.user.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final d in r.days) SizedBox(width: dayW, child: _dayCell(context, r, d)),
                    numCell((r.totals.totalMin / 60).toStringAsFixed(1), numW, bold: true),
                    numCell(
                      (r.totals.otMin / 60).toStringAsFixed(1),
                      numW,
                      color: r.totals.otMin > 0 ? c.amber : c.dim,
                    ),
                    if (double2x)
                      numCell(
                        (r.totals.dtMin / 60).toStringAsFixed(1),
                        numW,
                        color: r.totals.dtMin > 0 ? c.red : c.dim,
                      ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: stW,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: () {
                          final (t, tone) = status(r.status);
                          return TmPill(t, tone: tone);
                        }(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _weekday(BuildContext context, DateTime d) {
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const es = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return (context.isSpanish ? es : en)[d.weekday - 1];
  }

  /// `.daybtn` — hours + pin; amber = photo to review, red = rejected / missing punch.
  Widget _dayCell(BuildContext context, TimecardRow r, TimecardDay d) {
    final c = context.tm;
    if (!d.hasTime) {
      return Text('—', textAlign: TextAlign.right, style: TmType.mono(c.dim, size: 14));
    }
    final color = switch (d.state) {
      DayState.needsReview => c.amber,
      DayState.needsFix => c.red,
      _ => c.ink,
    };
    return Tooltip(
      message: '${r.user.name} · ${_weekday(context, d.date)} ${d.date.day} · ${context.t('tcMapOpen')}',
      child: InkWell(
        key: ValueKey('tc-day-${r.user.id}-${d.date.toIso8601String().substring(0, 10)}'),
        onTap: () => _openDay(r, d),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text((d.minutes / 60).toStringAsFixed(1), style: TmType.mono(color, size: 14)),
                const SizedBox(width: 2),
                Icon(Icons.place_outlined, size: 12, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
