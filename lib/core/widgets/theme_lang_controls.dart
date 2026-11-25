import 'package:flutter/material.dart';

import 'package:tm_clock/core/settings/app_settings.dart';
import 'package:tm_clock/core/l10n/strings.dart';
import 'package:tm_clock/core/theme/tm_colors.dart';

/// `.thm` — 44px square light/dark toggle.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final c = context.tm;
    return Tooltip(
      message: context.t('themeToggle'),
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: settings.toggleTheme,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              settings.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: c.soft,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.lang` — EN / ES segmented pill.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final c = context.tm;
    Widget seg(String code) {
      final on = settings.locale.languageCode == code;
      return Material(
        color: on ? c.g : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => settings.setLocale(Locale(code)),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              code.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? c.gInk : c.soft,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('en'), seg('es')]),
    );
  }
}
