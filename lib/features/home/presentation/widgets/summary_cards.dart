import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/animated_number.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/home_provider.dart';
import '../../domain/models/transaction.dart';
import '../pages/all_transactions_page.dart';

// ── Total balance ─────────────────────────────────────────────────────────────

class SummaryBalanceCard extends ConsumerWidget {
  const SummaryBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final balance = ref.watch(totalBalanceProvider);
    final currency = ref.watch(currencySymbolProvider);
    final pct = ref.watch(monthOverMonthProvider);

    // Ambient glow color driven by MoM trend
    final glowColor = pct == null
        ? AppColors.petroleum
        : pct >= 0
            ? AppColors.emerald
            : AppColors.negative;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ambient orb — sits behind the balance number
        Positioned(
          top: -50,
          left: -70,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  glowColor.withValues(alpha: 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label row with glowing dot
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.60),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'SALDO TOTAL',
                  style: AppTypography.eyebrow.copyWith(
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            AnimatedNumber(
              value: balance,
              style: AppTypography.displayL.copyWith(color: c.textPrimary),
              prefix: currency,
              duration: const Duration(milliseconds: 1400),
              showChangeBadge: true,
            ),

            const SizedBox(height: 10),
            _MonthBadge(),
          ],
        ),
      ],
    );
  }
}

// ── Month-over-month badge ────────────────────────────────────────────────────

class _MonthBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = ref.watch(monthOverMonthProvider);
    if (pct == null) return const SizedBox.shrink();

    final isUp = pct >= 0;
    final color = isUp ? AppColors.emerald : AppColors.negative;
    final sign = isUp ? '+' : '';
    final label = '$sign${pct.toStringAsFixed(1)}% vs el mes anterior';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelS.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
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
    final currency = ref.watch(currencySymbolProvider);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'INGRESOS',
            value: income,
            currency: currency,
            icon: Icons.arrow_downward_rounded,
            color: AppColors.positive,
            type: TransactionType.income,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            label: 'EGRESOS',
            value: expenses,
            currency: currency,
            icon: Icons.arrow_upward_rounded,
            color: AppColors.negative,
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
    required this.currency,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String label;
  final double value;
  final String currency;
  final IconData icon;
  final Color color;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AllTransactionsPage(typeFilter: type)),
      ),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
          // Outer shell: very faint color gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.01),
            ],
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Icon with gradient background
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.32),
                          color.withValues(alpha: 0.14),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 15, color: color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Label uses the card's accent color
                  Text(
                    label,
                    style: AppTypography.eyebrow.copyWith(
                      color: color.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedNumber(
                value: value,
                prefix: currency,
                style: AppTypography.headingM.copyWith(
                  color: c.textPrimary,
                  letterSpacing: -0.5,
                ),
                duration: const Duration(milliseconds: 1000),
              ),
              const SizedBox(height: 4),
              Text(
                'Este mes',
                style: AppTypography.labelS.copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
