import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/icons/vexa_icons.dart';
import '../../../../core/utils/id_gen.dart';
import '../../../../shared/widgets/icon_picker_sheet.dart';
import '../../domain/models/subcategory.dart';
import '../../domain/models/wallet_category.dart';
import '../providers/subcategories_provider.dart';

const _kSubColorOptions = [
  AppColors.catFood,
  AppColors.catTransport,
  AppColors.catShopping,
  AppColors.catEntertainment,
  AppColors.catHealth,
  AppColors.emerald,
  AppColors.petroleum,
  AppColors.negative,
  AppColors.warning,
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF3F51B5),
];

/// Formulario para crear o editar una subcategoría.
/// Devuelve la [Subcategory] guardada vía `Navigator.pop` para que los flujos
/// de transacción puedan seleccionarla inmediatamente.
class SubcategoryFormSheet extends ConsumerStatefulWidget {
  const SubcategoryFormSheet({
    super.key,
    required this.category,
    this.existing,
    this.initialName,
  });

  final WalletCategory category;
  final Subcategory? existing;

  /// Pre-rellena el nombre (creación rápida desde el flujo de transacción).
  final String? initialName;

  /// Abre el formulario y devuelve la subcategoría creada/actualizada.
  static Future<Subcategory?> show(
    BuildContext context, {
    required WalletCategory category,
    Subcategory? existing,
    String? initialName,
  }) {
    return showModalBottomSheet<Subcategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => SubcategoryFormSheet(
        category: category,
        existing: existing,
        initialName: initialName,
      ),
    );
  }

  @override
  ConsumerState<SubcategoryFormSheet> createState() =>
      _SubcategoryFormSheetState();
}

class _SubcategoryFormSheetState extends ConsumerState<SubcategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late IconData _icon;
  Color? _color; // null → hereda el color de la categoría
  bool _iconPickedManually = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.existing?.name ?? widget.initialName ?? '',
    );
    _icon =
        widget.existing?.icon ??
        suggestIconFor(widget.initialName ?? '') ??
        widget.category.icon;
    _color = widget.existing?.color;
    _iconPickedManually = widget.existing != null;
    _nameCtrl.addListener(_maybeSuggestIcon);
  }

  void _maybeSuggestIcon() {
    if (_iconPickedManually) {
      setState(() {});
      return;
    }
    final suggestion = suggestIconFor(_nameCtrl.text);
    setState(() {
      if (suggestion != null) _icon = suggestion;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Color get _effectiveColor => _color ?? widget.category.color;

  Future<void> _showIconPicker() async {
    final picked = await IconPickerSheet.show(
      context,
      selected: _icon,
      color: _effectiveColor,
    );
    if (picked != null && mounted) {
      setState(() {
        _icon = picked;
        _iconPickedManually = true;
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para la subcategoría')),
      );
      return;
    }
    final notifier = ref.read(subcategoriesProvider.notifier);
    final navigator = Navigator.of(context);

    Subcategory saved;
    if (widget.existing != null) {
      saved = widget.existing!.copyWith(
        name: name,
        icon: _icon,
        color: _color,
        clearColor: _color == null,
      );
      await notifier.update(saved);
    } else {
      final sortOrder = ref
          .read(subcategoriesByCategoryProvider(widget.category.id))
          .length;
      saved = Subcategory(
        id: generateId(),
        categoryId: widget.category.id,
        name: name,
        icon: _icon,
        color: _color,
        sortOrder: sortOrder,
        createdAt: DateTime.now(),
      );
      await notifier.add(saved);
    }
    HapticFeedback.mediumImpact();
    if (mounted) navigator.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;
    final cat = widget.category;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.lg + bottom + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Título con contexto de categoría padre
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: cat.surface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(cat.icon, size: 14, color: cat.color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isEdit
                      ? 'Editar subcategoría'
                      : 'Nueva subcategoría · ${cat.name}',
                  style: AppTypography.headingS.copyWith(color: c.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Icono + nombre
          Row(
            children: [
              GestureDetector(
                onTap: _showIconPicker,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _effectiveColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _effectiveColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(_icon, color: _effectiveColor, size: 22),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: !isEdit,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTypography.bodyM.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'ej. Café, Gasolina, Cine…',
                      hintStyle: AppTypography.bodyM.copyWith(
                        color: c.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Color (opcional): primero "auto" que hereda el del padre
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              // Heredar color del padre
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _color = null);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _color == null ? Colors.white : cat.color,
                      width: _color == null ? 2.5 : 1,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: cat.color,
                  ),
                ),
              ),
              ..._kSubColorOptions.map((col) {
                final isSel = _color?.toARGB32() == col.toARGB32();
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _color = col);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: isSel
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Vista previa
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _effectiveColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_icon, size: 16, color: _effectiveColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _nameCtrl.text.isEmpty ? 'Subcategoría' : _nameCtrl.text,
                    style: AppTypography.labelL.copyWith(color: c.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cat.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Text(
                    cat.name,
                    style: AppTypography.eyebrow.copyWith(color: cat.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Guardar
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.emeraldDim],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  isEdit ? 'Guardar cambios' : 'Crear subcategoría',
                  style: AppTypography.labelL.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
