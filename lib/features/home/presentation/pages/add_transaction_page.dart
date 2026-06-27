import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/receipt_image_store.dart';
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
import '../../../wallet/domain/models/subcategory.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/providers/subcategories_provider.dart';
import '../../../wallet/presentation/widgets/subcategory_form_sheet.dart';
import '../../../../shared/widgets/numeric_keypad.dart';
import '../../../../shared/widgets/drag_handle.dart';
import '../../../../core/utils/amount_formatter.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.existing,
    this.defaultType = TransactionType.expense,
    this.defaultAccountId,
    this.initialAmount,
    this.initialCategoryId,
    this.initialSubcategoryId,
  });

  final Transaction? existing;
  final TransactionType defaultType;
  /// When set, pre-selects this account without overriding with last-used.
  final String? defaultAccountId;
  /// Carry-over state from the quick-add sheet ("Más detalles").
  final String? initialAmount;
  final String? initialCategoryId;
  final String? initialSubcategoryId;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionType _type;
  late WalletCategory _category;
  Subcategory? _subcategory;
  String? _selectedAccountId;
  late DateTime _selectedDate;

  final _amountNotifier = ValueNotifier<String>('');

  final _merchantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _noteFocusNode = FocusNode();
  bool _noteExpanded = false;
  bool _isRecurring = false;
  bool _isSubmitting = false;
  RecurrenceFrequency _recurrenceFreq = RecurrenceFrequency.monthly;

  /// Nombres de archivo de fotos adjuntas (recibos/tickets).
  final List<String> _imageNames = [];

  /// Fotos quitadas durante la edición — se borran del disco solo al guardar.
  final List<String> _removedImages = [];

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
        : widget.initialCategoryId != null
            ? resolveCategory(widget.initialCategoryId!, cats)
            : cats.firstWhere((c) => c.type == catType,
                orElse: () => cats.first);

    // Subcategoría: del existing o del carry-over; validar que pertenezca
    // a la categoría activa (puede haber sido eliminada o cambiada).
    final subId = e?.subcategoryId ?? widget.initialSubcategoryId;
    final sub = resolveSubcategory(subId, ref.read(subcategoriesProvider));
    _subcategory =
        sub != null && sub.categoryId == _category.id ? sub : null;

    _selectedDate = e?.date ?? DateTime.now();

    if (e == null &&
        widget.initialAmount != null &&
        widget.initialAmount!.isNotEmpty) {
      _amountNotifier.value = widget.initialAmount!;
    }

    if (e != null) {
      _amountNotifier.value = e.amount.toStringAsFixed(2);
      _selectedAccountId = e.accountId;
      _noteCtrl.text = e.note ?? '';
      _imageNames.addAll(e.imagePaths);
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
    }
  }

  @override
  void dispose() {
    _amountNotifier.dispose();
    _merchantCtrl.dispose();
    _noteCtrl.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  double? get _parsedAmount {
    final raw = _amountNotifier.value;
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _openDatePicker() async {
    Haptics.selectionClick();
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

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final amount = _parsedAmount;
    if (amount == null || amount <= 0) {
      Haptics.heavyImpact();
      _showError('Ingresa un monto válido');
      return;
    }
    if (_selectedAccountId == null) {
      Haptics.heavyImpact();
      _showError('Selecciona una cuenta');
      return;
    }
    _isSubmitting = true;
    try {

    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final merchantText = _merchantCtrl.text.trim();
    final merchant = merchantText.isEmpty
        ? (_subcategory?.name ?? _category.name)
        : merchantText;

    // Capturar valores de contexto antes del async gap
    final currency = ref.read(currencySymbolProvider);
    final isIncome = _type == TransactionType.income;
    final label = isIncome ? 'Ingreso' : 'Gasto';
    final color = isIncome ? AppColors.positive : AppColors.negative;
    final amountStr = amount >= 1000
        ? '$currency${(amount / 1000).toStringAsFixed(1)}k'
        : '$currency${amount.toStringAsFixed(2)}';
    final contextColors = context.colors;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        merchant: merchant,
        amount: amount,
        type: _type,
        category: _category.id,
        subcategoryId: _subcategory?.id,
        clearSubcategory: _subcategory == null,
        date: _selectedDate,
        accountId: _selectedAccountId,
        note: note,
        tags: const [],
        imagePaths: List.from(_imageNames),
      );
      await ref.read(transactionsProvider.notifier).update(updated, widget.existing!);
    } else {
      final transaction = Transaction(
        id: generateId(),
        merchant: merchant,
        amount: amount,
        type: _type,
        category: _category.id,
        subcategoryId: _subcategory?.id,
        date: _selectedDate,
        accountId: _selectedAccountId,
        note: note,
        imagePaths: List.from(_imageNames),
      );
      await ref.read(transactionsProvider.notifier).add(transaction);
      await ref.read(streakProvider.notifier).recordTransaction();
    }
    // Las fotos quitadas se borran del disco solo después de guardar.
    if (_removedImages.isNotEmpty) {
      await ReceiptImageStore.deleteAll(_removedImages);
    }

    if (_selectedAccountId != null) {
      await LocalPrefsService.setString('last_account_id', _selectedAccountId!);
    }
    if (!_isEditing && _isRecurring) {
      await _saveRecurring();
    }

    Haptics.mediumImpact();
    if (mounted) {
      navigator.pop();
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
                      .copyWith(color: contextColors.textPrimary),
                ),
              ],
            ),
            backgroundColor: contextColors.card,
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  Future<void> _openCategorySheet() async {
    Haptics.selectionClick();
    final result = await showModalBottomSheet<_CategorySheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        selected: _category,
        selectedSubcategory: _subcategory,
        type: _type,
      ),
    );
    if (result == null || !mounted) return;
    if (result.createSubcategoryFor != null) {
      // Creación rápida sin salir del flujo.
      final created = await SubcategoryFormSheet.show(
        context,
        category: result.createSubcategoryFor!,
      );
      if (!mounted) return;
      setState(() {
        _category = result.createSubcategoryFor!;
        if (created != null) _subcategory = created;
      });
      return;
    }
    setState(() {
      _category = result.category;
      _subcategory = result.subcategory;
    });
  }

  void _openAccountSheet() {
    Haptics.selectionClick();
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

  static const int _maxPhotos = 3;

  Future<void> _attachPhoto() async {
    if (_imageNames.length >= _maxPhotos) {
      _showError('Máximo $_maxPhotos fotos por transacción');
      return;
    }
    Haptics.selectionClick();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final sc = sheetCtx.colors;
        return Container(
          decoration: BoxDecoration(
            color: sc.card,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.cardRadiusL)),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.xxl + MediaQuery.of(sheetCtx).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Adjuntar foto',
                  style:
                      AppTypography.headingS.copyWith(color: sc.textPrimary)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _PhotoSourceButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Cámara',
                      onTap: () =>
                          Navigator.of(sheetCtx).pop(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _PhotoSourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galería',
                      onTap: () =>
                          Navigator.of(sheetCtx).pop(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;
      final name = await ReceiptImageStore.persist(picked);
      if (name == null) {
        if (mounted) _showError('No se pudo guardar la foto');
        return;
      }
      if (mounted) setState(() => _imageNames.add(name));
    } catch (e) {
      if (mounted) _showError('No se pudo acceder a la imagen');
    }
  }

  void _removePhoto(String name) {
    Haptics.selectionClick();
    setState(() {
      _imageNames.remove(name);
      // Si venía de la transacción original, se borra del disco al guardar;
      // si era nueva, puede borrarse de inmediato.
      final wasOriginal =
          widget.existing?.imagePaths.contains(name) ?? false;
      if (wasOriginal) {
        _removedImages.add(name);
      } else {
        ReceiptImageStore.delete(name);
      }
    });
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
          const DragHandle(),

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
                      icon: _subcategory?.icon ?? _category.icon,
                      label: _subcategory != null
                          ? '${_category.name} · ${_subcategory!.name}'
                          : _category.name,
                      color: _subcategory?.effectiveColor(_category.color) ??
                          _category.color,
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
                      );
                    },
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
                                  Haptics.selectionClick();
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

          // ── Nota + foto ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, 10,
              AppSpacing.screenPadding, 0,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_noteExpanded)
                    _ExpandedNote(
                      controller: _noteCtrl,
                      focusNode: _noteFocusNode,
                      onCollapse: _toggleNote,
                    )
                  else
                    Row(
                      children: [
                        _NoteButton(onTap: _toggleNote),
                        const SizedBox(width: AppSpacing.lg),
                        _AttachPhotoButton(
                          count: _imageNames.length,
                          onTap: _attachPhoto,
                        ),
                      ],
                    ),
                  if (_noteExpanded) ...[
                    const SizedBox(height: 6),
                    _AttachPhotoButton(
                      count: _imageNames.length,
                      onTap: _attachPhoto,
                    ),
                  ],
                  if (_imageNames.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageNames.length,
                        separatorBuilder: (_, i) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, i) => _PhotoThumb(
                          fileName: _imageNames[i],
                          onRemove: () => _removePhoto(_imageNames[i]),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Keypad ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, 8,
              AppSpacing.screenPadding, AppSpacing.sm,
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: _amountNotifier,
              builder: (_, amountStr, _) => NumericKeypad(
                value: amountStr,
                onValueChanged: (v) => _amountNotifier.value = v,
                onConfirm: () async => await _submit(),
                confirmColor: _typeColor,
                currencySymbol: currency,
                keyHeight: 42,
                confirmHeight: 46,
              ),
            ),
          ),
        ],
      )),
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

// ── Attach photo button ───────────────────────────────────────────────────────

class _AttachPhotoButton extends StatelessWidget {
  const _AttachPhotoButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_outlined,
                size: 13, color: c.textTertiary),
            const SizedBox(width: 3),
            Text(
              count > 0 ? 'Foto ($count)' : 'Adjuntar foto',
              style: TextStyle(
                color: c.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo source button (cámara / galería) ────────────────────────────────────

class _PhotoSourceButton extends StatelessWidget {
  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        Haptics.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.glass,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: c.glassBorder, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.emerald),
            const SizedBox(height: 6),
            Text(label,
                style:
                    AppTypography.labelM.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Photo thumbnail with remove ───────────────────────────────────────────────

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.fileName, required this.onRemove});
  final String fileName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final path = ReceiptImageStore.resolve(fileName);
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: c.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.glassBorder, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: path != null
              ? Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: 168,
                  errorBuilder: (_, e2, st) => Icon(
                      Icons.broken_image_outlined,
                      size: 18,
                      color: c.textTertiary),
                )
              : Icon(Icons.image_not_supported_outlined,
                  size: 18, color: c.textTertiary),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
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
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

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
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Category bottom sheet ─────────────────────────────────────────────────────

/// Resultado del sheet de categoría: selección directa o petición de crear
/// una subcategoría para [createSubcategoryFor] (flujo de creación rápida).
class _CategorySheetResult {
  const _CategorySheetResult(this.category,
      {this.subcategory, this.createSubcategoryFor});
  final WalletCategory category;
  final Subcategory? subcategory;
  final WalletCategory? createSubcategoryFor;
}

class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({
    required this.selected,
    required this.type,
    this.selectedSubcategory,
  });

  final WalletCategory selected;
  final Subcategory? selectedSubcategory;
  final TransactionType type;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  /// Categoría con el panel de subcategorías expandido.
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    // Si ya hay subcategoría seleccionada, mostrar su panel expandido.
    if (widget.selectedSubcategory != null) {
      _expandedId = widget.selected.id;
    }
  }

  void _selectCategory(WalletCategory wc) {
    Haptics.selectionClick();
    Navigator.of(context).pop(_CategorySheetResult(wc));
  }

  void _selectSub(WalletCategory wc, Subcategory sub) {
    Haptics.selectionClick();
    Navigator.of(context).pop(_CategorySheetResult(wc, subcategory: sub));
  }

  void _toggleExpand(String catId) {
    Haptics.selectionClick();
    setState(() => _expandedId = _expandedId == catId ? null : catId);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final catType = widget.type == TransactionType.income
        ? WalletCategoryType.income
        : WalletCategoryType.expense;
    final categories = ref
        .watch(walletCategoriesProvider)
        .where((wc) => wc.type == catType)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final allSubs = ref.watch(subcategoriesProvider);

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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
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
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final wc in categories) ...[
                    Builder(builder: (context) {
                      final subs = allSubs
                          .where((s) => s.categoryId == wc.id)
                          .toList()
                        ..sort(
                            (a, b) => a.sortOrder.compareTo(b.sortOrder));
                      final expanded = _expandedId == wc.id;
                      return Column(
                        children: [
                          _SheetItem(
                            icon: wc.icon,
                            label: wc.name,
                            color: wc.color,
                            surface: wc.surface,
                            isSelected: wc.id == widget.selected.id,
                            trailing: subs.isEmpty
                                ? null
                                : GestureDetector(
                                    onTap: () => _toggleExpand(wc.id),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: AnimatedRotation(
                                        turns: expanded ? 0.5 : 0,
                                        duration: const Duration(
                                            milliseconds: 200),
                                        child: Icon(
                                          Icons.expand_more_rounded,
                                          size: 18,
                                          color: c.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ),
                            onTap: () => subs.isEmpty
                                ? _selectCategory(wc)
                                : _toggleExpand(wc.id),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: !expanded
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        AppSpacing.screenPadding + 12,
                                        2,
                                        AppSpacing.screenPadding,
                                        AppSpacing.sm),
                                    child: Wrap(
                                      spacing: 7,
                                      runSpacing: 7,
                                      children: [
                                        _SubPickChip(
                                          icon: wc.icon,
                                          label: 'Solo ${wc.name}',
                                          color: c.textSecondary,
                                          selected: wc.id ==
                                                  widget.selected.id &&
                                              widget.selectedSubcategory ==
                                                  null,
                                          onTap: () => _selectCategory(wc),
                                        ),
                                        ...subs.map((s) => _SubPickChip(
                                              icon: s.icon,
                                              label: s.name,
                                              color: s.effectiveColor(
                                                  wc.color),
                                              selected: widget
                                                      .selectedSubcategory
                                                      ?.id ==
                                                  s.id,
                                              onTap: () =>
                                                  _selectSub(wc, s),
                                            )),
                                        _SubPickChip(
                                          icon: Icons.add_rounded,
                                          label: 'Nueva',
                                          color: wc.color,
                                          selected: false,
                                          outlined: true,
                                          onTap: () {
                                            Haptics.selectionClick();
                                            Navigator.of(context).pop(
                                              _CategorySheetResult(wc,
                                                  createSubcategoryFor: wc),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      );
                    }),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subcategory pick chip ─────────────────────────────────────────────────────

class _SubPickChip extends StatelessWidget {
  const _SubPickChip({
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
            Icon(icon, size: 12, color: selected ? color : c.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : c.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
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
          const DragHandle(),
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
                  Haptics.selectionClick();
                  onChanged(account.id);
                },
              )),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
