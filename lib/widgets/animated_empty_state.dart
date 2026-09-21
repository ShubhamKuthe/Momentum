import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AnimatedEmptyState extends StatefulWidget {
  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String ctaLabel;
  final Future<void> Function() onTap;

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.isMomentumDark ? null : palette.surface,
        gradient: context.isMomentumDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.surfaceStrong,
                  palette.surface,
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final offset = Tween<double>(begin: -3, end: 5).transform(
                Curves.easeInOut.transform(_controller.value),
              );
              return Transform.translate(
                offset: Offset(0, offset),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: context.isMomentumDark ? palette.accentSoft : AppColors.emberDim,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: palette.accent,
                    size: 30,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textSoft,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.text,
              foregroundColor: palette.background,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: widget.onTap,
            child: Text(widget.ctaLabel),
          ),
        ],
      ),
    );
  }
}
