import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Custom ScrollBehavior to enable better scrolling experience on Web/Desktop.
///
/// Changes:
/// 1. Enables drag scrolling with mouse (optional, good for carousels).
/// 2. Ensures scrollbars are visible on desktop platforms.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
