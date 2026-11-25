import 'package:tm_clock/data/models/models.dart';
import 'package:tm_clock/data/repositories/auth_repository.dart';
import 'package:tm_clock/data/repositories/company_repository.dart';
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
    plan: 'pro',
    portalAllowed: false,
    lastActiveAt: DateTime(2026, 11, 18),
  ),
  Membership(
    companyId: 'c3',
    companyName: 'Isla Builders',
    city: 'San Juan, PR',
    role: Role.admin,
    lastActiveAt: DateTime(2026, 10, 30),
  ),
];

/// What a real server would remember between calls: the company the token is for.
class FakeServer {
  String? companyId;
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._server);
  final FakeServer _server;

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
  Future<void> selectCompany(String companyId, {required String client, bool remember = false}) =>
      Future.delayed(_latency, () => _server.companyId = companyId);

  @override
  Future<void> logout() => Future.delayed(_latency);
}

class FakePunchRepository implements PunchRepository {
  FakePunchRepository(this._server);
  final FakeServer _server;

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

  // ---- Portal: dashboard, approvals, edits (the prototype's sample crew) ----

  static const _lakeNona = SiteRef(id: 's1', name: 'Lake Nona — Bldg C');
  static const _colonial = SiteRef(id: 's2', name: 'Colonial Dr. warehouse', colorIndex: 1);
  static const _kissimmee = SiteRef(id: 's3', name: 'Kissimmee retail', colorIndex: 2);
  static const _sites = [_lakeNona, _colonial, _kissimmee];

  static const _marco = UserRef(id: 'u2', name: 'Marco Gómez', initials: 'MG', title: 'Electrician');
  static const _jaylen = UserRef(id: 'u3', name: 'Jaylen Thomas', initials: 'JT', title: 'Apprentice');
  static const _ana = UserRef(id: 'u4', name: 'Ana Rodríguez', initials: 'AR', title: 'Low-voltage tech');
  static const _luis = UserRef(id: 'u5', name: 'Luis Báez', initials: 'LB', title: 'Electrician');
  static const _david = UserRef(id: 'u1', name: 'David Soto', initials: 'DS', title: 'Foreman');
  static const _kim = UserRef(id: 'u6', name: 'Kim Pham', initials: 'KP', title: 'Low-voltage tech');
  static const _miguel = UserRef(id: 'u7', name: 'Miguel Ruiz', initials: 'MR', title: 'Electrician');

  static DateTime _at(int h, int m) {
    final d = DateTime.now();
    return DateTime(d.year, d.month, d.day, h, m);
  }

  late final List<Punch> _queue = [
    Punch(id: 'p1', kind: PunchKind.clockIn, at: _at(7, 2), user: _marco, site: _lakeNona, distanceFt: 40, inside: true, device: 'iPhone'),
    Punch(id: 'p2', kind: PunchKind.clockIn, at: _at(7, 16), user: _jaylen, site: _colonial, distanceFt: 120, inside: true, device: 'Android'),
    Punch(id: 'p3', kind: PunchKind.breakStart, at: _at(11, 58), user: _ana, site: _kissimmee, distanceFt: 15, inside: true, device: 'Shared tablet'),
    Punch(id: 'p4', kind: PunchKind.clockIn, at: _at(7, 5), user: _luis, site: _lakeNona, distanceFt: 11088, inside: false, device: 'Android', flags: const ['outside']),
  ];

  Punch _copy(Punch p, {PunchKind? kind, DateTime? at, SiteRef? site, ReviewStatus? review, PunchEdited? edited}) => Punch(
        id: p.id,
        kind: kind ?? p.kind,
        at: at ?? p.at,
        user: p.user,
        site: site ?? p.site,
        review: review ?? p.review,
        distanceFt: p.distanceFt,
        inside: p.inside,
        device: p.device,
        flags: edited != null ? {...p.flags, 'edited'}.toList() : p.flags,
        edited: edited ?? p.edited,
      );

  void _replace(Punch p) => _queue[_queue.indexWhere((q) => q.id == p.id)] = p;

  @override
  Future<ApprovalQueue> approvals() => Future.delayed(_latency, () {
        final pending = _queue.where((p) => p.review == ReviewStatus.pending).toList();
        return ApprovalQueue(
          items: [...pending, ..._queue.where((p) => p.review != ReviewStatus.pending)],
          pending: pending.length,
          pendingInside: pending.where((p) => p.inside == true && p.flags.isEmpty).length,
        );
      });

  @override
  Future<Punch> review(String punchId, ReviewStatus decision, {String? note}) => Future.delayed(_latency, () {
        final p = _copy(_queue.firstWhere((q) => q.id == punchId), review: decision);
        _replace(p);
        return p;
      });

  @override
  Future<Punch> editPunch(
    String punchId, {
    PunchKind? kind,
    DateTime? at,
    String? siteId,
    required EditReason reason,
    String? note,
    bool approve = false,
  }) =>
      Future.delayed(_latency, () {
        final old = _queue.firstWhere((q) => q.id == punchId);
        final p = _copy(
          old,
          kind: kind,
          at: at,
          site: siteId == null ? null : _sites.firstWhere((s) => s.id == siteId),
          review: approve ? ReviewStatus.approved : null,
          edited: PunchEdited(from: old.edited?.from ?? old.at, reason: reason, note: note ?? '', by: _me, at: DateTime.now()),
        );
        _replace(p);
        return p;
      });

  @override
  Future<int> approveOnSite({String? siteId}) => Future.delayed(_latency, () {
        var n = 0;
        for (final p in [..._queue]) {
          if (p.review == ReviewStatus.pending && p.inside == true && p.flags.isEmpty) {
            _replace(_copy(p, review: ReviewStatus.approved));
            n++;
          }
        }
        return n;
      });

  @override
  Future<List<SiteRef>> sites() => Future.delayed(_latency, () => _sites);

  @override
  Future<Dashboard> dashboard() {
    // Only the first sample company has a crew on the clock; the others start empty.
    if (_server.companyId != null && _server.companyId != 'c1') {
      return Future.delayed(
        _latency,
        () => const Dashboard(onClockCount: 0, scheduled: 0, onBreak: 0, late: 0, toReview: 0, onClock: []),
      );
    }
    ReviewStatus photo(String id) => _queue.firstWhere((p) => p.id == id).review;
    return Future.delayed(
      _latency,
      () => Dashboard(
        onClockCount: 7,
        scheduled: 9,
        onBreak: 1,
        late: 1,
        toReview: _queue.where((p) => p.review == ReviewStatus.pending).length,
        onClock: [
          OnClockEntry(user: _david, site: _lakeNona, since: _at(6, 45), state: WorkState.working, todayMinutes: 329, photo: ReviewStatus.approved),
          OnClockEntry(user: _ana, site: _kissimmee, since: _at(6, 55), state: WorkState.onBreak, todayMinutes: 303, photo: ReviewStatus.approved),
          OnClockEntry(user: _kim, site: _colonial, since: _at(7, 0), state: WorkState.working, todayMinutes: 314, photo: ReviewStatus.approved),
          OnClockEntry(user: _marco, site: _lakeNona, since: _at(7, 2), state: WorkState.working, todayMinutes: 312, photo: photo('p1'), punchId: 'p1'),
          OnClockEntry(user: _luis, site: _lakeNona, since: _at(7, 5), state: WorkState.offSite, todayMinutes: 309, photo: photo('p4'), punchId: 'p4'),
          OnClockEntry(user: _jaylen, site: _colonial, since: _at(7, 16), state: WorkState.late, todayMinutes: 298, photo: photo('p2'), punchId: 'p2'),
          OnClockEntry(user: _miguel, site: _lakeNona, since: _at(8, 10), state: WorkState.working, todayMinutes: 245, photo: ReviewStatus.approved),
        ],
        attention: const [
          Attention(kind: AttentionKind.outside, user: _luis, detail: '2.1 mi'),
          Attention(kind: AttentionKind.missingOut, user: _kim, detail: '4:30 PM'),
          Attention(kind: AttentionKind.nearOvertime, user: _david, detail: '38h'),
        ],
        startingSoon: const [
          ShiftRef(id: 'sh1', start: '13:00', end: '21:00', user: UserRef(id: 'u8', name: 'Sofía Vega', initials: 'SV'), site: _kissimmee),
          ShiftRef(id: 'sh2', start: '14:30', end: '22:30', user: UserRef(id: 'u9', name: 'Chris Allen', initials: 'CA'), site: _colonial),
        ],
      ),
    );
  }
}

class FakeCompanyRepository implements CompanyRepository {
  FakeCompanyRepository(this._server);
  final FakeServer _server;

  @override
  Future<MeInfo> me() => Future.delayed(
        _latency,
        () => MeInfo(
          userName: _me.name,
          initials: _me.initials,
          planTier: _server.companyId == 'c2' ? 'pro' : 'free',
          retentionDays: _server.companyId == 'c2' ? 365 : 90,
          seats: _server.companyId == 'c2' ? 75 : 50,
          seatsUsed: 12,
          permissions: const {'punch.approve', 'punch.edit', 'timecards.approve', 'payperiod.editLocked', 'payroll.export'},
        ),
      );

  @override
  Future<List<Plan>> plans() => Future.delayed(
        _latency,
        () => const [
          Plan(key: 'free', yearlyCents: 0, includedSeats: 50, retentionDays: 90),
          Plan(key: 'pro', yearlyCents: 49900, includedSeats: 75, retentionDays: 365),
          Plan(key: 'business', yearlyCents: 99900, includedSeats: 150, retentionDays: 1095),
        ],
      );
}
