import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../domain/models/subcategory.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../../../core/utils/id_gen.dart';

// ── Isar converters ───────────────────────────────────────────────────────────

IsarSubcategory _subToIsar(Subcategory s) => IsarSubcategory()
  ..subId = s.id
  ..categoryId = s.categoryId
  ..name = s.name
  ..iconCodePoint = s.icon.codePoint
  ..colorValue = s.color?.toARGB32()
  ..sortOrder = s.sortOrder
  ..createdAt = s.createdAt
  ..isDefault = s.isDefault;

Subcategory _isarToSub(IsarSubcategory i) => Subcategory(
  id: i.subId,
  categoryId: i.categoryId,
  name: i.name,
  icon: IconData(i.iconCodePoint, fontFamily: 'MaterialIcons'),
  color: i.colorValue != null ? Color(i.colorValue!) : null,
  sortOrder: i.sortOrder,
  createdAt: i.createdAt,
  isDefault: i.isDefault,
);

// ── Subcategorías predeterminadas ─────────────────────────────────────────────
// Solo se siembran una vez (flag en prefs) y solo para las categorías default
// que existan en ese momento. Si el usuario las borra, no reaparecen.

({String name, IconData icon}) _d(String name, IconData icon) =>
    (name: name, icon: icon);

final Map<String, List<({String name, IconData icon})>> _kDefaultSubs = {
  // Comida
  'wc1': [
    _d('Restaurantes', Icons.restaurant_rounded),
    _d('Café', Icons.local_cafe_rounded),
    _d('Fast Food', Icons.fastfood_rounded),
    _d('Súper', Icons.local_grocery_store_rounded),
    _d('Refrescos', Icons.local_drink_rounded),
    _d('Antojitos', Icons.tapas_rounded),
    _d('Delivery', Icons.delivery_dining_rounded),
  ],
  // Transporte
  'wc2': [
    _d('Gasolina', Icons.local_gas_station_rounded),
    _d('Taxi / Uber', Icons.local_taxi_rounded),
    _d('Autobús', Icons.directions_bus_rounded),
    _d('Estacionamiento', Icons.local_parking_rounded),
    _d('Casetas', Icons.toll_rounded),
    _d('Mantenimiento', Icons.car_repair_rounded),
  ],
  // Compras
  'wc3': [
    _d('Ropa', Icons.checkroom_rounded),
    _d('Tecnología', Icons.devices_rounded),
    _d('Hogar', Icons.chair_rounded),
    _d('Regalos', Icons.card_giftcard_rounded),
    _d('Online', Icons.shopping_cart_rounded),
  ],
  // Entretenimiento
  'wc4': [
    _d('Cine', Icons.movie_rounded),
    _d('Streaming', Icons.live_tv_rounded),
    _d('Videojuegos', Icons.sports_esports_rounded),
    _d('Eventos', Icons.music_video_rounded),
    _d('Salidas', Icons.nightlife_rounded),
  ],
  // Salud
  'wc5': [
    _d('Farmacia', Icons.local_pharmacy_rounded),
    _d('Consultas', Icons.medical_services_rounded),
    _d('Gimnasio', Icons.fitness_center_rounded),
    _d('Dentista', Icons.medical_information_rounded),
    _d('Cuidado personal', Icons.face_retouching_natural_rounded),
  ],
  // Salario
  'wc7': [
    _d('Nómina', Icons.badge_rounded),
    _d('Bonos', Icons.emoji_events_rounded),
    _d('Aguinaldo', Icons.redeem_rounded),
  ],
  // Freelance
  'wc8': [
    _d('Proyectos', Icons.rocket_launch_rounded),
    _d('Ventas', Icons.point_of_sale_rounded),
    _d('Comisiones', Icons.paid_rounded),
  ],
};

const _kSeedFlag = 'subcategories_seeded_v1';

// ── Notifier ──────────────────────────────────────────────────────────────────

class SubcategoriesNotifier extends StateNotifier<List<Subcategory>> {
  SubcategoriesNotifier(this._isar) : super(const []) {
    _load();
  }

  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    try {
      final records = await _isar.isarSubcategorys.where().findAll();
      if (_isLoaded) return;
      if (records.isEmpty) {
        final seeded = await LocalPrefsService.getBool(_kSeedFlag);
        if (!seeded) {
          await _seedDefaults();
          await LocalPrefsService.setBool(_kSeedFlag, true);
        }
      } else {
        state = records.map(_isarToSub).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('SubcategoriesNotifier._load failed: $e');
      _isLoaded = false;
    }
  }

  Future<void> _seedDefaults() async {
    // Solo sembrar bajo categorías default que existan en la BD ahora mismo.
    final existingCats = await _isar.isarWalletCategorys.where().findAll();
    final existingIds = existingCats.map((c) => c.categoryId).toSet();
    final now = DateTime.now();
    final seeded = <Subcategory>[];
    _kDefaultSubs.forEach((catId, subs) {
      if (existingIds.isNotEmpty && !existingIds.contains(catId)) return;
      for (var i = 0; i < subs.length; i++) {
        seeded.add(
          Subcategory(
            id: generateId(),
            categoryId: catId,
            name: subs[i].name,
            icon: subs[i].icon,
            sortOrder: i,
            createdAt: now,
            isDefault: true,
          ),
        );
      }
    });
    state = seeded;
    await _isar.writeTxn(
      () => _isar.isarSubcategorys.putAll(seeded.map(_subToIsar).toList()),
    );
  }

  Future<void> _persistAll() => _isar.writeTxn(() async {
    await _isar.isarSubcategorys.clear();
    await _isar.isarSubcategorys.putAll(state.map(_subToIsar).toList());
  });

  Future<void> add(Subcategory sub) async {
    _isLoaded = true;
    state = [...state, sub];
    await _isar.writeTxn(() => _isar.isarSubcategorys.put(_subToIsar(sub)));
  }

  /// Crea una subcategoría al final de su categoría y la devuelve.
  Future<Subcategory> create({
    required String categoryId,
    required String name,
    required IconData icon,
    Color? color,
  }) async {
    final sortOrder = state.where((s) => s.categoryId == categoryId).length;
    final sub = Subcategory(
      id: generateId(),
      categoryId: categoryId,
      name: name,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
    await add(sub);
    return sub;
  }

  Future<void> update(Subcategory updated) async {
    _isLoaded = true;
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
    await _persistAll();
  }

  Future<void> delete(String id) async {
    _isLoaded = true;
    state = state.where((s) => s.id != id).toList();
    await _isar.writeTxn(() => _isar.isarSubcategorys.deleteBySubId(id));
  }

  /// Elimina todas las subcategorías de una categoría (al borrar el padre).
  Future<void> deleteByCategory(String categoryId) async {
    _isLoaded = true;
    state = state.where((s) => s.categoryId != categoryId).toList();
    await _isar.writeTxn(
      () => _isar.isarSubcategorys
          .filter()
          .categoryIdEqualTo(categoryId)
          .deleteAll(),
    );
  }

  /// [newIndex] ya viene ajustado (callback onReorderItem).
  Future<void> reorder(String categoryId, int oldIndex, int newIndex) async {
    _isLoaded = true;
    final filtered = state.where((s) => s.categoryId == categoryId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (oldIndex < 0 || oldIndex >= filtered.length) return;
    final item = filtered.removeAt(oldIndex);
    filtered.insert(newIndex.clamp(0, filtered.length), item);

    final reordered = [
      for (final (i, s) in filtered.indexed) s.copyWith(sortOrder: i),
    ];
    state = [...state.where((s) => s.categoryId != categoryId), ...reordered];
    await _persistAll();
  }
}

final subcategoriesProvider =
    StateNotifierProvider<SubcategoriesNotifier, List<Subcategory>>(
      (ref) => SubcategoriesNotifier(ref.watch(isarProvider)),
    );

/// Subcategorías de una categoría, ordenadas por sortOrder.
final subcategoriesByCategoryProvider =
    Provider.family<List<Subcategory>, String>((ref, categoryId) {
      return ref
          .watch(subcategoriesProvider)
          .where((s) => s.categoryId == categoryId)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    });
