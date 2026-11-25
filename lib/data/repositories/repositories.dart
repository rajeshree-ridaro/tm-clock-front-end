import 'package:tm_clock/core/config/env.dart';
import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/api/token_store.dart';
import 'package:tm_clock/data/fake/fake_repositories.dart';
import 'package:tm_clock/data/fake/fake_timecards.dart';
import 'package:tm_clock/data/repositories/auth_repository.dart';
import 'package:tm_clock/data/repositories/company_repository.dart';
import 'package:tm_clock/data/repositories/punch_repository.dart';
import 'package:tm_clock/data/repositories/timecard_repository.dart';

export 'auth_repository.dart';
export 'company_repository.dart';
export 'punch_repository.dart';
export 'timecard_repository.dart';

/// Every repository the apps use, built once at startup.
/// Add a new feature's repository here and both apps get it.
class Repositories {
  Repositories({required this.auth, required this.punches, required this.company, required this.timecards});

  final AuthRepository auth;
  final PunchRepository punches;
  final CompanyRepository company;
  final TimecardRepository timecards;

  /// Real HTTP repositories, or sample data when [Env.useFakeData] is on.
  factory Repositories.create({required String Function() language}) {
    if (Env.useFakeData) {
      final server = FakeServer();
      return Repositories(
        auth: FakeAuthRepository(server),
        punches: FakePunchRepository(server),
        company: FakeCompanyRepository(server),
        timecards: FakeTimecardRepository(),
      );
    }
    final api = ApiClient(tokens: TokenStore(), language: language);
    return Repositories(
      auth: HttpAuthRepository(api),
      punches: HttpPunchRepository(api),
      company: HttpCompanyRepository(api),
      timecards: HttpTimecardRepository(api),
    );
  }
}
