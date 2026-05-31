import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/home_provider.dart';
import '../pages/all_transactions_page.dart';
import 'transaction_item.dart';

class TransactionsSection extends ConsumerWidget {
  const TransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final visible = transactions.take(5).toList();

    return Column(
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recientes',
              style: AppTypography.headingS.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AllTransactionsPage()),
              ),
              child: Row(
                children: [
                  Text(
                    'Ver todo',
                    style: AppTypography.labelM.copyWith(
                      color: AppColors.emerald,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.emerald,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // List container
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: visible.isEmpty
              ? _EmptyState()
              : Column(
                  children: [
                    for (int i = 0; i < visible.length; i++) ...[
                      TransactionItem(
                        transaction: visible[i],
                        isLast: i == visible.length - 1,
                      ),
                      if (i < visible.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.glassBorder,
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin transacciones',
            style: AppTypography.bodyM.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
