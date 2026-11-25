import 'package:flutter/material.dart';

import 'package:tm_clock/core/theme/tm_colors.dart';
import 'package:tm_clock/core/theme/tm_typography.dart';

/// Which app is running. Both share one theme; the crew app is a little
/// larger and brighter for gloves and sunlight.
enum TmFlavor { portal, crew }

/// Builds Material [ThemeData] for TM Clock from the prototype tokens.
abstract final class TmTheme {
  static const radiusSm = 10.0; // buttons, inputs, menu items
  static const radiusMd = 14.0; // stat tiles
  static const radiusLg = 16.0; // cards, modals
  static const minTap = 44.0; // every control is at least 44px tall

  static ThemeData dark(TmFlavor f) =>
      _build(f == TmFlavor.crew ? TmColors.darkCrew : TmColors.dark, Brightness.dark, f);
  static ThemeData light(TmFlavor f) => _build(TmColors.light, Brightness.light, f);

  static ThemeData _build(TmColors c, Brightness b, TmFlavor f) {
    final crew = f == TmFlavor.crew;
    final scheme = ColorScheme(
      brightness: b,
      primary: c.g,
      onPrimary: c.gInk,
      primaryContainer: c.brandBg,
      onPrimaryContainer: c.g2,
      secondary: c.accent,
      onSecondary: Colors.white,
      secondaryContainer: c.accentBg,
      onSecondaryContainer: c.accent2,
      tertiary: c.amber,
      onTertiary: const Color(0xFF241A05),
      error: c.red,
      onError: c.bg,
      errorContainer: c.noBg,
      onErrorContainer: c.red,
      surface: c.panel,
      onSurface: c.ink,
      onSurfaceVariant: c.mute,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.panel,
      surfaceContainer: c.panel,
      surfaceContainerHigh: c.raise,
      surfaceContainerHighest: c.raise,
      outline: c.line2,
      outlineVariant: c.line,
      scrim: c.scrim,
      shadow: Colors.black,
      inverseSurface: c.ink,
      onInverseSurface: c.bg,
      inversePrimary: c.g2,
    );

    final text = TmType.textTheme(c.ink, c.mute, large: crew);
    final btnShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm));
    const btnPadding = EdgeInsets.symmetric(horizontal: 16);
    const btnSize = Size(0, minTap);
    OutlineInputBorder border(Color color, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: color, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      extensions: [c],
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.line,
      hoverColor: c.hover,
      focusColor: c.g2.withValues(alpha: 0.2),
      splashFactory: InkSparkle.splashFactory,
      textTheme: text,
      iconTheme: IconThemeData(color: c.soft, size: 20),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),

      // .btn.pri
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.g,
          foregroundColor: c.gInk,
          minimumSize: btnSize,
          padding: btnPadding,
          shape: btnShape,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      // .btn
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.panel,
          foregroundColor: c.ink,
          side: BorderSide(color: c.line2),
          minimumSize: btnSize,
          padding: btnPadding,
          shape: btnShape,
          textStyle: text.labelLarge,
        ),
      ),
      // .btn.ghost
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.g2,
          minimumSize: btnSize,
          padding: btnPadding,
          shape: btnShape,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.soft,
          minimumSize: const Size(minTap, minTap),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // .card
      cardTheme: CardThemeData(
        color: c.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(crew ? 18 : radiusLg),
          side: BorderSide(color: c.line),
        ),
      ),

      // crew app bottom tabs (`.tabs button` / `.on`)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.panel,
        indicatorColor: c.raise,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected) ? c.g2 : c.mute,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: 24, color: s.contains(WidgetState.selected) ? c.g2 : c.mute),
        ),
      ),

      // .field input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.panel,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: text.bodyLarge?.copyWith(color: c.dim),
        labelStyle: text.titleSmall?.copyWith(color: c.ink),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: border(c.line2),
        enabledBorder: border(c.line2),
        focusedBorder: border(c.g2, 2),
        errorBorder: border(c.red),
        focusedErrorBorder: border(c.red, 2),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.raise,
        side: BorderSide(color: c.line),
        labelStyle: text.labelMedium,
        shape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.g : c.line2,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.g : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(c.gInk),
        side: BorderSide(color: c.line2, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.ink,
        unselectedLabelColor: c.soft,
        indicatorColor: c.g,
        dividerColor: c.line,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: c.line),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.panel,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
      // .toast
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.raise,
        contentTextStyle: text.titleSmall?.copyWith(color: c.ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.line2),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.raise,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.line2),
        ),
        textStyle: text.bodySmall?.copyWith(color: c.ink),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.g,
        linearTrackColor: c.line,
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TmType.label(c.mute),
        dataTextStyle: text.bodyMedium,
        dividerThickness: 1,
        headingRowHeight: 40,
      ),
    );
  }
}
