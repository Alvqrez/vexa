import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/home_provider.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transfer_record.dart';
import '../../domain/models/account.dart';
import '../widgets/transaction_item.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

// ── Sort options ──────────────────────────────────────────────────────────────

enum _SortBy { dateDesc, dateAsc, amountDesc, amountAsc }

extension _SortByX on _SortBy {
  String get label => switch (this) {
        _SortBy.dateDesc => 'Más reciente',
        _SortBy.dateAsc => 'Más antiguo',
        _SortBy.amountDesc => 'Mayor monto',
        _SortBy.amountAsc => 'Menor monto',
      };
  IconData get icon => switch (this) {
        _SortBy.dateDesc => Icons.arrow_downward_rounded,
        _SortBy.dateAsc => Icons.arrow_upward_rounded,
        _SortBy.amountDesc => Icons.trending_down_rounded,
        _SortBy.amountAsc => Icons.trending_up_rounded,
      };
}

// ── Page ──────────────────────────────────────────────────────────────────────

class AllTransactionsPage extends ConsumerStatefulWidget {
  const AllTransactionsPage({super.key, this.typeFilter});

  final TransactionType? typeFilter;

  @override
  ConsumerState<AllTransactionsPage> createState() =>
      _AllTransactionsPageState();
}

class _AllTransactionsPageState extends ConsumerState<AllTransactionsPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  String? _catFilter;
  _SortBy _sort = _SortBy.dateDesc;
  bool _showSearch = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Transaction> _applyFilters(List<Transaction> all, List<WalletCategory> walletCats) {
    var list = all;

    // Type filter from parent
    if (widget.typeFilter != null) {
      list = list.where((t) => t.type == widget.typeFilter).toList();
    }

    // Category filter
    if (_catFilter != null) {
      list = list.where((t) => t.category == _catFilter).toList();
    }

    // Search: nombre, nota, categoría, etiquetas y monto
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      final qAmount = double.tryParse(q.replaceAll(',', '.'));
      list = list.where((t) {
        final catName = resolveCategory(t.category, walletCats).name.toLowerCase();
        final amountMatch = qAmount != null &&
            ((t.amount - qAmount).abs() < 0.005 ||
                t.amount.toStringAsFixed(2).startsWith(q) ||
                t.amount.toStringAsFixed(0) == q);
        return t.merchant.toLowerCase().contains(q) ||
            catName.contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q)) ||
            (t.note?.toLowerCase().contains(q) ?? false) ||
            amountMatch;
      }).toList();
    }

    // Sort
    list = List.from(list);
    switch (_sort) {
      case _SortBy.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
      case _SortBy.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
      case _SortBy.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
      case _SortBy.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
    }

    return list;
  }

  List<TransferRecord> _filterTransfers(
      List<TransferRecord> transfers, List<Account> accounts) {
    if (_query.trim().isEmpty) return transfers;
    final q = _query.toLowerCase();
    return transfers.where((tr) {
      final from = accounts
          .where((a) => a.id == tr.fromAccountId)
          .map((a) => a.name)
          .firstOrNull ?? '';
      final to = accounts
          .where((a) => a.id == tr.toAccountId)
          .map((a) => a.name)
          .firstOrNull ?? '';
      return from.toLowerCase().contains(q) ||
          to.toLowerCase().contains(q) ||
          (tr.note?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<Object> _combineAndSort(
      List<Transaction> txns, List<TransferRecord> transfers) {
    final items = <Object>[...txns, ...transfers];
    items.sort((a, b) {
      final da = a is Transaction ? a.date : (a as TransferRecord).date;
      final db = b is Transaction ? b.date : (b as TransferRecord).date;
      return _sort == _SortBy.dateAsc
          ? da.compareTo(db)
          : db.compareTo(da);
    });
    return items;
  }

  // Groups items (Transaction | TransferRecord) by date heading
  Map<String, List<Object>> _groupByDate(List<Object> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final groups = <String, List<Object>>{};
    for (final item in items) {
      final date =
          item is Transaction ? item.date : (item as TransferRecord).date;
      final day = DateTime(date.year, date.month, date.day);
      String key;
      if (day == today) {
        key = 'Hoy';
      } else if (day == today.subtract(const Duration(days: 1))) {
        key = 'Ayer';
      } else if (today.difference(day).inDays < 7) {
        final raw = DateFormat('EEEE', 'es').format(date);
        key = raw[0].toUpperCase() + raw.substring(1);
      } else {
        key = DateFormat('d MMM yyyy', 'es').format(date);
      }
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  void _showSortSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: _sort,
        onSelect: (s) => setState(() => _sort = s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = ref.watch(transactionsProvider);
    final walletCats = ref.watch(walletCategoriesProvider);
    final accounts = ref.watch(accountsProvider);
    final allTransfers = ref.watch(transferHistoryProvider);
    final filtered = _applyFilters(all, walletCats);
    final showTransfers = widget.typeFilter == null && _catFilter == null;
    final filteredTransfers = showTransfers
        ? _filterTransfers(allTransfers, accounts)
        : <TransferRecord>[];
    final combined = _combineAndSort(filtered, filteredTransfers);
    final grouped = _groupByDate(combined);

    final income = filtered
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expenses = filtered
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.petroleum.withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Fixed header + filters ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      _Header(
                        title: widget.typeFilter == TransactionType.income
                            ? 'Ingresos'
                            : widget.typeFilter == TransactionType.expense
                                ? 'Egresos'
                                : 'Transacciones',
                        count: filtered.length,
                        showSearch: _showSearch,
                        onBack: () => Navigator.of(context).pop(),
                        onSearchToggle: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) {
                              _searchCtrl.clear();
                              _focusNode.unfocus();
                            } else {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () => _focusNode.requestFocus(),
                              );
                            }
                          });
                        },
                        onSortTap: _showSortSheet,
                        sortLabel: _sort.label,
                      ),
                      // Search bar
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: _showSearch
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.md),
                                child: _SearchBar(
                                  controller: _searchCtrl,
                                  focusNode: _focusNode,
                                  onClear: () {
                                    _searchCtrl.clear();
                                    _focusNode.unfocus();
                                  },
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Summary chips
                      Row(children: [
                        Expanded(
                            child: _SummaryChip(
                                label: 'Ingresos',
                                value: '+\$${income.toStringAsFixed(0)}',
                                color: AppColors.positive)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                            child: _SummaryChip(
                                label: 'Egresos',
                                value: '-\$${expenses.toStringAsFixed(0)}',
                                color: AppColors.negative)),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      // Category filter chips
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: 'Todo',
                              selected: _catFilter == null,
                              color: AppColors.petroleum,
                              onTap: () =>
                                  setState(() => _catFilter = null),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            ...walletCats.map((cat) => Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppSpacing.sm),
                                  child: _FilterChip(
                                    label: cat.name,
                                    selected: _catFilter == cat.id,
                                    color: cat.color,
                                    onTap: () =>
                                        setState(() => _catFilter = cat.id),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Divider(
                          height: 1,
                          thickness: 0.5,
                          color: c.glassBorder),
                    ],
                  ),
                ),

                // ── Scrollable transaction list ───────────────────────────
                Expanded(
                  child: combined.isEmpty
                      ? _EmptyState(
                          hasQuery: _query.isNotEmpty || _catFilter != null)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            AppSpacing.md,
                            AppSpacing.screenPadding,
                            120,
                          ),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) =>
                              _buildGroup(context, index, grouped, accounts),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    int index,
    Map<String, List<Object>> groups,
    List<Account> accounts,
  ) {
    final c = context.colors;
    final entry = groups.entries.elementAt(index);
    final items = entry.value;
    return Column(
      key: ValueKey('group_${entry.key}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: AppSpacing.lg, bottom: AppSpacing.sm),
          child: _DateHeader(label: entry.key),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: c.glassBorder, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (items[i] is Transaction)
                  TransactionItem(
                    key: ValueKey((items[i] as Transaction).id),
                    transaction: items[i] as Transaction,
                    isLast: i == items.length - 1,
                  )
                else
                  _TransferRow(
                    key: ValueKey((items[i] as TransferRecord).id),
                    transfer: items[i] as TransferRecord,
                    accounts: accounts,
                    isLast: i == items.length - 1,
                  ),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.count,
    required this.showSearch,
    required this.onBack,
    required this.onSearchToggle,
    required this.onSortTap,
    required this.sortLabel,
  });
  final String title;
  final int count;
  final bool showSearch;
  final VoidCallback onBack;
  final VoidCallback onSearchToggle;
  final VoidCallback onSortTap;
  final String sortLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_rounded,
                size: 18, color: c.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.headingM
                      .copyWith(color: c.textPrimary)),
              Text('$count movimientos',
                  style: AppTypography.labelS
                      .copyWith(color: c.textTertiary)),
            ],
          ),
        ),
        // Sort button
        GestureDetector(
          onTap: onSortTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.glass,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.glassBorder, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded,
                    size: 14, color: c.textTertiary),
                const SizedBox(width: 4),
                Text(sortLabel.split(' ').first,
                    style: AppTypography.labelS
                        .copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Search toggle
        GestureDetector(
          onTap: onSearchToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: showSearch
                  ? AppColors.emeraldSurface
                  : c.glass,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: showSearch
                    ? AppColors.emerald.withValues(alpha: 0.3)
                    : c.glassBorder,
                width: 0.5,
              ),
            ),
            child: Icon(
              showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              size: 18,
              color: showSearch ? AppColors.emerald : c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar(
      {required this.controller,
      required this.focusNode,
      required this.onClear});
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorderStrong, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: AppTypography.bodyM.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, nota, categoría o monto…',
          hintStyle: AppTypography.bodyM.copyWith(color: c.textTertiary),
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: c.textTertiary),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close_rounded,
                      size: 16, color: c.textTertiary),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

// ── Sort sheet ────────────────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current, required this.onSelect});
  final _SortBy current;
  final ValueChanged<_SortBy> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Ordenar por',
              style: AppTypography.headingS.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xl),
          ..._SortBy.values.map((s) {
            final active = s == current;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(s);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.emeraldSurface
                      : c.glass,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: active
                        ? AppColors.emerald.withValues(alpha: 0.3)
                        : c.glassBorder,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(s.icon,
                        size: 18,
                        color: active
                            ? AppColors.emerald
                            : c.textSecondary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(s.label,
                          style: AppTypography.labelL.copyWith(
                            color: active
                                ? AppColors.emerald
                                : c.textPrimary,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    ),
                    if (active)
                      const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.emerald),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Date header ───────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Text(label,
            style: AppTypography.labelM.copyWith(
                color: c.textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: c.glassBorder,
          ),
        ),
      ],
    );
  }
}

// ── Summary chip ──────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(
      {required this.label, required this.value, required this.color});
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
        border:
            Border.all(color: color.withValues(alpha: 0.20), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.labelS
                  .copyWith(color: context.colors.textTertiary)),
          Text(value,
              style: AppTypography.headingS
                  .copyWith(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : context.colors.glass,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.35)
                : context.colors.glassBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelM.copyWith(
            color: selected ? color : context.colors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.glass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.glassBorder, width: 0.5),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: 32, color: c.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              hasQuery ? 'Sin resultados' : 'Sin movimientos',
              style: AppTypography.headingS.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasQuery
                  ? 'Prueba con otro término o limpia los filtros.'
                  : 'Registra tu primer gasto o ingreso\ncon el botón +.',
              style: AppTypography.bodyM
                  .copyWith(color: c.textTertiary, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


// ── Transfer row ──────────────────────────────────────────────────────────────

class _TransferRow extends ConsumerWidget {
  const _TransferRow({
    super.key,
    required this.transfer,
    required this.accounts,
    this.isLast = false,
  });

  final TransferRecord transfer;
  final List<Account> accounts;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final currency = ref.watch(currencySymbolProvider);
    final from = accounts
        .where((a) => a.id == transfer.fromAccountId)
        .map((a) => a.name)
        .firstOrNull ?? transfer.fromAccountId;
    final to = accounts
        .where((a) => a.id == transfer.toAccountId)
        .map((a) => a.name)
        .firstOrNull ?? transfer.toAccountId;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.petroleumSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: AppColors.petroleumLight, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transferencia',
                  style: AppTypography.bodyM.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$from → $to',
                  style: AppTypography.labelS.copyWith(color: c.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '$currency${transfer.amount.toStringAsFixed(2)}',
            style: AppTypography.labelL.copyWith(
              color: AppColors.petroleum,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}