import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/transaction.dart';
import '../pages/transaction_detail_page.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
    this.isLast = false,
  });

  final Transaction transaction;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cat = transaction.category;
    final isIncome = transaction.isIncome;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TransactionDetailPage(transaction: transaction),
            ),
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          splashColor: AppColors.glassLight,
          highlightColor: AppColors.glassLight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cat.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant,
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            cat.label,
                            style: AppTypography.labelS.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppColors.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _relativeDate(transaction.date),
                            style: AppTypography.labelS.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      transaction.formattedAmount,
                      style: AppTypography.labelL.copyWith(
                        color: isIncome ? AppColors.positive : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? AppColors.positiveSurface
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                      ),
                      child: Text(
                        isIncome ? 'Entrada' : 'Salida',
                        style: AppTypography.labelS.copyWith(
                          color: isIncome
                              ? AppColors.positive
                              : AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays}d';
  }
}
