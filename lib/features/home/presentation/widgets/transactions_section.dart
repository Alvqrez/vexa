import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/widgets/vexa_empty_state.dart';
import '../../domain/models/transaction.dart';
import '../providers/home_provider.dart';
import '../pages/all_transactions_page.dart';
import 'transaction_item.dart';

class TransactionsSection extends ConsumerStatefulWidget {
  const TransactionsSection({super.key});

  @override
  ConsumerState<TransactionsSection> createState() =>
      _TransactionsSectionState();
}

class _TransactionsSectionState extends ConsumerState<TransactionsSection> {
  final Set<String> _selectedIds = {};

  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggle(String id) {
    Haptics.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    Haptics.lightImpact();
    setState(() => _selectedIds.clear());
  }

  Future<void> _deleteSelected(List<Transaction> visible) async {
    Haptics.heavyImpact();
    final toDelete = visible.where((t) => _selectedIds.contains(t.id)).toList();
    setState(() => _selectedIds.clear());
    for (final t in toDelete) {
      await ref.read(transactionsProvider.notifier).delete(t);
    }
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) {
      return 'Hoy, ${DateFormat("d 'de' MMMM", 'es').format(date)}';
    } else if (day == today.subtract(const Duration(days: 1))) {
      return 'Ayer, ${DateFormat("d 'de' MMMM", 'es').format(date)}';
    } else {
      final raw = DateFormat("EEEE, d 'de' MMMM", 'es').format(date);
      return raw[0].toUpperCase() + raw.substring(1);
    }
  }

  double _dayNet(List<Transaction> txns) =>
      txns.fold(0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));

  /// Computes the corner radius so adjacent selected items form one merged rect.
  BorderRadius _selectionRadius(List<Transaction> dayTxns, int i) {
    const r = Radius.circular(AppSpacing.cardRadius);
    const flat = Radius.zero;
    final prevSel = i > 0 && _selectedIds.contains(dayTxns[i - 1].id);
    final nextSel =
        i < dayTxns.length - 1 && _selectedIds.contains(dayTxns[i + 1].id);
    return BorderRadius.only(
      topLeft: prevSel ? flat : r,
      topRight: prevSel ? flat : r,
      bottomLeft: nextSel ? flat : r,
      bottomRight: nextSel ? flat : r,
    );
  }

  double _selectedNet(List<Transaction> visible) => visible
      .where((t) => _selectedIds.contains(t.id))
      .fold(0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final transactions = ref.watch(filteredTransactionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final visible = transactions.take(5).toList();

    // Group by calendar day, preserving descending date order.
    final groups = <DateTime, List<Transaction>>{};
    for (final t in visible) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      groups.putIfAbsent(day, () => []).add(t);
    }
    final sortedDays = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header / selection bar ────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isSelecting
              ? _SelectionBar(
                  key: const ValueKey('sel'),
                  count: _selectedIds.length,
                  net: _selectedNet(visible),
                  currency: currency,
                  onClear: _clearSelection,
                  onDelete: () => _deleteSelected(visible),
                )
              : _SectionHeader(
                  key: const ValueKey('hdr'),
                  onViewAll: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AllTransactionsPage()),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Grouped list ─────────────────────────────────────────────────
        if (visible.isEmpty)
          VexaEmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'Sin movimientos',
            body: 'Registra tu primer gasto\no ingreso con el botón +.',
            iconColor: c.textTertiary,
          )
        else
          for (final day in sortedDays) ...[
            _DayHeader(
              label: _dayLabel(groups[day]!.first.date),
              net: _dayNet(groups[day]!),
              currency: currency,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < groups[day]!.length; i++) ...[
              TransactionItem(
                key: ValueKey(groups[day]![i].id),
                transaction: groups[day]![i],
                isLast: i == groups[day]!.length - 1,
                isSelected: _selectedIds.contains(groups[day]![i].id),
                selectionMode: _isSelecting,
                onSelectToggle: () => _toggle(groups[day]![i].id),
                selectionRadius: _selectionRadius(groups[day]!, i),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({super.key, required this.onViewAll});
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recientes',
          style: AppTypography.headingS.copyWith(color: c.textPrimary),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Row(
            children: [
              Text(
                'Ver todo',
                style:
                    AppTypography.labelM.copyWith(color: AppColors.emerald),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: AppColors.emerald),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Selection action bar ──────────────────────────────────────────────────────

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    super.key,
    required this.count,
    required this.net,
    required this.currency,
    required this.onClear,
    required this.onDelete,
  });

  final int count;
  final double net;
  final String currency;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isPos = net >= 0;
    final netColor = isPos ? AppColors.positive : AppColors.negative;
    final netStr =
        '${isPos ? '+' : '-'}$currency${net.abs().toStringAsFixed(0)}';

    return Row(
      children: [
        GestureDetector(
          onTap: onClear,
          child: Icon(Icons.close_rounded, size: 20, color: c.textTertiary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$count seleccionado${count != 1 ? 's' : ''}',
          style: AppTypography.labelM.copyWith(
            color: c.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          netStr,
          style: AppTypography.labelM
              .copyWith(color: netColor, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onDelete,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.negative.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline_rounded,
                    size: 14, color: AppColors.negative),
                const SizedBox(width: 4),
                Text(
                  'Eliminar',
                  style: AppTypography.labelS.copyWith(
                      color: AppColors.negative, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Day header ────────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.label,
    required this.net,
    required this.currency,
  });

  final String label;
  final double net;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isPos = net >= 0;
    final netColor = isPos ? AppColors.positive : AppColors.negative;
    final netStr =
        '${isPos ? '+' : '-'}$currency${net.abs().toStringAsFixed(0)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelM.copyWith(
            color: c.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          netStr,
          style: AppTypography.labelM
              .copyWith(color: netColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
