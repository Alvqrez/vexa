import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/providers/settings_provider.dart';

class AnimatedNumber extends StatefulWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '\$',
    this.duration = const Duration(milliseconds: 1200),
    this.curve = const Cubic(0.16, 1.00, 0.30, 1.00),
    this.showChangeBadge = false,
    this.animate = true,
    this.hidden = false,
  });

  final double value;
  final TextStyle style;
  final String prefix;
  final Duration duration;
  final Curve curve;

  /// When true, briefly shows a +/- change indicator on value update.
  final bool showChangeBadge;

  /// When false, skips the counting animation (instant display).
  final bool animate;

  /// When true, masks the amount (privacy mode "Ocultar montos").
  final bool hidden;

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with TickerProviderStateMixin {
  late AnimationController _counter;
  late AnimationController _flash;
  late Animation<double> _animation;
  late Animation<double> _flashOpacity;
  late Animation<Offset> _flashSlide;

  double _previousValue = 0;
  double _lastDelta = 0;

  // Effective animation flag: honours both the per-widget opt-out and the
  // global "Animaciones" setting (reduced motion).
  bool get _animate => widget.animate && AppMotion.enabled;

  @override
  void initState() {
    super.initState();

    _counter = AnimationController(
      vsync: this,
      duration: _animate ? widget.duration : Duration.zero,
    );
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
    ]).animate(_flash);

    _flashSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _flash,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    ));

    _buildAnimation(0, widget.value);
    _counter.forward();
  }

  @override
  void didUpdateWidget(AnimatedNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _lastDelta = widget.value - old.value;
      _previousValue = old.value;
      _counter.duration = _animate ? widget.duration : Duration.zero;
      _buildAnimation(_previousValue, widget.value);
      _counter
        ..reset()
        ..forward();
      if (_animate && widget.showChangeBadge && _lastDelta != 0) {
        _flash
          ..reset()
          ..forward();
      }
    }
    // Respect animate toggle change mid-session
    if (old.animate != widget.animate) {
      _counter.duration = _animate ? widget.duration : Duration.zero;
    }
  }

  void _buildAnimation(double from, double to) {
    _animation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _counter, curve: widget.curve),
    );
  }

  @override
  void dispose() {
    _counter.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Privacy mode: render a masked placeholder instead of the figure.
    if (widget.hidden) {
      return Text('${widget.prefix}••••', style: widget.style);
    }

    final formatter = NumberFormat('#,##0.00', 'en_US');
    final isPositive = _lastDelta >= 0;
    final badgeColor =
        isPositive ? const Color(0xFF00D68F) : const Color(0xFFFF5F82);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Main counter
        AnimatedBuilder(
          animation: _animation,
          builder: (_, child) {
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
        ),

        // Change badge — appears to the right of the number, same baseline.
        if (widget.showChangeBadge)
          AnimatedBuilder(
            animation: _flash,
            builder: (_, child) {
              if (_flash.value == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: FadeTransition(
                  opacity: _flashOpacity,
                  child: SlideTransition(
                    position: _flashSlide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.35),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 10,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '\$${_lastDelta.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
