import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../../core/utils/id_gen.dart';
import '../../domain/models/recurring_transaction.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../providers/home_provider.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../../shared/widgets/numeric_keypad.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.existing,
    this.defaultType = TransactionType.expense,
    this.defaultAccountId,
  });

  final Transaction? existing;
  final TransactionType defaultType;
  /// When set, pre-selects this account without overriding with last-used.
  final String? defaultAccountId;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionType _type;
  late WalletCategory _category;
  String? _selectedAccountId;
  late DateTime _selectedDate;

  String _amountStr = '';

  final _merchantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _noteFocusNode = FocusNode();
  bool _noteExpanded = false;
  bool _isRecurring = false;
  RecurrenceFrequency _recurrenceFreq = RecurrenceFrequency.monthly;

  static const _monthNames = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = _selectedDate;
    final dateOnly = DateTime(d.year, d.month, d.day);
    if (dateOnly == today) return 'Hoy';
    if (dateOnly == yesterday) return 'Ayer';
    if (d.year == now.year) return '${d.day} ${_monthNames[d.month - 1]}';
    return '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.defaultType;
    final cats = ref.read(walletCategoriesProvider);
    final catType = _type == TransactionType.income
        ? WalletCategoryType.income
        : WalletCategoryType.expense;
    _category = e != null
        ? resolveCategory(e.category, cats)
        : cats.firstWhere((c) => c.type == catType, orElse: () => cats.first);

    _selectedDate = e?.date ?? DateTime.now();

    if (e != null) {
      _amountStr = e.amount.toStringAsFixed(2);
      _selectedAccountId = e.accountId;
      _noteCtrl.text = e.note ?? '';
      if (e.note != null && e.note!.isNotEmpty) _noteExpanded = true;
      _merchantCtrl.text =
          e.merchant != _category.name ? e.merchant : '';
    } else if (widget.defaultAccountId != null) {
      // Explicit account from caller — respect it, don't override with last-used.
      _selectedAccountId = widget.defaultAccountId;
    } else {
      final accounts = ref.read(accountsProvider);
      final wallet =
          accounts.where((a) => a.icon == AccountIcon.wallet).firstOrNull;
      _selectedAccountId = wallet?.id ?? accounts.firstOrNull?.id;
      // Override with last-used account — read accounts fresh after the async
      // gap to avoid using the snapshot captured in initState.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final lastId = await LocalPrefsService.getString('last_account_id');
        if (lastId != null && mounted) {
          final currentAccounts = ref.read(accountsProvider);
          if (currentAccounts.any((a) => a.id == lastId)) {
            setState(() => _selectedAccountId = lastId);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
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

  Future<void> _openDatePicker() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.emerald,
            onPrimary: Colors.white,
            surface: ctx.colors.card,
            onSurface: ctx.colors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = DateTime(
            picked.year, picked.month, picked.day,
            _selectedDate.hour, _selectedDate.minute,
          ));
    }
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
    final merchantText = _merchantCtrl.text.trim();
    final merchant = merchantText.isEmpty ? _category.name : merchantText;

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        merchant: merchant,
        amount: amount,
        type: _type,
        category: _category.id,
        date: _selectedDate,
        accountId: _selectedAccountId,
        note: note,
        tags: const [],
      );
      ref.read(transactionsProvider.notifier).update(updated, widget.existing!);
    } else {
      final transaction = Transaction(
        id: generateId(),
        merchant: merchant,
        amount: amount,
        type: _type,
        category: _category.id,
        date: _selectedDate,
        accountId: _selectedAccountId,
        note: note,
      );
      ref.read(transactionsProvider.notifier).add(transaction);
      ref.read(streakProvider.notifier).recordTransaction();
    }

    if (_selectedAccountId != null) {
      LocalPrefsService.setString('last_account_id', _selectedAccountId!);
    }
    if (!_isEditing && _isRecurring) {
      _saveRecurring();
    }

    final currency = ref.read(currencySymbolProvider);
    final isIncome = _type == TransactionType.income;
    final label = isIncome ? 'Ingreso' : 'Gasto';
    final color = isIncome ? AppColors.positive : AppColors.negative;
    final amountStr = amount >= 1000
        ? '$currency${(amount / 1000).toStringAsFixed(1)}k'
        : '$currency${amount.toStringAsFixed(2)}';
    final messenger = ScaffoldMessenger.of(context);

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, size: 15, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '$label de $amountStr ${_isEditing ? 'actualizado' : 'registrado'}',
                style: AppTypography.labelM
                    .copyWith(color: context.colors.textPrimary),
              ),
            ],
          ),
          backgroundColor: context.colors.card,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.bottomNavHeight +
                AppSpacing.bottomNavBottomPadding +
                AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
        ),
      );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.colors.cardElevated,
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
        onChanged: (wc) {
          setState(() => _category = wc);
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

  Future<void> _saveRecurring() async {
    final existing = await RecurringTransaction.loadAll();
    final now = DateTime.now();
    final next = _recurrenceFreq.nextDate(_selectedDate.isAfter(now)
        ? _selectedDate
        : DateTime(now.year, now.month, now.day, now.hour, now.minute));
    final merchantText = _merchantCtrl.text.trim();
    existing.add(RecurringTransaction(
      id: generateId(),
      merchant: merchantText.isEmpty ? _category.name : merchantText,
      amount: _parsedAmount!,
      type: _type.name,
      category: _category.id,
      accountId: _selectedAccountId,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      frequency: _recurrenceFreq,
      nextDate: next,
    ));
    await RecurringTransaction.saveAll(existing);
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
    final c = context.colors;
    final accounts = ref.watch(accountsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final selectedAccount =
        accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
    final split = _splitDisplay;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(child: Column(
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
                    color: c.textSecondary,
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
                          color: c.glassMedium,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            color: c.textSecondary, size: 16),
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
                      label: _category.name,
                      color: _category.color,
                      surface: _category.surface,
                      onTap: _openCategorySheet,
                    ),
                    const SizedBox(height: 7),
                    _CompactChip(
                      icon: selectedAccount?.icon.iconData ??
                          Icons.account_balance_wallet_rounded,
                      label: selectedAccount?.name ?? 'Sin cuenta',
                      color: selectedAccount?.color ?? c.textTertiary,
                      surface:
                          (selectedAccount?.color ?? c.textTertiary)
                              .withValues(alpha: 0.10),
                      onTap: _openAccountSheet,
                    ),
                    const SizedBox(height: 7),
                    _CompactChip(
                      icon: Icons.calendar_today_rounded,
                      label: _dateLabel,
                      color: c.textSecondary,
                      surface: c.glass,
                      onTap: _openDatePicker,
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

          // ── Merchant / concept field ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 8,
                AppSpacing.screenPadding, 0),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: c.glass,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                border: Border.all(
                    color: c.glassBorder, width: 0.5),
              ),
              child: TextField(
                controller: _merchantCtrl,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: '¿Dónde? (opcional)',
                  hintStyle: TextStyle(
                      color: c.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400),
                  prefixIcon: Icon(Icons.storefront_outlined,
                      size: 15, color: c.textTertiary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 4),
                ),
              ),
            ),
          ),

          // ── Recurring toggle ──────────────────────────────────────────────
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 6,
                  AppSpacing.screenPadding, 0),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.repeat_rounded,
                            size: 14, color: c.textTertiary),
                        const SizedBox(width: 5),
                        Text('Repetir',
                            style: TextStyle(
                                color: c.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.78,
                          child: Switch.adaptive(
                            value: _isRecurring,
                            onChanged: (v) =>
                                setState(() => _isRecurring = v),
                            activeThumbColor: AppColors.emerald,
                            activeTrackColor: AppColors.emeraldSurface,
                            inactiveThumbColor: c.textTertiary,
                            inactiveTrackColor: c.glass,
                          ),
                        ),
                      ],
                    ),
                    if (_isRecurring)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 2),
                        child: Row(
                          children: RecurrenceFrequency.values.map((f) {
                            final sel = f == _recurrenceFreq;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _recurrenceFreq = f);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.emeraldSurface
                                        : c.glass,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.pillRadius),
                                    border: Border.all(
                                      color: sel
                                          ? AppColors.emerald
                                              .withValues(alpha: 0.4)
                                          : c.glassBorder,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(f.label,
                                      style: TextStyle(
                                        color: sel
                                            ? AppColors.emerald
                                            : c.textTertiary,
                                        fontSize: 11,
                                        fontWeight: sel
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      )),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
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
      )),
    );
  }
}

// ── Drag handle ───────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: c.glassBorderStrong,
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
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 13, color: c.textTertiary),
              const SizedBox(width: 3),
              Text(
                'Nota',
                style: TextStyle(
                  color: c.textTertiary,
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
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: c.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 11),
            child: Icon(Icons.notes_rounded,
                size: 15, color: c.textTertiary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 3,
              minLines: 1,
              style: TextStyle(
                  color: c.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Añade una nota…',
                hintStyle:
                    TextStyle(color: c.textTertiary, fontSize: 13),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                alignLabelWithHint: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCollapse,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: Icon(Icons.close_rounded,
                  size: 15, color: c.textTertiary),
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
                  color: isSelected ? color : context.colors.textPrimary,
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

class _CategorySheet extends ConsumerWidget {
  const _CategorySheet({
    required this.selected,
    required this.type,
    required this.onChanged,
  });

  final WalletCategory selected;
  final TransactionType type;
  final ValueChanged<WalletCategory> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final catType = type == TransactionType.income
        ? WalletCategoryType.income
        : WalletCategoryType.expense;
    final categories = ref
        .watch(walletCategoriesProvider)
        .where((wc) => wc.type == catType)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: Text(
              'Categoría',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...categories.map((wc) => _SheetItem(
                icon: wc.icon,
                label: wc.name,
                color: wc.color,
                surface: wc.surface,
                isSelected: wc.id == selected.id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(wc);
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
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: Text(
              'Cuenta',
              style: TextStyle(
                color: c.textPrimary,
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
