import 'dart:math';

import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/models/models.dart';

/// Punches and crew status — used by the crew app (my punches, supervisor crew)
/// and the portal (dashboard, approvals).
abstract interface class PunchRepository {
  /// Crew app home — `GET /me/status`
  Future<MeStatus> myStatus();

  /// Before the camera opens — `POST /punches/check-location`
  Future<LocationCheck> checkLocation({required double lat, required double lng, int? accuracyFt});

  /// Clock in / break / clock out — `POST /punches`.
  /// [clientId] makes retries and offline sync safe; reuse it when retrying.
  Future<Punch> createPunch({
    required String clientId,
    required PunchKind kind,
    required DateTime deviceAt,
    String? userId,
    String? siteId,
    String? taskId,
    String? photoFileId,
    double? lat,
    double? lng,
  });

  /// Portal dashboard + supervisor crew list — `GET /dashboard`
  Future<Dashboard> dashboard();

  /// Photo approvals queue — `GET /approvals` (pending first, then today's decided).
  Future<ApprovalQueue> approvals();

  /// Approve / reject / ask for a retake — `POST /punches/{id}/review`
  Future<Punch> review(String punchId, ReviewStatus decision, {String? note});

  /// Edit a punch (type, time, job site) with a reason — `PATCH /punches/{id}`.
  /// [approve] is the portal's "Save & approve".
  Future<Punch> editPunch(
    String punchId, {
    PunchKind? kind,
    DateTime? at,
    String? siteId,
    required EditReason reason,
    String? note,
    bool approve = false,
  });

  /// "Approve all on site" — `POST /approvals/approve-on-site`. Returns how many were approved.
  Future<int> approveOnSite({String? siteId});

  /// Job sites — `GET /sites`
  Future<List<SiteRef>> sites();
}

class HttpPunchRepository implements PunchRepository {
  HttpPunchRepository(this._api);
  final ApiClient _api;

  @override
  Future<MeStatus> myStatus() async => MeStatus.fromJson(await _api.get('/me/status'));

  @override
  Future<LocationCheck> checkLocation({required double lat, required double lng, int? accuracyFt}) async =>
      LocationCheck.fromJson(await _api.post('/punches/check-location', body: {
        'lat': lat,
        'lng': lng,
        'accuracyFt': ?accuracyFt,
      }));

  @override
  Future<Punch> createPunch({
    required String clientId,
    required PunchKind kind,
    required DateTime deviceAt,
    String? userId,
    String? siteId,
    String? taskId,
    String? photoFileId,
    double? lat,
    double? lng,
  }) async =>
      Punch.fromJson(await _api.post('/punches', body: {
        'clientId': clientId,
        'kind': punchKindWire[kind],
        'deviceAt': deviceAt.toUtc().toIso8601String(),
        'device': {'type': 'phone'},
        'userId': ?userId,
        'siteId': ?siteId,
        'taskId': ?taskId,
        'photoFileId': ?photoFileId,
        if (lat != null && lng != null) 'gps': {'lat': lat, 'lng': lng},
      }));

  @override
  Future<Dashboard> dashboard() async => Dashboard.fromJson(await _api.get('/dashboard'));

  @override
  Future<ApprovalQueue> approvals() async => ApprovalQueue.fromJson(await _api.get('/approvals'));

  @override
  Future<Punch> review(String punchId, ReviewStatus decision, {String? note}) async =>
      Punch.fromJson(await _api.post('/punches/$punchId/review', body: {'decision': decision.name, 'note': ?note}));

  @override
  Future<Punch> editPunch(
    String punchId, {
    PunchKind? kind,
    DateTime? at,
    String? siteId,
    required EditReason reason,
    String? note,
    bool approve = false,
  }) async =>
      Punch.fromJson(await _api.patch('/punches/$punchId', body: {
        if (kind != null) 'kind': punchKindWire[kind],
        if (at != null) 'at': at.toUtc().toIso8601String(),
        'siteId': ?siteId,
        'reason': reason.name,
        if (note != null && note.isNotEmpty) 'note': note,
        'approve': approve,
      }));

  @override
  Future<int> approveOnSite({String? siteId}) async {
    final json = await _api.post<Map<String, dynamic>>('/approvals/approve-on-site', body: {'siteId': ?siteId});
    return json['approved'] as int? ?? 0;
  }

  @override
  Future<List<SiteRef>> sites() async {
    final json = await _api.get<Map<String, dynamic>>('/sites', query: {'active': true});
    return [for (final s in json['items'] as List) SiteRef.fromJson(s as Map<String, dynamic>)];
  }
}

/// RFC 4122 v4 UUID for `clientId`.
String newClientId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
