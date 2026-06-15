import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/id_gen.dart';
import '../../../../shared/widgets/drag_handle.dart';
import '../../../../shared/widgets/numeric_keypad.dart';
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
  late final ValueNotifier<String> _amountNotifier;
  late TransactionType _type;
  late WalletCategory _cat;
  late RecurrenceFrequency _freq;
  late int _times;
  late final Set<int> _weekDays;
  String? _accountId;
  bool _nameError = false;
  bool _isSubmitting = false;

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.merchant ?? '');
    _amountNotifier = ValueNotifier<String>(
        e != null ? e.amount.toStringAsFixed(2) : '');
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
    _amountNotifier.dispose();
    super.dispose();
  }

  Color get _typeColor =>
      _type == TransactionType.income ? AppColors.positive : AppColors.negative;

  void _showCategorySheet(List<WalletCategory> cats) {
    HapticFeedback.selectionClick();
    final c = context.colors;
    final bottom = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        padding: EdgeInsets.only(bottom: bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 4, AppSpacing.screenPadding, 8),
              child: Text('Categoría',
                  style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...cats.map((cat) {
                      final sel = cat.id == _cat.id;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _cat = cat);
                          Navigator.pop(context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenPadding, vertical: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? cat.color.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                          ),
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 18, color: cat.color),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(cat.name,
                                      style: AppTypography.labelL
                                          .copyWith(color: c.textPrimary))),
                              if (sel)
                                Icon(Icons.check_circle_rounded,
                                    size: 18, color: cat.color),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFrequencySheet() {
    HapticFeedback.selectionClick();
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 4, AppSpacing.screenPadding, 8),
              child: Text('Frecuencia',
                  style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            ),
            ...RecurrenceFrequency.values.map((f) {
              final sel = f == _freq;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _freq = f);
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding, vertical: 3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.emeraldSurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 18,
                          color: sel ? AppColors.emerald : c.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(f.label,
                              style: AppTypography.labelL
                                  .copyWith(color: c.textPrimary))),
                      if (sel)
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.emerald),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showAccountSheet() {
    if (widget.accounts.isEmpty) return;
    HapticFeedback.selectionClick();
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            top: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Text('Cuenta',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppSpacing.md),
            ...widget.accounts.map((a) {
              final sel = a.id == _accountId;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _accountId = a.id);
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding, vertical: 3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: sel
                        ? a.color.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: sel
                          ? a.color.withValues(alpha: 0.30)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(a.icon.iconData, size: 18, color: a.color),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(a.name,
                              style: AppTypography.labelL
                                  .copyWith(color: c.textPrimary))),
                      if (sel)
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: a.color),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountNotifier.value.replaceAll(',', '.'));
    final nameInvalid = name.isEmpty;
    final amountInvalid = amount == null || amount <= 0;
    if (nameInvalid || amountInvalid) {
      HapticFeedback.heavyImpact();
      setState(() => _nameError = nameInvalid);
      if (mounted) {
        final c = context.colors;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              nameInvalid
                  ? 'Ingresa un concepto.'
                  : 'Ingresa un monto válido mayor a cero.',
              style: AppTypography.labelM.copyWith(color: c.textPrimary)),
          backgroundColor: c.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        ));
      }
      return;
    }
    setState(() { _isSubmitting = true; _nameError = false; });
    try {
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
        await ref.read(recurringListProvider.notifier).update(r);
      } else {
        await ref.read(recurringListProvider.notifier).add(r);
      }
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final showDays = _freq == RecurrenceFrequency.daily ||
        _freq == RecurrenceFrequency.weekly;
    final isEdit = widget.existing != null;
    final c = context.colors;
    final cats = ref.watch(walletCategoriesProvider);
    final currency = ref.watch(currencySymbolProvider);
    final account =
        widget.accounts.where((a) => a.id == _accountId).firstOrNull;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom),
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
            const DragHandle(),
            Text(isEdit ? 'Editar recurrente' : 'Nueva recurrente',
                style: AppTypography.headingS.copyWith(color: c.textPrimary)),
            const SizedBox(height: 12),

            // Concepto
            _Field(
              controller: _nameCtrl,
              hint: 'ej. Transporte, Gimnasio…',
              icon: Icons.label_outline_rounded,
              autofocus: !isEdit,
              hasError: _nameError,
            ),
            const SizedBox(height: 10),

            // Tipo (ingreso / gasto)
            Row(
              children: TransactionType.values.map((t) {
                final sel = t == _type;
                final color = t == TransactionType.income
                    ? AppColors.positive
                    : AppColors.negative;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: t == TransactionType.income ? 4 : 0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _type = t);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: sel ? color.withValues(alpha: 0.12) : c.glass,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(
                            color: sel
                                ? color.withValues(alpha: 0.4)
                                : c.glassBorder,
                          ),
                        ),
                        child: Text(
                          t == TransactionType.income ? 'Ingreso' : 'Gasto',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelS.copyWith(
                            color: sel ? color : c.textTertiary,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Chips (izq) | Monto (der)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RecChip(
                        icon: _cat.icon,
                        label: _cat.name,
                        color: _cat.color,
                        onTap: () => _showCategorySheet(cats),
                      ),
                      const SizedBox(height: 6),
                      _RecChip(
                        icon: Icons.repeat_rounded,
                        label: _freq.label,
                        color: AppColors.emerald,
                        onTap: _showFrequencySheet,
                      ),
                      if (widget.accounts.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _RecChip(
                          icon: account?.icon.iconData ??
                              Icons.account_balance_wallet_rounded,
                          label: account?.name ?? 'Sin cuenta',
                          color: account?.color ?? c.textTertiary,
                          onTap: _showAccountSheet,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<String>(
                  valueListenable: _amountNotifier,
                  builder: (_, raw, _) {
                    final split = splitAmount(raw.isEmpty ? '0' : raw);
                    return Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(currency,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _typeColor.withValues(alpha: 0.65),
                                      height: 1)),
                            ),
                            const SizedBox(width: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(split.integer,
                                    style: TextStyle(
                                        fontSize: 46,
                                        fontWeight: FontWeight.w800,
                                        color: _typeColor,
                                        letterSpacing: -1.5,
                                        height: 1)),
                                Text(split.decimal,
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: _typeColor.withValues(alpha: 0.45),
                                        letterSpacing: -0.5,
                                        height: 1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            if (showDays) ...[
              const SizedBox(height: 12),
              // Veces por día/semana
              Row(
                children: [
                  _Label('Veces por ${_freq == RecurrenceFrequency.daily ? 'día' : 'semana'}'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (_times > 1) setState(() => _times--);
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: c.glass,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: c.glassBorder, width: 0.5),
                      ),
                      child: Icon(Icons.remove_rounded,
                          size: 16, color: c.textSecondary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('$_times',
                        style: AppTypography.headingS
                            .copyWith(color: c.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _times++),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: c.glass,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: c.glassBorder, width: 0.5),
                      ),
                      child: Icon(Icons.add_rounded,
                          size: 16, color: c.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Label('Días'),
              const SizedBox(height: 6),
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
                        height: 34,
                        decoration: BoxDecoration(
                          color: sel ? AppColors.emeraldSurface : c.glass,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: sel
                                ? AppColors.emerald.withValues(alpha: 0.4)
                                : c.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(_dayLabels[i],
                              style: AppTypography.labelM.copyWith(
                                color: sel ? AppColors.emerald : c.textTertiary,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w400,
                              )),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],

            const SizedBox(height: 8),

            ValueListenableBuilder<String>(
              valueListenable: _amountNotifier,
              builder: (_, raw, _) => NumericKeypad(
                value: raw,
                onValueChanged: (v) => _amountNotifier.value = v,
                confirmColor: _typeColor,
                onConfirm: _submit,
                keyHeight: 44,
                confirmHeight: 48,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _RecChip extends StatelessWidget {
  const _RecChip({
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: color)),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded,
                size: 13, color: color.withValues(alpha: 0.7)),
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
    this.hasError = false,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool autofocus;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: hasError ? AppColors.negative.withValues(alpha: 0.06) : c.glass,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: hasError ? AppColors.negative.withValues(alpha: 0.5) : c.glassBorder,
          width: hasError ? 1.0 : 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,

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
