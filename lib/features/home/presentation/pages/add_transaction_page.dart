import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../providers/home_provider.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../../shared/widgets/numeric_keypad.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.existing,
    this.defaultType = TransactionType.expense,
  });

  final Transaction? existing;
  final TransactionType defaultType;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionType _type;
  late TransactionCategory _category;
  String? _selectedAccountId;

  // Amount managed as a string — driven by NumericKeypad
  String _amountStr = '';

  final _merchantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.defaultType;
    _category = e?.category ??
        (_type == TransactionType.income
            ? TransactionCategory.salary
            : TransactionCategory.other);

    if (e != null) {
      _amountStr = e.amount.toStringAsFixed(2);
      _selectedAccountId = e.accountId;
      _merchantCtrl.text = e.merchant;
      _noteCtrl.text = e.note ?? '';
    } else {
      final accounts = ref.read(accountsProvider);
      final wallet =
          accounts.where((a) => a.icon == AccountIcon.wallet).firstOrNull;
      _selectedAccountId = wallet?.id ?? accounts.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    if (_amountStr.isEmpty) return null;
    return double.tryParse(_amountStr);
  }

  void _submit() {
    final amount = _parsedAmount;
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      _showError('Ingresa un monto válido');
      return;
    }
    if (_selectedAccountId == null) {
      HapticFeedback.heavyImpact();
      _showError('Selecciona una cuenta');
      return;
    }

    final merchant = _merchantCtrl.text.trim().isEmpty
        ? _category.label
        : _merchantCtrl.text.trim();
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        merchant: merchant,
        amount: amount,
        type: _type,
        category: _category,
        accountId: _selectedAccountId,
        note: note,
        tags: const [],
      );
      ref.read(transactionsProvider.notifier).update(updated, widget.existing!);
    } else {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        merchant: merchant,
        amount: amount,
        type: _type,
        category: _category,
        date: DateTime.now(),
        accountId: _selectedAccountId,
        note: note,
      );
      ref.read(transactionsProvider.notifier).add(transaction);
      ref.read(streakProvider.notifier).recordTransaction();
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
    );
  }

  Color get _typeColor =>
      _type == TransactionType.expense ? AppColors.negative : AppColors.positive;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      // Pad bottom so content clears safe area + any extra bottom inset
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          const _DragHandle(),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, AppSpacing.xs,
              AppSpacing.screenPadding, 0,
            ),
            child: Row(
              children: [
                // Type badge (replaces toggle — type comes from FAB selection)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                    border: Border.all(
                        color: _typeColor.withValues(alpha: 0.30), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _type == TransactionType.expense
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 12,
                        color: _typeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _type == TransactionType.expense ? 'Gasto' : 'Ingreso',
                        style: TextStyle(
                          color: _typeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _isEditing ? 'Editar transacción' : 'Nueva transacción',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : const Color(0xFF5A5A7A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.glassMedium,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // ── Amount display ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.lg,
            ),
            child: _AmountDisplay(
              value: _amountStr,
              typeColor: _typeColor,
              currencySymbol: currency,
            ),
          ),

          // ── Scrollable fields ─────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Merchant / Description
                  _SectionLabel('Descripción'),
                  const SizedBox(height: AppSpacing.sm),
                  _FormField(
                    controller: _merchantCtrl,
                    hint: _category.label,
                    icon: Icons.storefront_rounded,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Category
                  _SectionLabel('Categoría'),
                  const SizedBox(height: AppSpacing.sm),
                  _CategoryPicker(
                    selected: _category,
                    type: _type,
                    onChanged: (c) => setState(() => _category = c),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Account
                  _SectionLabel('Cuenta'),
                  const SizedBox(height: AppSpacing.sm),
                  _AccountPicker(
                    accounts: accounts,
                    selectedId: _selectedAccountId,
                    onChanged: (id) =>
                        setState(() => _selectedAccountId = id),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Notes
                  _SectionLabel('Notas (opcional)'),
                  const SizedBox(height: AppSpacing.sm),
                  _NotesField(controller: _noteCtrl),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),

          // ── Keypad ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, 0,
              AppSpacing.screenPadding, AppSpacing.md,
            ),
            child: NumericKeypad(
              value: _amountStr,
              onValueChanged: (v) => setState(() => _amountStr = v),
              onConfirm: _submit,
              confirmColor: _typeColor,
              currencySymbol: currency,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drag handle ───────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.glassBorderStrong,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          ),
        ),
      ),
    );
  }
}

// ── Amount display ────────────────────────────────────────────────────────────

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({
    required this.value,
    required this.typeColor,
    required this.currencySymbol,
  });

  final String value;
  final Color typeColor;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? '0' : value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          currencySymbol,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: typeColor.withValues(alpha: 0.70),
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          display,
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w800,
            color: typeColor,
            letterSpacing: -2,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── Form field (merchant) ─────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
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

// ── Notes field ───────────────────────────────────────────────────────────────

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        minLines: 1,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'ej. Comida con amigos, pago de libros…',
          hintStyle:
              TextStyle(color: AppColors.textTertiary, fontSize: 14),
          prefixIcon: Icon(Icons.notes_rounded, size: 18, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}

// ── Category picker ───────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.selected,
    required this.type,
    required this.onChanged,
  });

  final TransactionCategory selected;
  final TransactionType type;
  final ValueChanged<TransactionCategory> onChanged;

  List<TransactionCategory> get _categories =>
      type == TransactionType.income
          ? [TransactionCategory.salary, TransactionCategory.other]
          : TransactionCategory.values
              .where((c) => c != TransactionCategory.salary)
              .toList();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _categories.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(c);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? c.surface : AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              border: Border.all(
                color: isSelected
                    ? c.color.withValues(alpha: 0.40)
                    : AppColors.glassBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon,
                    size: 14,
                    color: isSelected ? c.color : AppColors.textTertiary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  c.label,
                  style: TextStyle(
                    color: isSelected ? c.color : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Account picker ────────────────────────────────────────────────────────────

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: accounts.map((account) {
        final isSelected = account.id == selectedId;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: account == accounts.last ? 0 : AppSpacing.sm,
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(account.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? account.color.withValues(alpha: 0.12)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: isSelected
                        ? account.color.withValues(alpha: 0.40)
                        : AppColors.glassBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      account.icon.iconData,
                      size: 20,
                      color: isSelected
                          ? account.color
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.name,
                      style: TextStyle(
                        color: isSelected
                            ? account.color
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
