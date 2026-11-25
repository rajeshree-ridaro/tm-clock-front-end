import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type from the prototype: Inter for body/UI, IBM Plex Sans for headings
/// and big numbers, IBM Plex Mono for uppercase labels and table headers.
abstract final class TmType {
  /// [large] = crew app: bigger body and headings for field use (mobile prototype: 16px body, 34px h1).
  static TextTheme textTheme(Color ink, Color mute, {bool large = false}) {
    final up = large ? 1.0 : 0.0;
    const body = TextTheme();
    TextStyle plex(double size, {double height = 1.1}) => GoogleFonts.ibmPlexSans(
          fontSize: size,
          fontWeight: FontWeight.w600,
          height: height,
          color: ink,
        );
    return body
        .copyWith(
          // h1: clamp(24px, 3vw, 30px)
          displaySmall: plex(36),
          headlineLarge: plex(large ? 34 : 30, height: 1.08),
          headlineMedium: plex(24),
          headlineSmall: plex(20, height: 1.2),
          // h2: 18px
          titleLarge: plex(18 + up, height: 1.3),
          titleMedium: GoogleFonts.inter(fontSize: 15 + up, fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5),
          bodyMedium: GoogleFonts.inter(fontSize: 15 + up, height: 1.45),
          bodySmall: GoogleFonts.inter(fontSize: 13, height: 1.4, color: mute),
          labelLarge: GoogleFonts.inter(fontSize: 15 + up, fontWeight: FontWeight.w600),
          labelMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          labelSmall: label(mute),
        )
        .apply(bodyColor: ink, displayColor: ink);
  }

  /// `.lbl` — mono, 11px, uppercase, 0.6 letter spacing.
  static TextStyle label(Color color) => GoogleFonts.ibmPlexMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: color,
      );

  /// `.stat .v` — big stat number.
  static TextStyle statValue(Color color) => GoogleFonts.ibmPlexSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: color,
      );

  /// `.mono`
  static TextStyle mono(Color color, {double size = 14}) =>
      GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: FontWeight.w500, color: color);
}
