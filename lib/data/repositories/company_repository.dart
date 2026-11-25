import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/models/models.dart';

/// The signed-in company: who I am there, plan and seats, and the public price list.
abstract interface class CompanyRepository {
  /// `GET /me` — user, company plan and seats, my permissions.
  Future<MeInfo> me();

  /// `GET /billing/plans` — Free / Pro / Business prices (data, never hard-coded).
  Future<List<Plan>> plans();
}

class HttpCompanyRepository implements CompanyRepository {
  HttpCompanyRepository(this._api);
  final ApiClient _api;

  @override
  Future<MeInfo> me() async => MeInfo.fromJson(await _api.get('/me'));

  @override
  Future<List<Plan>> plans() async {
    final json = await _api.get<Map<String, dynamic>>('/billing/plans');
    return [for (final p in json['plans'] as List) Plan.fromJson(p as Map<String, dynamic>)];
  }
}
