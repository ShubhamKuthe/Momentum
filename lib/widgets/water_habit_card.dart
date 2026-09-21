import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/typography.dart';

class WaterHabitCard extends StatefulWidget {
  const WaterHabitCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.status,
    required this.onTap,
    required this.onManualLog,
    this.accentColor = const Color(0xFF4C9BFF),
  });

  final String title;
  final int currentValue;
  final int targetValue;
  final String unit;
  final String status;
  final VoidCallback onTap;
  final VoidCallback onManualLog;
  final Color accentColor;

  @override
  State<WaterHabitCard> createState() => _WaterHabitCardState();
}

class _WaterHabitCardState extends State<WaterHabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<UserAccelerometerEvent>? _userAccelerometerSubscription;

  double _targetTilt = 0;
  double _currentTilt = 0;
  double _targetShake = 0;
  double _currentShake = 0;
  bool _sensorActive = false;

  double get _progress {
    if (widget.targetValue <= 0) {
      return 0;
    }
    return (widget.currentValue / widget.targetValue).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )
      ..addListener(_tickWaterPhysics)
      ..repeat();
    _initSensors();
  }

  Future<void> _initSensors() async {
    final platform = defaultTargetPlatform;
    final supportsSensors = kIsWeb ||
        platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS;

    if (!supportsSensors) {
      return;
    }

    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (event) {
          final tilt = (-event.x / 9.8).clamp(-1.0, 1.0).toDouble();
          _targetTilt = tilt;
          if (!_sensorActive && mounted) {
            setState(() => _sensorActive = true);
          }
        },
        onError: (_) {
          _disposeSensorSubscriptions();
        },
        cancelOnError: true,
      );

      _userAccelerometerSubscription = userAccelerometerEventStream().listen(
        (event) {
          final intensity = math.sqrt(
            (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
          );
          _targetShake = math.max(
            _targetShake,
            (intensity / 3.6).clamp(0.0, 1.0).toDouble(),
          );
          if (!_sensorActive && mounted) {
            setState(() => _sensorActive = true);
          }
        },
        onError: (_) {
          _disposeSensorSubscriptions();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _disposeSensorSubscriptions();
    }
  }

  void _disposeSensorSubscriptions() {
    _accelerometerSubscription?.cancel();
    _userAccelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _userAccelerometerSubscription = null;
  }

  void _tickWaterPhysics() {
    final nextTilt = lerpDouble(_currentTilt, _targetTilt, 0.12) ?? _targetTilt;
    final nextShake = lerpDouble(_currentShake, _targetShake, 0.1) ?? _targetShake;
    _targetShake *= 0.92;

    if ((nextTilt - _currentTilt).abs() > 0.001 ||
        (nextShake - _currentShake).abs() > 0.001) {
      setState(() {
        _currentTilt = nextTilt;
        _currentShake = nextShake;
      });
    } else if (_currentShake > 0.001) {
      setState(() {
        _currentShake = nextShake;
      });
    }
  }

  @override
  void dispose() {
    _waveController
      ..removeListener(_tickWaterPhysics)
      ..dispose();
    _disposeSensorSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final compact = MediaQuery.of(context).size.width < 390;
    final textColor = context.isMomentumDark ? Colors.white : const Color(0xFF192439);
    final softTextColor = context.isMomentumDark
        ? Colors.white.withValues(alpha: 0.74)
        : const Color(0xFF41506B);
    final percent = (_progress * 100).round();
    final borderColor = context.isMomentumDark
        ? palette.border.withValues(alpha: 0.8)
        : const Color(0xFFD8E4F7);
    final baseGradient = context.isMomentumDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111A27), Color(0xFF182438)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FBFF), Color(0xFFEAF3FF)],
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: compact ? 228 : 236,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: context.isMomentumDark ? 0.16 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Ink(
            decoration: BoxDecoration(
              gradient: baseGradient,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WaterCardPainter(
                        progress: _progress,
                        wavePhase: _waveController.value * math.pi * 4,
                        tilt: _currentTilt,
                        shake: _currentShake,
                        accentColor: widget.accentColor,
                        isDarkMode: context.isMomentumDark,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: context.isMomentumDark
                                ? [
                                    const Color(0xCC0D1420),
                                    const Color(0x500D1420),
                                    Colors.transparent,
                                  ]
                                : [
                                    const Color(0xCCF7FBFF),
                                    const Color(0x80F7FBFF),
                                    Colors.transparent,
                                  ],
                            stops: const [0.0, 0.42, 0.86],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 18,
                      compact ? 14 : 16,
                      compact ? 16 : 18,
                      compact ? 12 : 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.isMomentumDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(AppRadii.badge),
                                border: Border.all(
                                  color: context.isMomentumDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFDCE8FB),
                                ),
                              ),
                              child: Icon(
                                Icons.water_drop_rounded,
                                color: widget.accentColor,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: context.isMomentumDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.86),
                                borderRadius: BorderRadius.circular(AppRadii.control),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _sensorActive
                                        ? Icons.sensors_rounded
                                        : Icons.water_rounded,
                                    color: textColor.withValues(alpha: 0.76),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$percent%',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontSize: compact ? 17.5 : 18.5,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daily',
                          style: TextStyle(
                            color: softTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: widget.currentValue.toDouble()),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return Text(
                              '${value.round()} / ${widget.targetValue}',
                              style: MomentumTypography.numbers(
                                TextStyle(
                                  color: textColor,
                                  fontSize: compact ? 24 : 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.7,
                                  height: 1,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.unit} today',
                          style: TextStyle(
                            color: softTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: context.isMomentumDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(AppRadii.control),
                                ),
                                child: Text(
                                  widget.status,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 34,
                              child: TextButton(
                                onPressed: widget.onManualLog,
                                style: TextButton.styleFrom(
                                  foregroundColor: textColor,
                                  backgroundColor: context.isMomentumDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.82),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(44, 34),
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadii.control),
                                  ),
                                ),
                                child: const Text(
                                  'Log',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterCardPainter extends CustomPainter {
  const _WaterCardPainter({
    required this.progress,
    required this.wavePhase,
    required this.tilt,
    required this.shake,
    required this.accentColor,
    required this.isDarkMode,
  });

  final double progress;
  final double wavePhase;
  final double tilt;
  final double shake;
  final Color accentColor;
  final bool isDarkMode;

  @override
  void paint(Canvas canvas, Size size) {
    final fillRatio = progress.clamp(0.0, 1.0);
    if (fillRatio <= 0) {
      return;
    }

    final baseHeight = size.height * (1 - fillRatio);
    final tiltOffset = (tilt.clamp(-1.0, 1.0) * 12).toDouble();
    final amplitude = lerpDouble(7, 20, shake.clamp(0.0, 1.0))!;
    final secondaryAmplitude = amplitude * 0.42;

    final path = Path()..moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 4) {
      final normalizedX = x / size.width;
      final slope = lerpDouble(-tiltOffset, tiltOffset, normalizedX)!;
      final primaryWave = math.sin((normalizedX * math.pi * 2.15) + wavePhase) * amplitude;
      final secondaryWave =
          math.sin((normalizedX * math.pi * 4.1) - (wavePhase * 1.1)) * secondaryAmplitude;
      final y = baseHeight + slope + primaryWave + secondaryWave;
      path.lineTo(x, y.clamp(0.0, size.height));
    }

    path
      ..lineTo(size.width, size.height)
      ..close();

    final waterBounds = Rect.fromLTWH(0, baseHeight - 24, size.width, size.height);
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: isDarkMode ? 0.78 : 0.62),
          accentColor,
          const Color(0xFF2878FF),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(waterBounds);

    canvas.drawPath(path, waterPaint);

    final highlightPath = Path();
    for (double x = 0; x <= size.width; x += 4) {
      final normalizedX = x / size.width;
      final slope = lerpDouble(-tiltOffset, tiltOffset, normalizedX)!;
      final primaryWave = math.sin((normalizedX * math.pi * 2.15) + wavePhase) * amplitude;
      final secondaryWave =
          math.sin((normalizedX * math.pi * 4.1) - (wavePhase * 1.1)) * secondaryAmplitude;
      final y = baseHeight + slope + primaryWave + secondaryWave;
      if (x == 0) {
        highlightPath.moveTo(x, y);
      } else {
        highlightPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: isDarkMode ? 0.32 : 0.52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDarkMode ? 0.12 : 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(0, baseHeight - 12, size.width, size.height - baseHeight + 12),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, baseHeight - 10, size.width, size.height - baseHeight + 10),
      shimmerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterCardPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.tilt != tilt ||
        oldDelegate.shake != shake ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
