import 'package:flutter/material.dart';

/// Design tokens from the TM Clock web prototype (`:root` / `[data-theme=light]`).
///
/// Access in widgets with `context.tm` (see [TmColorsX]).
@immutable
class TmColors extends ThemeExtension<TmColors> {
  const TmColors({
    required this.bg,
    required this.panel,
    required this.raise,
    required this.line,
    required this.line2,
    required this.ink,
    required this.soft,
    required this.mute,
    required this.dim,
    required this.strong,
    required this.hover,
    required this.amber,
    required this.red,
    required this.blue,
    required this.ok,
    required this.okBg,
    required this.waitBg,
    required this.noBg,
    required this.noBorder,
    required this.breakBg,
    required this.photo,
    required this.face,
    required this.faceFg,
    required this.scrim,
    required this.stage,
    required this.frame,
    required this.map,
    required this.street,
    required this.block,
    required this.fence,
    required this.g,
    required this.g2,
    required this.gInk,
    required this.brandBg,
    required this.accent,
    required this.accent2,
    required this.accentBg,
    required this.markAccent,
    required this.logoRing,
    required this.logoCrown,
    required this.wordmarkTm,
    required this.wordmarkClock,
  });

  /// Surfaces
  final Color bg, panel, raise, line, line2, hover, stage, frame;

  /// Text
  final Color ink, soft, mute, dim, strong;

  /// Status (foreground / background pairs)
  final Color amber, red, blue, ok, okBg, waitBg, noBg, noBorder, breakBg;

  /// Photo + avatar placeholders, overlay scrim
  final Color photo, face, faceFg, scrim;

  /// Map (job sites)
  final Color map, street, block, fence;

  /// Brand: TM Clock teal (`g`), link/focus teal (`g2`), ink on teal (`gInk`)
  final Color g, g2, gInk, brandBg;

  /// TM family purple accent
  final Color accent, accent2, accentBg, markAccent;

  /// Logo + wordmark
  final Color logoRing, logoCrown, wordmarkTm, wordmarkClock;

  static const dark = TmColors(
    bg: Color(0xFF16141F),
    panel: Color(0xFF1E1B2E),
    raise: Color(0xFF252235),
    line: Color(0xFF2C2842),
    line2: Color(0xFF3A3456),
    ink: Color(0xFFE2DFF0),
    soft: Color(0xFFC9C4DE),
    mute: Color(0xFFA49FC0),
    dim: Color(0xFF6F6A8A),
    strong: Color(0xFFFFFFFF),
    hover: Color(0xFF221F33),
    amber: Color(0xFFF5B942),
    red: Color(0xFFF28B96),
    blue: Color(0xFF7FB2F0),
    ok: Color(0xFF5FD384),
    okBg: Color(0xFF163A22),
    waitBg: Color(0xFF3B2F12),
    noBg: Color(0xFF3D1C22),
    noBorder: Color(0xFF5A2A33),
    breakBg: Color(0xFF1D2D45),
    photo: Color(0xFF2F2A45),
    face: Color(0xFF3F3860),
    faceFg: Color(0xFFD8D3EE),
    scrim: Color(0xD60B0A12),
    stage: Color(0xFF0F0E16),
    frame: Color(0xFF2A2738),
    map: Color(0xFF1B1929),
    street: Color(0xFF2A2740),
    block: Color(0xFF232036),
    fence: Color(0x1421BA45),
    g: Color(0xFF2DD4BF),
    g2: Color(0xFF2DD4BF),
    gInk: Color(0xFF062B27),
    brandBg: Color(0xFF123532),
    accent: Color(0xFF7C3AED),
    accent2: Color(0xFFC4B5FD),
    accentBg: Color(0xFF2E2350),
    markAccent: Color(0xFFA78BFA),
    logoRing: Color(0xFFF8D004),
    logoCrown: Color(0xFFA78BFA),
    wordmarkTm: Color(0xFF60A5FA),
    wordmarkClock: Color(0xFF4ADE80),
  );

  static const light = TmColors(
    bg: Color(0xFFF4F3FA),
    panel: Color(0xFFFFFFFF),
    raise: Color(0xFFEEECF6),
    line: Color(0xFFE2DFEE),
    line2: Color(0xFFCBC6E0),
    ink: Color(0xFF1F1B33),
    soft: Color(0xFF46415C),
    mute: Color(0xFF625C7D),
    dim: Color(0xFF9A95B0),
    strong: Color(0xFF1F1B33),
    hover: Color(0xFFF2F0F8),
    amber: Color(0xFF8A5A00),
    red: Color(0xFFB4232F),
    blue: Color(0xFF1F5FAE),
    ok: Color(0xFF137A32),
    okBg: Color(0xFFDCF2E2),
    waitBg: Color(0xFFFBEFD2),
    noBg: Color(0xFFFBE1E4),
    noBorder: Color(0xFFE8B4BA),
    breakBg: Color(0xFFE1ECFA),
    photo: Color(0xFFE6E3F1),
    face: Color(0xFFCFC9E6),
    faceFg: Color(0xFF2B2546),
    scrim: Color(0x991F1B33),
    stage: Color(0xFFE9E7F2),
    frame: Color(0xFFCFCAE0),
    map: Color(0xFFEEF0E8),
    street: Color(0xFFFFFFFF),
    block: Color(0xFFDEDBE9),
    fence: Color(0x2221BA45),
    g: Color(0xFF14B8A6),
    g2: Color(0xFF0F766E),
    gInk: Color(0xFF04201D),
    brandBg: Color(0xFFCCFBF1),
    accent: Color(0xFF7C3AED),
    accent2: Color(0xFF5B21B6),
    accentBg: Color(0xFFEDE9FE),
    markAccent: Color(0xFF7C3AED),
    logoRing: Color(0xFF2563EB),
    logoCrown: Color(0xFFDC2626),
    wordmarkTm: Color(0xFF7C3AED),
    wordmarkClock: Color(0xFF16A34A),
  );

  /// Crew app (dark): brighter text for bright sunlight — mobile prototype `--ink` / `--soft`.
  static final darkCrew = dark.copyWith(ink: const Color(0xFFEFEDF7), soft: const Color(0xFFCFCAE3));

  @override
  TmColors copyWith({Color? ink, Color? soft}) => TmColors(
        bg: bg,
        panel: panel,
        raise: raise,
        line: line,
        line2: line2,
        ink: ink ?? this.ink,
        soft: soft ?? this.soft,
        mute: mute,
        dim: dim,
        strong: strong,
        hover: hover,
        amber: amber,
        red: red,
        blue: blue,
        ok: ok,
        okBg: okBg,
        waitBg: waitBg,
        noBg: noBg,
        noBorder: noBorder,
        breakBg: breakBg,
        photo: photo,
        face: face,
        faceFg: faceFg,
        scrim: scrim,
        stage: stage,
        frame: frame,
        map: map,
        street: street,
        block: block,
        fence: fence,
        g: g,
        g2: g2,
        gInk: gInk,
        brandBg: brandBg,
        accent: accent,
        accent2: accent2,
        accentBg: accentBg,
        markAccent: markAccent,
        logoRing: logoRing,
        logoCrown: logoCrown,
        wordmarkTm: wordmarkTm,
        wordmarkClock: wordmarkClock,
      );

  @override
  TmColors lerp(ThemeExtension<TmColors>? other, double t) {
    if (other is! TmColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return TmColors(
      bg: l(bg, other.bg),
      panel: l(panel, other.panel),
      raise: l(raise, other.raise),
      line: l(line, other.line),
      line2: l(line2, other.line2),
      ink: l(ink, other.ink),
      soft: l(soft, other.soft),
      mute: l(mute, other.mute),
      dim: l(dim, other.dim),
      strong: l(strong, other.strong),
      hover: l(hover, other.hover),
      amber: l(amber, other.amber),
      red: l(red, other.red),
      blue: l(blue, other.blue),
      ok: l(ok, other.ok),
      okBg: l(okBg, other.okBg),
      waitBg: l(waitBg, other.waitBg),
      noBg: l(noBg, other.noBg),
      noBorder: l(noBorder, other.noBorder),
      breakBg: l(breakBg, other.breakBg),
      photo: l(photo, other.photo),
      face: l(face, other.face),
      faceFg: l(faceFg, other.faceFg),
      scrim: l(scrim, other.scrim),
      stage: l(stage, other.stage),
      frame: l(frame, other.frame),
      map: l(map, other.map),
      street: l(street, other.street),
      block: l(block, other.block),
      fence: l(fence, other.fence),
      g: l(g, other.g),
      g2: l(g2, other.g2),
      gInk: l(gInk, other.gInk),
      brandBg: l(brandBg, other.brandBg),
      accent: l(accent, other.accent),
      accent2: l(accent2, other.accent2),
      accentBg: l(accentBg, other.accentBg),
      markAccent: l(markAccent, other.markAccent),
      logoRing: l(logoRing, other.logoRing),
      logoCrown: l(logoCrown, other.logoCrown),
      wordmarkTm: l(wordmarkTm, other.wordmarkTm),
      wordmarkClock: l(wordmarkClock, other.wordmarkClock),
    );
  }
}

extension TmColorsX on BuildContext {
  TmColors get tm => Theme.of(this).extension<TmColors>()!;
}
