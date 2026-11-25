import 'package:flutter/foundation.dart';

import 'package:tm_clock/data/models/models.dart';
import 'package:tm_clock/data/repositories/repositories.dart';

/// Who is signed in and which company they are working for.
/// Same flow in both apps: sign in → pick a company (if several) → app.
class Session extends ChangeNotifier {
  Session(this._auth);
  final AuthRepository _auth;

  UserRef? user;
  List<Membership> companies = const [];
  Membership? company;

  bool get signedIn => user != null;
  bool get hasCompany => company != null;
  Role? get role => company?.role;
  bool get isSupervisor => role != null && role != Role.employee;

  /// Call after a successful sign-in. Picks the company automatically when there is only one.
  Future<void> start(AuthResult result, {required String client}) async {
    user = result.user;
    companies = result.companies;
    company = null;
    if (!result.needsCompany && companies.length == 1) {
      await selectCompany(companies.first, client: client);
    }
    notifyListeners();
  }

  Future<void> selectCompany(Membership m, {required String client}) async {
    await _auth.selectCompany(m.companyId, client: client);
    company = m;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.logout();
    user = null;
    companies = const [];
    company = null;
    notifyListeners();
  }
}
