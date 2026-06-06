import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/vexa_empty_state.dart';
import '../providers/home_provider.dart';
import '../pages/all_transactions_page.dart';
import 'transaction_item.dart';

class TransactionsSection extends ConsumerWidget {
  const TransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
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
                color: c.textPrimary,
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
            color: c.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: c.glassBorder, width: 0.5),
          ),
          child: visible.isEmpty
              ? VexaEmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Sin movimientos',
                  body: 'Registra tu primer gasto\no ingreso con el botón +.',
                  iconColor: c.textTertiary,
                )
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
                            color: c.glassBorder,
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

