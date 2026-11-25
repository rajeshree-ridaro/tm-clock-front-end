/// App models for the shapes both apps use. Field names follow
/// tm-clock-api/api/openapi.yaml so `fromJson` maps 1:1.
library;

enum Role { owner, admin, supervisor, employee }

enum ClockState { out, clockedIn, onBreak }

enum PunchKind { clockIn, breakStart, breakEnd, clockOut }

enum ReviewStatus { pending, approved, rejected, retake }

/// `onClock[].state` on the dashboard.
enum WorkState { working, late, onBreak, offSite }

T _enum<T extends Enum>(List<T> values, Object? raw, T fallback, [Map<String, T> alias = const {}]) {
  if (raw is! String) return fallback;
  return alias[raw] ?? values.firstWhere((v) => v.name == raw, orElse: () => fallback);
}

ClockState clockStateFrom(Object? raw) =>
    _enum(ClockState.values, raw, ClockState.out, {'in': ClockState.clockedIn});

const punchKindWire = {
  PunchKind.clockIn: 'in',
  PunchKind.breakStart: 'breakStart',
  PunchKind.breakEnd: 'breakEnd',
  PunchKind.clockOut: 'out',
};

PunchKind punchKindFrom(Object? raw) => punchKindWire.entries
    .firstWhere((e) => e.value == raw, orElse: () => punchKindWire.entries.first)
    .key;

/// `UserRef`
class UserRef {
  const UserRef({required this.id, required this.name, required this.initials, this.title = ''});
  final String id, name, initials;

  /// Job title ("Electrician"); sent on lists that show it.
  final String title;

  factory UserRef.fromJson(Map<String, dynamic> j) => UserRef(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        initials: j['initials'] as String? ?? '',
        title: j['title'] as String? ?? '',
      );
}

/// Why a punch was edited (`EditReason`).
enum EditReason { forgot, wrongTime, wrongSite, phone, supervisorEntry, other }

/// `Punch.edited` — the last edit (the full trail is in history).
class PunchEdited {
  const PunchEdited({this.from, required this.reason, this.note = '', this.by, this.at});
  final DateTime? from;
  final EditReason reason;
  final String note;
  final UserRef? by;
  final DateTime? at;

  factory PunchEdited.fromJson(Map<String, dynamic> j) => PunchEdited(
        from: DateTime.tryParse(j['from'] as String? ?? '')?.toLocal(),
        reason: _enum(EditReason.values, j['reason'], EditReason.other),
        note: j['note'] as String? ?? '',
        by: j['by'] == null ? null : UserRef.fromJson(j['by'] as Map<String, dynamic>),
        at: DateTime.tryParse(j['at'] as String? ?? '')?.toLocal(),
      );
}

/// `SiteRef`
class SiteRef {
  const SiteRef({required this.id, required this.name, this.colorIndex = 0});
  final String id, name;
  final int colorIndex;

  factory SiteRef.fromJson(Map<String, dynamic> j) => SiteRef(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        colorIndex: j['colorIndex'] as int? ?? 0,
      );
}

/// `Membership` — one company this login belongs to.
class Membership {
  const Membership({
    required this.companyId,
    required this.companyName,
    required this.city,
    required this.role,
    this.plan = 'free',
    this.portalAllowed = true,
    this.lastActiveAt,
    this.clockState = ClockState.out,
  });

  final String companyId, companyName, city;

  /// `free`, `pro` or `business`.
  final String plan;
  final Role role;
  final bool portalAllowed;
  final DateTime? lastActiveAt;
  final ClockState clockState;

  String get initials => companyName
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
        companyId: j['companyId'] as String,
        companyName: j['companyName'] as String? ?? '',
        city: j['city'] as String? ?? '',
        role: _enum(Role.values, j['role'], Role.employee),
        plan: j['plan'] as String? ?? 'free',
        portalAllowed: j['portalAllowed'] as bool? ?? false,
        lastActiveAt: DateTime.tryParse(j['lastActiveAt'] as String? ?? ''),
        clockState: clockStateFrom(j['clockState']),
      );
}

/// `Tokens` response, minus the tokens themselves (kept in TokenStore).
class AuthResult {
  const AuthResult({required this.user, required this.needsCompany, required this.companies});
  final UserRef user;
  final bool needsCompany;
  final List<Membership> companies;

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        user: UserRef.fromJson(j['user'] as Map<String, dynamic>? ?? const {}),
        needsCompany: j['needsCompany'] as bool? ?? false,
        companies: [
          for (final m in (j['companies'] as List? ?? const [])) Membership.fromJson(m as Map<String, dynamic>),
        ],
      );
}

/// `Punch` (fields the apps show).
class Punch {
  const Punch({
    required this.id,
    required this.kind,
    required this.at,
    this.user,
    this.site,
    this.review = ReviewStatus.pending,
    this.distanceFt,
    this.inside,
    this.device = '',
    this.flags = const [],
    this.edited,
  });

  final String id;
  final PunchKind kind;
  final DateTime at;
  final UserRef? user;
  final SiteRef? site;
  final ReviewStatus review;

  /// GPS check against the job site.
  final int? distanceFt;
  final bool? inside;

  /// "iPhone", "Shared tablet"…
  final String device;
  final List<String> flags;
  final PunchEdited? edited;

  factory Punch.fromJson(Map<String, dynamic> j) => Punch(
        id: j['id'] as String,
        kind: punchKindFrom(j['kind']),
        at: DateTime.parse(j['at'] as String).toLocal(),
        user: j['user'] == null ? null : UserRef.fromJson(j['user'] as Map<String, dynamic>),
        site: j['site'] == null ? null : SiteRef.fromJson(j['site'] as Map<String, dynamic>),
        review: _enum(ReviewStatus.values, (j['review'] as Map?)?['status'], ReviewStatus.pending),
        distanceFt: (j['gps'] as Map?)?['distanceFt'] as int?,
        inside: (j['gps'] as Map?)?['inside'] as bool?,
        device: ((j['device'] as Map?)?['model'] ?? (j['device'] as Map?)?['type'] ?? '') as String,
        flags: [for (final f in (j['flags'] as List? ?? const [])) f as String],
        edited: j['edited'] == null ? null : PunchEdited.fromJson(j['edited'] as Map<String, dynamic>),
      );
}

/// `GET /approvals`
class ApprovalQueue {
  const ApprovalQueue({required this.items, required this.pending, required this.pendingInside});
  final List<Punch> items;
  final int pending, pendingInside;

  factory ApprovalQueue.fromJson(Map<String, dynamic> j) => ApprovalQueue(
        items: [for (final p in (j['items'] as List? ?? const [])) Punch.fromJson(p as Map<String, dynamic>)],
        pending: j['pending'] as int? ?? 0,
        pendingInside: j['pendingInside'] as int? ?? 0,
      );
}

/// `GET /billing/plans` → one plan (prices are data, never hard-coded).
class Plan {
  const Plan({required this.key, required this.yearlyCents, this.includedSeats = 0, this.retentionDays = 90});
  final String key;
  final int yearlyCents, includedSeats, retentionDays;

  int get yearlyDollars => yearlyCents ~/ 100;

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        key: j['key'] as String? ?? 'free',
        yearlyCents: j['yearlyCents'] as int? ?? 0,
        includedSeats: j['includedSeats'] as int? ?? 0,
        retentionDays: j['retentionDays'] as int? ?? 90,
      );
}

/// `GET /me` → company summary for the menu (plan, seats) and the header (who's signed in).
class MeInfo {
  const MeInfo({
    required this.userName,
    required this.initials,
    required this.planTier,
    required this.retentionDays,
    required this.seats,
    required this.seatsUsed,
    this.permissions = const {},
    this.timezone,
  });

  final String userName, initials, planTier;

  /// Company IANA time zone, e.g. "America/New_York".
  final String? timezone;
  final int retentionDays, seats, seatsUsed;
  final Set<String> permissions;

  factory MeInfo.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? const {};
    final plan = (j['company'] as Map?)?['plan'] as Map? ?? const {};
    return MeInfo(
      userName: user['name'] as String? ?? '',
      initials: user['initials'] as String? ?? '',
      planTier: plan['tier'] as String? ?? 'free',
      retentionDays: plan['retentionDays'] as int? ?? 90,
      seats: plan['seats'] as int? ?? 0,
      seatsUsed: plan['seatsUsed'] as int? ?? 0,
      permissions: {for (final p in (j['permissions'] as List? ?? const [])) p as String},
      timezone: (j['company'] as Map?)?['timezone'] as String?,
    );
  }
}

/// `GET /me/status` — crew app home.
class MeStatus {
  const MeStatus({
    required this.state,
    this.lastPunch,
    this.todayMinutes = 0,
    this.weekMinutes = 0,
    this.briefingToSign = false,
  });

  final ClockState state;
  final Punch? lastPunch;
  final int todayMinutes, weekMinutes;
  final bool briefingToSign;

  factory MeStatus.fromJson(Map<String, dynamic> j) => MeStatus(
        state: clockStateFrom(j['state']),
        lastPunch: j['lastPunch'] == null ? null : Punch.fromJson(j['lastPunch'] as Map<String, dynamic>),
        todayMinutes: j['todayMinutes'] as int? ?? 0,
        weekMinutes: j['weekMinutes'] as int? ?? 0,
        briefingToSign: j['briefingToSign'] != null,
      );
}

/// `POST /punches/check-location`
class LocationCheck {
  const LocationCheck({required this.site, required this.distanceFt, required this.inside});
  final SiteRef? site;
  final int distanceFt;
  final bool inside;

  factory LocationCheck.fromJson(Map<String, dynamic> j) => LocationCheck(
        site: j['site'] == null ? null : SiteRef.fromJson(j['site'] as Map<String, dynamic>),
        distanceFt: j['distanceFt'] as int? ?? 0,
        inside: j['inside'] as bool? ?? false,
      );
}

/// `GET /dashboard` → `onClock[]` row. Used by the portal dashboard
/// and the crew app's supervisor "My crew" tab.
class OnClockEntry {
  const OnClockEntry({
    required this.user,
    required this.site,
    required this.since,
    required this.state,
    this.todayMinutes = 0,
    this.photo = ReviewStatus.pending,
    this.punchId,
  });

  /// The clock-in punch, so the portal can open its photo review.
  final String? punchId;
  final UserRef user;
  /// null when the punch had no job site.
  final SiteRef? site;
  final DateTime since;
  final WorkState state;
  final int todayMinutes;
  final ReviewStatus photo;

  factory OnClockEntry.fromJson(Map<String, dynamic> j) => OnClockEntry(
        user: UserRef.fromJson(j['user'] as Map<String, dynamic>),
        site: j['site'] == null ? null : SiteRef.fromJson(j['site'] as Map<String, dynamic>),
        since: DateTime.parse(j['since'] as String).toLocal(),
        state: _enum(WorkState.values, j['state'], WorkState.working),
        todayMinutes: j['todayMinutes'] as int? ?? 0,
        photo: _enum(ReviewStatus.values, j['photo'], ReviewStatus.pending),
        punchId: j['punchId'] as String?,
      );
}

/// `GET /dashboard` → `attention[]`.
enum AttentionKind { outside, missingOut, nearOvertime, unsignedBriefing, longBreak }

class Attention {
  const Attention({required this.kind, required this.user, this.detail = ''});
  final AttentionKind kind;
  final UserRef user;
  final String detail;

  factory Attention.fromJson(Map<String, dynamic> j) => Attention(
        kind: _enum(AttentionKind.values, j['kind'], AttentionKind.outside),
        user: UserRef.fromJson(j['user'] as Map<String, dynamic>? ?? const {}),
        detail: j['detail'] as String? ?? '',
      );
}

/// `Shift` (fields the dashboard shows).
class ShiftRef {
  const ShiftRef({required this.id, required this.start, required this.end, this.user, this.site});
  final String id;

  /// Local "HH:mm".
  final String start, end;
  final UserRef? user;
  final SiteRef? site;

  factory ShiftRef.fromJson(Map<String, dynamic> j) => ShiftRef(
        id: j['id'] as String? ?? '',
        start: j['start'] as String? ?? '',
        end: j['end'] as String? ?? '',
        user: j['user'] == null ? null : UserRef.fromJson(j['user'] as Map<String, dynamic>),
        site: j['site'] == null ? null : SiteRef.fromJson(j['site'] as Map<String, dynamic>),
      );
}

/// `GET /dashboard`
class Dashboard {
  const Dashboard({
    required this.onClockCount,
    required this.scheduled,
    required this.onBreak,
    required this.late,
    required this.toReview,
    required this.onClock,
    this.attention = const [],
    this.startingSoon = const [],
  });

  final int onClockCount, scheduled, onBreak, late, toReview;
  final List<OnClockEntry> onClock;
  final List<Attention> attention;
  final List<ShiftRef> startingSoon;

  factory Dashboard.fromJson(Map<String, dynamic> j) {
    final c = j['counts'] as Map<String, dynamic>? ?? const {};
    return Dashboard(
      onClockCount: c['onClock'] as int? ?? 0,
      scheduled: c['scheduled'] as int? ?? 0,
      onBreak: c['onBreak'] as int? ?? 0,
      late: c['late'] as int? ?? 0,
      toReview: c['toReview'] as int? ?? 0,
      onClock: [
        for (final e in (j['onClock'] as List? ?? const [])) OnClockEntry.fromJson(e as Map<String, dynamic>),
      ],
      attention: [for (final a in (j['attention'] as List? ?? const [])) Attention.fromJson(a as Map<String, dynamic>)],
      startingSoon: [for (final s in (j['startingSoon'] as List? ?? const [])) ShiftRef.fromJson(s as Map<String, dynamic>)],
    );
  }
}
