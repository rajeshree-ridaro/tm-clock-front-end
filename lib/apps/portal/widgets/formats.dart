import 'package:flutter/material.dart';

import 'package:tm_clock/apps/portal/state/portal_store.dart';
import 'package:tm_clock/apps/portal/widgets/company_time.dart';
import 'package:tm_clock/core/l10n/strings.dart';

/// Display formats shared by portal pages (prototype `fmt*` helpers), in EN or ES.
abstract final class Fmt {
  static const _daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _daysEs = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _monEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  /// An instant → wall-clock time at the company (the browser's zone when unknown).
  static DateTime wall(BuildContext context, DateTime at) => CompanyTime.wall(at, PortalScope.maybeRead(context)?.location);

  /// Now, on the company's clock.
  static DateTime now(BuildContext context) => wall(context, DateTime.now());

  /// A day + time on the company's clock → the instant to send to the API.
  static DateTime instant(BuildContext context, DateTime day, TimeOfDay time) =>
      CompanyTime.instant(day.year, day.month, day.day, time.hour, time.minute, PortalScope.maybeRead(context)?.location);

  /// "7:02 AM" on the company's clock.
  static String clock(BuildContext context, DateTime at) =>
      MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(wall(context, at)));

  /// "13:00" (shift time) → "1:00 PM"
  static String hhmm(BuildContext context, String value) {
    final parts = value.split(':');
    if (parts.length != 2) return value;
    return MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0));
  }

  /// 312 → "5h 12m"
  static String minutes(int m) => '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';

  /// 40 → "40 ft", 11088 → "2.1 mi"
  static String distance(int? ft) => ft == null ? '' : ft < 1000 ? '$ft ft' : '${(ft / 5280).toStringAsFixed(1)} mi';

  /// Header date: "Sunday, Nov 22" / "Domingo, 22 nov"
  static String dayHeader(BuildContext context, DateTime d) => context.isSpanish
      ? '${_daysEs[d.weekday - 1]}, ${d.day} ${_monEs[d.month - 1]}'
      : '${_daysEn[d.weekday - 1]}, ${_monEn[d.month - 1]} ${d.day}';

  /// "Aug 25, 2026" / "25 ago 2026"
  static String date(BuildContext context, DateTime d) => context.isSpanish
      ? '${d.day} ${_monEs[d.month - 1]} ${d.year}'
      : '${_monEn[d.month - 1]} ${d.day}, ${d.year}';

  /// Retention: 90 → "90 days", 365 → "1 year", 1095 → "3 years"
  static String retention(BuildContext context, int days) =>
      context.t(days >= 1095 ? 'days1095' : days >= 365 ? 'days365' : 'days90');
}
