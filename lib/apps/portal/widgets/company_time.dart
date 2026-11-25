import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The company's time zone (IANA name from `GET /me`, e.g. "America/New_York").
/// The portal shows punch times on the company's clock, not the browser's — an office
/// admin in another zone must see the same 7:00 AM the crew punched.
abstract final class CompanyTime {
  static bool _loaded = false;

  static tz.Location? location(String? name) {
    if (name == null || name.isEmpty) return null;
    if (!_loaded) {
      tzdata.initializeTimeZones();
      _loaded = true;
    }
    try {
      return tz.getLocation(name);
    } on Exception {
      return null;
    }
  }

  /// An instant → the wall-clock time at the company.
  static DateTime wall(DateTime instant, tz.Location? loc) {
    if (loc == null) return instant.toLocal();
    final t = tz.TZDateTime.from(instant, loc);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  /// A wall-clock time at the company → the instant (send `.toUtc()` to the API).
  static DateTime instant(int year, int month, int day, int hour, int minute, tz.Location? loc) =>
      loc == null ? DateTime(year, month, day, hour, minute) : tz.TZDateTime(loc, year, month, day, hour, minute);
}
