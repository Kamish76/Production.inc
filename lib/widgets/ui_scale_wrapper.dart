import 'package:flutter/material.dart';

/// Wraps the application tree to dynamically scale the UI canvas
/// according to the user's zoom preference while preserving pixel-perfect
/// touch hit-testing, device safe-areas, and keyboard view insets.
class UiScaleWrapper extends StatelessWidget {
  final double scale;
  final Widget child;

  const UiScaleWrapper({
    super.key,
    required this.scale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if ((scale - 1.0).abs() < 0.001) {
      return child;
    }

    final mediaQuery = MediaQuery.of(context);
    final originalSize = mediaQuery.size;
    final scaledWidth = originalSize.width / scale;
    final scaledHeight = originalSize.height / scale;

    return MediaQuery(
      data: mediaQuery.copyWith(
        size: Size(scaledWidth, scaledHeight),
        padding: mediaQuery.padding / scale,
        viewInsets: mediaQuery.viewInsets / scale,
        viewPadding: mediaQuery.viewPadding / scale,
      ),
      child: SizedBox(
        width: originalSize.width,
        height: originalSize.height,
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: scaledWidth,
            height: scaledHeight,
            child: child,
          ),
        ),
      ),
    );
  }
}
