import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../providers/home_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.existing,
    this.defaultType = TransactionType.expense,
    this.scrollController,
  });

  final Transaction? existing;
  final TransactionType defaultType;
  final ScrollController? scrollController;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionType _type;
  late TransactionCategory _category;
  String? _selectedAccountId;

  final _amountController = TextEditingController();

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
      _amountController.text = e.amount.toStringAsFixed(2);
      _selectedAccountId = e.accountId;
    } else {
      final accounts = ref.read(accountsProvider);
      final wallet =
          accounts.where((a) => a.icon == AccountIcon.wallet).firstOrNull;
      _selectedAccountId = wallet?.id ?? accounts.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (_selectedAccountId == null) {
      HapticFeedback.heavyImpact();
      _showAccountRequiredSnack();
      return;
    }

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        merchant: _category.label,
        amount: amount,
        type: _type,
        category: _category,
        accountId: _selectedAccountId,
        clearNote: true,
        tags: const [],
      );
      ref
          .read(transactionsProvider.notifier)
          .update(updated, widget.existing!);
    } else {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        merchant: _category.label,
        amount: amount,
        type: _type,
        category: _category,
        date: DateTime.now(),
        accountId: _selectedAccountId,
      );
      ref.read(transactionsProvider.notifier).add(transaction);
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  void _showAccountRequiredSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Selecciona una cuenta'),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final accounts = ref.watch(accountsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          Flexible(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xs,
                AppSpacing.screenPadding,
                AppSpacing.xxl + bottom,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetHeader(
                      isEditing: _isEditing,
                      type: _type,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _TypeToggle(
                      selected: _type,
                      onChanged: (t) => setState(() {
                        _type = t;
                        _category = t == TransactionType.income
                            ? TransactionCategory.salary
                            : TransactionCategory.other;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _AmountField(
                      controller: _amountController,
                      type: _type,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CategoryPicker(
                      selected: _category,
                      type: _type,
                      onChanged: (c) => setState(() => _category = c),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AccountPicker(
                      accounts: accounts,
                      selectedId: _selectedAccountId,
                      onChanged: (id) =>
                          setState(() => _selectedAccountId = id),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _SaveButton(
                      type: _type,
                      isEditing: _isEditing,
                      onTap: _submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.isEditing,
    required this.type,
    required this.onClose,
  });

  final bool isEditing;
  final TransactionType type;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          isEditing ? 'Editar transacción' : 'Nueva transacción',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.glassMedium,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Type toggle ───────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.selected, required this.onChanged});

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Gasto',
            icon: Icons.arrow_downward_rounded,
            active: selected == TransactionType.expense,
            activeColor: AppColors.negative,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _ToggleOption(
            label: 'Ingreso',
            icon: Icons.arrow_upward_rounded,
            active: selected == TransactionType.income,
            activeColor: AppColors.positive,
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 4),
            border: active
                ? Border.all(
                    color: activeColor.withValues(alpha: 0.30), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? activeColor : AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: active ? activeColor : AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Amount field ──────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.type,
  });

  final TextEditingController controller;
  final TransactionType type;

  Color get _accentColor =>
      type == TransactionType.expense ? AppColors.negative : AppColors.positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '\$',
            style: TextStyle(
              color: _accentColor,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
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
    final cats = _categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: cats.map((c) {
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
                    Icon(
                      c.icon,
                      size: 14,
                      color: isSelected ? c.color : AppColors.textTertiary,
                    ),
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
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cuenta',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
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
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
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
        ),
      ],
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  const _SaveButton({
    required this.type,
    required this.isEditing,
    required this.onTap,
  });

  final TransactionType type;
  final bool isEditing;
  final VoidCallback onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Color get _color => widget.type == TransactionType.expense
      ? AppColors.negative
      : AppColors.positive;

  Color get _colorDim => widget.type == TransactionType.expense
      ? AppColors.negative.withValues(alpha: 0.75)
      : AppColors.emeraldDim;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) => _press.forward(),
      onTapCancel: () => _press.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _press,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_color, _colorDim],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.28),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.isEditing ? 'Guardar cambios' : 'Guardar',
            style: const TextStyle(
              color: AppColors.textInverse,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
