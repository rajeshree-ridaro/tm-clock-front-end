import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/models/timecards.dart';
import 'package:tm_clock/data/repositories/punch_repository.dart';

/// Pay periods, the timecards page, manual days, approval and payroll export.
abstract interface class TimecardRepository {
  /// `GET /pay-periods` — newest first (current period first).
  Future<List<PayPeriod>> payPeriods({int limit = 12});

  /// `GET /pay-periods/{id}/timecards`
  Future<TimecardSheet> timecards(String periodId);

  /// `GET /pay-periods/{id}/timecards/{userId}/days/{date}`
  Future<TimecardDayDetail> day(String periodId, String userId, DateTime date);

  /// "Add timecard" — `POST /pay-periods/{id}/timecards`. Throws `DAY_HAS_PUNCHES` (409) when the day has time.
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
  });

  /// `POST /pay-periods/{id}/approve`. Throws `TIMECARDS_NEED_FIX` (409) unless [force].
  Future<PayPeriod> approve(String periodId, {bool force = false});

  /// `POST /pay-periods/{id}/export` (csv) → the file's name and CSV text.
  Future<(String, String)> exportCsv(String periodId);

  /// Missing clock-out added from the day popup — `POST /punches` for a crew member.
  Future<void> addClockOut({required String userId, required DateTime at, String? siteId});
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class HttpTimecardRepository implements TimecardRepository {
  HttpTimecardRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<PayPeriod>> payPeriods({int limit = 12}) async {
    final json = await _api.get<Map<String, dynamic>>('/pay-periods', query: {'limit': limit});
    return [for (final p in json['items'] as List) PayPeriod.fromJson(p as Map<String, dynamic>)];
  }

  @override
  Future<TimecardSheet> timecards(String periodId) async =>
      TimecardSheet.fromJson(await _api.get('/pay-periods/$periodId/timecards'));

  @override
  Future<TimecardDayDetail> day(String periodId, String userId, DateTime date) async =>
      TimecardDayDetail.fromJson(await _api.get('/pay-periods/$periodId/timecards/$userId/days/${_date(date)}'));

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
      _api.post<Map<String, dynamic>>('/pay-periods/$periodId/timecards', body: {
        'userId': userId,
        'date': _date(date),
        'siteId': siteId,
        'in': inTime,
        'out': outTime,
        'breakMin': breakMin,
        'reason': reason.name,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  @override
  Future<PayPeriod> approve(String periodId, {bool force = false}) async =>
      PayPeriod.fromJson(await _api.post('/pay-periods/$periodId/approve', body: {'force': force}));

  @override
  Future<(String, String)> exportCsv(String periodId) async {
    final job = await _api.post<Map<String, dynamic>>('/pay-periods/$periodId/export', body: {'format': 'csv'});
    final url = (job['fileUrl'] as String).replaceFirst('/v1', '');
    final csv = await _api.get<String>(url);
    return (job['fileName'] as String? ?? 'timecards.csv', csv);
  }

  @override
  Future<void> addClockOut({required String userId, required DateTime at, String? siteId}) =>
      _api.post<Map<String, dynamic>>('/punches', body: {
        'clientId': newClientId(),
        'userId': userId,
        'kind': 'out',
        'deviceAt': at.toUtc().toIso8601String(),
        'at': at.toUtc().toIso8601String(),
        'siteId': ?siteId,
        'device': {'type': 'web'},
      });
}
