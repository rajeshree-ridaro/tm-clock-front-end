import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/features/dashboard/presentation/dashboard_sections.dart';
import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/apps/portal/widgets/formats.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/data/models/models.dart';

/// The prototype's six reasons → the API's `EditReason` (+ note for "Worked through break").
enum _Reason {
  forgot('r_forgot', EditReason.forgot),
  wrongTime('r_wrongTime', EditReason.wrongTime),
  wrongSite('r_wrongSite', EditReason.wrongSite),
  breakWork('r_breakWork', EditReason.other),
  phone('r_phone', EditReason.phone),
  supervisor('r_supervisorEntry', EditReason.supervisorEntry);

  const _Reason(this.key, this.api);
  final String key;
  final EditReason api;
}

/// "Edit punch" (prototype `punchModal`). Returns the saved punch, or null when cancelled.
Future<Punch?> showPunchEditDialog(BuildContext context, Punch punch) => showDialog<Punch>(
      context: context,
      builder: (_) => withPortal(context, _PunchEditDialog(punch: punch)),
    );

class _PunchEditDialog extends StatefulWidget {
  const _PunchEditDialog({required this.punch});
  final Punch punch;

  @override
  State<_PunchEditDialog> createState() => _PunchEditDialogState();
}

class _PunchEditDialogState extends State<_PunchEditDialog> {
  late PunchKind _kind = widget.punch.kind;
  late final DateTime _wall = Fmt.wall(context, widget.punch.at);
  late TimeOfDay _time = TimeOfDay.fromDateTime(_wall);
  late String? _siteId = widget.punch.site?.id;
  _Reason? _reason;
  final _note = TextEditingController();
  late final Future<List<SiteRef>> _sites = context.repos.punches.sites();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// The punch's day + the chosen time, on the company's clock.
  DateTime get _at => Fmt.instant(context, _wall, _time);

  bool get _timeChanged => _time != TimeOfDay.fromDateTime(_wall);

  bool get _changed {
    final p = widget.punch;
    return _kind != p.kind || _timeChanged || (_siteId != null && _siteId != p.site?.id);
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _save({required bool approve}) async {
    final p = widget.punch;
    if (!_changed && !approve) return _toast(context.t('peNoChange'));
    if (_changed && _reason == null) return _toast(context.t('peNeedR'));
    final repo = context.repos.punches;
    final navigator = Navigator.of(context);
    final note = [if (_reason == _Reason.breakWork) context.t('r_breakWork'), _note.text.trim()]
        .where((s) => s.isNotEmpty)
        .join(' — ');
    setState(() => _saving = true);
    try {
      final saved = _changed
          ? await repo.editPunch(
              p.id,
              kind: _kind != p.kind ? _kind : null,
              at: _timeChanged ? _at : null,
              siteId: _siteId != p.site?.id ? _siteId : null,
              reason: _reason!.api,
              note: note,
              approve: approve,
            )
          : await repo.review(p.id, ReviewStatus.approved);
      navigator.pop(saved);
    } on Exception catch (e) {
      _toast('$e');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final p = widget.punch;
    final inside = p.inside ?? true;
    final field = InputDecoration(isDense: true, labelStyle: TextStyle(color: c.soft));
    Widget label(String key) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(context.t(key), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: c.ink)),
        );

    final kindField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      label('peType'),
      DropdownButtonFormField<PunchKind>(
        initialValue: _kind,
        isExpanded: true,
        decoration: field,
        items: [
          for (final k in PunchKind.values)
            DropdownMenuItem(value: k, child: Text(context.t('k_${punchKindWire[k]}'), overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _kind = v ?? _kind),
      ),
    ]);
    final timeField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      label('peTime'),
      InkWell(
        onTap: () async {
          final t = await showTimePicker(context: context, initialTime: _time);
          if (t != null) setState(() => _time = t);
        },
        child: InputDecorator(
          decoration: field.copyWith(suffixIcon: const Icon(Icons.schedule_rounded, size: 18)),
          child: Text(MaterialLocalizations.of(context).formatTimeOfDay(_time)),
        ),
      ),
    ]);
    final siteField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      label('peSite'),
      FutureBuilder<List<SiteRef>>(
        future: _sites,
        builder: (context, snap) {
          final sites = [...?snap.data];
          if (p.site != null && sites.every((s) => s.id != p.site!.id)) sites.insert(0, p.site!);
          return DropdownButtonFormField<String>(
            key: ValueKey(sites.length),
            initialValue: _siteId,
            isExpanded: true,
            decoration: field,
            items: [for (final s in sites) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _siteId = v),
          );
        },
      ),
    ]);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.t('peTitle'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink)),
                  Text([p.user?.name ?? '', if ((p.user?.title ?? '').isNotEmpty) p.user!.title].join(' · '),
                      style: TextStyle(fontSize: 14, color: c.mute)),
                ]),
              ),
              IconButton(
                tooltip: context.t('peCancel'),
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ]),
            const SizedBox(height: 16),
            _photos(context, p),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: inside ? c.okBg : c.noBg, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.place_outlined, size: 18, color: inside ? c.ok : c.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${context.t('gps')}: ${context.t(inside ? 'inside' : 'outside')} · ${Fmt.distance(p.distanceFt)} · ${p.site?.name ?? '—'}',
                    style: TextStyle(color: inside ? c.ok : c.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            if (context.isPhone) ...[kindField, const SizedBox(height: 12), timeField, const SizedBox(height: 12), siteField]
            else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: kindField),
                const SizedBox(width: 12),
                Expanded(child: timeField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: siteField),
              ]),
            const SizedBox(height: 16),
            label('peReason'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in _Reason.values)
                ChoiceChip(
                  label: Text(context.t(r.key)),
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                ),
            ]),
            const SizedBox(height: 16),
            label('peNote'),
            TextField(controller: _note, maxLength: 400, decoration: field.copyWith(counterText: '')),
            if (p.edited != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: c.raise, borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.t('peHist'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c.ink)),
                  if (p.edited!.from != null)
                    Text('${context.t('peOrig')}: ${Fmt.clock(context, p.edited!.from!)}', style: TextStyle(fontSize: 13, color: c.mute)),
                  Text(
                    [
                      context.t('edited'),
                      context.t(_Reason.values.firstWhere((r) => r.api == p.edited!.reason, orElse: () => _Reason.supervisor).key),
                      if (p.edited!.by != null) p.edited!.by!.name,
                      if (p.edited!.at != null) Fmt.clock(context, p.edited!.at!),
                    ].join(' · '),
                    style: TextStyle(fontSize: 13, color: c.mute),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            Text(context.t('peAudit'), style: TextStyle(fontSize: 12, color: c.mute)),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton(
                onPressed: _saving ? null : () => _save(approve: true),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(context.t('peSaveOk'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              OutlinedButton(
                onPressed: _saving ? null : () => _save(approve: false),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(context.t('peSave')),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(context.t('peCancel')),
              ),
              if (_saving) const Padding(padding: EdgeInsets.all(12), child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _photos(BuildContext context, Punch p) {
    final c = context.tm;
    Widget figure(Widget box, String caption) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: box),
          const SizedBox(height: 6),
          Text(caption, style: TextStyle(fontSize: 13, color: c.mute)),
        ]);
    final taken = figure(
      PhotoPlaceholder(punch: p, height: 170, showPen: false),
      [context.t('k_${punchKindWire[p.kind]}'), Fmt.clock(context, p.at), if (p.device.isNotEmpty) p.device].join(' · '),
    );
    final onFile = figure(
      Container(
        height: 170,
        color: c.raise,
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.line2, shape: BoxShape.circle),
            child: Text(p.user?.initials ?? '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: c.ink)),
          ),
          const SizedBox(height: 8),
          Text(context.t('onFile'), style: TextStyle(color: c.soft)),
        ]),
      ),
      context.t('peOnFileSub'),
    );
    return context.isPhone
        ? Column(children: [taken, const SizedBox(height: 12), onFile])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: taken),
            const SizedBox(width: 12),
            Expanded(child: onFile),
          ]);
  }
}
