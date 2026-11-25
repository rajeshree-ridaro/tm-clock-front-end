import 'package:flutter/widgets.dart';

/// Breakpoints used by the prototype's media queries.
abstract final class Breakpoints {
  /// Below this the side menu becomes a top bar.
  static const tablet = 900.0;

  /// Below this grids collapse to one column.
  static const phone = 600.0;

  static const maxContent = 1400.0;
  static const sideNavWidth = 248.0;
}

extension BreakpointsX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isPhone => screenWidth < Breakpoints.phone;
  bool get isCompact => screenWidth < Breakpoints.tablet;
}
