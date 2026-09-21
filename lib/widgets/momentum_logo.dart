import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';

class MomentumLogo extends StatelessWidget {
  const MomentumLogo({
    super.key,
    this.size = 88,
    this.radius = 24,
    this.showShadow = true,
  });

  final double size;
  final double radius;
  final bool showShadow;

  static const String assetPath = 'assets/images/momentum_logo.png';

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow
            ? AppElevations.floating(
                palette.shadow,
                isDark: context.isMomentumDark,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
