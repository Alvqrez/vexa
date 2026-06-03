import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';

class FinancialCard extends ConsumerStatefulWidget {
  const FinancialCard({super.key});

  @override
  ConsumerState<FinancialCard> createState() => _FinancialCardState();
}

class _FinancialCardState extends ConsumerState<FinancialCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _cardName(String name) {
    final n = name.trim().toUpperCase();
    return n.isEmpty ? 'USUARIO VEXA' : n;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: AspectRatio(
          aspectRatio: 1.586, // ISO/IEC 7810 ID-1 ratio
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.45, 1.0],
                colors: [
                  Color(0xFF1E2A4A),
                  Color(0xFF0F1E3A),
                  Color(0xFF0A1628),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.petroleum.withValues(alpha: 0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
              child: Stack(
                children: [
                  // ── Decorative geometry ─────────────────────────────────
                  _CardGeometry(),
                  // ── Glass shimmer border ────────────────────────────────
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadiusL,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // ── Content ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: label + logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'VEXA CARD',
                              style: AppTypography.labelS.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 2.5,
                                fontSize: 10,
                              ),
                            ),
                            _NetworkLogo(),
                          ],
                        ),
                        const Spacer(),
                        // Chip
                        _ChipIcon(),
                        const SizedBox(height: AppSpacing.lg),
                        // Card number
                        Text(
                          '••••  ••••  ••••  ••••',
                          style: AppTypography.monoL.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 2,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Bottom row: holder name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TITULAR',
                              style: AppTypography.labelS.copyWith(
                                color: Colors.white.withValues(alpha: 0.4),
                                letterSpacing: 1.2,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _cardName(ref.watch(userProfileProvider).name),
                              style: AppTypography.labelL.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.8,
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

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CardGeometry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: CustomPaint(painter: _GeometryPainter()));
  }
}

class _GeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Large circle — top right
    paint.color = const Color(0xFF1A7A9A).withValues(alpha: 0.15);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * -0.1),
      size.width * 0.55,
      paint,
    );

    // Small circle — bottom left
    paint.color = const Color(0xFF00D68F).withValues(alpha: 0.07);
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 1.1),
      size.width * 0.4,
      paint,
    );

    // Subtle arc line
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 1.1, size.height * 0.5),
        width: size.width * 1.4,
        height: size.width * 1.4,
      ),
      math.pi * 0.6,
      math.pi * 0.5,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_GeometryPainter _) => false;
}

class _ChipIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4AF37), Color(0xFFA07820)],
        ),
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      paint,
    );
    // Vertical center
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChipPainter _) => false;
}

class _NetworkLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEB001B).withValues(alpha: 0.85),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF79E1B).withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
