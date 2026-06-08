import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_curves.dart';
import '../../../../shared/widgets/success_creation_overlay.dart';
import '../../domain/models/wallet_category.dart';
import '../providers/wallet_provider.dart';
import '../../../../core/utils/id_gen.dart';

const _kIconOptions = [
  Icons.fork_right_rounded,
  Icons.directions_car_rounded,
  Icons.shopping_bag_rounded,
  Icons.movie_rounded,
  Icons.favorite_rounded,
  Icons.home_rounded,
  Icons.school_rounded,
  Icons.flight_rounded,
  Icons.sports_esports_rounded,
  Icons.fitness_center_rounded,
  Icons.local_cafe_rounded,
  Icons.pets_rounded,
  Icons.music_note_rounded,
  Icons.health_and_safety_rounded,
  Icons.savings_rounded,
  Icons.category_rounded,
  Icons.work_rounded,
  Icons.laptop_rounded,
  Icons.business_center_rounded,
  Icons.attach_money_rounded,
];

const _kColorOptions = [
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
  AppColors.catOther,
];

class WalletCategoriesPage extends ConsumerStatefulWidget {
  const WalletCategoriesPage({super.key});

  @override
  ConsumerState<WalletCategoriesPage> createState() =>
      _WalletCategoriesPageState();
}

class _WalletCategoriesPageState extends ConsumerState<WalletCategoriesPage>
    with TickerProviderStateMixin {
  late AnimationController _stagger;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _stagger.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) {
    final start = (i / 3 * 0.5).clamp(0.0, 1.0);
    final end = (start + 0.5).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, end, curve: AppCurves.gentle),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _stagger,
                curve: Interval(start, end, curve: AppCurves.spring),
              ),
            ),
        child: child,
      ),
    );
  }

  void _showAddSheet(WalletCategoryType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(
        type: type,
        onSave: (cat) async {
          await ref.read(walletCategoriesProvider.notifier).add(cat);
          if (mounted) {
            SuccessCreationOverlay.show(
              context,
              title: 'Categoría creada',
              subtitle: cat.name,
              icon: Icons.check_circle_rounded,
            );
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showEditSheet(WalletCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(
        type: category.type,
        existing: category,
        onSave: (cat) async =>
            await ref.read(walletCategoriesProvider.notifier).update(cat),
      ),
    );
  }

  void _confirmDelete(WalletCategory cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text(
          'Eliminar categoría',
          style: AppTypography.headingS.copyWith(color: context.colors.textPrimary),
        ),
        content: Text(
          '¿Eliminar "${cat.name}"?',
          style: AppTypography.bodyM.copyWith(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTypography.labelM.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(walletCategoriesProvider.notifier).delete(cat.id);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Eliminar',
              style: AppTypography.labelM.copyWith(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          _CatBg(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: _reveal(0, _CatHeader()),
                ),
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: _reveal(1, _CatTabBar(controller: _tabCtrl)),
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: _reveal(
                    2,
                    TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _CategoryList(
                          type: WalletCategoryType.expense,
                          onAdd: () =>
                              _showAddSheet(WalletCategoryType.expense),
                          onEdit: _showEditSheet,
                          onDelete: _confirmDelete,
                        ),
                        _CategoryList(
                          type: WalletCategoryType.income,
                          onAdd: () => _showAddSheet(WalletCategoryType.income),
                          onEdit: _showEditSheet,
                          onDelete: _confirmDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _CatBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: context.colors.background),
          Positioned(
            top: -60,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.08),
                    Colors.transparent,
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

// ── Header ────────────────────────────────────────────────────────────────────

class _CatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.colors.glass,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: context.colors.glassBorder, width: 0.5),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categorías',
              style: AppTypography.headingM.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            Text(
              'Personaliza tus categorías',
              style: AppTypography.labelM.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _CatTabBar extends StatelessWidget {
  const _CatTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.colors.glassBorder, width: 0.5),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.emeraldSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.emerald.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTypography.labelM.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: AppTypography.labelM.copyWith(fontSize: 13),
        labelColor: AppColors.emerald,
        unselectedLabelColor: context.colors.textTertiary,
        tabs: const [
          Tab(text: 'Gastos'),
          Tab(text: 'Ingresos'),
        ],
      ),
    );
  }
}

// ── Category list ─────────────────────────────────────────────────────────────

class _CategoryList extends ConsumerWidget {
  const _CategoryList({
    required this.type,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final WalletCategoryType type;
  final VoidCallback onAdd;
  final ValueChanged<WalletCategory> onEdit;
  final ValueChanged<WalletCategory> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = type == WalletCategoryType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.xxxl,
      ),
      onReorderItem: (oldIndex, newIndex) {
        ref
            .read(walletCategoriesProvider.notifier)
            .reorder(oldIndex, newIndex, type);
      },
      footer: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: _AddCategoryButton(onTap: onAdd),
      ),
      itemCount: cats.length,
      itemBuilder: (context, i) {
        final cat = cats[i];
        return Padding(
          key: ValueKey(cat.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _CategoryTile(
            category: cat,
            onEdit: () => onEdit(cat),
            onDelete: () => onDelete(cat),
          ),
        );
      },
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });
  final WalletCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onEdit();
      },
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius + 2.5),
          color: Colors.white.withValues(alpha: 0.02),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, size: 18, color: category.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.labelL.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    Text(
                      category.type.label,
                      style: AppTypography.labelS.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _CategoryActionSheet(
                      category: category,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  );
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: context.colors.glass,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 14,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.drag_handle_rounded,
                size: 18,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add category button ───────────────────────────────────────────────────────

class _AddCategoryButton extends StatelessWidget {
  const _AddCategoryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.glass,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: context.colors.glassBorderStrong, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.emeraldSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.emerald,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Nueva categoría',
              style: AppTypography.labelL.copyWith(color: AppColors.emerald),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category form sheet ───────────────────────────────────────────────────────

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({
    required this.type,
    required this.onSave,
    this.existing,
  });
  final WalletCategoryType type;
  final WalletCategory? existing;
  final ValueChanged<WalletCategory> onSave;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late IconData _icon;
  late Color _color;
  late WalletCategoryType _type;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _icon = widget.existing?.icon ?? _kIconOptions.first;
    _color = widget.existing?.color ?? _kColorOptions.first;
    _type = widget.existing?.type ?? widget.type;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    final cats = ref.read(walletCategoriesProvider);
    final sortOrder =
        widget.existing?.sortOrder ?? cats.where((c) => c.type == _type).length;

    widget.onSave(
      WalletCategory(
        id: widget.existing?.id ?? generateId(),
        name: name,
        color: _color,
        icon: _icon,
        type: _type,
        sortOrder: sortOrder,
        isDefault: widget.existing?.isDefault ?? false,
      ),
    );
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          decoration: BoxDecoration(
            color: ctx.colors.card,
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
                  margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: ctx.colors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Elige un icono',
                style: AppTypography.headingS.copyWith(
                  color: ctx.colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _IconPickerGrid(
                icons: _kIconOptions,
                selected: _icon,
                color: _color,
                onChanged: (ic) {
                  setState(() => _icon = ic);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.56 + bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.md,
          AppSpacing.xxl,
          AppSpacing.lg + bottom,
        ),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.cardRadiusL),
          ),
        ),
        child: SingleChildScrollView(
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
                    color: context.colors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? 'Editar categoría' : 'Nueva categoría',
                style: AppTypography.headingS.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Nombre + Icono en la misma fila
              Row(
                children: [
                  GestureDetector(
                    onTap: _showIconPicker,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _color.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(_icon, color: _color, size: 22),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _FormTextField(
                      controller: _nameCtrl,
                      hint: 'ej. Gimnasio, Suscripciones…',
                      autofocus: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Tipo
              Row(
                children: WalletCategoryType.values.map((t) {
                  final active = t == _type;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: t == WalletCategoryType.expense
                            ? AppSpacing.sm
                            : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _type = t);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.emeraldSurface
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.cardRadius,
                            ),
                            border: Border.all(
                              color: active
                                  ? AppColors.emerald.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            t.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.labelM.copyWith(
                              color: active
                                  ? AppColors.emerald
                                  : context.colors.textTertiary,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              // Colores
              _ColorPickerRow(
                colors: _kColorOptions,
                selected: _color,
                onChanged: (c) => setState(() => _color = c),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon, size: 18, color: _color),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _nameCtrl.text.isEmpty ? 'Categoría' : _nameCtrl.text,
                      style: AppTypography.labelL.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _type == WalletCategoryType.expense
                            ? AppColors.negativeSurface
                            : AppColors.positiveSurface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.pillRadius,
                        ),
                      ),
                      child: Text(
                        _type.label,
                        style: AppTypography.eyebrow.copyWith(
                          color: _type == WalletCategoryType.expense
                              ? AppColors.negative
                              : AppColors.positive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.emerald, AppColors.emeraldDim],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      isEdit ? 'Guardar cambios' : 'Crear categoría',
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
        ),
      ),
    );
  }
}

// ── Form shared widgets ───────────────────────────────────────────────────────

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        style: AppTypography.bodyM.copyWith(color: context.colors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyM.copyWith(
            color: context.colors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

class _IconPickerGrid extends StatelessWidget {
  const _IconPickerGrid({
    required this.icons,
    required this.selected,
    required this.color,
    required this.onChanged,
  });
  final List<IconData> icons;
  final IconData selected;
  final Color color;
  final ValueChanged<IconData> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: icons.map((ic) {
        final isSel = ic == selected;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(ic);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSel
                  ? color.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isSel
                    ? color.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.06),
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Icon(
              ic,
              size: 20,
              color: isSel ? color : context.colors.textTertiary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Category action sheet ─────────────────────────────────────────────────────

class _CategoryActionSheet extends StatelessWidget {
  const _CategoryActionSheet({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });
  final WalletCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.colors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(category.icon, size: 22, color: category.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                category.name,
                style: AppTypography.headingS.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _CategoryActionTile(
            icon: Icons.edit_rounded,
            label: 'Editar categoría',
            color: AppColors.petroleum,
            onTap: () {
              Navigator.of(context).pop();
              onEdit();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _CategoryActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Eliminar categoría',
            color: AppColors.negative,
            onTap: () {
              Navigator.of(context).pop();
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryActionTile extends StatelessWidget {
  const _CategoryActionTile({
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
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
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

class _ColorPickerRow extends StatelessWidget {
  const _ColorPickerRow({
    required this.colors,
    required this.selected,
    required this.onChanged,
  });
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: colors.map((c) {
        final isSel = c.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(c);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSel ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: c.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: isSel
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
