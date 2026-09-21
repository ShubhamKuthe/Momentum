import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/typography.dart';

class HabitCard extends StatefulWidget {
  const HabitCard({
    super.key,
    required this.name,
    required this.cue,
    required this.target,
    required this.unit,
    required this.currentProgress,
    required this.streak,
    required this.isCompleted,
    required this.onQuickLog,
    required this.onTap,
    this.leadingIcon = Icons.auto_awesome_rounded,
    this.accentColor,
  });

  final String name;
  final String cue;
  final int target;
  final String unit;
  final int currentProgress;
  final int streak;
  final bool isCompleted;
  final VoidCallback onQuickLog;
  final VoidCallback onTap;
  final IconData leadingIcon;
  final Color? accentColor;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  bool _pulseActive = false;
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isCompleted && widget.isCompleted) {
      _triggerCompletionPulse();
    }
  }

  void _triggerCompletionPulse() {
    HapticFeedback.lightImpact();
    setState(() => _pulseActive = true);
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (mounted) {
        setState(() => _pulseActive = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;
    final palette = context.momentum;
    final accent = widget.accentColor ?? palette.accent;
    final iconSurface = context.isMomentumDark
        ? accent.withValues(alpha: 0.2)
        : accent.withValues(alpha: 0.14);
    final progress = widget.target == 0
        ? 0.0
        : (widget.currentProgress / widget.target).clamp(0.0, 1.0);

    return AnimatedScale(
      scale: _pulseActive ? 1.018 : 1,
      duration: AppDurations.stateChange,
      curve: AppEasing.standard,
      child: AnimatedContainer(
        duration: AppDurations.progress,
        curve: AppEasing.standard,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
              color: widget.isCompleted
                  ? AppColors.moss.withValues(alpha: _pulseActive ? 0.18 : 0.08)
                  : Colors.black
                      .withValues(alpha: context.isMomentumDark ? 0.16 : 0.035),
              blurRadius:
                  widget.isCompleted ? 22 : (context.isMomentumDark ? 10 : 16),
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            onTap: widget.onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: widget.isCompleted
                    ? (context.isMomentumDark
                        ? palette.successSoft.withValues(alpha: 0.7)
                        : AppColors.mossDim.withValues(alpha: 0.42))
                    : (context.isMomentumDark
                        ? palette.surface
                        : palette.surface),
                gradient: null,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: widget.isCompleted
                      ? palette.success
                          .withValues(alpha: context.isMomentumDark ? 0.82 : 1)
                      : palette.border,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(compact ? AppSpacing.x3 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutCubic,
                          width: compact ? 42 : 46,
                          height: compact ? 42 : 46,
                          decoration: BoxDecoration(
                            color: widget.isCompleted
                                ? palette.successSoft
                                : iconSurface,
                            borderRadius: BorderRadius.circular(AppRadii.badge),
                            border: Border.all(
                              color: widget.isCompleted
                                  ? palette.success
                                  : iconSurface,
                            ),
                          ),
                          child: Icon(
                            widget.leadingIcon,
                            color:
                                widget.isCompleted ? palette.success : accent,
                            size: compact ? 20 : 22,
                          ),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: AnimatedScale(
                            scale: widget.isCompleted ? 1 : 0.2,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutBack,
                            child: AnimatedOpacity(
                              opacity: widget.isCompleted ? 1 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: Container(
                                width: compact ? 20 : 22,
                                height: compact ? 20 : 22,
                                decoration: BoxDecoration(
                                  color: palette.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.isMomentumDark
                                        ? palette.surface
                                        : palette.background,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: compact ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.cue,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: palette.textSoft,
                                ),
                          ),
                          const SizedBox(height: 10),
                          _AnimatedProgressBar(
                            value: progress,
                            color:
                                widget.isCompleted ? palette.success : accent,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 240),
                                  child: Text(
                                    widget.isCompleted
                                        ? 'Completed'
                                        : '${widget.currentProgress} / ${widget.target} ${widget.unit}',
                                    key: ValueKey(
                                      '${widget.isCompleted}-${widget.currentProgress}',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: palette.textSoft,
                                        ),
                                  ),
                                ),
                              ),
                              Text(
                                '${widget.streak} day streak',
                                style: MomentumTypography.numbers(
                                  Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        color: palette.textSoft,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    GestureDetector(
                      onTapDown: (_) => setState(() => _pressed = true),
                      onTapCancel: () => setState(() => _pressed = false),
                      onTapUp: (_) => setState(() => _pressed = false),
                      onTap: widget.onQuickLog,
                      child: AnimatedScale(
                        scale: _pressed ? 0.93 : 1,
                        duration: AppDurations.press,
                        curve: AppEasing.standard,
                        child: Container(
                          width: compact ? 38 : 44,
                          height: compact ? 38 : 44,
                          decoration: BoxDecoration(
                            color: context.isMomentumDark
                                ? palette.accentSoft
                                : AppColors.emberDim,
                            borderRadius:
                                BorderRadius.circular(AppRadii.control),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: compact ? 20 : 24,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 7,
        color: context.isMomentumDark ? palette.ringTrack : AppColors.paperDim,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: AppDurations.progress,
          curve: AppEasing.standard,
          builder: (context, animatedValue, _) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animatedValue,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
