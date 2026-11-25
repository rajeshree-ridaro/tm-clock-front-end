import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:tm_clock/core/app/app_scope.dart';
import 'package:tm_clock/core/session/session.dart';
import 'package:tm_clock/core/settings/app_settings.dart';
import 'package:tm_clock/core/theme/tm_theme.dart';
import 'package:tm_clock/data/repositories/repositories.dart';

/// Shared root for both apps: settings, repositories, session, theme, EN/ES.
/// Each app only supplies its [flavor], [title] and router.
class TmApp extends StatefulWidget {
  const TmApp({super.key, required this.flavor, required this.title, required this.buildRouter});

  final TmFlavor flavor;
  final String title;
  final GoRouter Function(AppServices services) buildRouter;

  @override
  State<TmApp> createState() => _TmAppState();
}

class _TmAppState extends State<TmApp> {
  final _settings = AppSettings();
  late final AppServices _services;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final repos = Repositories.create(language: () => _settings.locale.languageCode);
    _services = AppServices(flavor: widget.flavor, repos: repos, session: Session(repos.auth));
    _router = widget.buildRouter(_services);
  }

  @override
  void dispose() {
    _router.dispose();
    _services.session.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: _services,
      child: AppSettingsScope(
        settings: _settings,
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => MaterialApp.router(
            title: widget.title,
            debugShowCheckedModeBanner: false,
            theme: TmTheme.light(widget.flavor),
            darkTheme: TmTheme.dark(widget.flavor),
            themeMode: _settings.themeMode,
            locale: _settings.locale,
            supportedLocales: const [Locale('en'), Locale('es')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
