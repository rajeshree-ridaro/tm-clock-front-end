import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/apps/portal/widgets/formats.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/models/models.dart';
import 'package:tm_clock/data/models/timecards.dart';

/// Result of the Add timecard dialog.
sealed class AddTimecardResult {}

class TimecardSaved extends AddTimecardResult {}

/// The person already has time that day: the page opens that day's punches instead (prototype).
class DayHasTime extends AddTimecardResult {
  DayHasTime(this.user, this.date);
  final UserRef user;
  final DateTime date;
}

/// The prototype's reasons → the API's `ManualTimecardInput.reason` (+ a note where there's no exact match).
enum _Reason {
  paper('mr_paperTimesheet', ManualReason.paperTimesheet),
  noSignal('mr_noSignal', ManualReason.noSignal),
  forgot('mr_forgot', ManualReason.forgot),
  offsite('mr_offsite', ManualReason.other),
  supervisor('mr_supervisor', ManualReason.other);

  const _Reason(this.key, this.api);
  final String key;
  final ManualReason api;
}

Future<AddTimecardResult?> showAddTimecardDialog(BuildContext context, {required TimecardSheet sheet}) =>
    showDialog<AddTimecardResult>(
      context: context,
      builder: (_) => withPortal(context, _AddTimecardDialog(sheet: sheet)),
    );

class _AddTimecardDialog extends StatefulWidget {
  const _AddTimecardDialog({required this.sheet});
  final TimecardSheet sheet;

  @override
  State<_AddTimecardDialog> createState() => _AddTimecardDialogState();
}

class _AddTimecardDialogState extends State<_AddTimecardDialog> {
  late final DateTime _today = () {
    final n = Fmt.now(context);
    return DateTime(n.year, n.month, n.day);
  }();
  late String? _userId = widget.sheet.items.isEmpty ? null : widget.sheet.items.first.user.id;
  late DateTime? _date = widget.sheet.period.end.isBefore(_today) ? widget.sheet.period.end : _today;
  String? _siteId;
  TimeOfDay _in = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _out = const TimeOfDay(hour: 15, minute: 30);
  final _break = TextEditingController(text: '30');
  final _note = TextEditingController();
  _Reason? _reason;
  late final Future<List<SiteRef>> _sites = context.repos.punches.sites();
  bool _saving = false;

  @override
  void dispose() {
    _break.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _breakMin => (int.tryParse(_break.text) ?? 0).clamp(0, 240);
  int get _span => (_out.hour * 60 + _out.minute) - (_in.hour * 60 + _in.minute) - _breakMin;

  String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    final period = widget.sheet.period;
    final inM = _in.hour * 60 + _in.minute, outM = _out.hour * 60 + _out.minute;
    if (_date == null) return _toast(context.t('tcErrDate'));
    if (outM <= inM) return _toast(context.t('tcErrOrder'));
    if (_breakMin >= outM - inM) return _toast(context.t('tcErrBreak'));
    if (_reason == null) return _toast(context.t('tcErrReason'));
    if (_date!.isBefore(period.start) || _date!.isAfter(period.end)) return _toast(context.t('tcErrPeriod'));
    if (_date!.isAfter(_today)) return _toast(context.t('tcErrFuture'));
    final user = widget.sheet.items.firstWhere((r) => r.user.id == _userId).user;
    final siteId = _siteId ?? (await _sites).firstOrNull?.id;
    if (siteId == null || !mounted) return;
    final repo = context.repos.timecards;
    final navigator = Navigator.of(context);
    final note = [
      if (_reason == _Reason.offsite || _reason == _Reason.supervisor) context.t(_reason!.key),
      _note.text.trim(),
    ].where((s) => s.isNotEmpty).join(' — ');
    setState(() => _saving = true);
    try {
      await repo.addTimecard(
        period.id,
        userId: user.id,
        date: _date!,
        siteId: siteId,
        inTime: _hhmm(_in),
        outTime: _hhmm(_out),
        breakMin: _breakMin,
        reason: _reason!.api,
        note: note,
      );
      navigator.pop(TimecardSaved());
    } on ApiException catch (e) {
      if (e.code == 'DAY_HAS_PUNCHES') {
        navigator.pop(DayHasTime(user, _date!));
        return;
      }
      _toast(e.message);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final period = widget.sheet.period;
    final last = period.end.isBefore(_today) ? period.end : _today;
    Widget field(String key, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t(key),
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: c.ink),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
    Widget timeField(String key, TimeOfDay value, ValueChanged<TimeOfDay> set) => field(
      key,
      InkWell(
        onTap: () async {
          final t = await showTimePicker(context: context, initialTime: value);
          if (t != null) setState(() => set(t));
        },
        child: InputDecorator(
          decoration: const InputDecoration(isDense: true, suffixIcon: Icon(Icons.schedule_rounded, size: 18)),
          child: Text(MaterialLocalizations.of(context).formatTimeOfDay(value)),
        ),
      ),
    );
    final fields = <Widget>[
      field(
        'tcEmp',
        DropdownButtonFormField<String>(
          initialValue: _userId,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          items: [
            for (final r in widget.sheet.items)
              DropdownMenuItem(
                value: r.user.id,
                child: Text(r.user.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _userId = v),
        ),
      ),
      field(
        'tcDate',
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date ?? last,
              firstDate: period.start,
              lastDate: last.isBefore(period.start) ? period.start : last,
            );
            if (d != null) setState(() => _date = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(isDense: true, suffixIcon: Icon(Icons.calendar_today_rounded, size: 18)),
            child: Text(_date == null ? '—' : Fmt.date(context, _date!)),
          ),
        ),
      ),
      field(
        'apSite',
        FutureBuilder<List<SiteRef>>(
          future: _sites,
          builder: (context, snap) {
            final sites = snap.data ?? const <SiteRef>[];
            return DropdownButtonFormField<String>(
              key: ValueKey(sites.length),
              initialValue: _siteId ?? sites.firstOrNull?.id,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: [
                for (final s in sites)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _siteId = v),
            );
          },
        ),
      ),
      timeField('k_in', _in, (t) => _in = t),
      timeField('k_out', _out, (t) => _out = t),
      field(
        'tcBreak',
        TextField(
          controller: _break,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(isDense: true),
          onChanged: (_) => setState(() {}),
        ),
      ),
      field(
        'tcHours',
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _span > 0 ? (_span / 60).toStringAsFixed(2) : '—',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.g2),
          ),
        ),
      ),
    ];
    final cols = context.isPhone ? 1 : 2;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      context.t('tcAddTitle'),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink),
                    ),
                  ),
                  IconButton(
                    tooltip: context.t('peCancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(context.t('tcAddSub'), style: TextStyle(fontSize: 14, color: c.mute)),
              const SizedBox(height: 18),
              for (var i = 0; i < fields.length; i += cols) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = i; j < i + cols; j++) ...[
                      if (j > i) const SizedBox(width: 14),
                      Expanded(child: j < fields.length ? fields[j] : const SizedBox.shrink()),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
              ],
              field(
                'peReason',
                DropdownButtonFormField<_Reason?>(
                  initialValue: _reason,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    DropdownMenuItem<_Reason?>(value: null, child: Text(context.t('tcPickReason'))),
                    for (final r in _Reason.values) DropdownMenuItem<_Reason?>(value: r, child: Text(context.t(r.key))),
                  ],
                  onChanged: (v) => setState(() => _reason = v),
                ),
              ),
              const SizedBox(height: 14),
              field(
                'peNote',
                TextField(
                  controller: _note,
                  maxLength: 400,
                  decoration: const InputDecoration(isDense: true, counterText: ''),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: Text(context.t('tcSave'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: Text(context.t('peCancel')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
