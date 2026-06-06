import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/home_provider.dart';

class QuickStats extends ConsumerWidget {
  const QuickStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final savings = ref.watch(monthlySavingsProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Ingresos',
            value: _compact(income, currency),
            icon: Icons.south_rounded,
            color: AppColors.positive,
            surface: AppColors.positiveSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            label: 'Gastos',
            value: _compact(expenses, currency),
            icon: Icons.north_rounded,
            color: AppColors.negative,
            surface: AppColors.negativeSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            label: 'Ahorrado',
            value: _compact(savings, currency),
            icon: Icons.savings_outlined,
            color: AppColors.petroleum,
            surface: AppColors.petroleumSurface,
          ),
        ),
      ],
    );
  }

  String _compact(double v, String symbol) {
    if (v >= 1000) return '$symbol${(v / 1000).toStringAsFixed(1)}k';
    return '$symbol${v.toStringAsFixed(0)}';
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
    final c = context.colors;
    // Double-Bezel outer tray
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
        color: c.glass,
        border: Border.all(
          color: c.glassBorder,
          width: 0.5,
        ),
      ),
      // Inner core
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.card,
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
                color: c.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelS.copyWith(
                color: c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
