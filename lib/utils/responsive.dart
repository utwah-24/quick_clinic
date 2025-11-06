import 'package:flutter/widgets.dart';

/// Phone-first responsive helpers.
///
/// This utility intentionally targets phones only (no tablet/desktop layouts).
class Responsive {
  /// Whether the current layout should be treated as a phone.
  /// We force phone layout everywhere as per requirements.
  static bool isPhone(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return size.shortestSide < 600 || true;
  }

  /// Base width used for scaling. iPhone 11/12/13 (~375 logical px) is a sane default.
  static const double _defaultBaseWidth = 375.0;

  /// Returns a bounded scale factor based on screen width.
  ///
  /// Keeps UI readable on very small and very large phones by clamping.
  static double scale(
    BuildContext context, {
    double baseWidth = _defaultBaseWidth,
    double minScale = 0.85,
    double maxScale = 1.20,
  }) {
    final double width = MediaQuery.of(context).size.width;
    final double factor = width / baseWidth;
    return factor.clamp(minScale, maxScale);
  }

  /// Scale a numeric dimension (padding, size, etc.) by width.
  static double wp(BuildContext context, double value) {
    return value * scale(context);
  }

  /// Scale font size with width-based scale factor.
  static double sp(BuildContext context, double fontSize) {
    return fontSize * scale(context);
  }

  /// Determine a reasonable phone grid column count.
  /// 2 columns on typical phones, 3 on wider phones (e.g., >= 430 logical px).
  static int phoneGridColumns(BuildContext context, {int min = 2, int max = 3}) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= 430) return max;
    return min;
  }
}


