import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/home_provider.dart';

class QuickStats extends ConsumerWidget {
  const QuickStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final savings = ref.watch(monthlySavingsProvider);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Ingresos',
            value: _compact(income),
            icon: Icons.south_rounded,
            color: AppColors.positive,
            surface: AppColors.positiveSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            label: 'Gastos',
            value: _compact(expenses),
            icon: Icons.north_rounded,
            color: AppColors.negative,
            surface: AppColors.negativeSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            label: 'Ahorrado',
            value: _compact(savings),
            icon: Icons.savings_outlined,
            color: AppColors.petroleum,
            surface: AppColors.petroleumSurface,
          ),
        ),
      ],
    );
  }

  String _compact(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.surface,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    // Double-Bezel outer tray
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      // Inner core
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: AppTypography.headingS.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelS.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
