import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/portal/features/dashboard/presentation/dashboard_sections.dart';
import 'package:tm_clock/apps/portal/features/dashboard/presentation/punch_edit_dialog.dart';
import 'package:tm_clock/apps/portal/router/portal_routes.dart';
import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/apps/portal/widgets/formats.dart';
import 'package:tm_clock/apps/portal/widgets/portal_header.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/layout/breakpoints.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/models/models.dart';

/// Dashboard (prototype `dashboard()`): who's working now, photos to review, live crew
/// board, needs attention, starting soon. Data: `GET /dashboard` + `GET /approvals`.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Dashboard? _dash;
  ApprovalQueue? _queue;
  Object? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.repos.punches;
    final store = PortalScope.read(context);
    try {
      final results = await Future.wait([repo.dashboard(), repo.approvals()]);
      if (!mounted) return;
      setState(() {
        _dash = results[0] as Dashboard;
        _queue = results[1] as ApprovalQueue;
        _error = null;
      });
      store.setPending(_queue!.pending);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _decide(Punch p, ReviewStatus decision) async {
    final done = '${context.t(decision == ReviewStatus.approved ? 'tApproved' : decision == ReviewStatus.rejected ? 'tRejected' : 'tRetake')} · ${p.user?.name ?? ''}';
    setState(() => _busy.add(p.id));
    try {
      await context.repos.punches.review(p.id, decision);
      _toast(done);
      await _load();
    } on Exception catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
  }

  Future<void> _edit(Punch p) async {
    final approvedMsg = '${context.t('tApproved')} · ${p.user?.name ?? ''}';
    final savedMsg = context.t('peSaved');
    final saved = await showPunchEditDialog(context, p);
    if (saved == null || !mounted) return;
    _toast(saved.review == ReviewStatus.approved && p.review != ReviewStatus.approved ? approvedMsg : savedMsg);
    await _load();
  }

  /// A crew-board row with a photo waiting: open it in Photo approvals (prototype `data-go`).
  void _openPunch(String punchId) => context.go('${Routes.approvals}?punch=$punchId');

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final store = context.portal;
    final company = context.session.company?.companyName ?? '';
    final header = PortalHeader(
      eyebrow: '${Fmt.dayHeader(context, Fmt.now(context))} · $company',
      title: context.t('dWho'),
    );

    if (_dash == null || _queue == null) {
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

    final d = _dash!;
    final ads = store.isFree;
    final left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PhotoReviewCard(queue: _queue!, busyIds: _busy, onDecide: _decide, onOpen: _edit),
      const SizedBox(height: 20),
      CrewBoard(entries: d.onClock, onOpenPunch: _openPunch),
      if (ads) ...[const SizedBox(height: 20), const AdSlot(size: '728 × 90', minHeight: 96)],
    ]);
    final right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AttentionCard(items: d.attention),
      const SizedBox(height: 20),
      StartingSoonCard(shifts: d.startingSoon),
      if (ads) ...[const SizedBox(height: 20), const AdSlot(size: '300 × 250', minHeight: 250, short: true)],
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        header,
        const SizedBox(height: 24),
        const RetentionBanner(),
        if (!store.bannerHidden) const SizedBox(height: 24),
        StatsRow(dashboard: d),
        const SizedBox(height: 24),
        // Two columns when the content area (screen minus side menu) is at least ~1000 px.
        // Screen width, not LayoutBuilder: the columns hold text fields.
        if (context.screenWidth - Breakpoints.sideNavWidth - 112 < 1000)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 20), right])
        else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: left),
            const SizedBox(width: 24),
            SizedBox(width: 350, child: right),
          ]),
      ]);
  }
}
