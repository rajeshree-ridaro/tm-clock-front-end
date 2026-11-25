import 'package:flutter/widgets.dart';

import 'package:tm_clock/core/session/session.dart';
import 'package:tm_clock/core/theme/tm_theme.dart';
import 'package:tm_clock/data/repositories/repositories.dart';

/// Shared services for any screen in either app: `context.repos`, `context.session`.
class AppServices {
  AppServices({required this.flavor, required this.repos, required this.session});
  final TmFlavor flavor;
  final Repositories repos;
  final Session session;

  /// `client` value for `POST /auth/select-company`.
  String get client => flavor == TmFlavor.portal ? 'portal' : 'app';
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope old) => old.services != services;
}

extension AppScopeX on BuildContext {
  AppServices get services => AppScope.of(this);
  Repositories get repos => AppScope.of(this).repos;
  Session get session => AppScope.of(this).session;
}
