import 'package:tm_clock/core/config/env.dart';
import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/api/token_store.dart';
import 'package:tm_clock/data/fake/fake_repositories.dart';
import 'package:tm_clock/data/repositories/auth_repository.dart';
import 'package:tm_clock/data/repositories/punch_repository.dart';

export 'auth_repository.dart';
export 'punch_repository.dart';

/// Every repository the apps use, built once at startup.
/// Add a new feature's repository here and both apps get it.
class Repositories {
  Repositories({required this.auth, required this.punches});

  final AuthRepository auth;
  final PunchRepository punches;

  /// Real HTTP repositories, or sample data when [Env.useFakeData] is on.
  factory Repositories.create({required String Function() language}) {
    if (Env.useFakeData) {
      return Repositories(auth: FakeAuthRepository(), punches: FakePunchRepository());
    }
    final api = ApiClient(tokens: TokenStore(), language: language);
    return Repositories(auth: HttpAuthRepository(api), punches: HttpPunchRepository(api));
  }
}
