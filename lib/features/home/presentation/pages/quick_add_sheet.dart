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
import '../../domain/models/transaction.dart';
import '../../domain/models/account.dart';
import '../providers/home_provider.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/domain/models/subcategory.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/providers/subcategories_provider.dart';
import '../../../wallet/presentation/widgets/subcategory_form_sheet.dart';
import '../../../../shared/widgets/numeric_keypad.dart';
import '../../../../shared/widgets/drag_handle.dart';
import '../../../../core/utils/amount_formatter.dart';

/// Resultado que QuickAddSheet devuelve al pop para que el shell maneje el flujo.
sealed class QuickAddOutcome {
  const QuickAddOutcome();
}

/// La transacción fue guardada correctamente.
class QuickAddSaved extends QuickAddOutcome {
  const QuickAddSaved();
}

/// El usuario intentó confirmar sin categoría; el shell debe abrir el picker.
class QuickAddNeedsCategory extends QuickAddOutcome {
  const QuickAddNeedsCategory(this.amount);
  final String amount;
}

/// Registro rápido: monto → categoría → guardar en 2-3 interacciones.
/// La fecha es hoy, la cuenta es la última usada y el tipo por defecto es gasto.
class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({
    super.key,
    this.initialType = TransactionType.expense,
    this.initialCategoryId,
    this.initialSubcategoryId,
    this.initialAmount,
    this.initialAccountId,
    this.onTransfer,
    this.onGoal,
    this.onSubscription,
    this.onMoreDetails,
  });

  final TransactionType initialType;
  final String? initialCategoryId;
  final String? initialSubcategoryId;
  final String? initialAmount;
  final String? initialAccountId;

  /// Accesos secundarios — el shell inyecta los flujos existentes.
  final VoidCallback? onTransfer;
  final VoidCallback? onGoal;
  final VoidCallback? onSubscription;

  /// Abre el formulario completo con el estado actual (monto, categoría,
  /// subcategoría y tipo).
  final void Function(
    TransactionType type,
    String amount,
    String? categoryId,
    String? subcategoryId,
  )? onMoreDetails;

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  late TransactionType _type;
  final _amountNotifier = ValueNotifier<String>('');
  String? _categoryId;
  String? _subcategoryId;
  String? _accountId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _categoryId = widget.initialCategoryId;
    _subcategoryId = widget.initialSubcategoryId;
    if (widget.initialAmount != null && widget.initialAmount!.isNotEmpty) {
      _amountNotifier.value = widget.initialAmount!;
    }
    final accounts = ref.read(accountsProvider);
    final candidateId = widget.initialAccountId;
    if (candidateId != null && accounts.any((a) => a.id == candidateId)) {
      _accountId = candidateId;
    } else {
      _accountId = accounts.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _amountNotifier.dispose();
    super.dispose();
  }

  /// Selector rápido de subcategoría al mantener presionado un chip.
  Future<void> _showSubcategorySheetFor(WalletCategory cat) async {
    HapticFeedback.mediumImpact();
    final subs = ref.read(subcategoriesByCategoryProvider(cat.id));
    final c = context.colors;
    final selected = await showModalBottomSheet<Object?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadiusL)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).padding.bottom + AppSpacing.lg,
          top: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Row(
                children: [
                  Icon(cat.icon, size: 16, color: cat.color),
                  const SizedBox(width: 6),
                  Text(cat.name,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _SubChip(
                    icon: cat.icon,
                    label: 'Sin subcategoría',
                    color: c.textTertiary,
                    selected: _subcategoryId == null,
                    onTap: () => Navigator.of(sheetCtx).pop('none'),
                  ),
                  ...subs.map((s) => _SubChip(
                        icon: s.icon,
                        label: s.name,
                        color: s.effectiveColor(cat.color),
                        selected: _subcategoryId == s.id,
                        onTap: () => Navigator.of(sheetCtx).pop(s),
                      )),
                  _SubChip(
                    icon: Icons.add_rounded,
                    label: 'Nueva',
                    color: cat.color,
                    selected: false,
                    outlined: true,
                    onTap: () => Navigator.of(sheetCtx).pop('create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (selected == 'none') {
      setState(() {
        _categoryId = cat.id;
        _subcategoryId = null;
      });
    } else if (selected == 'create') {
      final created = await SubcategoryFormSheet.show(context, category: cat);
      if (created != null && mounted) {
        setState(() {
          _categoryId = cat.id;
          _subcategoryId = created.id;
        });
      }
    } else if (selected is Subcategory) {
      setState(() {
        _categoryId = cat.id;
        _subcategoryId = selected.id;
      });
    }
  }

  List<WalletCategory> _categoriesFor(TransactionType type) {
    final catType = type == TransactionType.income
        ? WalletCategoryType.income
        : WalletCategoryType.expense;
    return ref
        .read(walletCategoriesProvider)
        .where((c) => c.type == catType)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  WalletCategory? get _selectedCategory {
    if (_categoryId == null) return null;
    return _categoriesFor(_type).where((c) => c.id == _categoryId).firstOrNull;
  }

  Color get _typeColor =>
      _type == TransactionType.expense ? AppColors.negative : AppColors.positive;

  void _switchType(TransactionType type) {
    if (_type == type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      _categoryId = null; // re-resolverá al primer chip del nuevo tipo
      _subcategoryId = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final amountStr = _amountNotifier.value;
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto mayor a cero')),
      );
      return;
    }
    final cat = _selectedCategory;
    if (cat == null) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(QuickAddNeedsCategory(amountStr));
      return;
    }

    _isSubmitting = true;
    try {
      // Capture navigator before async gaps.
      final navigator = Navigator.of(context);

      // Validar que la subcategoría siga existiendo y pertenezca a la categoría.
      final sub = resolveSubcategory(
          _subcategoryId, ref.read(subcategoriesProvider));
      final validSub = sub != null && sub.categoryId == cat.id ? sub : null;

      final transaction = Transaction(
        id: generateId(),
        merchant: validSub?.name ?? cat.name,
        amount: amount,
        type: _type,
        category: cat.id,
        subcategoryId: validSub?.id,
        date: DateTime.now(),
        accountId: _accountId,
      );
      await ref.read(transactionsProvider.notifier).add(transaction);
      await ref.read(streakProvider.notifier).recordTransaction();

      if (_accountId != null) {
        await LocalPrefsService.setString('last_account_id', _accountId!);
      }

      HapticFeedback.mediumImpact();
      if (!mounted) return;
      // Mark this transaction for flash animation in the list.
      ref.read(newTransactionIdsProvider.notifier).state = {transaction.id};
      navigator.pop(const QuickAddSaved());
      // Pulse the FAB as haptic-visual confirmation.
      ref.read(fabPulseProvider.notifier).state++;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openCategorySheet() {
    HapticFeedback.selectionClick();
    final cats = _categoriesFor(_type);
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding, 4, AppSpacing.screenPadding, 12),
              child: Text('Categoría',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((cat) {
                  final sel = cat.id == _categoryId;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_categoryId != cat.id) _subcategoryId = null;
                        _categoryId = cat.id;
                      });
                      Navigator.pop(context);
                    },
                    onLongPress: () {
                      Navigator.pop(context);
                      _showSubcategorySheetFor(cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? cat.surface : c.glass,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.pillRadius),
                        border: Border.all(
                          color: sel
                              ? cat.color.withValues(alpha: 0.45)
                              : c.glassBorder,
                          width: sel ? 1 : 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon,
                              size: 14,
                              color: sel ? cat.color : c.textTertiary),
                          const SizedBox(width: 5),
                          Text(cat.name,
                              style: TextStyle(
                                color: sel ? cat.color : c.textSecondary,
                                fontSize: 13,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _openAccountPicker() {
    HapticFeedback.selectionClick();
    final accounts = ref.read(accountsProvider);
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
          top: AppSpacing.lg,
        ),
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
            ...accounts.map((a) {
              final sel = a.id == _accountId;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _accountId = a.id);
                  Navigator.of(context).pop();
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
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(a.name,
                            style: AppTypography.labelL
                                .copyWith(color: c.textPrimary)),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final currency = ref.watch(currencySymbolProvider);
    final accounts = ref.watch(accountsProvider);
    // watch para que los chips reaccionen a cambios de categorías
    ref.watch(walletCategoriesProvider);
    final selected = _selectedCategory;
    final account = accounts.where((a) => a.id == _accountId).firstOrNull;
    final activeSub = selected != null
        ? resolveSubcategory(_subcategoryId, ref.watch(subcategoriesProvider))
        : null;
    final showSub = activeSub != null && activeSub.categoryId == selected?.id;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          const DragHandle(),

          // ── Header: toggle tipo + accesos secundarios ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 10, AppSpacing.screenPadding, 0),
            child: Row(
              children: [
                _TypeToggle(
                  type: _type,
                  onChanged: _switchType,
                ),
                const Spacer(),
                if (widget.onTransfer != null)
                  _MiniAction(
                    icon: Icons.compare_arrows_rounded,
                    color: AppColors.catTransport,
                    tooltip: 'Transferencia',
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onTransfer!();
                    },
                  ),
                if (widget.onGoal != null) ...[
                  const SizedBox(width: 6),
                  _MiniAction(
                    icon: Icons.flag_rounded,
                    color: AppColors.petroleum,
                    tooltip: 'Nueva meta',
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onGoal!();
                    },
                  ),
                ],
                if (widget.onSubscription != null) ...[
                  const SizedBox(width: 6),
                  _MiniAction(
                    icon: Icons.subscriptions_rounded,
                    color: AppColors.warning,
                    tooltip: 'Suscripción',
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSubscription!();
                    },
                  ),
                ],
              ],
            ),
          ),

          // ── Chips izquierda + Monto derecha ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 14, AppSpacing.screenPadding, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QChip(
                      icon: showSub
                          ? activeSub.icon
                          : (selected?.icon ?? Icons.category_rounded),
                      label: showSub
                          ? activeSub.name
                          : (selected?.name ?? 'Categoría'),
                      color: showSub
                          ? (activeSub.color ?? selected!.color)
                          : (selected?.color ?? c.textTertiary),
                      surface: showSub
                          ? (activeSub.color ?? selected!.color)
                              .withValues(alpha: 0.12)
                          : (selected != null ? selected.surface : c.glass),
                      onTap: _openCategorySheet,
                      onLongPress: selected != null
                          ? () => _showSubcategorySheetFor(selected)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _QChip(
                      icon: account?.icon.iconData ??
                          Icons.account_balance_wallet_rounded,
                      label: account?.name ?? 'Sin cuenta',
                      color: account?.color ?? c.textTertiary,
                      surface: (account?.color ?? c.textTertiary)
                          .withValues(alpha: 0.10),
                      onTap: _openAccountPicker,
                    ),
                    if (widget.onMoreDetails != null) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final cat = _selectedCategory;
                          Navigator.of(context).pop();
                          widget.onMoreDetails!(_type, _amountNotifier.value,
                              cat?.id, _subcategoryId);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded,
                                  size: 12, color: c.textTertiary),
                              const SizedBox(width: 3),
                              Text('Más detalles',
                                  style: TextStyle(
                                    color: c.textTertiary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _amountNotifier,
                    builder: (_, amountStr, _) {
                      final split = splitAmount(amountStr);
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
                                      fontSize: 46,
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
                                      color:
                                          _typeColor.withValues(alpha: 0.45),
                                      letterSpacing: -0.5,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Keypad ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              10,
              AppSpacing.screenPadding,
              AppSpacing.sm,
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: _amountNotifier,
              builder: (_, amountStr, _) => NumericKeypad(
                value: amountStr,
                onValueChanged: (v) => _amountNotifier.value = v,
                onConfirm: _submit,
                confirmColor: _typeColor,
                currencySymbol: currency,
                keyHeight: 44,
                confirmHeight: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle Gasto / Ingreso ────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: c.glassBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem(
            context,
            label: 'Gasto',
            icon: Icons.arrow_downward_rounded,
            color: AppColors.negative,
            active: type == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _toggleItem(
            context,
            label: 'Ingreso',
            icon: Icons.arrow_upward_rounded,
            color: AppColors.positive,
            active: type == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: active ? color : c.textTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? color : c.textTertiary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de subcategoría (selector rápido) ────────────────────────────────────

class _SubChip extends StatelessWidget {
  const _SubChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : c.glass,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(
            color: selected || outlined
                ? color.withValues(alpha: 0.45)
                : c.glassBorder,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? color : c.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : c.textSecondary,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact chip para la fila izquierda ──────────────────────────────────────

class _QChip extends StatelessWidget {
  const _QChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    required this.onTap,
    this.onLongPress,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onLongPress: onLongPress,
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
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded,
                size: 13, color: color.withValues(alpha: 0.70)),
          ],
        ),
      ),
    );
  }
}

// ── Mini acción secundaria ────────────────────────────────────────────────────

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: color.withValues(alpha: 0.25), width: 0.5),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
