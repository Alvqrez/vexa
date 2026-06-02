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

  String _amountStr = '';

  final _noteCtrl = TextEditingController();
  final _noteFocusNode = FocusNode();
  bool _noteExpanded = false;

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
      _noteCtrl.text = e.note ?? '';
      if (e.note != null && e.note!.isNotEmpty) _noteExpanded = true;
    } else {
      final accounts = ref.read(accountsProvider);
      final wallet =
          accounts.where((a) => a.icon == AccountIcon.wallet).firstOrNull;
      _selectedAccountId = wallet?.id ?? accounts.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    if (_amountStr.isEmpty) return null;
    return double.tryParse(_amountStr);
  }

  ({String integer, String decimal}) get _splitDisplay {
    final raw = _amountStr;
    if (raw.isEmpty) return (integer: '0', decimal: '.00');

    String intPart;
    String decPart;

    if (raw.contains('.')) {
      final idx = raw.indexOf('.');
      intPart = raw.substring(0, idx).isEmpty ? '0' : raw.substring(0, idx);
      final d = raw.substring(idx + 1);
      if (d.isEmpty) {
        decPart = '.';
      } else if (d.length == 1) {
        decPart = '.${d}0';
      } else {
        decPart = '.$d';
      }
    } else {
      intPart = raw;
      decPart = '.00';
    }

    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }

    return (integer: buf.toString(), decimal: decPart);
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

    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        merchant: _category.label,
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
        merchant: _category.label,
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

  void _openCategorySheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        selected: _category,
        type: _type,
        onChanged: (c) {
          setState(() => _category = c);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openAccountSheet() {
    HapticFeedback.selectionClick();
    final accounts = ref.read(accountsProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountSheet(
        accounts: accounts,
        selectedId: _selectedAccountId,
        onChanged: (id) {
          setState(() => _selectedAccountId = id);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _toggleNote() {
    setState(() => _noteExpanded = !_noteExpanded);
    if (_noteExpanded) {
      Future.microtask(() => _noteFocusNode.requestFocus());
    } else {
      _noteFocusNode.unfocus();
    }
  }

  Color get _typeColor =>
      _type == TransactionType.expense ? AppColors.negative : AppColors.positive;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedAccount =
        accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
    final split = _splitDisplay;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          const _DragHandle(),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, 8,
              AppSpacing.screenPadding, 0,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Title — truly centered regardless of badge/button widths
                Text(
                  _isEditing ? 'Editar transacción' : 'Nueva transacción',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : const Color(0xFF5A5A7A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Badge (left) + Close button (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                        border: Border.all(
                            color: _typeColor.withValues(alpha: 0.30),
                            width: 0.5),
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
                            _type == TransactionType.expense
                                ? 'Gasto'
                                : 'Ingreso',
                            style: TextStyle(
                              color: _typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
              ],
            ),
          ),

          // ── Compact row: [category + account] | [amount] ─────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, 12,
              AppSpacing.screenPadding, 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CompactChip(
                      icon: _category.icon,
                      label: _category.label,
                      color: _category.color,
                      surface: _category.surface,
                      onTap: _openCategorySheet,
                    ),
                    const SizedBox(height: 7),
                    _CompactChip(
                      icon: selectedAccount?.icon.iconData ??
                          Icons.account_balance_wallet_rounded,
                      label: selectedAccount?.name ?? 'Sin cuenta',
                      color: selectedAccount?.color ?? AppColors.textTertiary,
                      surface:
                          (selectedAccount?.color ?? AppColors.textTertiary)
                              .withValues(alpha: 0.10),
                      onTap: _openAccountSheet,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              currency,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _typeColor.withValues(alpha: 0.65),
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                split.integer,
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  color: _typeColor,
                                  letterSpacing: -1.5,
                                  height: 1,
                                ),
                              ),
                              Text(
                                split.decimal,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: _typeColor.withValues(alpha: 0.45),
                                  letterSpacing: -0.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Nota toggle ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, 10,
              AppSpacing.screenPadding, 0,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _noteExpanded
                  ? _ExpandedNote(
                      controller: _noteCtrl,
                      focusNode: _noteFocusNode,
                      onCollapse: _toggleNote,
                    )
                  : _NoteButton(onTap: _toggleNote),
            ),
          ),

          // ── Keypad ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, 8,
              AppSpacing.screenPadding, AppSpacing.sm,
            ),
            child: NumericKeypad(
              value: _amountStr,
              onValueChanged: (v) => setState(() => _amountStr = v),
              onConfirm: _submit,
              confirmColor: _typeColor,
              currencySymbol: currency,
              keyHeight: 42,
              confirmHeight: 46,
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

// ── Compact chip ──────────────────────────────────────────────────────────────

class _CompactChip extends StatelessWidget {
  const _CompactChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded,
                size: 13, color: color.withValues(alpha: 0.70)),
          ],
        ),
      ),
    );
  }
}

// ── Note button ("+ Nota") ────────────────────────────────────────────────────

class _NoteButton extends StatelessWidget {
  const _NoteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 13, color: AppColors.textTertiary),
              SizedBox(width: 3),
              Text(
                'Nota',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expanded note input ───────────────────────────────────────────────────────

class _ExpandedNote extends StatelessWidget {
  const _ExpandedNote({
    required this.controller,
    required this.focusNode,
    required this.onCollapse,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 11),
            child: Icon(Icons.notes_rounded,
                size: 15, color: AppColors.textTertiary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Añade una nota…',
                hintStyle:
                    TextStyle(color: AppColors.textTertiary, fontSize: 13),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                alignLabelWithHint: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCollapse,
            child: const Padding(
              padding: EdgeInsets.only(right: 8, top: 8),
              child: Icon(Icons.close_rounded,
                  size: 15, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet item ────────────────────────────────────────────────────────────────

class _SheetItem extends StatelessWidget {
  const _SheetItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: 3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.30)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Category bottom sheet ─────────────────────────────────────────────────────

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DragHandle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: Text(
              'Categoría',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ..._categories.map((c) => _SheetItem(
                icon: c.icon,
                label: c.label,
                color: c.color,
                surface: c.surface,
                isSelected: c == selected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(c);
                },
              )),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ── Account bottom sheet ──────────────────────────────────────────────────────

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DragHandle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: Text(
              'Cuenta',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...accounts.map((account) => _SheetItem(
                icon: account.icon.iconData,
                label: account.name,
                color: account.color,
                surface: account.color.withValues(alpha: 0.10),
                isSelected: account.id == selectedId,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(account.id);
                },
              )),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
