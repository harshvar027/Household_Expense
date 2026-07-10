import 'package:flutter/material.dart';
import '../../utils/money_format.dart';

class AnimatedCounter extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int fractionDigits;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.fractionDigits = kMoneyDecimals,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _start = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _start = _animation.value;
      _animation = Tween<double>(begin: _start, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        final v = _animation.value;
        final text = v.abs().toStringAsFixed(widget.fractionDigits);
        final sign = v < 0 ? '-' : '';
        return Text(
          '${widget.prefix}$sign$text${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
