import 'package:flutter/material.dart';

class AnimatedCountText extends StatefulWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1100),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = '',
    this.fractionDigits = 0,
    this.style,
    this.textAlign,
  });

  final double value;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;
  final int fractionDigits;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<AnimatedCountText> {
  late double _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = 0;
  }

  @override
  void didUpdateWidget(covariant AnimatedCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _previousValue, end: widget.value),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, _) {
        final display = widget.fractionDigits == 0
            ? value.round().toString()
            : value.toStringAsFixed(widget.fractionDigits);
        return Text(
          '${widget.prefix}$display${widget.suffix}',
          textAlign: widget.textAlign,
          style: widget.style,
        );
      },
    );
  }
}
