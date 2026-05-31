import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/transaction.dart';
import '../pages/transaction_detail_page.dart';
import '../pages/add_transaction_page.dart';
import '../providers/home_provider.dart';

class TransactionItem extends ConsumerStatefulWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
    this.isLast = false,
    this.enableSwipe = true,
  });

  final Transaction transaction;
  final bool isLast;
  final bool enableSwipe;

  @override
  ConsumerState<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends ConsumerState<TransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _openDetail() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailPage(transaction: widget.transaction),
      ),
    );
  }

  void _openEdit() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddTransactionSheet(existing: widget.transaction),
    );
  }

  void _delete() {
    HapticFeedback.heavyImpact();
    ref
        .read(transactionsProvider.notifier)
        .delete(widget.transaction);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final cat = t.category;
    final isIncome = t.isIncome;

    Widget tile = GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) => _press.forward(),
      onTapCancel: () => _press.forward(),
      onTap: _openDetail,
      child: ScaleTransition(
        scale: _press,
        child: Container(
          margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Hero: icon expands into the detail page
                Hero(
                  tag: 'txn_icon_${t.id}',
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: cat.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 20),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.merchant,
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
                          Text(cat.label,
                              style: AppTypography.labelS
                                  .copyWith(color: AppColors.textTertiary)),
                          const SizedBox(width: 6),
                          Container(
                            width: 3, height: 3,
                            decoration: const BoxDecoration(
                              color: AppColors.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(_relativeDate(t.date),
                              style: AppTypography.labelS
                                  .copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                      if (t.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: t.tags.take(3).map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.glassMedium,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(tag,
                                style: AppTypography.labelS.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 9)),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t.formattedAmount,
                      style: AppTypography.labelL.copyWith(
                        color: isIncome
                            ? AppColors.positive
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? AppColors.positiveSurface
                            : AppColors.card,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
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

    if (!widget.enableSwipe) return tile;

    return Dismissible(
      key: ValueKey(t.id),
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: AppColors.petroleum,
        icon: Icons.edit_rounded,
        label: 'Editar',
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: AppColors.negative,
        icon: Icons.delete_outline_rounded,
        label: 'Eliminar',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit — don't actually dismiss
          _openEdit();
          return false;
        }
        // Delete — confirm
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _delete();
        }
      },
      child: tile,
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

// ── Swipe background ──────────────────────────────────────────────────────────

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      color: color.withValues(alpha: 0.12),
      alignment: alignment,
      padding: EdgeInsets.only(
        left: isLeft ? AppSpacing.xl : 0,
        right: isLeft ? 0 : AppSpacing.xl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: AppTypography.labelM
                        .copyWith(color: color, fontWeight: FontWeight.w600)),
              ]
            : [
                Text(label,
                    style: AppTypography.labelM
                        .copyWith(color: color, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
      ),
    );
  }
}
