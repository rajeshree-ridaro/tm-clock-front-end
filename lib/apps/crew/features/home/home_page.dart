import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/apps/crew/router/crew_routes.dart';
import 'package:tm_clock/apps/crew/widgets/crew_widgets.dart';
import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/widgets/async_view.dart';
import 'package:tm_clock/core/widgets/tm_components.dart';
import 'package:tm_clock/data/models/models.dart';
import 'package:tm_clock/data/repositories/repositories.dart';

/// Crew home — status + one big action, then links. Data: `GET /me/status`.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<MeStatus> _status = context.repos.punches.myStatus();
  bool _busy = false;

  void _reload() => setState(() => _status = context.repos.punches.myStatus());

  Future<void> _break(PunchKind kind) async {
    setState(() => _busy = true);
    try {
      await context.repos.punches.createPunch(clientId: newClientId(), kind: kind, deviceAt: DateTime.now());
    } finally {
      if (mounted) {
        _busy = false;
        _reload();
      }
    }
  }

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    return context.t(h < 12 ? 'greetMorning' : (h < 18 ? 'greetAfternoon' : 'greetEvening'));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final text = Theme.of(context).textTheme;
    final session = context.session;
    final firstName = (session.user?.name ?? '').split(' ').first;
    final date = MaterialLocalizations.of(context).formatFullDate(DateTime.now()).split(',').take(2).join(',');

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: CrewBody(
        children: [
          Text(date, style: TextStyle(color: c.soft, fontSize: 14)),
          const SizedBox(height: 2),
          Text('${_greeting(context)}, $firstName', style: text.headlineLarge?.copyWith(fontSize: 28)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              label: Text(session.company?.companyName ?? ''),
              avatar: const Icon(Icons.business_rounded, size: 16),
              onPressed: () => context.go(CrewRoutes.me),
            ),
          ),
          const SizedBox(height: 16),
          AsyncView<MeStatus>(
            future: _status,
            onRetry: _reload,
            builder: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusCard(status: s, busy: _busy, onBreak: _break),
                const SizedBox(height: 16),
                if (session.isSupervisor) ...[
                  ActionTile(
                    icon: Icons.groups_outlined,
                    title: context.t('myCrew'),
                    subtitle: context.t('myCrewSub'),
                    onTap: () => context.go(CrewRoutes.crew),
                  ),
                  const SizedBox(height: 12),
                ],
                ActionTile(
                  icon: Icons.shield_outlined,
                  iconBg: c.waitBg,
                  iconColor: c.amber,
                  title: context.t('brief'),
                  subtitle: context.t('briefSub'),
                  trailing: s.briefingToSign ? TmPill(context.t('open'), tone: PillTone.wait) : null,
                  onTap: () => context.go(CrewRoutes.safety),
                ),
                const SizedBox(height: 12),
                ActionTile(
                  icon: Icons.receipt_long_outlined,
                  title: context.t('myHours'),
                  subtitle: '${context.t('today')}: ${formatMinutes(s.todayMinutes)} · '
                      '${context.t('thisWeek')}: ${formatMinutes(s.weekMinutes)}',
                  onTap: () => context.go(CrewRoutes.hours),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.busy, required this.onBreak});
  final MeStatus status;
  final bool busy;
  final ValueChanged<PunchKind> onBreak;

  @override
  Widget build(BuildContext context) {
    final c = context.tm;
    final (dot, label) = switch (status.state) {
      ClockState.out => (c.dim, context.t('notIn')),
      ClockState.clockedIn => (c.ok, context.t('clockedIn')),
      ClockState.onBreak => (c.blue, context.t('onBreak')),
    };
    final since = status.lastPunch == null || status.state == ClockState.out
        ? ''
        : ' · ${context.t('since')} ${TimeOfDay.fromDateTime(status.lastPunch!.at).format(context)}';

    return TmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text('$label$since', style: Theme.of(context).textTheme.titleMedium)),
          ]),
          if (status.state == ClockState.out) ...[
            const SizedBox(height: 8),
            Text(context.t('briefNote'), style: TextStyle(color: c.soft, fontSize: 15)),
          ],
          const SizedBox(height: 16),
          switch (status.state) {
            ClockState.out => BigButton(
                label: context.t('clockIn'),
                icon: Icons.photo_camera_outlined,
                onPressed: () => context.go(CrewRoutes.clockIn),
              ),
            ClockState.clockedIn => Column(children: [
                BigButton(
                  label: context.t('clockOut'),
                  icon: Icons.logout_rounded,
                  danger: true,
                  onPressed: () => context.go(CrewRoutes.clockOut),
                ),
                const SizedBox(height: 12),
                BigButton(
                  label: context.t('startBreak'),
                  icon: Icons.free_breakfast_outlined,
                  outlined: true,
                  busy: busy,
                  onPressed: () => onBreak(PunchKind.breakStart),
                ),
              ]),
            ClockState.onBreak => BigButton(
                label: context.t('endBreak'),
                icon: Icons.play_arrow_rounded,
                busy: busy,
                onPressed: () => onBreak(PunchKind.breakEnd),
              ),
          },
        ],
      ),
    );
  }
}
