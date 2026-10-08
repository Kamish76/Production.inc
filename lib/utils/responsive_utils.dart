import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Central responsive utilities providing content-driven layout calculations,
/// breakpoint detection, and safe padding across diverse mobile and tablet screen dimensions.
class ResponsiveUtils {
  /// Minimum recommended width for an ItemCard to prevent button & text overflows.
  static const double minItemCardWidth = 160.0;

  /// Standard column gap used in grid layouts.
  static const double defaultGridSpacing = 8.0;

  /// Breakpoints
  static const double phoneMaxBreakpoint = 580.0;
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;

  /// Dynamically calculates the number of grid columns that can comfortably fit
  /// within [availableWidth] given a minimum item width and spacing.
  static int getGridColumnCount(
    double availableWidth, {
    double minWidth = minItemCardWidth,
    double spacing = defaultGridSpacing,
  }) {
    if (availableWidth <= 0) return 1;

    // availableWidth >= count * minWidth + (count - 1) * spacing
    // count * (minWidth + spacing) <= availableWidth + spacing
    final int count = ((availableWidth + spacing) / (minWidth + spacing)).floor();
    return math.max(1, count);
  }

  /// Whether current viewport is a compact phone (< 600 dp).
  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < tabletBreakpoint;

  /// Whether current viewport is a tablet / foldable (600 dp - 1023 dp).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Whether current viewport is a desktop / wide display (>= 1024 dp).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Provides responsive outer screen padding.
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  /// Provides responsive header padding.
  static EdgeInsets getHeaderPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    } else {
      return const EdgeInsets.all(20);
    }
  }
}
