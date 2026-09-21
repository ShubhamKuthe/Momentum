import 'package:flutter/material.dart';

class MomentumTypography {
  static TextTheme build(
    TextTheme base, {
    required Color textColor,
    required Color mutedColor,
    required Color captionColor,
  }) {
    return base.copyWith(
      displayLarge: _style(
        base.displayLarge,
        color: textColor,
        size: 34,
        height: 40 / 34,
        weight: FontWeight.w700,
        spacing: -0.45,
      ),
      displayMedium: _style(
        base.displayMedium,
        color: textColor,
        size: 30,
        height: 36 / 30,
        weight: FontWeight.w700,
        spacing: -0.4,
      ),
      headlineMedium: _style(
        base.headlineMedium,
        color: textColor,
        size: 20,
        height: 24 / 20,
        weight: FontWeight.w600,
        spacing: -0.2,
      ),
      titleLarge: _style(
        base.titleLarge,
        color: textColor,
        size: 20,
        height: 24 / 20,
        weight: FontWeight.w600,
        spacing: -0.18,
      ),
      titleMedium: _style(
        base.titleMedium,
        color: textColor,
        size: 17,
        height: 22 / 17,
        weight: FontWeight.w600,
        spacing: -0.05,
      ),
      titleSmall: _style(
        base.titleSmall,
        color: textColor,
        size: 16,
        height: 21 / 16,
        weight: FontWeight.w600,
        spacing: -0.04,
      ),
      bodyLarge: _style(
        base.bodyLarge,
        color: textColor,
        size: 16,
        height: 22 / 16,
        weight: FontWeight.w400,
      ),
      bodyMedium: _style(
        base.bodyMedium,
        color: mutedColor,
        size: 15,
        height: 21 / 15,
        weight: FontWeight.w400,
      ),
      bodySmall: _style(
        base.bodySmall,
        color: mutedColor,
        size: 13,
        height: 18 / 13,
        weight: FontWeight.w500,
        spacing: 0.1,
      ),
      labelLarge: _style(
        base.labelLarge,
        color: textColor,
        size: 16,
        height: 20 / 16,
        weight: FontWeight.w600,
        spacing: -0.04,
      ),
      labelMedium: _style(
        base.labelMedium,
        color: captionColor,
        size: 12,
        height: 16 / 12,
        weight: FontWeight.w500,
        spacing: 0.5,
      ),
      labelSmall: _style(
        base.labelSmall,
        color: captionColor,
        size: 12,
        height: 16 / 12,
        weight: FontWeight.w500,
        spacing: 0.5,
      ),
    );
  }

  static TextStyle numbers(TextStyle style) {
    return style.copyWith(
      fontWeight: style.fontWeight == null || style.fontWeight!.value < FontWeight.w600.value
          ? FontWeight.w600
          : style.fontWeight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle _style(
    TextStyle? base, {
    required Color color,
    required double size,
    required double height,
    required FontWeight weight,
    double spacing = 0,
  }) {
    return (base ?? const TextStyle()).copyWith(
      color: color,
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: spacing,
    );
  }
}
