import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/models/models.dart';

/// Sign-in for both apps: portal uses email/password, crew app uses phone + SMS code.
abstract interface class AuthRepository {
  /// Portal — `POST /auth/login`
  Future<AuthResult> loginWithPassword(String email, String password);

  /// Crew app — `POST /auth/otp/send`
  Future<void> sendOtp(String phone);

  /// Crew app — `POST /auth/otp/verify`
  Future<AuthResult> verifyOtp(String phone, String code);

  /// `GET /me/companies`
  Future<List<Membership>> myCompanies();

  /// `POST /auth/select-company`. `client` is `portal` or `app`.
  Future<void> selectCompany(String companyId, {required String client});

  /// `POST /auth/logout`
  Future<void> logout();
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api);
  final ApiClient _api;

  Future<AuthResult> _saveTokens(Map<String, dynamic> json) async {
    _api.tokens.save(access: json['accessToken'] as String, refresh: json['refreshToken'] as String);
    return AuthResult.fromJson(json);
  }

  @override
  Future<AuthResult> loginWithPassword(String email, String password) async =>
      _saveTokens(await _api.post('/auth/login', body: {'email': email, 'password': password}));

  @override
  Future<void> sendOtp(String phone) => _api.post<void>('/auth/otp/send', body: {'phone': phone});

  @override
  Future<AuthResult> verifyOtp(String phone, String code) async => _saveTokens(
        await _api.post('/auth/otp/verify', body: {
          'phone': phone,
          'code': code,
          'device': {'type': 'phone'},
        }),
      );

  @override
  Future<List<Membership>> myCompanies() async {
    final json = await _api.get<Map<String, dynamic>>('/me/companies');
    return [for (final m in json['items'] as List) Membership.fromJson(m as Map<String, dynamic>)];
  }

  @override
  Future<void> selectCompany(String companyId, {required String client}) async {
    await _saveTokens(await _api.post(
      '/auth/select-company',
      body: {'companyId': companyId, 'remember': true, 'client': client},
    ));
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post<void>('/auth/logout');
    } finally {
      _api.tokens.clear();
    }
  }
}
