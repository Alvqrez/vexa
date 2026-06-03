import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../providers/home_provider.dart';
import '../../../budget/presentation/pages/budget_page.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../../core/providers/settings_provider.dart';

class SpendingCard extends ConsumerStatefulWidget {
  const SpendingCard({super.key});

  @override
  ConsumerState<SpendingCard> createState() => _SpendingCardState();
}

class _SpendingCardState extends ConsumerState<SpendingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _arcController;
  late Animation<double> _arcAnimation;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _arcAnimation = CurvedAnimation(
      parent: _arcController,
      curve: AppCurves.spring,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _arcController.forward();
    });
  }

  @override
  void dispose() {
    _arcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(monthlyExpensesProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final ratio = ref.watch(budgetSpendingRatioProvider);
    final limit = ref.watch(totalBudgetLimitProvider);
    final currency = ref.watch(currencySymbolProvider);

    // ── Double-Bezel outer tray ─────────────────────────────────────────────
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BudgetPage()),
        );
      },
      child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL + 3),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFF1C1C32), Color(0xFF141428), Color(0xFF0F0F1E)],
          ),
          // Inner top highlight — glass-plate illusion,
          boxShadow: [
            // Emerald ambient glow
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.07),
              blurRadius: 60,
              spreadRadius: -8,
              offset: const Offset(0, 24),
            ),
            // Mid ambient
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            // Contact shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Arc chart
            AnimatedBuilder(
              animation: _arcAnimation,
              builder: (context, _) {
                return SizedBox(
                  width: 112,
                  height: 112,
                  child: CustomPaint(
                    painter: _ArcPainter(
                      progress: ratio * _arcAnimation.value,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(ratio * 100).toStringAsFixed(0)}%',
                            style: AppTypography.headingS.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 19,
                            ),
                          ),
                          Text(
                            'usado',
                            style: AppTypography.eyebrow.copyWith(
                              color: AppColors.textTertiary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.xl),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eyebrow tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                    ),
                    child: Text(
                      'ESTE MES',
                      style: AppTypography.eyebrow.copyWith(
                        color: AppColors.emeraldDim,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (limit > 0) ...[
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$currency${expenses.toStringAsFixed(0)}',
                            style: AppTypography.headingL.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: ' / $currency${limit.toStringAsFixed(0)}',
                            style: AppTypography.bodyM.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _StatRow(
                      label: 'Ingresos',
                      value: '$currency${income.toStringAsFixed(0)}',
                      color: AppColors.positive,
                      icon: Icons.south_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatRow(
                      label: 'Gastos',
                      value: '$currency${expenses.toStringAsFixed(0)}',
                      color: AppColors.negative,
                      icon: Icons.north_rounded,
                    ),
                  ] else ...[
                    Text(
                      'Sin presupuesto',
                      style: AppTypography.headingS.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Toca para configurar\nlímites de gasto.',
                      style: AppTypography.labelM.copyWith(
                        color: AppColors.textTertiary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _StatRow(
                      label: 'Ingresos',
                      value: '$currency${income.toStringAsFixed(0)}',
                      color: AppColors.positive,
                      icon: Icons.south_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatRow(
                      label: 'Gastos',
                      value: '$currency${expenses.toStringAsFixed(0)}',
                      color: AppColors.negative,
                      icon: Icons.north_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 11, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.labelM.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.labelL.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;
    const strokeWidth = 7.0;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.card
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Glow layer
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..color = AppColors.emeraldGlow
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Progress — sweep gradient
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle * progress,
          colors: [
            AppColors.emerald.withValues(alpha: 0.6),
            AppColors.emerald,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
