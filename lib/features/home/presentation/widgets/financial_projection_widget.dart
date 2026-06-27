import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/financial_projection_provider.dart';

class FinancialProjectionWidget extends ConsumerWidget {
  const FinancialProjectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projection = ref.watch(financialProjectionProvider);
    final currency = ref.watch(currencySymbolProvider);
    final hide = ref.watch(hideAmountsProvider);
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proyección 90 días',
                style: AppTypography.headingS.copyWith(color: c.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: projection.isTrendingPositive
                      ? AppColors.positiveSurface
                      : AppColors.negativeSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  projection.isTrendingPositive ? '📈 Positivo' : '📉 Negativo',
                  style: AppTypography.labelS.copyWith(
                    color: projection.isTrendingPositive
                        ? AppColors.positive
                        : AppColors.negative,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Mini chart
          _ProjectionChart(projection: projection),
          const SizedBox(height: AppSpacing.lg),
          // Stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Ingreso (30 días)',
                  value: maskMoney(hide,
                      '$currency${projection.averageMonthlyIncome.toStringAsFixed(0)}'),
                  color: AppColors.positive,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  label: 'Gasto (30 días)',
                  value: maskMoney(hide,
                      '$currency${projection.averageMonthlyExpense.toStringAsFixed(0)}'),
                  color: AppColors.negative,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (projection.upcomingSubscriptions > 0) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${projection.upcomingSubscriptions} suscripción(es) en 30 días',
                    style: AppTypography.labelS.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectionChart extends StatelessWidget {
  const _ProjectionChart({required this.projection});

  final FinancialProjection projection;

  @override
  Widget build(BuildContext context) {
    if (projection.projections.length < 2) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Sin datos suficientes',
            style: AppTypography.bodyS.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
      );
    }

    final points = projection.projections;
    final minBalance =
        points.map((p) => p.balance).reduce((a, b) => a < b ? a : b);
    final maxBalance =
        points.map((p) => p.balance).reduce((a, b) => a > b ? a : b);
    final range = maxBalance - minBalance;

    return SizedBox(
      height: 100,
      child: CustomPaint(
        painter: _ProjectionChartPainter(
          points: points,
          minBalance: minBalance,
          maxBalance: maxBalance,
          range: range,
          color: projection.isTrendingPositive
              ? AppColors.positive
              : AppColors.negative,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ProjectionChartPainter extends CustomPainter {
  _ProjectionChartPainter({
    required this.points,
    required this.minBalance,
    required this.maxBalance,
    required this.range,
    required this.color,
  });

  final List<ProjectionPoint> points;
  final double minBalance;
  final double maxBalance;
  final double range;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = (i / (points.length - 1)) * size.width;
      final normalizedBalance =
          range == 0 ? 0.5 : (point.balance - minBalance) / range;
      final y = size.height * (1 - normalizedBalance);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Dibujar puntos
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = (i / (points.length - 1)) * size.width;
      final normalizedBalance =
          range == 0 ? 0.5 : (point.balance - minBalance) / range;
      final y = size.height * (1 - normalizedBalance);

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_ProjectionChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelS.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.labelM.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
