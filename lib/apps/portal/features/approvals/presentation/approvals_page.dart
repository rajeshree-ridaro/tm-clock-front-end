import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/portal/features/dashboard/presentation/dashboard_sections.dart';
import 'package:tm_clock/apps/portal/features/dashboard/presentation/punch_edit_dialog.dart';
import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/apps/portal/widgets/formats.dart';
import 'package:tm_clock/apps/portal/widgets/portal_header.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/theme/tm_typography.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/models/models.dart';

/// Photo approvals (prototype `approvals()`): queue on the left, the selected punch on the
/// right with both photos, job site / GPS / device, a note, Edit punch, and
/// Approve / Ask to retake / Reject. Header: "Approve all on site (N)".
/// `?punch=<id>` selects a punch (from the dashboard's crew board).
class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  ApprovalQueue? _queue;
  Object? _error;
  String? _selectedId;
  bool _busy = false;
  final _note = TextEditingController();

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _selectedId = GoRouterState.of(context).uri.queryParameters['punch'];
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = PortalScope.read(context);
    try {
      final q = await context.repos.punches.approvals();
      if (!mounted) return;
      setState(() {
        _queue = q;
        _error = null;
        if (_selectedId == null || q.items.every((p) => p.id != _selectedId)) {
          _selectedId = q.items.isEmpty ? null : q.items.first.id;
        }
      });
      store.setPending(q.pending);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Punch? get _selected => _queue?.items.where((p) => p.id == _selectedId).firstOrNull;

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _select(Punch p) => setState(() {
        _selectedId = p.id;
        _note.clear();
      });

  /// After a decision, move to the next punch still waiting (prototype behaviour).
  void _selectNextPending(String decidedId) {
    final items = _queue?.items ?? const <Punch>[];
    final next = items.where((p) => p.id != decidedId && p.review == ReviewStatus.pending).firstOrNull;
    if (next != null) _selectedId = next.id;
  }

  Future<void> _decide(Punch p, ReviewStatus decision) async {
    final key = switch (decision) {
      ReviewStatus.approved => 'tApproved',
      ReviewStatus.rejected => 'tRejected',
      _ => 'tRetake',
    };
    final done = '${context.t(key)} · ${p.user?.name ?? ''}';
    final note = _note.text.trim();
    setState(() => _busy = true);
    try {
      await context.repos.punches.review(p.id, decision, note: note.isEmpty ? null : note);
      _selectNextPending(p.id);
      _note.clear();
      _toast(done);
      await _load();
    } on Exception catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approveOnSite() async {
    final repo = context.repos.punches;
    setState(() => _busy = true);
    try {
      final n = await repo.approveOnSite();
      if (!mounted) return;
      _toast(context.tf('apAllDoneN', {'n': n}));
      final first = _queue?.items.where((p) => p.review == ReviewStatus.pending && !(p.inside == true && p.flags.isEmpty)).firstOrNull;
      if (first != null) _selectedId = first.id;
      await _load();
    } on Exception catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(Punch p) async {
    final approvedMsg = '${context.t('tApproved')} · ${p.user?.name ?? ''}';
    final savedMsg = context.t('peSaved');
    final saved = await showPunchEditDialog(context, p);
    if (saved == null || !mounted) return;
    final approved = saved.review == ReviewStatus.approved && p.review != ReviewStatus.approved;
    if (approved) _selectNextPending(p.id);
    _toast(approved ? approvedMsg : savedMsg);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final q = _queue;
    final onSite = q?.pendingInside ?? 0;
    final header = PortalHeader(
      eyebrow: context.t('apSup'),
      eyebrowCaps: true,
      title: context.t('appr'),
      subtitle: context.t('apSub'),
      trailing: [
        Tooltip(
          message: onSite == 0 ? context.t('apNoneOnSite') : '',
          child: Opacity(
            opacity: onSite == 0 ? 0.5 : 1,
            child: OutlinedButton(
              onPressed: onSite == 0 || _busy ? null : _approveOnSite,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 18)),
              child: Text('${context.t('apAll')} ($onSite)', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );

    if (q == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        header,
        const SizedBox(height: 40),
        Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Column(children: [
                  Text(_error is ApiException ? (_error as ApiException).message : '$_error', style: TextStyle(color: c.red)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: Text(context.t('retry'))),
                ]),
        ),
      ]);
    }

    final queue = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final p in q.items) ...[
        _QueueItem(punch: p, selected: p.id == _selectedId, onTap: () => _select(p)),
        const SizedBox(height: 10),
      ],
      if (q.pending == 0)
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Center(child: Text(context.t(q.items.isEmpty ? 'apEmpty' : 'dAllDone'), style: TextStyle(color: c.mute))),
        ),
    ]);
    final sel = _selected;
    final detail = sel == null ? const SizedBox.shrink() : _detail(context, sel);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      header,
      const SizedBox(height: 24),
      // Screen width, not LayoutBuilder: the detail holds a text field.
      if (context.screenWidth - (context.isCompact ? 0 : Breakpoints.sideNavWidth + 112) < 900)
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [queue, const SizedBox(height: 10), detail])
      else
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 380, child: queue),
          const SizedBox(width: 20),
          Expanded(child: detail),
        ]),
    ]);
  }

  Widget _detail(BuildContext context, Punch p) {
    final c = context.tm;
    final inside = p.inside ?? true;
    final kind = context.t('k_${punchKindWire[p.kind]}');
    final time = Fmt.clock(context, p.at);
    final (statusText, tone) = _statusOf(context, p.review);

    Widget fact(String label, String value, {Color? color}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: TmType.label(c.mute)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color ?? c.ink)),
          ],
        );
    final facts = [
      fact(context.t('apSite'), p.site?.name ?? '—'),
      fact(context.t('gps'), '${context.t(inside ? 'inside' : 'outside')} · ${Fmt.distance(p.distanceFt)}', color: inside ? c.ok : c.red),
      fact(context.t('apDevice'), p.device.isEmpty ? '—' : p.device),
    ];

    return DashCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.user?.name ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink)),
              Text([if ((p.user?.title ?? '').isNotEmpty) p.user!.title, kind, time].join(' · '),
                  style: TextStyle(fontSize: 14, color: c.mute)),
            ]),
          ),
          TmPill(statusText, tone: tone),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 14) / 2;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: w, child: _photo(context, p, taken: true, caption: time)),
            const SizedBox(width: 14),
            SizedBox(width: w, child: _photo(context, p, taken: false)),
          ]);
        }),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, box) {
          if (box.maxWidth < 480) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final f in facts) ...[f, const SizedBox(height: 10)],
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final f in facts) Expanded(child: f),
          ]);
        }),
        const SizedBox(height: 16),
        Text(context.t('apNote'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: c.ink)),
        const SizedBox(height: 6),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(hintText: context.t('apNotePh'), counterText: ''),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _edit(p),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(context.t('peTitle')),
          ),
        ),
        if (p.edited != null) ...[
          const SizedBox(height: 8),
          Text(
            [
              context.t('edited'),
              if (p.edited!.from != null) '${context.t('apWas')} ${Fmt.clock(context, p.edited!.from!)}',
              context.t(_reasonKey(p.edited!.reason)),
              if (p.edited!.note.isNotEmpty) p.edited!.note,
              if (p.edited!.by != null) p.edited!.by!.name,
            ].join(' · '),
            style: TextStyle(fontSize: 13, color: c.amber),
          ),
        ],
        const SizedBox(height: 16),
        if (_busy)
          const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else
          Wrap(spacing: 10, runSpacing: 10, children: [
            _ActionButton(flex: 2, onPressed: () => _decide(p, ReviewStatus.approved), filled: true, label: context.t('approve')),
            _ActionButton(onPressed: () => _decide(p, ReviewStatus.retake), label: context.t('apRetake')),
            _ActionButton(onPressed: () => _decide(p, ReviewStatus.rejected), label: context.t('reject'), danger: true),
          ]),
        const SizedBox(height: 12),
        Text(context.t('apKeep'), style: TextStyle(fontSize: 13, color: c.mute)),
      ]),
    );
  }

  static String _reasonKey(EditReason r) => switch (r) {
        EditReason.forgot => 'r_forgot',
        EditReason.wrongTime => 'r_wrongTime',
        EditReason.wrongSite => 'r_wrongSite',
        EditReason.phone => 'r_phone',
        EditReason.supervisorEntry => 'r_supervisorEntry',
        EditReason.other => 'r_breakWork',
      };

  /// `.photos .ph` (taken) and `.ph.file` (profile photo on file).
  /// TODO: real images once photo upload is built.
  Widget _photo(BuildContext context, Punch p, {required bool taken, String? caption}) {
    final c = context.tm;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: taken ? c.photo : c.raise,
            borderRadius: BorderRadius.circular(12),
            border: taken ? null : Border.all(color: c.line2),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: taken ? c.face : c.line2, shape: BoxShape.circle),
              child: Text(p.user?.initials ?? '',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: taken ? c.faceFg : c.ink)),
            ),
            const SizedBox(height: 10),
            Text(context.t(taken ? 'photoTaken' : 'onFile'), style: TextStyle(fontSize: 13, color: c.mute)),
          ]),
        ),
      ),
      if (caption != null) ...[
        const SizedBox(height: 6),
        Text(caption, style: TextStyle(fontSize: 13, color: c.mute)),
      ],
    ]);
  }
}

(String, PillTone) _statusOf(BuildContext context, ReviewStatus s) => switch (s) {
      ReviewStatus.pending => (context.t('ph_pending'), PillTone.wait),
      ReviewStatus.approved => (context.t('ph_approved'), PillTone.ok),
      ReviewStatus.rejected => (context.t('ph_rejected'), PillTone.no),
      ReviewStatus.retake => (context.t('ph_retake'), PillTone.brk),
    };

/// `.qi` / `.qi.on` — one punch in the queue.
class _QueueItem extends StatelessWidget {
  const _QueueItem({required this.punch, required this.selected, required this.onTap});
  final Punch punch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final p = punch;
    final (text, tone) = _statusOf(context, p.review);
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? c.g : c.line, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.face, shape: BoxShape.circle),
              child: Text(p.user?.initials ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: c.faceFg)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.user?.name ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                Text(
                  [context.t('k_${punchKindWire[p.kind]}'), Fmt.clock(context, p.at), p.site?.name ?? '—'].join(' · '),
                  style: TextStyle(fontSize: 13, color: c.mute),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            TmPill(text, tone: tone),
          ]),
        ),
      ),
    );
  }
}

/// `.acts .btn` — Approve (wider, primary), Ask to retake, Reject (red outline).
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed, this.flex = 1, this.filled = false, this.danger = false});
  final String label;
  final VoidCallback onPressed;
  final int flex;
  final bool filled, danger;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final style = const TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: flex == 2 ? 180 : 140, minHeight: 48),
      child: filled
          ? FilledButton(onPressed: onPressed, style: FilledButton.styleFrom(minimumSize: const Size(0, 48)), child: Text(label, style: style))
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: danger ? c.red : c.ink,
                side: BorderSide(color: danger ? c.noBorder : c.line2),
              ),
              child: Text(label, style: style),
            ),
    );
  }
}
