// Runs every call the apps make, through the real HTTP repositories, against an API server
// (the Prism mock or the real back end) and reports which ones fail and why.
//
//   dart run tool/check_api.dart                         # mock from tool/mock_api.ps1
//   dart run tool/check_api.dart http://localhost:8080/v1 # real back end
//
// A failure here means the app and the API disagree: a request the spec rejects,
// or a response the models can't read.
//
// Signs in with the back end's demo logins (tm-clock-back-end/scripts/seed.py); the mock accepts anything.
import 'dart:io';

import 'package:tm_clock/data/api/api_client.dart';
import 'package:tm_clock/data/api/token_store.dart';
import 'package:tm_clock/data/models/models.dart';
import 'package:tm_clock/data/repositories/auth_repository.dart';
import 'package:tm_clock/data/repositories/punch_repository.dart';

Future<void> main(List<String> args) async {
  final baseUrl = args.isNotEmpty ? args.first : 'http://localhost:4010';
  final api = ApiClient(tokens: TokenStore(), language: () => 'en', baseUrl: baseUrl);
  final auth = HttpAuthRepository(api);
  final punches = HttpPunchRepository(api);
  var failed = 0;

  Future<T?> check<T>(String name, Future<T> Function() call) async {
    try {
      final result = await call();
      stdout.writeln('  ok    $name');
      return result;
    } catch (e) {
      failed++;
      stdout.writeln('  FAIL  $name\n        $e');
      return null;
    }
  }

  stdout.writeln('Checking $baseUrl');
  await check('POST /auth/login', () => auth.loginWithPassword('maria@riveraelectric.test', 'password123'));
  await check('POST /auth/otp/send', () => auth.sendOtp('+14075550110'));
  await check('POST /auth/otp/verify', () => auth.verifyOtp('+14075550110', '123456'));
  final companies = await check('GET /me/companies', auth.myCompanies) ?? const <Membership>[];
  if (companies.isNotEmpty) {
    await check('POST /auth/select-company', () => auth.selectCompany(companies.first.companyId, client: 'app'));
  }
  final status = await check('GET /me/status', punches.myStatus);
  final loc = await check('POST /punches/check-location', () => punches.checkLocation(lat: 28.4, lng: -81.2));
  // The real API enforces out → in → (break)* → out, so send whatever comes next.
  final next = switch (status?.state) {
    ClockState.clockedIn => PunchKind.clockOut,
    ClockState.onBreak => PunchKind.breakEnd,
    _ => PunchKind.clockIn,
  };
  await check('POST /punches (${punchKindWire[next]})', () => punches.createPunch(
        clientId: newClientId(),
        kind: next,
        deviceAt: DateTime.now(),
        siteId: loc?.site?.id,
        lat: 28.4,
        lng: -81.2,
      ));
  await check('GET /dashboard', punches.dashboard);
  await check('POST /auth/logout', auth.logout);

  stdout.writeln(failed == 0 ? 'All calls match the API.' : '$failed call(s) failed.');
  exit(failed == 0 ? 0 : 1);
}
