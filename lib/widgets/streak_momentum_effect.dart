import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'animated_count_text.dart';

class StreakMomentumEffect extends StatefulWidget {
  const StreakMomentumEffect({
    super.key,
    required this.streak,
    this.compact = false,
  });

  final int streak;
  final bool compact;

  @override
  State<StreakMomentumEffect> createState() => _StreakMomentumEffectState();
}

class _StreakMomentumEffectState extends State<StreakMomentumEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 42.0 : 48.0;
    final palette = context.momentum;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MomentumTrailPainter(progress: _controller.value),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x1AFFFFFF),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.ember,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          AnimatedCountText(
            value: widget.streak.toDouble(),
            suffix: widget.streak == 1 ? ' day' : ' days',
            style: TextStyle(
              color: palette.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentumTrailPainter extends CustomPainter {
  const _MomentumTrailPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final particles = List.generate(5, (index) => index);

    for (final particle in particles) {
      final orbit = ((progress + (particle * 0.14)) % 1) * math.pi * 2;
      final radius = (size.width * 0.18) + (particle * 2.4);
      final opacity = (1 - (((progress + particle * 0.14) % 1) - 0.5).abs() * 2)
          .clamp(0.12, 0.42);
      final offset = Offset(
        center.dx + math.cos(orbit) * radius * 0.5,
        center.dy - 8 - math.sin(orbit) * radius,
      );

      canvas.drawCircle(
        offset,
        2.2 - (particle * 0.18),
        Paint()..color = AppColors.ember.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MomentumTrailPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
