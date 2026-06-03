import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/id_gen.dart';
import '../../domain/models/recurring_transaction.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../providers/home_provider.dart';

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

  Future<void> refresh() async => state = await RecurringTransaction.loadAll();
}

// ── Page ──────────────────────────────────────────────────────────────────────

class RecurringTransactionsPage extends ConsumerWidget {
  const RecurringTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recurringListProvider);
    final currency = ref.watch(currencySymbolProvider);
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                        color: AppColors.glassLight,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: AppColors.glassBorder, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Transacciones recurrentes',
                        style: AppTypography.headingS
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => _showAddSheet(context, ref, accounts),
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
                    .copyWith(color: AppColors.textTertiary),
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
                              size: 40, color: AppColors.textTertiary),
                          const SizedBox(height: AppSpacing.md),
                          Text('Sin transacciones recurrentes',
                              style: AppTypography.labelL
                                  .copyWith(color: AppColors.textTertiary)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Toca + para agregar una.',
                              style: AppTypography.labelM
                                  .copyWith(color: AppColors.textTertiary)),
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

  void _showAddSheet(
      BuildContext context, WidgetRef ref, List<Account> accounts) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _AddRecurringSheet(accounts: accounts),
    ).then((_) =>
        ref.read(recurringListProvider.notifier).refresh());
  }
}

// ── Row widget ────────────────────────────────────────────────────────────────

class _RecurringItemRow extends StatelessWidget {
  const _RecurringItemRow({
    required this.item,
    required this.account,
    required this.currency,
    required this.onDelete,
  });

  final RecurringTransaction item;
  final Account? account;
  final String currency;
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
  Widget build(BuildContext context) {
    final cat = TransactionCategory.values.firstWhere(
      (c) => c.name == item.category,
      orElse: () => TransactionCategory.other,
    );
    final isIncome = item.type == TransactionType.income.name;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.negative.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.negative, size: 22),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
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
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(_freqLabel(),
                          style: AppTypography.labelS
                              .copyWith(color: AppColors.textTertiary)),
                      if (account != null) ...[
                        const Text(' · ',
                            style:
                                TextStyle(color: AppColors.textTertiary)),
                        Text(account!.name,
                            style: AppTypography.labelS.copyWith(
                                color: AppColors.textTertiary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}$currency${item.amount.toStringAsFixed(2)}',
              style: AppTypography.labelL.copyWith(
                color: isIncome ? AppColors.positive : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add sheet ─────────────────────────────────────────────────────────────────

class _AddRecurringSheet extends ConsumerStatefulWidget {
  const _AddRecurringSheet({required this.accounts});
  final List<Account> accounts;

  @override
  ConsumerState<_AddRecurringSheet> createState() =>
      _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  TransactionCategory _cat = TransactionCategory.transport;
  RecurrenceFrequency _freq = RecurrenceFrequency.daily;
  int _times = 1;
  final Set<int> _weekDays = {1, 2, 3, 4, 5}; // Mon–Fri default
  String? _accountId;

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    if (widget.accounts.isNotEmpty) {
      _accountId = widget.accounts.first.id;
    }
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
        final sorted = _weekDays.toList();
        sorted.sort();
        weekDaysValue = sorted;
      }
    }

    final r = RecurringTransaction(
      id: generateId(),
      merchant: name,
      amount: amount,
      type: _type.name,
      category: _cat.name,
      accountId: _accountId,
      frequency: _freq,
      nextDate: today,
      timesPerOccurrence: _times,
      weekDays: weekDaysValue,
    );

    RecurringTransaction.loadAll().then((all) {
      all.add(r);
      RecurringTransaction.saveAll(all);
    });

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final showDays = _freq == RecurrenceFrequency.daily ||
        _freq == RecurrenceFrequency.weekly;

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxl + bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Nueva recurrente',
                style: AppTypography.headingS
                    .copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xxl),

            // Concept
            _Label('Concepto'),
            const SizedBox(height: AppSpacing.sm),
            _Field(controller: _nameCtrl, hint: 'ej. Transporte, Gimnasio…',
                icon: Icons.label_outline_rounded, autofocus: true),
            const SizedBox(height: AppSpacing.xl),

            // Amount
            _Label('Monto por vez'),
            const SizedBox(height: AppSpacing.sm),
            _Field(
                controller: _amountCtrl,
                hint: '0.00',
                icon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: AppSpacing.xl),

            // Type
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
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                        border: Border.all(
                          color: sel
                              ? color.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                          t == TransactionType.income ? 'Ingreso' : 'Gasto',
                          style: AppTypography.labelM.copyWith(
                            color: sel ? color : AppColors.textTertiary,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Category
            _Label('Categoría'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: TransactionCategory.values.map((c) {
                final sel = c == _cat;
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
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: sel
                            ? c.color.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 12, color: sel ? c.color : AppColors.textTertiary),
                        const SizedBox(width: 5),
                        Text(c.label,
                            style: AppTypography.labelS.copyWith(
                              color: sel ? c.color : AppColors.textTertiary,
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

            // Frequency
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
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.pillRadius),
                      border: Border.all(
                        color: sel
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(f.label,
                        style: AppTypography.labelM.copyWith(
                          color: sel
                              ? AppColors.emerald
                              : AppColors.textTertiary,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Times per occurrence
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
                      color: AppColors.glassLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.glassBorder, width: 0.5),
                    ),
                    child: const Icon(Icons.remove_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Text('$_times',
                    style: AppTypography.headingS
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(width: AppSpacing.lg),
                GestureDetector(
                  onTap: () => setState(() => _times++),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.glassLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.glassBorder, width: 0.5),
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('por ${_freq == RecurrenceFrequency.daily ? 'día' : 'semana'}',
                    style: AppTypography.labelM
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),

            // Days of week (shown for daily and weekly)
            if (showDays) ...[
              const SizedBox(height: AppSpacing.xl),
              _Label('Días de la semana'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: List.generate(7, (i) {
                  final day = i + 1; // 1=Mon…7=Sun
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
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                        height: 38,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.emeraldSurface
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: sel
                                ? AppColors.emerald.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _dayLabels[i],
                            style: AppTypography.labelM.copyWith(
                              color: sel
                                  ? AppColors.emerald
                                  : AppColors.textTertiary,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],

            // Account
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
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                        border: Border.all(
                          color: sel
                              ? a.color.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(a.icon.iconData,
                              size: 13,
                              color: sel ? a.color : AppColors.textTertiary),
                          const SizedBox(width: 5),
                          Text(a.name,
                              style: AppTypography.labelM.copyWith(
                                color: sel ? a.color : AppColors.textTertiary,
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

            // Submit
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.emerald, AppColors.emeraldDim]),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text('Agregar',
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
          color: AppColors.textSecondary, fontWeight: FontWeight.w600));
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}
