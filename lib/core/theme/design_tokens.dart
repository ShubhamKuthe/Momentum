import 'package:flutter/material.dart';

class AppSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 32;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: x5);
  static const EdgeInsets cardPadding = EdgeInsets.all(x5);
  static const EdgeInsets compactCardPadding = EdgeInsets.all(x4);
}

class AppRadii {
  static const double card = 22;
  static const double modal = 24;
  static const double control = 14;
  static const double field = 14;
  static const double chip = 10;
  static const double badge = 12;
  static const double tile = 18;
  static const double pill = 999;
}

class AppHeights {
  static const double minimumTap = 44;
  static const double button = 50;
  static const double field = 50;
  static const double row = 72;
  static const double compactRow = 64;
  static const double toggleWidth = 51;
  static const double toggleHeight = 31;
}

class AppDurations {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration card = Duration(milliseconds: 200);
  static const Duration stateChange = Duration(milliseconds: 280);
  static const Duration progress = Duration(milliseconds: 480);
  static const Duration page = Duration(milliseconds: 280);
}

class AppEasing {
  static const Curve standard = Curves.easeOutCubic;
}

class AppElevations {
  static List<BoxShadow> card(Color shadowColor, {required bool isDark}) {
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: isDark ? 0.22 : 0.055),
        blurRadius: isDark ? 24 : 26,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static List<BoxShadow> modal(Color shadowColor, {required bool isDark}) {
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: isDark ? 0.3 : 0.08),
        blurRadius: isDark ? 32 : 36,
        offset: const Offset(0, 16),
      ),
    ];
  }

  static List<BoxShadow> floating(Color shadowColor, {required bool isDark}) {
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: isDark ? 0.34 : 0.1),
        blurRadius: isDark ? 26 : 28,
        offset: const Offset(0, 12),
      ),
    ];
  }
}
