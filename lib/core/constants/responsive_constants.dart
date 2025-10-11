import 'package:flutter/widgets.dart';

class MobileBreakpoint {
  static const double start = 0;
  static const double end = 450;
}

class TabletBreakpoint {
  static const double start = 451;
  static const double end = 800;
}

class DesktopBreakpoint {
  static const double start = 801;
  static const double end = 1920;
}

const EdgeInsets screenPadding = EdgeInsets.symmetric(
  horizontal: 8.0,
  vertical: 8.0,
);

// border radius for cards and containers
const BorderRadius allBorderRadius = BorderRadius.all(Radius.circular(16.0));
