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
