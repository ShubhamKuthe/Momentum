import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/responsive.dart';

class MomentumBottomNav extends StatelessWidget {
  const MomentumBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onAddTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Future<void> Function() onAddTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final screenWidth = responsive.width;
    final compact = responsive.isSmallPhone;
    final horizontalMargin =
        responsive.value(compact ? 14 : 18, min: 12, max: 20);
    final barWidth = math
        .max(
          responsive.value(compact ? 320 : 336, min: 300, max: 356),
          screenWidth - (horizontalMargin * 2),
        )
        .clamp(
          responsive.value(compact ? 300 : 312, min: 288, max: 324),
          screenWidth - (horizontalMargin * 2),
        )
        .toDouble();
    final barHeight = responsive.value(compact ? 66 : 68, min: 62, max: 70);
    final fabSize = responsive.value(compact ? 50 : 52, min: 48, max: 54);
    final totalHeight = barHeight + responsive.value(14, min: 12, max: 16);
    final shellColor = context.isMomentumDark
        ? const Color(0xFF1E2230)
        : const Color(0xFFEEE7DB);

    return Padding(
      padding: EdgeInsets.only(
        bottom: responsive.bottomSafeGap,
      ),
      child: SizedBox(
        width: barWidth,
        height: totalHeight,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = math.min(
                    responsive.value(16, min: 12, max: 18),
                    constraints.maxWidth * 0.065,
                  );
                  final centerGap = math.min(
                    fabSize + responsive.value(14, min: 8, max: 16),
                    constraints.maxWidth * 0.32,
                  );
                  final slotWidth = (constraints.maxWidth -
                          (horizontalPadding * 2) -
                          centerGap) /
                      4;
                  final iconExtent = math.max(
                    28.0,
                    math.min(
                      slotWidth - 2,
                      responsive.value(compact ? 42 : 46, min: 38, max: 48),
                    ),
                  );

                  return Container(
                    height: barHeight,
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    decoration: BoxDecoration(
                      color: shellColor,
                      borderRadius: BorderRadius.circular(
                        responsive.radius(AppRadii.card),
                      ),
                      border: Border.all(
                        color: context.isMomentumDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFD8CCBA),
                      ),
                      boxShadow: AppElevations.floating(
                        context.momentum.shadow,
                        isDark: context.isMomentumDark,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: _MomentumNavIcon(
                              icon: Icons.home_rounded,
                              active: selectedIndex == 0,
                              onTap: () => onItemSelected(0),
                              extent: iconExtent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _MomentumNavIcon(
                              icon: Icons.bolt_rounded,
                              active: selectedIndex == 1,
                              onTap: () => onItemSelected(1),
                              extent: iconExtent,
                            ),
                          ),
                        ),
                        SizedBox(width: centerGap),
                        Expanded(
                          child: Center(
                            child: _MomentumNavIcon(
                              icon: Icons.lightbulb_outline_rounded,
                              active: selectedIndex == 3,
                              onTap: () => onItemSelected(3),
                              extent: iconExtent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _MomentumNavIcon(
                              icon: Icons.insert_chart_outlined_rounded,
                              active: selectedIndex == 4,
                              onTap: () => onItemSelected(4),
                              extent: iconExtent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: onAddTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: fabSize,
                  height: fabSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6680),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentumNavIcon extends StatelessWidget {
  const _MomentumNavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.extent,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final compact = responsive.isSmallPhone;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        child: AnimatedContainer(
          duration: AppDurations.press,
          curve: AppEasing.standard,
          width: extent,
          height: extent,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius:
                BorderRadius.circular(responsive.radius(AppRadii.chip)),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: context.isMomentumDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0x1A20242E),
                      blurRadius: responsive.value(10, min: 8, max: 12),
                      offset: Offset(0, responsive.value(3, min: 2, max: 4)),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: math.min(
                extent * 0.48,
                responsive.value(compact ? 20 : 22, min: 18, max: 23),
              ),
              color: active
                  ? const Color(0xFF1C1E2D)
                  : context.isMomentumDark
                      ? Colors.white.withValues(alpha: 0.72)
                      : const Color(0xFF6D7380),
            ),
          ),
        ),
      ),
    );
  }
}
