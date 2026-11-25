import 'package:tm_clock/data/models/models.dart';
import 'package:tm_clock/data/repositories/auth_repository.dart';
import 'package:tm_clock/data/repositories/punch_repository.dart';

/// Sample data matching the prototypes, so both apps run with no backend
/// (`Env.useFakeData`). Delete once the API is live.
const _latency = Duration(milliseconds: 250);

const _me = UserRef(id: 'u1', name: 'David Soto', initials: 'DS');

final _companies = [
  Membership(
    companyId: 'c1',
    companyName: 'Rivera Electric',
    city: 'Orlando, FL',
    role: Role.supervisor,
    lastActiveAt: DateTime(2026, 11, 23),
  ),
  Membership(
    companyId: 'c2',
    companyName: 'Coastal Low Voltage',
    city: 'Tampa, FL',
    role: Role.employee,
    portalAllowed: false,
    lastActiveAt: DateTime(2026, 11, 18),
  ),
  Membership(
    companyId: 'c3',
    companyName: 'Isla Builders',
    city: 'Ponce, PR',
    role: Role.employee,
    portalAllowed: false,
    lastActiveAt: DateTime(2026, 10, 30),
  ),
];

class FakeAuthRepository implements AuthRepository {
  AuthResult get _result => AuthResult(user: _me, needsCompany: true, companies: _companies);

  @override
  Future<AuthResult> loginWithPassword(String email, String password) =>
      Future.delayed(_latency, () => _result);

  @override
  Future<void> sendOtp(String phone) => Future.delayed(_latency);

  @override
  Future<AuthResult> verifyOtp(String phone, String code) => Future.delayed(_latency, () => _result);

  @override
  Future<List<Membership>> myCompanies() => Future.delayed(_latency, () => _companies);

  @override
  Future<void> selectCompany(String companyId, {required String client}) => Future.delayed(_latency);

  @override
  Future<void> logout() => Future.delayed(_latency);
}

class FakePunchRepository implements PunchRepository {
  ClockState _state = ClockState.out;
  Punch? _last;

  @override
  Future<MeStatus> myStatus() => Future.delayed(
        _latency,
        () => MeStatus(
          state: _state,
          lastPunch: _last,
          todayMinutes: 240,
          weekMinutes: 36 * 60,
          briefingToSign: true,
        ),
      );

  @override
  Future<LocationCheck> checkLocation({required double lat, required double lng, int? accuracyFt}) =>
      Future.delayed(
        _latency,
        () => const LocationCheck(
          site: SiteRef(id: 's1', name: 'Lake Nona — Bldg C'),
          distanceFt: 40,
          inside: true,
        ),
      );

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
  }) =>
      Future.delayed(_latency, () {
        _state = switch (kind) {
          PunchKind.clockIn || PunchKind.breakEnd => ClockState.clockedIn,
          PunchKind.breakStart => ClockState.onBreak,
          PunchKind.clockOut => ClockState.out,
        };
        return _last = Punch(id: clientId, kind: kind, at: deviceAt, user: _me);
      });

  @override
  Future<Dashboard> dashboard() {
    final today = DateTime.now();
    DateTime at(int h, int m) => DateTime(today.year, today.month, today.day, h, m);
    const site1 = SiteRef(id: 's1', name: 'Riverside Plaza');
    const site2 = SiteRef(id: 's2', name: 'Oak St. Remodel', colorIndex: 1);
    return Future.delayed(
      _latency,
      () => Dashboard(
        onClockCount: 14,
        scheduled: 18,
        onBreak: 2,
        late: 1,
        toReview: 5,
        onClock: [
          OnClockEntry(
            user: const UserRef(id: 'u2', name: 'Miguel Ruiz', initials: 'MR'),
            site: site1,
            since: at(6, 58),
            state: WorkState.working,
            photo: ReviewStatus.approved,
          ),
          OnClockEntry(
            user: const UserRef(id: 'u3', name: 'Jasmine Taylor', initials: 'JT'),
            site: site2,
            since: at(7, 12),
            state: WorkState.working,
          ),
          OnClockEntry(
            user: const UserRef(id: 'u4', name: 'Daniel Kim', initials: 'DK'),
            site: site1,
            since: at(6, 45),
            state: WorkState.onBreak,
            photo: ReviewStatus.approved,
          ),
          OnClockEntry(
            user: const UserRef(id: 'u5', name: 'Ana López', initials: 'AL'),
            site: site2,
            since: at(7, 30),
            state: WorkState.offSite,
          ),
        ],
      ),
    );
  }
}
