/// Pay periods and timecards (field names follow tm-clock-api/api/openapi.yaml).
library;

import 'package:tm_clock/data/models/models.dart';

enum PeriodStatus { open, approved, locked }

enum DataState { kept, partlyDeleted, deleted }

/// `PayPeriod`
class PayPeriod {
  const PayPeriod({
    required this.id,
    required this.type,
    required this.start,
    required this.end,
    required this.label,
    this.current = false,
    this.status = PeriodStatus.open,
    this.dataState = DataState.kept,
  });

  final String id, type, label;
  final DateTime start, end;
  final bool current;
  final PeriodStatus status;
  final DataState dataState;

  bool get isLocked => status != PeriodStatus.open;

  /// Every day in the period.
  List<DateTime> get dates => [for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) d];

  factory PayPeriod.fromJson(Map<String, dynamic> j) => PayPeriod(
        id: j['id'] as String,
        type: j['type'] as String? ?? 'weekly',
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        label: j['label'] as String? ?? '',
        current: j['current'] as bool? ?? false,
        status: PeriodStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => PeriodStatus.open),
        dataState: DataState.values.firstWhere((s) => s.name == j['dataState'], orElse: () => DataState.kept),
      );
}

/// `OvertimeRule`
class OvertimeRule {
  const OvertimeRule({required this.key, required this.nameEn, required this.nameEs, this.weeklyHours = 40, this.dailyHours, this.doubleAfter, this.seventhDay});
  final String key, nameEn, nameEs;
  final int weeklyHours;
  final int? dailyHours, doubleAfter;
  final String? seventhDay;

  bool get hasDouble => doubleAfter != null || seventhDay == 'ca';

  factory OvertimeRule.fromJson(Map<String, dynamic> j) => OvertimeRule(
        key: j['key'] as String? ?? 'federal',
        nameEn: (j['name'] as Map?)?['en'] as String? ?? '',
        nameEs: (j['name'] as Map?)?['es'] as String? ?? '',
        weeklyHours: j['weeklyHours'] as int? ?? 40,
        dailyHours: j['dailyHours'] as int?,
        doubleAfter: j['doubleAfter'] as int?,
        seventhDay: j['seventhDay'] as String?,
      );
}

enum DayState { ok, needsReview, needsFix, off, future }

enum TimecardStatus { ok, needsReview, needsFix, approved }

class TimecardDay {
  const TimecardDay({required this.date, required this.minutes, required this.state, this.site});
  final DateTime date;
  final int minutes;
  final DayState state;
  final SiteRef? site;

  bool get hasTime => state != DayState.off && state != DayState.future;

  factory TimecardDay.fromJson(Map<String, dynamic> j) => TimecardDay(
        date: DateTime.parse(j['date'] as String),
        minutes: j['minutes'] as int? ?? 0,
        state: DayState.values.firstWhere((s) => s.name == j['state'], orElse: () => DayState.off),
        site: j['site'] == null ? null : SiteRef.fromJson(j['site'] as Map<String, dynamic>),
      );
}

class TimecardTotals {
  const TimecardTotals({this.regularMin = 0, this.otMin = 0, this.dtMin = 0});
  final int regularMin, otMin, dtMin;
  int get totalMin => regularMin + otMin + dtMin;

  factory TimecardTotals.fromJson(Map<String, dynamic>? j) => TimecardTotals(
        regularMin: j?['regularMin'] as int? ?? 0,
        otMin: j?['otMin'] as int? ?? 0,
        dtMin: j?['dtMin'] as int? ?? 0,
      );
}

/// `Timecard` — one person × pay period.
class TimecardRow {
  const TimecardRow({required this.user, required this.days, required this.totals, required this.status});
  final UserRef user;
  final List<TimecardDay> days;
  final TimecardTotals totals;
  final TimecardStatus status;

  factory TimecardRow.fromJson(Map<String, dynamic> j) => TimecardRow(
        user: UserRef.fromJson(j['user'] as Map<String, dynamic>),
        days: [for (final d in (j['days'] as List? ?? const [])) TimecardDay.fromJson(d as Map<String, dynamic>)],
        totals: TimecardTotals.fromJson(j['totals'] as Map<String, dynamic>?),
        status: TimecardStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => TimecardStatus.ok),
      );
}

/// `GET /pay-periods/{id}/timecards`
class TimecardSheet {
  const TimecardSheet({required this.period, required this.rule, required this.items, required this.flagged, required this.approved});
  final PayPeriod period;
  final OvertimeRule rule;
  final List<TimecardRow> items;
  final int flagged, approved;

  int get regularMin => items.fold(0, (a, r) => a + r.totals.regularMin);
  int get overtimeMin => items.fold(0, (a, r) => a + r.totals.otMin + r.totals.dtMin);

  factory TimecardSheet.fromJson(Map<String, dynamic> j) {
    final t = j['totals'] as Map<String, dynamic>? ?? const {};
    return TimecardSheet(
      period: PayPeriod.fromJson(j['period'] as Map<String, dynamic>),
      rule: OvertimeRule.fromJson(j['rule'] as Map<String, dynamic>? ?? const {}),
      items: [for (final r in (j['items'] as List? ?? const [])) TimecardRow.fromJson(r as Map<String, dynamic>)],
      flagged: t['flagged'] as int? ?? 0,
      approved: t['approved'] as int? ?? 0,
    );
  }
}

/// `GET /pay-periods/{id}/timecards/{userId}/days/{date}` — the map popup.
class TimecardDayDetail {
  const TimecardDayDetail({required this.punches, this.siteName, this.radiusFt = 500, this.minutes = 0, this.missingOut = false});
  final List<Punch> punches;
  final String? siteName;
  final int radiusFt;
  final int minutes;
  final bool missingOut;

  factory TimecardDayDetail.fromJson(Map<String, dynamic> j) => TimecardDayDetail(
        punches: [for (final p in (j['punches'] as List? ?? const [])) Punch.fromJson(p as Map<String, dynamic>)],
        siteName: (j['site'] as Map?)?['name'] as String?,
        radiusFt: (j['site'] as Map?)?['effectiveRadiusFt'] as int? ?? 500,
        minutes: j['minutes'] as int? ?? 0,
        missingOut: j['missingOut'] as bool? ?? false,
      );
}

/// `ManualTimecardInput.reason` — the prototype's five reasons map onto these.
enum ManualReason { paperTimesheet, noSignal, forgot, other }
