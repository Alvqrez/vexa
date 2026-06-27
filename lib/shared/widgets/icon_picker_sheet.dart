import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vexa_finance/core/utils/haptics.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/vexa_colors_ext.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/data/local_prefs_service.dart';
import '../../core/icons/vexa_icons.dart';

/// Selector de iconos profesional de Vexa.
///
/// - Búsqueda instantánea por nombre y keywords (ES/EN, sin acentos).
/// - Recientes y favoritos persistidos en prefs.
/// - Chips de categorías + grid perezosa (GridView.builder).
///
/// Devuelve el [IconData] elegido vía `Navigator.pop`.
class IconPickerSheet extends StatefulWidget {
  const IconPickerSheet({
    super.key,
    required this.selected,
    required this.color,
  });

  final IconData? selected;
  final Color color;

  /// Abre el selector y devuelve el icono elegido (o null si se cierra).
  static Future<IconData?> show(
    BuildContext context, {
    IconData? selected,
    required Color color,
  }) {
    return showModalBottomSheet<IconData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => IconPickerSheet(selected: selected, color: color),
    );
  }

  @override
  State<IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<IconPickerSheet> {
  static const _kRecentsKey = 'icon_picker_recents';
  static const _kFavoritesKey = 'icon_picker_favorites';
  static const _kMaxRecents = 16;

  final _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  /// null = "Todos"; 'recientes' / 'favoritos' son pseudo-categorías.
  String? _activeCategory;

  List<IconData> _recents = const [];
  Set<int> _favorites = {};

  /// Índice codePoint → VexaIcon para reconstruir instancias const.
  static final Map<int, VexaIcon> _byCodePoint = {
    for (final i in kAllVexaIcons) i.icon.codePoint: i,
  };

  @override
  void initState() {
    super.initState();
    _loadPersisted();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPersisted() async {
    final recentsRaw = await LocalPrefsService.getString(_kRecentsKey);
    final favsRaw = await LocalPrefsService.getString(_kFavoritesKey);
    if (!mounted) return;
    setState(() {
      _recents = _parseCodePoints(
        recentsRaw,
      ).map((cp) => _byCodePoint[cp]?.icon).whereType<IconData>().toList();
      _favorites = _parseCodePoints(favsRaw).toSet();
    });
  }

  static List<int> _parseCodePoints(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw.split(',').map((s) => int.tryParse(s)).whereType<int>().toList();
  }

  Future<void> _select(IconData icon) async {
    Haptics.selectionClick();
    final cps = [
      icon.codePoint,
      ..._recents.map((i) => i.codePoint).where((c) => c != icon.codePoint),
    ].take(_kMaxRecents).toList();
    await LocalPrefsService.setString(_kRecentsKey, cps.join(','));
    if (mounted) Navigator.of(context).pop(icon);
  }

  Future<void> _toggleFavorite(IconData icon) async {
    Haptics.mediumImpact();
    setState(() {
      if (!_favorites.remove(icon.codePoint)) {
        _favorites.add(icon.codePoint);
      }
    });
    await LocalPrefsService.setString(_kFavoritesKey, _favorites.join(','));
  }

  List<VexaIcon> get _visibleIcons {
    if (_query.isNotEmpty) return searchVexaIcons(_query);
    if (_activeCategory == 'recientes') {
      return _recents
          .map((i) => _byCodePoint[i.codePoint])
          .whereType<VexaIcon>()
          .toList();
    }
    if (_activeCategory == 'favoritos') {
      return _favorites
          .map((cp) => _byCodePoint[cp])
          .whereType<VexaIcon>()
          .toList();
    }
    if (_activeCategory != null) {
      return kVexaIconCategories
          .firstWhere(
            (c) => c.id == _activeCategory,
            orElse: () => kVexaIconCategories.last,
          )
          .icons;
    }
    return kAllVexaIcons;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icons = _visibleIcons;
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: c.glassBorderStrong,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              14,
              AppSpacing.screenPadding,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Elige un icono',
                    style: AppTypography.headingS.copyWith(
                      color: c.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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

          // ── Búsqueda ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              12,
              AppSpacing.screenPadding,
              0,
            ),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: c.glass,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                border: Border.all(color: c.glassBorder, width: 0.5),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 150), () {
                    if (mounted) setState(() => _query = v);
                  });
                },
                style: TextStyle(color: c.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Buscar: café, gasolina, gym…',
                  hintStyle: TextStyle(color: c.textTertiary, fontSize: 13.5),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 17,
                    color: c.textTertiary,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _debounce?.cancel();
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: c.textTertiary,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 4,
                  ),
                ),
              ),
            ),
          ),

          // ── Chips de categorías ──────────────────────────────────────
          if (_query.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  children: [
                    _CategoryChip(
                      label: 'Todos',
                      icon: Icons.apps_rounded,
                      selected: _activeCategory == null,
                      color: widget.color,
                      onTap: () => setState(() => _activeCategory = null),
                    ),
                    if (_recents.isNotEmpty)
                      _CategoryChip(
                        label: 'Recientes',
                        icon: Icons.history_rounded,
                        selected: _activeCategory == 'recientes',
                        color: widget.color,
                        onTap: () =>
                            setState(() => _activeCategory = 'recientes'),
                      ),
                    if (_favorites.isNotEmpty)
                      _CategoryChip(
                        label: 'Favoritos',
                        icon: Icons.favorite_rounded,
                        selected: _activeCategory == 'favoritos',
                        color: widget.color,
                        onTap: () =>
                            setState(() => _activeCategory = 'favoritos'),
                      ),
                    ...kVexaIconCategories.map(
                      (cat) => _CategoryChip(
                        label: cat.label,
                        icon: cat.icon,
                        selected: _activeCategory == cat.id,
                        color: widget.color,
                        onTap: () => setState(() => _activeCategory = cat.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Grid ─────────────────────────────────────────────────────
          Flexible(
            child: icons.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: c.textTertiary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Sin resultados',
                            style: AppTypography.labelM.copyWith(
                              color: c.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.md,
                      AppSpacing.screenPadding,
                      AppSpacing.lg + MediaQuery.of(context).padding.bottom,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                        ),
                    itemCount: icons.length,
                    itemBuilder: (context, i) {
                      final entry = icons[i];
                      final isSel =
                          entry.icon.codePoint == widget.selected?.codePoint;
                      final isFav = _favorites.contains(entry.icon.codePoint);
                      return _IconCell(
                        entry: entry,
                        selected: isSel,
                        favorite: isFav,
                        color: widget.color,
                        onTap: () => _select(entry.icon),
                        onLongPress: () => _toggleFavorite(entry.icon),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Chip de categoría ─────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: () {
          Haptics.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.16) : c.glass,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.45) : c.glassBorder,
              width: selected ? 1 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 13, color: selected ? color : c.textTertiary),
              const SizedBox(width: 5),
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
      ),
    );
  }
}

// ── Celda de icono ────────────────────────────────────────────────────────────

class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.entry,
    required this.selected,
    required this.favorite,
    required this.color,
    required this.onTap,
    required this.onLongPress,
  });

  final VexaIcon entry;
  final bool selected;
  final bool favorite;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: entry.name,
      waitDuration: const Duration(milliseconds: 600),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.06),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Icon(
                  entry.icon,
                  size: 21,
                  color: selected ? color : c.textSecondary,
                ),
              ),
            ),
            if (favorite)
              Positioned(
                top: 3,
                right: 3,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 9,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
