import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/portal/router/portal_routes.dart';
import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/apps/portal/widgets/formats.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/theme/tm_typography.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/models/models.dart';

/// `$499` from the plan catalog (never hard-coded); falls back to an em dash while loading.
String _price(PortalStore s, String key) => '${s.plan(key)?.yearlyDollars ?? '—'}';

/// `.card` with the prototype's 22px title.
class DashCard extends StatelessWidget {
  const DashCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: c.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      child: child,
    );
  }
}

TextStyle _h2(BuildContext context) => TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.tm.ink);

// ------------------------------------------------------------------ data-limit banner

/// `.retbar` — how long this plan keeps data, with exports and plans.
class RetentionBanner extends StatelessWidget {
  const RetentionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final store = context.portal;
    if (store.bannerHidden) return const SizedBox.shrink();
    final free = store.isFree;
    final days = store.me?.retentionDays ?? 90;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final tone = free ? c.amber : c.blue;
    final title = free
        ? context.t('retFree')
        : context.tf('retPaid', {'plan': context.t('plan_${store.me?.planTier ?? 'pro'}'), 'days': Fmt.retention(context, days)});

    final buttons = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // TODO: show "Exports: on" once scheduled exports exist (Settings → Data).
        OutlinedButton(
          onPressed: () => context.go(Routes.settings),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), backgroundColor: c.panel),
          child: Text(context.t('retExportsSetup'), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        if (free)
          FilledButton(
            onPressed: () => context.go(Routes.settings),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(context.tf('retPlans', {'pro': _price(store, 'pro'), 'biz': _price(store, 'business')}),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        Tooltip(
          message: context.t('hide'),
          child: OutlinedButton(
            onPressed: PortalScope.read(context).hideBanner,
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48), padding: EdgeInsets.zero),
            child: Icon(Icons.close_rounded, color: c.ink, semanticLabel: context.t('hide')),
          ),
        ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
        const SizedBox(height: 4),
        Text(context.tf('retBody', {'n': days, 'date': Fmt.date(context, cutoff)}),
            style: TextStyle(fontSize: 13.5, height: 1.45, color: c.soft)),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: free ? c.waitBg : c.breakBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.7)),
      ),
      child: context.isCompact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, color: tone, size: 20),
                const SizedBox(width: 12),
                Expanded(child: body),
              ]),
              const SizedBox(height: 12),
              buttons,
            ])
          : Row(children: [
              Icon(Icons.info_outline_rounded, color: tone, size: 20),
              const SizedBox(width: 14),
              Expanded(child: body),
              const SizedBox(width: 16),
              buttons,
            ]),
    );
  }
}

// ------------------------------------------------------------------ counts

class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.dashboard});
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final d = dashboard;
    final tiles = [
      _Stat(context.t('dOnClock'), d.onClockCount, context.tf('dOfN', {'n': d.scheduled}), c.ok),
      _Stat(context.t('dOnBreak'), d.onBreak, context.t('dNow'), c.blue),
      _Stat(context.t('dLate'), d.late, context.t(d.late == 1 ? 'dEmp1' : 'dEmpN'), c.amber),
      _Stat(context.t('dToReview'), d.toReview, context.t('dWaiting'), d.toReview > 0 ? c.amber : c.ok),
    ];
    final cols = context.isPhone ? 2 : 4;
    return LayoutBuilder(builder: (context, box) {
      const gap = 16.0;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
    });
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.suffix, this.color);
  final String label, suffix;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return DashCard(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: c.soft)),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 6,
            children: [
              Text('$value', style: TextStyle(fontSize: 38, height: 1.05, fontWeight: FontWeight.w700, color: color)),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(suffix, style: TextStyle(fontSize: 15, color: c.soft)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ photos to review

/// "Clock-in photos to review": up to three pending punches with Approve / Reject.
class PhotoReviewCard extends StatelessWidget {
  const PhotoReviewCard({
    super.key,
    required this.queue,
    required this.busyIds,
    required this.onDecide,
    required this.onOpen,
  });

  final ApprovalQueue queue;
  final Set<String> busyIds;
  final void Function(Punch, ReviewStatus) onDecide;
  final void Function(Punch) onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final pending = queue.items.where((p) => p.review == ReviewStatus.pending).take(3).toList();
    final n = queue.pending;
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(context.t('dReview'), style: _h2(context)),
                if (n > 0) TmPill('$n ${context.t('dWaiting')}', tone: PillTone.wait),
              ]),
              TextButton(
                onPressed: () => context.go(Routes.approvals),
                style: TextButton.styleFrom(foregroundColor: c.g2, padding: const EdgeInsets.symmetric(horizontal: 4)),
                child: Text(context.t('dReviewAll'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text(context.t('dAllDone'), style: TextStyle(color: c.mute))),
            )
          else
            LayoutBuilder(builder: (context, box) {
              const gap = 16.0;
              final cols = box.maxWidth < 520 ? 1 : box.maxWidth < 780 ? 2 : 3;
              final w = ((box.maxWidth - gap * (cols - 1)) / cols).clamp(0.0, 300.0);
              return Wrap(spacing: gap, runSpacing: gap, children: [
                for (final p in pending)
                  SizedBox(
                    width: w,
                    child: _PhotoCard(
                      punch: p,
                      busy: busyIds.contains(p.id),
                      onApprove: () => onDecide(p, ReviewStatus.approved),
                      onReject: () => onDecide(p, ReviewStatus.rejected),
                      onOpen: () => onOpen(p),
                    ),
                  ),
              ]);
            }),
        ],
      ),
    );
  }
}

/// `.pc` — photo tile (opens Edit punch), name, site, Approve / Reject.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.punch, required this.busy, required this.onApprove, required this.onReject, required this.onOpen});
  final Punch punch;
  final bool busy;
  final VoidCallback onApprove, onReject, onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final p = punch;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.raise, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: '${context.t('peTitle')}: ${p.user?.name ?? ''}',
            child: InkWell(
              onTap: onOpen,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                PhotoPlaceholder(punch: p, height: 160),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.user?.name ?? '', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
                    Text(p.site?.name ?? '—', style: TextStyle(fontSize: 14, color: c.soft)),
                  ]),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: busy
                ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : Row(children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onApprove,
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 52), padding: EdgeInsets.zero),
                        child: Text(context.t('approve'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), padding: EdgeInsets.zero, backgroundColor: c.panel),
                        child: Text(context.t('reject'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c.ink)),
                      ),
                    ),
                  ]),
          ),
        ],
      ),
    );
  }
}

/// The punch photo area: face placeholder, "Clock in · 7:02 AM" tag, "Edited" tag, pen icon.
/// TODO: show the real photo once photo upload (`/files/upload-url`) is built.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key, required this.punch, this.height = 160, this.showPen = true});
  final Punch punch;
  final double height;
  final bool showPen;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final p = punch;
    Widget tag(String text, {Color? bg, Color? fg}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: bg ?? c.bg.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6)),
          child: Text(text, style: TmType.mono(fg ?? c.ink, size: 12)),
        );
    return SizedBox(
      height: height,
      child: Stack(children: [
        Positioned.fill(child: ColoredBox(color: c.photo)),
        Center(
          child: Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.face, shape: BoxShape.circle),
            child: Text(p.user?.initials ?? '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: c.faceFg)),
          ),
        ),
        Positioned(left: 12, top: 12, child: tag('${context.t('k_${punchKindWire[p.kind]}')} · ${Fmt.clock(context, p.at)}')),
        if (p.edited != null)
          Positioned(right: 12, top: 12, child: tag(context.t('edited'), bg: c.waitBg, fg: c.amber)),
        if (showPen)
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: c.panel.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.edit_outlined, size: 16, color: c.ink),
            ),
          ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ live crew board

/// "On the clock" table with search. Rows with a photo waiting open the approvals page.
class CrewBoard extends StatefulWidget {
  const CrewBoard({super.key, required this.entries, required this.onOpenPunch});
  final List<OnClockEntry> entries;
  final void Function(String punchId) onOpenPunch;

  @override
  State<CrewBoard> createState() => _CrewBoardState();
}

class _CrewBoardState extends State<CrewBoard> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final q = _q.trim().toLowerCase();
    final rows = widget.entries
        .where((e) => q.isEmpty || e.user.name.toLowerCase().contains(q) || (e.site?.name.toLowerCase().contains(q) ?? false))
        .toList();
    final search = SizedBox(
      width: context.isPhone ? double.infinity : 260,
      child: TextField(
        onChanged: (v) => setState(() => _q = v),
        decoration: InputDecoration(
          hintText: context.t('dSearch'),
          prefixIcon: Icon(Icons.search_rounded, color: c.mute),
          isDense: true,
        ),
      ),
    );
    final table = context.isPhone ? _stacked(context, rows) : _table(context, rows);
    return DashCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        context.isPhone
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.t('dOnClock'), style: _h2(context)),
                const SizedBox(height: 12),
                search,
              ])
            : Row(children: [Expanded(child: Text(context.t('dOnClock'), style: _h2(context))), search]),
        const SizedBox(height: 14),
        if (widget.entries.isEmpty)
          _empty(context, 'dNobody')
        else if (rows.isEmpty)
          _empty(context, 'dNoMatch')
        else
          table,
      ]),
    );
  }

  Widget _empty(BuildContext context, String key) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(context.t(key), style: TextStyle(color: context.tm.mute))),
      );

  (String, PillTone) _status(BuildContext context, WorkState s) => switch (s) {
        WorkState.working => (context.t('st_working'), PillTone.ok),
        WorkState.late => (context.t('st_late'), PillTone.wait),
        WorkState.onBreak => (context.t('st_onBreak'), PillTone.brk),
        WorkState.offSite => (context.t('st_offSite'), PillTone.no),
      };

  (String, PillTone) _photo(BuildContext context, ReviewStatus s) => switch (s) {
        ReviewStatus.pending => (context.t('ph_pending'), PillTone.wait),
        ReviewStatus.approved => (context.t('ph_approved'), PillTone.ok),
        ReviewStatus.rejected => (context.t('ph_rejected'), PillTone.no),
        ReviewStatus.retake => (context.t('ph_retake'), PillTone.brk),
      };

  VoidCallback? _tap(OnClockEntry e) =>
      e.photo == ReviewStatus.pending && e.punchId != null ? () => widget.onOpenPunch(e.punchId!) : null;

  Widget _who(BuildContext context, OnClockEntry e) => Row(children: [
        TmAvatar(e.user.initials),
        const SizedBox(width: 10),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.user.name, style: TextStyle(fontWeight: FontWeight.w700, color: context.tm.ink), overflow: TextOverflow.ellipsis),
            if (e.user.title.isNotEmpty) Text(e.user.title, style: TextStyle(fontSize: 12, color: context.tm.mute)),
          ]),
        ),
      ]);

  Widget _table(BuildContext context, List<OnClockEntry> rows) {
    final c = context.tm;
    TextStyle head = TmType.label(c.mute);
    Widget cell(Widget child, int flex) => Expanded(flex: flex, child: child);
    final mono = TmType.mono(c.soft, size: 14);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(children: [
          cell(Text(context.t('cEmp').toUpperCase(), style: head), 5),
          cell(Text(context.t('cSite').toUpperCase(), style: head), 4),
          cell(Text(context.t('cSince').toUpperCase(), style: head), 2),
          cell(Text(context.t('cToday').toUpperCase(), style: head), 2),
          cell(Text(context.t('cStatus').toUpperCase(), style: head), 3),
          cell(Text(context.t('cPhoto').toUpperCase(), style: head), 3),
        ]),
      ),
      for (final e in rows)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _tap(e),
            child: Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(children: [
                cell(_who(context, e), 5),
                cell(Text(e.site?.name ?? '—', style: TextStyle(color: c.soft)), 4),
                cell(Text(Fmt.clock(context, e.since), style: mono), 2),
                cell(Text(Fmt.minutes(e.todayMinutes), style: mono), 2),
                cell(Align(alignment: Alignment.centerLeft, child: _pill(_status(context, e.state))), 3),
                cell(Align(alignment: Alignment.centerLeft, child: _pill(_photo(context, e.photo))), 3),
              ]),
            ),
          ),
        ),
    ]);
  }

  Widget _pill((String, PillTone) v) => TmPill(v.$1, tone: v.$2);

  Widget _stacked(BuildContext context, List<OnClockEntry> rows) {
    final c = context.tm;
    return Column(children: [
      for (final e in rows)
        InkWell(
          onTap: _tap(e),
          child: Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _who(context, e),
              const SizedBox(height: 8),
              Text('${e.site?.name ?? '—'} · ${Fmt.clock(context, e.since)} · ${Fmt.minutes(e.todayMinutes)}',
                  style: TextStyle(fontSize: 13, color: c.soft)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [_pill(_status(context, e.state)), _pill(_photo(context, e.photo))]),
            ]),
          ),
        ),
    ]);
  }
}

// ------------------------------------------------------------------ right column

class AttentionCard extends StatelessWidget {
  const AttentionCard({super.key, required this.items});
  final List<Attention> items;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    Color bar(AttentionKind k) => switch (k) {
          AttentionKind.outside => c.red,
          AttentionKind.nearOvertime => c.blue,
          _ => c.amber,
        };
    return DashCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(context.t('dAttn'), style: _h2(context)),
        const SizedBox(height: 14),
        if (items.isEmpty) Text(context.t('dAttnNone'), style: TextStyle(color: c.mute)),
        for (final a in items)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(color: c.raise, borderRadius: BorderRadius.circular(12)),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(width: 4, decoration: BoxDecoration(color: bar(a.kind), borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.t('at_${a.kind.name}'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                    const SizedBox(height: 2),
                    Text([a.user.name, if (a.detail.isNotEmpty) a.detail].join(' · '), style: TextStyle(fontSize: 14, color: c.soft)),
                  ]),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

class StartingSoonCard extends StatelessWidget {
  const StartingSoonCard({super.key, required this.shifts});
  final List<ShiftRef> shifts;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    return DashCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(context.t('dStartSoon'), style: _h2(context)),
        const SizedBox(height: 12),
        if (shifts.isEmpty) Text(context.t('dStartNone'), style: TextStyle(color: c.mute)),
        for (final s in shifts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 84, child: Text(Fmt.hhmm(context, s.start), style: TmType.mono(c.g2, size: 14))),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.user?.name ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink)),
                  Text(s.site?.name ?? '', style: TextStyle(fontSize: 13, color: c.soft)),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}

/// `.ad` — ad placeholder (free plan). The real banner comes from Google AdSense / Ad Manager.
class AdSlot extends StatelessWidget {
  const AdSlot({super.key, required this.size, required this.minHeight, this.short = false});
  final String size;
  final double minHeight;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final store = context.portal;
    final args = {
      'pro': _price(store, 'pro'),
      'biz': _price(store, 'business'),
      'proSeats': store.plan('pro')?.includedSeats ?? '—',
      'bizSeats': store.plan('business')?.includedSeats ?? '—',
    };
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line2),
        color: c.raise.withValues(alpha: 0.4),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(context.t('ad').toUpperCase(), style: TmType.label(c.mute)),
        const SizedBox(height: 6),
        Text('Google AdSense · $size', style: TextStyle(color: c.mute)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => context.go(Routes.settings),
          child: Text(context.tf(short ? 'adPlansShort' : 'adPlans', args),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.g2)),
        ),
      ]),
    );
  }
}
