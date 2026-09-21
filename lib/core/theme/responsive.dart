import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

class MomentumResponsive {
  const MomentumResponsive(this.context);

  final BuildContext context;

  static const double _baselineWidth = 390;

  Size get size => MediaQuery.sizeOf(context);
  double get width => size.width;
  double get height => size.height;
  double get safeTop => MediaQuery.paddingOf(context).top;
  double get safeBottom => MediaQuery.paddingOf(context).bottom;
  double get keyboardInset => MediaQuery.viewInsetsOf(context).bottom;

  double get scale => (width / _baselineWidth).clamp(0.85, 1.15);

  bool get isSmallPhone => width <= 360;
  bool get isStandardPhone => width > 360 && width < 430;
  bool get isLargePhone => width >= 430 && width < 600;
  bool get isFoldable => width >= 600;
  bool get isShortHeight => height < 820;
  bool get isUltraCompactHeight => height < 760;

  double value(
    double raw, {
    double? min,
    double? max,
  }) {
    final scaled = raw * scale;
    return scaled.clamp(
      min ?? (raw * 0.85),
      max ?? (raw * 1.15),
    );
  }

  double font(
    double raw, {
    double? min,
    double? max,
  }) {
    final scaled = raw * scale;
    return scaled.clamp(
      min ?? (raw * 0.92),
      max ?? (raw * 1.12),
    );
  }

  double radius(double raw) {
    return value(raw, min: raw * 0.92, max: raw * 1.08);
  }

  EdgeInsets all(double spacing) => EdgeInsets.all(value(spacing));

  EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: value(horizontal, min: horizontal == 0 ? 0 : horizontal * 0.85),
      vertical: value(vertical, min: vertical == 0 ? 0 : vertical * 0.85),
    );
  }

  EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: value(left, min: left == 0 ? 0 : left * 0.85),
      top: value(top, min: top == 0 ? 0 : top * 0.85),
      right: value(right, min: right == 0 ? 0 : right * 0.85),
      bottom: value(bottom, min: bottom == 0 ? 0 : bottom * 0.85),
    );
  }

  double get pagePadding => value(AppSpacing.x5, min: 16, max: 20);
  double get cardPadding => value(AppSpacing.x4, min: 14, max: 18);
  double get compactCardPadding => value(AppSpacing.x3, min: 12, max: 16);
  double get sectionGap => value(AppSpacing.x5, min: 16, max: 20);
  double get cardGap => value(AppSpacing.x3, min: 10, max: 14);
  double get itemGap => value(AppSpacing.x2, min: 8, max: 12);
  double get minButtonHeight => value(AppHeights.button, min: 46, max: 56);
  double get minFieldHeight => value(AppHeights.field, min: 48, max: 56);

  double get bottomSafeGap => safeBottom + value(AppSpacing.x4, min: 14, max: 20);

  double get constrainedSheetWidth => math.min(width - (pagePadding * 2), 500);

  int adaptiveColumns({
    double minTileWidth = 164,
    int maxColumns = 4,
  }) {
    final columns = (width / minTileWidth).floor();
    return columns.clamp(1, maxColumns);
  }

  SliverGridDelegateWithMaxCrossAxisExtent adaptiveGrid({
    required double maxCrossAxisExtent,
    double mainAxisSpacing = AppSpacing.x3,
    double crossAxisSpacing = AppSpacing.x3,
    double? childAspectRatio,
    double? mainAxisExtent,
  }) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: value(maxCrossAxisExtent, min: maxCrossAxisExtent * 0.92, max: maxCrossAxisExtent),
      mainAxisSpacing: value(mainAxisSpacing, min: 10, max: 18),
      crossAxisSpacing: value(crossAxisSpacing, min: 10, max: 18),
      childAspectRatio: childAspectRatio ?? 1,
      mainAxisExtent: mainAxisExtent == null
          ? null
          : value(mainAxisExtent, min: mainAxisExtent * 0.95, max: mainAxisExtent * 1.05),
    );
  }
}

extension MomentumResponsiveContext on BuildContext {
  MomentumResponsive get responsive => MomentumResponsive(this);
}

class MomentumSheetFrame extends StatelessWidget {
  const MomentumSheetFrame({
    super.key,
    required this.child,
    this.margin,
  });

  final Widget child;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SafeArea(
      top: false,
      child: Padding(
        padding: margin ??
            EdgeInsets.fromLTRB(
              responsive.pagePadding,
              responsive.value(12, min: 10, max: 18),
              responsive.pagePadding,
              responsive.bottomSafeGap,
            ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: responsive.constrainedSheetWidth,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
