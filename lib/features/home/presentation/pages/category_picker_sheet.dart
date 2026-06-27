import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vexa_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../wallet/domain/models/wallet_category.dart';
import '../../../wallet/domain/models/subcategory.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/providers/subcategories_provider.dart';
import '../../../wallet/presentation/widgets/subcategory_form_sheet.dart';
import '../../domain/models/transaction.dart';
import '../../../../shared/widgets/drag_handle.dart';

/// Resultado del selector: categoría + subcategoría opcional.
class CategorySelection {
  const CategorySelection(this.category, [this.subcategory]);
  final WalletCategory category;
  final Subcategory? subcategory;
}

/// Step-2 overlay: shown on top of QuickAddSheet so the user can pick a
/// category before entering the amount.
///
/// Interacción:
/// - Toque normal → selecciona solo la categoría.
/// - Mantener presionado → las subcategorías emergen del tile con animación
///   escalonada; deslizar (sin levantar el dedo) hasta una y soltar para
///   seleccionarla.
///
/// Returns a [CategorySelection] via [Navigator.pop].
class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({
    super.key,
    required this.initialType,
    this.selectedCategoryId,
    this.selectedSubcategoryId,
  });

  final TransactionType initialType;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet>
    with TickerProviderStateMixin {
  late TransactionType _activeType;
  late TabController _tabCtrl;
  late AnimationController _overlayCtrl;

  /// Categoría cuyo panel contextual de subcategorías está visible.
  WalletCategory? _overlayCategory;

  /// Rect (en coordenadas del sheet) del tile que originó el overlay.
  Rect? _overlayAnchor;

  /// Índice de la opción actualmente "hovered" durante el deslizamiento.
  int _hoveredOption = -1;

  /// Keys de las opciones del panel para hit-testing durante el slide.
  List<GlobalKey> _optionKeys = const [];

  final _sheetKey = GlobalKey();

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
        _activeType = _tabCtrl.index == 0
            ? TransactionType.expense
            : TransactionType.income;
        _dismissOverlay();
      });
    });
    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _overlayCtrl.dispose();
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

  void _select(WalletCategory cat, [Subcategory? sub]) {
    Haptics.selectionClick();
    Navigator.of(context).pop(CategorySelection(cat, sub));
  }

  // ── Overlay contextual de subcategorías ─────────────────────────────

  static const int _maxDisplaySubs = 10; // 10 subs + Solo + Nueva = 12 = 3×4

  List<Subcategory> get _overlaySubs {
    if (_overlayCategory == null) return const [];
    final all = ref.read(subcategoriesByCategoryProvider(_overlayCategory!.id));
    return all.length > _maxDisplaySubs ? all.sublist(0, _maxDisplaySubs) : all;
  }

  void _showOverlay(WalletCategory cat, Rect tileRect) {
    final allSubs = ref.read(subcategoriesByCategoryProvider(cat.id));
    final displayCount = allSubs.length.clamp(0, _maxDisplaySubs);
    _overlayCtrl.reset();
    _overlayCtrl.forward();
    setState(() {
      _overlayCategory = cat;
      _overlayAnchor = tileRect;
      _hoveredOption = -1;
      // opciones: subcategorías (capped) + "solo categoría" + "nueva subcategoría"
      _optionKeys = List.generate(displayCount + 2, (_) => GlobalKey());
    });
  }

  void _dismissOverlay() {
    if (_overlayCategory == null) return;
    _overlayCtrl.reset();
    setState(() {
      _overlayCategory = null;
      _overlayAnchor = null;
      _hoveredOption = -1;
      _optionKeys = const [];
    });
  }

  /// Convierte una posición global a coordenadas locales del sheet.
  Offset _toSheetLocal(Offset global) {
    final box = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(global) ?? global;
  }

  int _hitTestOption(Offset globalPos) {
    for (var i = 0; i < _optionKeys.length; i++) {
      final ctx = _optionKeys[i].currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.contains(globalPos)) return i;
    }
    return -1;
  }

  void _onSlideUpdate(Offset globalPos) {
    if (_overlayCategory == null) return;
    final hit = _hitTestOption(globalPos);
    if (hit != _hoveredOption) {
      if (hit != -1) Haptics.selectionClick();
      setState(() => _hoveredOption = hit);
    }
  }

  Future<void> _onSlideEnd() async {
    final cat = _overlayCategory;
    if (cat == null) return;
    final subs = _overlaySubs;
    final hit = _hoveredOption;

    if (hit == -1) {
      // Soltó sin apuntar a nada: el panel queda abierto para usar con toques.
      setState(() => _hoveredOption = -1);
      return;
    }
    if (hit < subs.length) {
      _select(cat, subs[hit]);
    } else if (hit == subs.length) {
      _select(cat); // "Solo {categoría}"
    } else {
      await _createSubcategory(cat); // "+ Nueva subcategoría"
    }
  }

  Future<void> _createSubcategory(WalletCategory cat) async {
    _dismissOverlay();
    final created = await SubcategoryFormSheet.show(context, category: cat);
    if (created != null && mounted) _select(cat, created);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(walletCategoriesProvider); // rebuild when categories change
    ref.watch(subcategoriesProvider); // rebuild when subcategories change
    final c = context.colors;
    final cats = _categories;

    return Container(
      key: _sheetKey,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              const DragHandle(),

              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  16,
                  AppSpacing.screenPadding,
                  0,
                ),
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
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: c.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Hint ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  4,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: Text(
                  'Mantén presionada una categoría para elegir subcategoría',
                  style: AppTypography.labelS.copyWith(color: c.textTertiary),
                ),
              ),

              // ── Type tabs ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  12,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: c.glass,
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
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
                      borderRadius: BorderRadius.circular(
                        AppSpacing.pillRadius,
                      ),
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
                      style: AppTypography.bodyM.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
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
                      final isSelected = cat.id == widget.selectedCategoryId;
                      return _CategoryTile(
                        category: cat,
                        selected: isSelected,
                        dimmed:
                            _overlayCategory != null &&
                            _overlayCategory!.id != cat.id,
                        onTap: () => _select(cat),
                        onLongPressStart: (details) {
                          final local = _toSheetLocal(
                            details.tileGlobalRect.topLeft,
                          );
                          _showOverlay(
                            cat,
                            local & details.tileGlobalRect.size,
                          );
                        },
                        onLongPressMove: _onSlideUpdate,
                        onLongPressEnd: _onSlideEnd,
                      );
                    },
                  ),
                ),
            ],
          ),

          // ── Barrier + panel contextual ───────────────────────────────────
          if (_overlayCategory != null) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissOverlay,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),
            _buildOverlayPanel(context),
          ],
        ],
      ),
    );
  }

  Widget _buildOverlayPanel(BuildContext context) {
    final cat = _overlayCategory!;
    final subs = _overlaySubs; // capped at _maxDisplaySubs
    final anchor = _overlayAnchor;
    final sheetBox = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    final sheetWidth = sheetBox?.size.width ?? MediaQuery.of(context).size.width;
    final sheetHeight = sheetBox?.size.height ?? 500.0;

    final double panelW = sheetWidth - AppSpacing.screenPadding * 2;
    const double arrowH = 9.0;
    const int cols = 4;
    const double tileGap = 5.0;
    const double hPad = AppSpacing.md; // 12

    // Todos los items en el grid: subs + "Solo" + "+"
    final int totalItems = subs.length + 2;
    final int gridRows = (totalItems + cols - 1) ~/ cols;
    // Estimado: icono(26) + gap(4) + texto(~18) + padding(12) ≈ 60px por fila
    const double tileRowH = 60.0;
    final double gridH = gridRows * tileRowH + (gridRows - 1) * tileGap;
    // header(30) + grid + padding(20)
    final double contentH = 30.0 + gridH + 20.0;

    // Preferencia: abrirse HACIA ABAJO desde el tile.
    // Solo sube si no cabe abajo. Clampeado para quedar en la mitad inferior.
    final double tileBottom = anchor?.bottom ?? sheetHeight * 0.5;
    final double spaceBelow = sheetHeight - tileBottom - contentH - arrowH - 6.0;
    final bool isAbove = spaceBelow < 0;

    final double tileCenterX =
        anchor != null ? anchor.left + anchor.width / 2 : sheetWidth / 2;

    var panelLeft = tileCenterX - panelW / 2;
    panelLeft = panelLeft.clamp(
      AppSpacing.screenPadding.toDouble(),
      sheetWidth - panelW - AppSpacing.screenPadding.toDouble(),
    );

    double panelTop;
    if (anchor == null) {
      panelTop = ((sheetHeight - contentH) / 2).clamp(8.0, sheetHeight - contentH - 8);
    } else if (isAbove) {
      // Va arriba; no subir más del 35% del sheet (clamp seguro: min nunca > max)
      final double rawTop = anchor.top - contentH - arrowH - 4;
      final double minTop = sheetHeight * 0.35;
      final double maxTop = sheetHeight - contentH - 8;
      panelTop = maxTop < minTop ? minTop : rawTop.clamp(minTop, maxTop);
    } else {
      panelTop = tileBottom + arrowH + 4;
    }

    final double arrowX = anchor != null
        ? (tileCenterX - panelLeft).clamp(14.0, panelW - 14.0)
        : panelW / 2;

    final double scaleAlignX = (arrowX / panelW) * 2 - 1;
    final double scaleAlignY = isAbove ? 1.35 : -1.35;

    final bgColor = context.colors.cardElevated;
    final borderColor = cat.color.withValues(alpha: 0.35);
    final c = context.colors;

    final arrowWidget = SizedBox(
      width: panelW,
      height: arrowH,
      child: CustomPaint(
        painter: _PanelArrowPainter(
          arrowX: arrowX,
          pointsUp: !isAbove,
          fillColor: bgColor,
          strokeColor: borderColor,
        ),
      ),
    );

    // Construye un tile del grid por índice global
    Widget buildTile(int i) {
      if (i < subs.length) {
        return _staggeredItem(
          index: i,
          total: totalItems,
          child: _OverlaySubTile(
            key: _optionKeys[i],
            icon: subs[i].icon,
            label: subs[i].name,
            color: subs[i].effectiveColor(cat.color),
            hovered: _hoveredOption == i,
            onTap: () => _select(cat, subs[i]),
          ),
        );
      } else if (i == subs.length) {
        // "Solo [cat]" — muted, borde sutil siempre visible
        return _staggeredItem(
          index: i,
          total: totalItems,
          child: _OverlaySubTile(
            key: _optionKeys[i],
            icon: cat.icon,
            label: 'Solo',
            color: c.textTertiary,
            hovered: _hoveredOption == i,
            subtle: true,
            onTap: () => _select(cat),
          ),
        );
      } else {
        // "+" Nueva subcategoría — fondo tintado + borde coloreado siempre
        return _staggeredItem(
          index: i,
          total: totalItems,
          child: _OverlaySubTile(
            key: _optionKeys[i],
            icon: Icons.add_rounded,
            label: 'Nueva',
            color: cat.color,
            hovered: _hoveredOption == i,
            outlined: true,
            onTap: () => _createSubcategory(cat),
          ),
        );
      }
    }

    final panelBody = Container(
      width: panelW,
      padding: const EdgeInsets.all(hPad),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusL),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header compacto ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(cat.icon, size: 13, color: cat.color),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    cat.name,
                    style: AppTypography.labelM.copyWith(
                      color: cat.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'desliza y suelta',
                  style: AppTypography.labelS
                      .copyWith(color: c.textTertiary, fontSize: 9),
                ),
              ],
            ),
          ),

          // ── Grid unificado: subs + Solo + + ──────────────────────────
          // Row+Expanded garantiza exactamente 4 columnas (Wrap tiene bug FP)
          for (int row = 0; row < gridRows; row++) ...[
            if (row > 0) const SizedBox(height: tileGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int col = 0; col < cols; col++) ...[
                  if (col > 0) const SizedBox(width: tileGap),
                  Expanded(
                    child: () {
                      final i = row * cols + col;
                      return i < totalItems
                          ? buildTile(i)
                          : const SizedBox.shrink();
                    }(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    return Positioned(
      left: panelLeft,
      top: panelTop,
      child: AnimatedBuilder(
        animation: _overlayCtrl,
        builder: (_, child) {
          final progress = _overlayCtrl.value.clamp(0.0, 1.0);
          final springT = Curves.easeOutBack.transform(progress);
          return Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: (0.78 + 0.22 * springT).clamp(0.0, 1.12),
              alignment: Alignment(scaleAlignX, scaleAlignY),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: isAbove
              ? [panelBody, arrowWidget]
              : [arrowWidget, panelBody],
        ),
      ),
    );
  }

  /// Envuelve [child] en una animación escalonada de entrada (fade + slide-up).
  Widget _staggeredItem({
    required int index,
    required int total,
    required Widget child,
  }) {
    // Cada item ocupa una ventana de 0.45 dentro de [0, 0.95], escalonada.
    final double start = (index / total * 0.55).clamp(0.0, 0.55);
    final double end = (start + 0.45).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _overlayCtrl,
      builder: (_, c) {
        final raw = total > 0
            ? (_overlayCtrl.value - start) / (end - start)
            : _overlayCtrl.value;
        final t = Curves.easeOutCubic.transform(raw.clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 10.0 * (1 - t)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

// ── Triangle arrow painter ────────────────────────────────────────────────────

class _PanelArrowPainter extends CustomPainter {
  const _PanelArrowPainter({
    required this.arrowX,
    required this.pointsUp,
    required this.fillColor,
    required this.strokeColor,
  });

  final double arrowX;
  final bool pointsUp;
  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsUp) {
      // Arrow at top of the SizedBox pointing up (panel below tile)
      path.moveTo(arrowX - 9, size.height);
      path.lineTo(arrowX, 0);
      path.lineTo(arrowX + 9, size.height);
    } else {
      // Arrow at bottom of the SizedBox pointing down (panel above tile)
      path.moveTo(arrowX - 9, 0);
      path.lineTo(arrowX, size.height);
      path.lineTo(arrowX + 9, 0);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(covariant _PanelArrowPainter old) =>
      old.arrowX != arrowX ||
      old.pointsUp != pointsUp ||
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor;
}

// ── Subcategory grid tile ─────────────────────────────────────────────────────

class _OverlaySubTile extends StatelessWidget {
  const _OverlaySubTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.hovered,
    required this.onTap,
    this.subtle = false,   // "Solo [cat]": borde siempre visible, color muted
    this.outlined = false, // "+" Nueva: fondo tintado + borde coloreado siempre
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool hovered;
  final bool subtle;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Color de fondo en reposo
    final Color bgRest = outlined
        ? color.withValues(alpha: 0.08)
        : Colors.transparent;
    // Color de borde en reposo
    final Color borderRest = hovered
        ? color.withValues(alpha: 0.55)
        : (outlined
            ? color.withValues(alpha: 0.30)
            : (subtle ? c.glassBorder : Colors.transparent));
    // Color de fondo en hover
    final Color bgHover = color.withValues(alpha: 0.18);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        decoration: BoxDecoration(
          color: hovered ? bgHover : bgRest,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: borderRest, width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: subtle
                    ? c.glass
                    : color.withValues(alpha: hovered ? 0.25 : (outlined ? 0.15 : 0.14)),
                borderRadius: BorderRadius.circular(8),
                border: subtle
                    ? Border.all(color: c.glassBorder, width: 0.5)
                    : null,
              ),
              child: Icon(icon, size: 12, color: subtle ? c.textTertiary : color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hovered
                    ? color
                    : (subtle ? c.textTertiary : c.textPrimary),
                fontSize: 9.5,
                fontWeight: hovered ? FontWeight.w700 : FontWeight.w500,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Long-press details (rect del tile + posición global) ─────────────────────

class _TileLongPressDetails {
  const _TileLongPressDetails(this.tileGlobalRect);
  final Rect tileGlobalRect;
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressMove,
    required this.onLongPressEnd,
    this.dimmed = false,
  });

  final WalletCategory category;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;
  final ValueChanged<_TileLongPressDetails> onLongPressStart;
  final ValueChanged<Offset> onLongPressMove;
  final VoidCallback onLongPressEnd;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;
  Timer? _longPressTimer;
  bool _longPressFired = false;
  Offset? _pointerDownPos;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  Rect _globalRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cat = widget.category;

    // Usamos Listener en lugar de GestureDetector para los eventos de long-press:
    // Listener recibe PointerEvents RAW antes del gesture arena, por lo que nunca
    // pierde contra el VerticalDragRecognizer del BottomSheet ni otros ancestros.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _longPressFired = false;
        _pointerDownPos = e.position;
        setState(() => _pressed = true);
        _longPressTimer?.cancel();
        _longPressTimer = Timer(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          _longPressFired = true;
          setState(() => _pressed = false);
          Haptics.mediumImpact();
          widget.onLongPressStart(_TileLongPressDetails(_globalRect()));
        });
      },
      onPointerMove: (e) {
        if (_longPressFired) {
          widget.onLongPressMove(e.position);
        } else if (_pointerDownPos != null) {
          if ((e.position - _pointerDownPos!).distance > 8.0) {
            _longPressTimer?.cancel();
            setState(() => _pressed = false);
          }
        }
      },
      onPointerUp: (e) {
        _longPressTimer?.cancel();
        setState(() => _pressed = false);
        final wasLongPress = _longPressFired;
        _longPressFired = false;
        _pointerDownPos = null;
        if (wasLongPress) {
          widget.onLongPressEnd();
        } else {
          widget.onTap();
        }
      },
      onPointerCancel: (e) {
        _longPressTimer?.cancel();
        final wasLongPress = _longPressFired;
        _longPressFired = false;
        _pointerDownPos = null;
        setState(() => _pressed = false);
        if (wasLongPress) widget.onLongPressEnd();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.dimmed ? 0.35 : 1.0,
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
                      alpha: widget.selected ? 0.20 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(cat.icon, size: 20, color: cat.color),
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
                    color: widget.selected ? cat.color : c.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
