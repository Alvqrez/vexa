import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/home_provider.dart';

class PredictionCard extends ConsumerWidget {
  const PredictionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(predictionProvider);
    final currency = ref.watch(currencySymbolProvider);

    // No data yet — don't show misleading predictions
    if (!p.hasData) {
      return Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
          color: Colors.white.withValues(alpha: 0.025),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.05), width: 0.5),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.glassLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_graph_rounded,
                    size: 15, color: AppColors.textTertiary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Registra ingresos y gastos para ver la predicción del mes.',
                  style: AppTypography.labelM
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = p.isOnTrack ? AppColors.emerald : AppColors.negative;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    size: 15,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'PREDICCIÓN DEL MES',
                  style: AppTypography.eyebrow
                      .copyWith(color: AppColors.textTertiary),
                ),
                const Spacer(),
                Text(
                  '${p.daysLeft} días restantes',
                  style: AppTypography.labelS
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _PredItem(
                    label: 'Gasto estimado',
                    value: '$currency${p.predictedExpenses.toStringAsFixed(0)}',
                    color: AppColors.negative,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PredItem(
                    label: p.predictedIncome > 0
                        ? 'Neto estimado'
                        : 'Gasto diario',
                    value: p.predictedIncome > 0
                        ? (p.predictedSavings >= 0
                            ? '+$currency${p.predictedSavings.toStringAsFixed(0)}'
                            : '-$currency${p.predictedSavings.abs().toStringAsFixed(0)}')
                        : '$currency${p.dailyAvgExpense.toStringAsFixed(0)}/día',
                    color: p.predictedIncome > 0
                        ? (p.predictedSavings >= 0
                            ? AppColors.emerald
                            : AppColors.negative)
                        : AppColors.warning,
                    icon: p.predictedIncome > 0
                        ? (p.predictedSavings >= 0
                            ? Icons.savings_rounded
                            : Icons.warning_rounded)
                        : Icons.show_chart_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Row(
                children: [
                  Icon(
                    p.isOnTrack
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    size: 13,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.predictedIncome > 0
                          ? (p.isOnTrack
                              ? 'A este ritmo cerrarás el mes con saldo positivo.'
                              : 'Atención: tus gastos superarán tus ingresos este mes.')
                          : 'Sin ingresos registrados aún este mes.',
                      style: AppTypography.labelS.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredItem extends StatelessWidget {
  const _PredItem({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelS
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.headingS.copyWith(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
