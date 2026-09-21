import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/typography.dart';

class StepHabitCard extends StatelessWidget {
  const StepHabitCard({
    super.key,
    required this.title,
    required this.currentSteps,
    required this.targetSteps,
    required this.status,
    required this.onTap,
    this.onManualLog,
    this.accentColor = AppColors.ember,
  });

  final String title;
  final int currentSteps;
  final int targetSteps;
  final String status;
  final VoidCallback onTap;
  final VoidCallback? onManualLog;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final compact = MediaQuery.of(context).size.width < 390;
    final progress = targetSteps <= 0
        ? 0.0
        : (currentSteps / targetSteps).clamp(0.0, 1.0);
    final formattedTarget = NumberFormat.decimalPattern().format(targetSteps);
    final cardColor = context.isMomentumDark ? palette.surfaceStrong : palette.surface;
    final iconSurface = context.isMomentumDark
        ? accentColor.withValues(alpha: 0.18)
        : accentColor.withValues(alpha: 0.12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: compact ? 192 : 198,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: context.isMomentumDark ? 0.08 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 18,
              compact ? 14 : 16,
              compact ? 16 : 18,
              compact ? 12 : 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconSurface,
                              borderRadius: BorderRadius.circular(AppRadii.badge),
                            ),
                            child: Icon(
                              Icons.directions_walk_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: compact ? 17.5 : 18.5,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _AnimatedStepCount(
                            value: currentSteps,
                            style: MomentumTypography.numbers(
                              TextStyle(
                                color: palette.text,
                                fontSize: compact ? 30 : 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'of $formattedTarget steps',
                            style: TextStyle(
                              color: palette.textSoft,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _StepProgressRing(
                      progress: progress,
                      accentColor: accentColor,
                      size: compact ? 72 : 80,
                      trackColor: context.isMomentumDark
                          ? palette.surfaceMuted
                          : palette.ringTrack,
                      textColor: palette.text,
                      innerColor: cardColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: context.isMomentumDark
                              ? palette.surfaceMuted.withValues(alpha: 0.72)
                              : palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadii.control),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync_rounded,
                              color: palette.textSoft,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.textSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onManualLog != null) ...[
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 64),
                        child: SizedBox(
                          height: 34,
                          child: TextButton(
                            onPressed: onManualLog,
                            style: TextButton.styleFrom(
                              foregroundColor: accentColor,
                              backgroundColor: context.isMomentumDark
                                  ? accentColor.withValues(alpha: 0.12)
                                  : accentColor.withValues(alpha: 0.1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              minimumSize: const Size(64, 34),
                              tapTargetSize: MaterialTapTargetSize.padded,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.control),
                              ),
                            ),
                            child: const Text(
                              'Log',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStepCount extends StatelessWidget {
  const _AnimatedStepCount({
    required this.value,
    required this.style,
  });

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          formatter.format(animatedValue.round()),
          style: style,
        );
      },
    );
  }
}

class _StepProgressRing extends StatelessWidget {
  const _StepProgressRing({
    required this.progress,
    required this.accentColor,
    required this.size,
    required this.trackColor,
    required this.textColor,
    required this.innerColor,
  });

  final double progress;
  final Color accentColor;
  final double size;
  final Color trackColor;
  final Color textColor;
  final Color innerColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _StepRingPainter(
                  progress: animatedValue,
                  accentColor: accentColor,
                  trackColor: trackColor,
                ),
              ),
              Container(
                width: size * 0.64,
                height: size * 0.64,
                decoration: BoxDecoration(
                  color: innerColor,
                  shape: BoxShape.circle,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(animatedValue * 100).round()}%',
                    style: MomentumTypography.numbers(
                      TextStyle(
                        color: textColor,
                        fontSize: size < 82 ? 17 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'goal',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.55),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepRingPainter extends CustomPainter {
  const _StepRingPainter({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
  });

  final double progress;
  final Color accentColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          accentColor.withValues(alpha: 0.65),
          accentColor,
          const Color(0xFFFF8C72),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StepRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.trackColor != trackColor;
  }
}
