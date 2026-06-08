import 'package:flutter/material.dart';

class AnimatedBalanceDisplay extends StatefulWidget {
  const AnimatedBalanceDisplay({
    super.key,
    required this.balance,
    required this.currency,
    this.textStyle,
  });

  final double balance;
  final String currency;
  final TextStyle? textStyle;

  @override
  State<AnimatedBalanceDisplay> createState() => _AnimatedBalanceDisplayState();
}

class _AnimatedBalanceDisplayState extends State<AnimatedBalanceDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  double _previousBalance = 0;
  double? _deltaBounce;

  @override
  void initState() {
    super.initState();
    _previousBalance = widget.balance;

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedBalanceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.balance != widget.balance) {
      // Calcular el delta para mostrar
      _deltaBounce = widget.balance - _previousBalance;
      _previousBalance = widget.balance;

      // Resetear y re-animar
      _scaleController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceText = '${widget.currency}${widget.balance.toStringAsFixed(2)}';

    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Text(
            balanceText,
            style: widget.textStyle,
          ),
        ),
        // Mostrar delta que flota hacia arriba y desaparece
        if (_deltaBounce != null && _deltaBounce != 0)
          _DeltaBubble(
            delta: _deltaBounce!,
            currency: widget.currency,
            isPositive: _deltaBounce! > 0,
          ),
      ],
    );
  }
}

class _DeltaBubble extends StatefulWidget {
  const _DeltaBubble({
    required this.delta,
    required this.currency,
    required this.isPositive,
  });

  final double delta;
  final String currency;
  final bool isPositive;

  @override
  State<_DeltaBubble> createState() => _DeltaBubbleState();
}

class _DeltaBubbleState extends State<_DeltaBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -3),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sign = widget.isPositive ? '+' : '';
    final color = widget.isPositive
        ? const Color(0xFF00D68F) // Emerald
        : const Color(0xFFFF5F82); // Negative

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Text(
          '$sign${widget.currency}${widget.delta.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
