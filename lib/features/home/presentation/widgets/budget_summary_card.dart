import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/home_provider.dart';
import '../../../budget/presentation/providers/budget_provider.dart';

class BudgetSummaryCard extends ConsumerWidget {
  const BudgetSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(budgetWithSpentProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    final c = context.colors;
    int overCount = 0;
    int warnCount = 0;
    for (final b in items) {
      if (b.isOver) {
        overCount++;
      } else if (b.isWarning) {
        warnCount++;
      }
    }
    final total = items.length;

    final statusColor = overCount > 0
        ? AppColors.negative
        : warnCount > 0
            ? AppColors.warning
            : AppColors.positive;

    return GestureDetector(
      onTap: () => ref.read(selectedNavIndexProvider.notifier).state = 3,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.pie_chart_rounded,
                      size: 15, color: statusColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Presupuestos',
                  style: AppTypography.headingS.copyWith(
                    color: c.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: c.textTertiary),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Up to 3 budget bars
            ...items.take(3).map((b) => _BudgetBar(item: b)),
            if (total > 3) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '+${total - 3} más',
                style: AppTypography.labelS.copyWith(color: c.textTertiary),
              ),
            ],
            if (overCount > 0 || warnCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      overCount > 0
                          ? Icons.error_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      overCount > 0
                          ? '$overCount ${overCount == 1 ? 'presupuesto' : 'presupuestos'} excedido${overCount == 1 ? '' : 's'}'
                          : '$warnCount ${warnCount == 1 ? 'presupuesto' : 'presupuestos'} en alerta',
                      style: AppTypography.labelS.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.item});
  final BudgetItemWithSpent item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = item.isOver
        ? AppColors.negative
        : item.isWarning
            ? AppColors.warning
            : item.item.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(item.item.icon, size: 12, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  item.item.name,
                  style: AppTypography.labelS.copyWith(color: c.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(item.ratio * 100).toStringAsFixed(0)}%',
                style: AppTypography.labelS.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            child: LinearProgressIndicator(
              value: item.ratio,
              minHeight: 4,
              backgroundColor: c.glass,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
