import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/models/models.dart';
import 'package:tm_clock/data/models/timecards.dart';
import 'package:tm_clock/data/repositories/timecard_repository.dart';

const _latency = Duration(milliseconds: 250);

/// Sample pay periods and timecards (prototype `tc` rows), so the page works with no backend.
class FakeTimecardRepository implements TimecardRepository {
  static const _site = SiteRef(id: 's1', name: 'Lake Nona — Bldg C');
  static const _people = [
    UserRef(id: 'u1', name: 'David Soto', initials: 'DS', title: 'Foreman'),
    UserRef(id: 'u2', name: 'Marco Gómez', initials: 'MG', title: 'Electrician'),
    UserRef(id: 'u3', name: 'Jaylen Thomas', initials: 'JT', title: 'Apprentice'),
    UserRef(id: 'u4', name: 'Ana Rodríguez', initials: 'AR', title: 'Low-voltage tech'),
    UserRef(id: 'u5', name: 'Luis Báez', initials: 'LB', title: 'Electrician'),
    UserRef(id: 'u6', name: 'Kim Pham', initials: 'KP', title: 'Low-voltage tech'),
  ];

  final Map<String, PeriodStatus> _status = {};
  final Map<String, int> _manual = {}; // "periodId|userId|yyyy-mm-dd" → minutes

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  List<PayPeriod> _periods(int count) {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    return [
      for (var i = 0; i < count; i++)
        () {
          final start = monday.subtract(Duration(days: 7 * i));
          final end = start.add(const Duration(days: 6));
          final id = 'pp$i';
          return PayPeriod(
            id: id,
            type: 'weekly',
            start: start,
            end: end,
            label: '${start.month}/${start.day} – ${end.month}/${end.day}, ${end.year}',
            current: i == 0,
            status: _status[id] ?? (i >= 2 ? PeriodStatus.locked : PeriodStatus.open),
          );
        }(),
    ];
  }

  String _key(String periodId, String userId, DateTime d) => '$periodId|$userId|${d.year}-${d.month}-${d.day}';

  @override
  Future<List<PayPeriod>> payPeriods({int limit = 12}) => Future.delayed(_latency, () => _periods(limit));

  @override
  Future<TimecardSheet> timecards(String periodId) => Future.delayed(_latency, () {
        final period = _periods(12).firstWhere((p) => p.id == periodId);
        final rows = <TimecardRow>[];
        for (var ui = 0; ui < _people.length; ui++) {
          final u = _people[ui];
          final days = <TimecardDay>[];
          for (var di = 0; di < period.dates.length; di++) {
            final d = period.dates[di];
            final manual = _manual[_key(periodId, u.id, d)];
            if (d.isAfter(_today)) {
              days.add(TimecardDay(date: d, minutes: 0, state: DayState.future));
            } else if (manual != null) {
              days.add(TimecardDay(date: d, minutes: manual, state: DayState.needsReview, site: _site));
            } else if (d.weekday >= 6) {
              days.add(TimecardDay(date: d, minutes: 0, state: DayState.off));
            } else {
              final minutes = (ui == 0 ? 540 : 480) + const [0, 30, 0, -30, 60, 0, 15][(ui + di) % 7];
              final state = period.current && ui == 5 && di == 1
                  ? DayState.needsFix
                  : period.current && (ui == 1 || ui == 2) && d == _today
                      ? DayState.needsReview
                      : DayState.ok;
              days.add(TimecardDay(date: d, minutes: state == DayState.needsFix ? 0 : minutes, state: state, site: _site));
            }
          }
          final total = days.fold(0, (a, d) => a + d.minutes);
          final ot = total > 2400 ? total - 2400 : 0;
          final states = days.map((d) => d.state).toSet();
          final locked = period.isLocked;
          rows.add(TimecardRow(
            user: u,
            days: days,
            totals: TimecardTotals(regularMin: total - ot, otMin: ot),
            status: locked && !states.contains(DayState.needsFix)
                ? TimecardStatus.approved
                : states.contains(DayState.needsFix)
                    ? TimecardStatus.needsFix
                    : states.contains(DayState.needsReview)
                        ? TimecardStatus.needsReview
                        : TimecardStatus.ok,
          ));
        }
        return TimecardSheet(
          period: period,
          rule: const OvertimeRule(key: 'federal', nameEn: 'Federal (FLSA)', nameEs: 'Federal (FLSA)'),
          items: rows,
          flagged: rows.fold(0, (a, r) => a + r.days.where((d) => d.state == DayState.needsReview || d.state == DayState.needsFix).length),
          approved: rows.where((r) => r.status == TimecardStatus.ok || r.status == TimecardStatus.approved).length,
        );
      });

  @override
  Future<TimecardDayDetail> day(String periodId, String userId, DateTime date) => Future.delayed(_latency, () {
        final u = _people.firstWhere((p) => p.id == userId);
        DateTime at(int h, int m) => DateTime(date.year, date.month, date.day, h, m);
        final missing = periodId == 'pp0' && userId == 'u6' && date.weekday == DateTime.tuesday;
        final punches = [
          Punch(id: '$userId-1', kind: PunchKind.clockIn, at: at(7, 0), user: u, site: _site, distanceFt: 40, inside: true, review: ReviewStatus.approved),
          Punch(id: '$userId-2', kind: PunchKind.breakStart, at: at(11, 30), user: u, site: _site, distanceFt: 35, inside: true, review: ReviewStatus.approved),
          Punch(id: '$userId-3', kind: PunchKind.breakEnd, at: at(12, 0), user: u, site: _site, distanceFt: 30, inside: true, review: ReviewStatus.approved),
          if (!missing)
            Punch(id: '$userId-4', kind: PunchKind.clockOut, at: at(15, 30), user: u, site: _site, distanceFt: 45, inside: true, review: ReviewStatus.approved),
        ];
        return TimecardDayDetail(punches: punches, siteName: _site.name, minutes: missing ? 0 : 480, missingOut: missing);
      });

  @override
  Future<void> addTimecard(
    String periodId, {
    required String userId,
    required DateTime date,
    required String siteId,
    required String inTime,
    required String outTime,
    required int breakMin,
    required ManualReason reason,
    String? note,
  }) =>
      Future.delayed(_latency, () async {
        final sheet = await timecards(periodId);
        final row = sheet.items.firstWhere((r) => r.user.id == userId);
        final day = row.days.firstWhere((d) => d.date == DateTime(date.year, date.month, date.day));
        if (day.hasTime) {
          throw ApiException(status: 409, code: 'DAY_HAS_PUNCHES', message: 'This person already has time on this day.');
        }
        int mins(String hhmm) => int.parse(hhmm.split(':')[0]) * 60 + int.parse(hhmm.split(':')[1]);
        _manual[_key(periodId, userId, date)] = mins(outTime) - mins(inTime) - breakMin;
      });

  @override
  Future<PayPeriod> approve(String periodId, {bool force = false}) => Future.delayed(_latency, () async {
        final sheet = await timecards(periodId);
        final fix = sheet.items.where((r) => r.status == TimecardStatus.needsFix).length;
        if (fix > 0 && !force) {
          throw ApiException(
            status: 409,
            code: 'TIMECARDS_NEED_FIX',
            message: '$fix timecard(s) still need a fix before the period can be approved.',
            details: {'count': fix},
          );
        }
        _status[periodId] = PeriodStatus.approved;
        return _periods(12).firstWhere((p) => p.id == periodId);
      });

  @override
  Future<(String, String)> exportCsv(String periodId) => Future.delayed(_latency, () async {
        final sheet = await timecards(periodId);
        final lines = [
          'Employee,Regular hours,Overtime 1.5x,Total hours,Status',
          for (final r in sheet.items)
            '${r.user.name},${(r.totals.regularMin / 60).toStringAsFixed(2)},${(r.totals.otMin / 60).toStringAsFixed(2)},'
                '${(r.totals.totalMin / 60).toStringAsFixed(2)},${r.status.name}',
        ];
        return ('TM-Clock-timecards-$periodId.csv', lines.join('\n'));
      });

  @override
  Future<void> addClockOut({required String userId, required DateTime at, String? siteId}) => Future.delayed(_latency);
}
