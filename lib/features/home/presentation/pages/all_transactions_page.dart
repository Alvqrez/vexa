import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/home_provider.dart';
import '../../domain/models/transaction.dart';
import '../widgets/transaction_item.dart';

class AllTransactionsPage extends ConsumerStatefulWidget {
  const AllTransactionsPage({super.key, this.typeFilter});

  final TransactionType? typeFilter;

  @override
  ConsumerState<AllTransactionsPage> createState() =>
      _AllTransactionsPageState();
}

class _AllTransactionsPageState extends ConsumerState<AllTransactionsPage> {
  TransactionCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(transactionsProvider);
    final typeFiltered = widget.typeFilter == null
        ? all
        : all.where((t) => t.type == widget.typeFilter).toList();
    final filtered = _filter == null
        ? typeFiltered
        : typeFiltered.where((t) => t.category == _filter).toList();

    final income = filtered
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expenses = filtered
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.petroleum.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // Header
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.typeFilter == TransactionType.income
                                    ? 'Ingresos'
                                    : widget.typeFilter ==
                                            TransactionType.expense
                                        ? 'Egresos'
                                        : 'Transacciones',
                                style: AppTypography.headingM
                                    .copyWith(color: AppColors.textPrimary),
                              ),
                              Text(
                                '${filtered.length} movimientos',
                                style: AppTypography.labelS
                                    .copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Summary row
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryChip(
                              label: 'Ingresos',
                              value: '+\$${income.toStringAsFixed(0)}',
                              color: AppColors.positive,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _SummaryChip(
                              label: 'Egresos',
                              value: '-\$${expenses.toStringAsFixed(0)}',
                              color: AppColors.negative,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Category filter
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: 'Todo',
                              selected: _filter == null,
                              color: AppColors.petroleum,
                              onTap: () =>
                                  setState(() => _filter = null),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            ...TransactionCategory.values.map((cat) => Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppSpacing.sm),
                                  child: _FilterChip(
                                    label: cat.label,
                                    selected: _filter == cat,
                                    color: cat.color,
                                    onTap: () =>
                                        setState(() => _filter = cat),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Transaction list
                      if (filtered.isEmpty)
                        _EmptyState()
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                                color: AppColors.glassBorder, width: 0.5),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < filtered.length; i++) ...[
                                TransactionItem(
                                  transaction: filtered[i],
                                  isLast: i == filtered.length - 1,
                                ),
                                if (i < filtered.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md),
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

                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
            color: color.withValues(alpha: 0.20), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.labelS
                  .copyWith(color: AppColors.textTertiary)),
          Text(value,
              style: AppTypography.headingS
                  .copyWith(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelM.copyWith(
            color: selected ? color : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded,
              size: 36, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sin movimientos',
            style: AppTypography.bodyM
                .copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
