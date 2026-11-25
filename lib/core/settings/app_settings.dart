import 'package:flutter/material.dart';

/// App-wide UI preferences: light/dark mode and EN/ES language.
/// The prototype defaults to dark mode and English.
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
  }
}

/// Makes [AppSettings] available below the app root.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()!.notifier!;
}
