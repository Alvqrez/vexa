import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/id_gen.dart';
import '../../domain/models/recurring_transaction.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../providers/home_provider.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final recurringListProvider =
    StateNotifierProvider<_RecurringListNotifier, List<RecurringTransaction>>(
  (ref) => _RecurringListNotifier(),
);

class _RecurringListNotifier
    extends StateNotifier<List<RecurringTransaction>> {
  _RecurringListNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    state = await RecurringTransaction.loadAll();
  }

  Future<void> add(RecurringTransaction r) async {
    state = [r, ...state];
    await RecurringTransaction.saveAll(state);
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await RecurringTransaction.saveAll(state);
  }

  Future<void> update(RecurringTransaction r) async {
    state = state.map((x) => x.id == r.id ? r : x).toList();
    await RecurringTransaction.saveAll(state);
  }

  Future<void> refresh() async => state = await RecurringTransaction.loadAll();
}

// ── Page ──────────────────────────────────────────────────────────────────────

class RecurringTransactionsPage extends ConsumerWidget {
  const RecurringTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = ref.watch(recurringListProvider);
    final currency = ref.watch(currencySymbolProvider);
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, AppSpacing.lg,
                  AppSpacing.screenPadding, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: c.glass,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: c.glassBorder, width: 0.5),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 18, color: c.textSecondary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Transacciones recurrentes',
                        style: AppTypography.headingS
                            .copyWith(color: c.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => _showFormSheet(context, ref, accounts),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.emeraldSurface,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: AppColors.emeraldGlow, width: 0.5),
                      ),
                      child: const Icon(Icons.add_rounded,
                          size: 20, color: AppColors.emerald),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Text(
                'Se registran automáticamente cuando abres la app.',
                style: AppTypography.labelM
                    .copyWith(color: c.textTertiary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat_rounded,
                              size: 40, color: c.textTertiary),
                          const SizedBox(height: AppSpacing.md),
                          Text('Sin transacciones recurrentes',
                              style: AppTypography.labelL
                                  .copyWith(color: c.textTertiary)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Toca + para agregar una.',
                              style: AppTypography.labelM
                                  .copyWith(color: c.textTertiary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding),
                      itemCount: items.length,
                      separatorBuilder: (context2, i) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final r = items[i];
                        final account = accounts
                            .where((a) => a.id == r.accountId)
                            .firstOrNull;
                        return _RecurringItemRow(
                          item: r,
                          account: account,
                          currency: currency,
                          onEdit: () => _showFormSheet(context, ref, accounts,
                              existing: r),
                          onDelete: () => ref
                              .read(recurringListProvider.notifier)
                              .remove(r.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormSheet(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts, {
    RecurringTransaction? existing,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) =>
          _RecurringFormSheet(accounts: accounts, existing: existing),
    ).then((_) => ref.read(recurringListProvider.notifier).refresh());
  }
}

// ── Row widget ────────────────────────────────────────────────────────────────

class _RecurringItemRow extends ConsumerWidget {
  const _RecurringItemRow({
    required this.item,
    required this.account,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringTransaction item;
  final Account? account;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _freqLabel() {
    final f = item.frequency.label.toLowerCase();
    final t = item.timesPerOccurrence;
    final d = item.weekDays;
    final daysLabel = d != null ? ' (${_daysStr(d)})' : '';
    return '$f${t > 1 ? ' × $t' : ''}$daysLabel';
  }

  String _daysStr(List<int> days) {
    const names = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return days.map((d) => (d >= 1 && d <= 7) ? names[d] : '?').join('-');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(walletCategoriesProvider);
    final cat = resolveCategory(item.category, cats);
    final isIncome = item.type == TransactionType.income.name;

    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: cat.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat.icon, size: 18, color: cat.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.merchant,
                    style: AppTypography.labelL
                        .copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(_freqLabel(),
                        style: AppTypography.labelS
                            .copyWith(color: c.textTertiary)),
                    if (account != null) ...[
                      Text(' · ',
                          style: TextStyle(color: c.textTertiary)),
                      Text(account!.name,
                          style: AppTypography.labelS
                              .copyWith(color: c.textTertiary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}$currency${item.amount.toStringAsFixed(2)}',
            style: AppTypography.labelL.copyWith(
              color: isIncome ? AppColors.positive : c.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _RecurringActionSheet(
                  item: item,
                  currency: currency,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              );
            },
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: c.glass,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.more_vert_rounded,
                  size: 14, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recurring action sheet ────────────────────────────────────────────────────

class _RecurringActionSheet extends ConsumerWidget {
  const _RecurringActionSheet({
    required this.item,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringTransaction item;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(walletCategoriesProvider);
    final cat = resolveCategory(item.category, cats);
    final isIncome = item.type == TransactionType.income.name;

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
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: cat.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(cat.icon, size: 22, color: cat.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.merchant,
                      style: AppTypography.headingS
                          .copyWith(color: c.textPrimary)),
                  Text(
                    '${isIncome ? '+' : '-'}$currency${item.amount.toStringAsFixed(2)}',
                    style: AppTypography.labelM
                        .copyWith(color: c.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _RecurringActionTile(
            icon: Icons.edit_rounded,
            label: 'Editar recurrente',
            color: AppColors.petroleum,
            onTap: () {
              Navigator.of(context).pop();
              onEdit();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _RecurringActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Eliminar recurrente',
            color: AppColors.negative,
            onTap: () {
              onDelete();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _RecurringActionTile extends StatelessWidget {
  const _RecurringActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.labelL.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Form sheet (create / edit) ────────────────────────────────────────────────

class _RecurringFormSheet extends ConsumerStatefulWidget {
  const _RecurringFormSheet({required this.accounts, this.existing});
  final List<Account> accounts;
  final RecurringTransaction? existing;

  @override
  ConsumerState<_RecurringFormSheet> createState() =>
      _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late TransactionType _type;
  late WalletCategory _cat;
  late RecurrenceFrequency _freq;
  late int _times;
  late final Set<int> _weekDays;
  String? _accountId;

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.merchant ?? '');
    _amountCtrl = TextEditingController(
        text: e != null ? e.amount.toStringAsFixed(2) : '');
    _type = e != null
        ? TransactionType.values.firstWhere((t) => t.name == e.type,
            orElse: () => TransactionType.expense)
        : TransactionType.expense;
    final cats = ref.read(walletCategoriesProvider);
    _cat = e != null
        ? resolveCategory(e.category, cats)
        : cats.firstWhere((c) => c.type == WalletCategoryType.expense,
            orElse: () => cats.first);
    _freq = e?.frequency ?? RecurrenceFrequency.daily;
    _times = e?.timesPerOccurrence ?? 1;
    _weekDays = e?.weekDays != null
        ? Set<int>.from(e!.weekDays!)
        : {1, 2, 3, 4, 5};
    _accountId = e?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<int>? weekDaysValue;
    if (_freq == RecurrenceFrequency.weekly ||
        _freq == RecurrenceFrequency.daily) {
      if (_weekDays.isNotEmpty) {
        final sorted = _weekDays.toList()..sort();
        weekDaysValue = sorted;
      }
    }

    final r = RecurringTransaction(
      id: widget.existing?.id ?? generateId(),
      merchant: name,
      amount: amount,
      type: _type.name,
      category: _cat.id,
      accountId: _accountId,
      frequency: _freq,
      nextDate: widget.existing?.nextDate ?? today,
      timesPerOccurrence: _times,
      weekDays: weekDaysValue,
    );

    if (widget.existing != null) {
      ref.read(recurringListProvider.notifier).update(r);
    } else {
      ref.read(recurringListProvider.notifier).add(r);
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final showDays = _freq == RecurrenceFrequency.daily ||
        _freq == RecurrenceFrequency.weekly;
    final isEdit = widget.existing != null;

    final c = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: c.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(isEdit ? 'Editar recurrente' : 'Nueva recurrente',
                style: AppTypography.headingS
                    .copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.xxl),

            _Label('Concepto'),
            const SizedBox(height: AppSpacing.sm),
            _Field(
                controller: _nameCtrl,
                hint: 'ej. Transporte, Gimnasio…',
                icon: Icons.label_outline_rounded,
                autofocus: !isEdit),
            const SizedBox(height: AppSpacing.xl),

            _Label('Monto por vez'),
            const SizedBox(height: AppSpacing.sm),
            _Field(
                controller: _amountCtrl,
                hint: '0.00',
                icon: Icons.attach_money_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: AppSpacing.xl),

            _Label('Tipo'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: TransactionType.values.map((t) {
                final sel = t == _type;
                final color = t == TransactionType.income
                    ? AppColors.positive
                    : AppColors.negative;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _type = t);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? color.withValues(alpha: 0.12)
                            : c.glass,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                        border: Border.all(
                          color: sel
                              ? color.withValues(alpha: 0.4)
                              : c.glassBorder,
                        ),
                      ),
                      child: Text(
                          t == TransactionType.income ? 'Ingreso' : 'Gasto',
                          style: AppTypography.labelM.copyWith(
                            color: sel ? color : c.textTertiary,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Label('Categoría'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ref.watch(walletCategoriesProvider).map((c) {
                final sel = c.id == _cat.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _cat = c);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel
                          ? c.color.withValues(alpha: 0.12)
                          : context.colors.glass,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: sel
                            ? c.color.withValues(alpha: 0.4)
                            : context.colors.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon,
                            size: 12,
                            color: sel ? c.color : context.colors.textTertiary),
                        const SizedBox(width: 5),
                        Text(c.name,
                            style: AppTypography.labelS.copyWith(
                              color: sel ? c.color : context.colors.textTertiary,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Label('Frecuencia'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: RecurrenceFrequency.values.map((f) {
                final sel = f == _freq;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _freq = f);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.emeraldSurface
                          : c.glass,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: sel
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : c.glassBorder,
                      ),
                    ),
                    child: Text(f.label,
                        style: AppTypography.labelM.copyWith(
                          color:
                              sel ? AppColors.emerald : c.textTertiary,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Label('¿Cuántas veces?'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_times > 1) setState(() => _times--);
                  },
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: c.glass,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.glassBorder, width: 0.5),
                    ),
                    child: Icon(Icons.remove_rounded,
                        size: 18, color: c.textSecondary),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Text('$_times',
                    style: AppTypography.headingS
                        .copyWith(color: c.textPrimary)),
                const SizedBox(width: AppSpacing.lg),
                GestureDetector(
                  onTap: () => setState(() => _times++),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: c.glass,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.glassBorder, width: 0.5),
                    ),
                    child: Icon(Icons.add_rounded,
                        size: 18, color: c.textSecondary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                    'por ${_freq == RecurrenceFrequency.daily ? 'día' : 'semana'}',
                    style: AppTypography.labelM
                        .copyWith(color: c.textTertiary)),
              ],
            ),

            if (showDays) ...[
              const SizedBox(height: AppSpacing.xl),
              _Label('Días de la semana'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final sel = _weekDays.contains(day);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (sel) {
                            _weekDays.remove(day);
                          } else {
                            _weekDays.add(day);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 38,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.emeraldSurface
                              : c.glass,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: sel
                                ? AppColors.emerald.withValues(alpha: 0.4)
                                : c.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _dayLabels[i],
                            style: AppTypography.labelM.copyWith(
                              color: sel
                                  ? AppColors.emerald
                                  : c.textTertiary,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],

            if (widget.accounts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _Label('Cuenta'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: widget.accounts.map((a) {
                  final sel = a.id == _accountId;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _accountId = a.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel
                            ? a.color.withValues(alpha: 0.12)
                            : c.glass,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                        border: Border.all(
                          color: sel
                              ? a.color.withValues(alpha: 0.4)
                              : c.glassBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.icon.iconData,
                              size: 13,
                              color: sel ? a.color : c.textTertiary),
                          const SizedBox(width: 5),
                          Text(a.name,
                              style: AppTypography.labelM.copyWith(
                                color:
                                    sel ? a.color : c.textTertiary,
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.w400,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),

            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.emeraldDim]),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(isEdit ? 'Guardar cambios' : 'Agregar',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelL.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTypography.labelM.copyWith(
          color: context.colors.textSecondary, fontWeight: FontWeight.w600));
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.autofocus = false,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool autofocus;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        style: TextStyle(color: c.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textTertiary, fontSize: 14),
          prefixIcon: Icon(icon, size: 18, color: c.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}
