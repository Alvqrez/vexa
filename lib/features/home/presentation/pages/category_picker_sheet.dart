import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/models/transaction.dart';

/// Step-2 overlay: shown on top of QuickAddSheet so the user can pick a
/// category before entering the amount.  Returns the selected [WalletCategory]
/// via [Navigator.pop].
class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({
    super.key,
    required this.initialType,
    this.selectedCategoryId,
  });

  final TransactionType initialType;
  final String? selectedCategoryId;

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet>
    with SingleTickerProviderStateMixin {
  late TransactionType _activeType;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _activeType = widget.initialType;
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: _activeType == TransactionType.expense ? 0 : 1,
    );
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) return;
      setState(() {
        _activeType =
            _tabCtrl.index == 0 ? TransactionType.expense : TransactionType.income;
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<WalletCategory> get _categories {
    final catType = _activeType == TransactionType.expense
        ? WalletCategoryType.expense
        : WalletCategoryType.income;
    return ref
        .read(walletCategoriesProvider)
        .where((c) => c.type == catType)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  void _select(WalletCategory cat) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(cat);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(walletCategoriesProvider); // rebuild when categories change
    final c = context.colors;
    final cats = _categories;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Center(
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
          ),

          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 16, AppSpacing.screenPadding, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Seleccionar categoría',
                    style: AppTypography.headingS.copyWith(
                      color: c.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(null),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c.glass,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.glassBorder, width: 0.5),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: c.textTertiary),
                  ),
                ),
              ],
            ),
          ),

          // ── Type tabs ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 14, AppSpacing.screenPadding, 0),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: c.glass,
                borderRadius:
                    BorderRadius.circular(AppSpacing.pillRadius),
                border: Border.all(color: c.glassBorder, width: 0.5),
              ),
              child: TabBar(
                controller: _tabCtrl,
                labelStyle: AppTypography.labelM.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTypography.labelM.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                labelColor: c.textPrimary,
                unselectedLabelColor: c.textTertiary,
                indicator: BoxDecoration(
                  color: c.card,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.pillRadius),
                  border: Border.all(color: c.glassBorder, width: 0.5),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabs: const [
                  Tab(text: 'Gastos'),
                  Tab(text: 'Ingresos'),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Category grid ────────────────────────────────────────────
          if (cats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  'Sin categorías',
                  style:
                      AppTypography.bodyM.copyWith(color: c.textTertiary),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.05,
                ),
                itemCount: cats.length,
                itemBuilder: (context, i) {
                  final cat = cats[i];
                  final isSelected =
                      cat.id == widget.selectedCategoryId;
                  return _CategoryTile(
                    category: cat,
                    selected: isSelected,
                    onTap: () => _select(cat),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final WalletCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cat = widget.category;

    return GestureDetector(
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) {
        _press.forward();
        widget.onTap();
      },
      onTapCancel: () => _press.forward(),
      child: ScaleTransition(
        scale: _press,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: widget.selected ? cat.surface : c.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: widget.selected
                  ? cat.color.withValues(alpha: 0.45)
                  : c.glassBorder,
              width: widget.selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.color.withValues(
                      alpha: widget.selected ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  cat.icon,
                  size: 20,
                  color: cat.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cat.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: widget.selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color:
                      widget.selected ? cat.color : c.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
