import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/animated_number.dart';
import '../providers/home_provider.dart';
import '../../domain/models/transaction.dart';
import '../pages/all_transactions_page.dart';

// ── Total balance — flat display (no card) ────────────────────────────────────

class SummaryBalanceCard extends ConsumerWidget {
  const SummaryBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(totalBalanceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.emerald,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'SALDO TOTAL',
              style: AppTypography.eyebrow.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedNumber(
          value: balance,
          style: AppTypography.displayL.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_upward_rounded,
              size: 12,
              color: AppColors.emerald,
            ),
            const SizedBox(width: 4),
            Text(
              '+12% vs el mes anterior',
              style: AppTypography.labelS.copyWith(
                color: AppColors.emerald,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Income / Expense cards row ────────────────────────────────────────────────

class SummaryCardsRow extends ConsumerWidget {
  const SummaryCardsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'INGRESOS',
            value: income,
            icon: Icons.arrow_downward_rounded,
            color: AppColors.positive,
            surface: AppColors.positiveSurface,
            type: TransactionType.income,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            label: 'EGRESOS',
            value: expenses,
            icon: Icons.arrow_upward_rounded,
            color: AppColors.negative,
            surface: AppColors.negativeSurface,
            type: TransactionType.expense,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.surface,
    required this.type,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final Color surface;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AllTransactionsPage(typeFilter: type),
        ),
      ),
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedNumber(
              value: value,
              style: AppTypography.headingM.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              duration: const Duration(milliseconds: 1000),
            ),
            const SizedBox(height: 4),
            Text(
              'Este mes',
              style: AppTypography.labelS.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
