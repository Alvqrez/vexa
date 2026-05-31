import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedNumber extends StatefulWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '\$',
    this.duration = const Duration(milliseconds: 1200),
    this.curve = const Cubic(0.16, 1.00, 0.30, 1.00),
  });

  final double value;
  final TextStyle style;
  final String prefix;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _buildAnimation(0, widget.value);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _previousValue = old.value;
      _buildAnimation(_previousValue, widget.value);
      _controller
        ..reset()
        ..forward();
    }
  }

  void _buildAnimation(double from, double to) {
    _animation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final parts = formatter.format(_animation.value).split('.');
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${widget.prefix}${parts[0]}',
                style: widget.style,
              ),
              TextSpan(
                text: '.${parts[1]}',
                style: widget.style.copyWith(
                  fontSize: (widget.style.fontSize ?? 40) * 0.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
