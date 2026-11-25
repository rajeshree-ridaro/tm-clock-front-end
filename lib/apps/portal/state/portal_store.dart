import 'package:flutter/widgets.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:tm_clock/apps/portal/widgets/company_time.dart';

import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/data/models/models.dart';

/// What every portal page and the menu share for the selected company: who's signed in,
/// plan and seats (menu plan card, banner), the price list, and the photos-to-review
/// count (menu badge). Reloads by itself when the company changes.
class PortalStore extends ChangeNotifier {
  PortalStore(this._services) {
    _services.session.addListener(_onSession);
    _onSession();
  }

  final AppServices _services;
  String? _companyId;

  MeInfo? me;
  List<Plan> plans = const [];

  /// The company's time zone (null → the browser's).
  tz.Location? location;
  int pending = 0;

  /// The data-limit banner's ✕ (for this browser session).
  bool bannerHidden = false;

  Plan? plan(String key) => plans.where((p) => p.key == key).firstOrNull;
  bool get isFree => (me?.planTier ?? _services.session.company?.plan ?? 'free') == 'free';

  void _onSession() {
    final id = _services.session.company?.companyId;
    if (id == _companyId) return;
    _companyId = id;
    me = null;
    location = null;
    pending = 0;
    if (id != null) reload();
  }

  Future<void> reload() async {
    final repos = _services.repos;
    try {
      final results = await Future.wait([repos.company.me(), repos.company.plans(), repos.punches.approvals()]);
      me = results[0] as MeInfo;
      location = CompanyTime.location(me!.timezone);
      plans = results[1] as List<Plan>;
      pending = (results[2] as ApprovalQueue).pending;
      notifyListeners();
    } on Exception {
      // The menu just shows less; pages report their own errors.
    }
  }

  void setPending(int n) {
    if (n == pending) return;
    pending = n;
    notifyListeners();
  }

  void hideBanner() {
    bannerHidden = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _services.session.removeListener(_onSession);
    super.dispose();
  }
}

class PortalScope extends InheritedNotifier<PortalStore> {
  const PortalScope({super.key, required PortalStore store, required super.child}) : super(notifier: store);

  /// Listens: rebuilds the caller when the store changes. Use in build().
  static PortalStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortalScope>()!.notifier!;

  /// Without listening, and null outside the portal shell (e.g. dialogs in tests).
  static PortalStore? maybeRead(BuildContext context) => context.getInheritedWidgetOfExactType<PortalScope>()?.notifier;

  /// Doesn't listen. Use in initState and event handlers.
  static PortalStore read(BuildContext context) => context.getInheritedWidgetOfExactType<PortalScope>()!.notifier!;
}

extension PortalScopeX on BuildContext {
  PortalStore get portal => PortalScope.of(this);
}

/// Dialogs open above the portal shell; this carries the store into them (company time zone, plans).
Widget withPortal(BuildContext context, Widget child) {
  final store = PortalScope.maybeRead(context);
  return store == null ? child : PortalScope(store: store, child: child);
}
