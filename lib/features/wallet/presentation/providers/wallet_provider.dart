import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../domain/models/wallet_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/isar_provider.dart';
import '../../../../core/data/isar_service.dart';
import 'subcategories_provider.dart';

// ── Isar converters ───────────────────────────────────────────────────────────

IsarWalletCategory _catToIsar(WalletCategory c) => IsarWalletCategory()
  ..categoryId = c.id
  ..name = c.name
  ..colorValue = c.color.toARGB32()
  ..iconCodePoint = c.icon.codePoint
  ..typeStr = c.type.name
  ..sortOrder = c.sortOrder
  ..isDefault = c.isDefault;

WalletCategory _isarToCat(IsarWalletCategory ic) => WalletCategory(
      id: ic.categoryId,
      name: ic.name,
      color: Color(ic.colorValue),
      icon: IconData(ic.iconCodePoint, fontFamily: 'MaterialIcons'),
      type: WalletCategoryType.values.firstWhere(
        (t) => t.name == ic.typeStr,
        orElse: () => WalletCategoryType.expense,
      ),
      sortOrder: ic.sortOrder,
      isDefault: ic.isDefault,
    );

final _defaultCategories = [
  const WalletCategory(
    id: 'wc1',
    name: 'Comida',
    color: AppColors.catFood,
    icon: Icons.fork_right_rounded,
    type: WalletCategoryType.expense,
    sortOrder: 0,
    isDefault: true,
  ),
  const WalletCategory(
    id: 'wc2',
    name: 'Transporte',
    color: AppColors.catTransport,
    icon: Icons.directions_car_rounded,
    type: WalletCategoryType.expense,
    sortOrder: 1,
    isDefault: true,
  ),
  const WalletCategory(
    id: 'wc3',
    name: 'Compras',
    color: AppColors.catShopping,
    icon: Icons.shopping_bag_rounded,
    type: WalletCategoryType.expense,
    sortOrder: 2,
    isDefault: true,
  ),
  const WalletCategory(
    id: 'wc4',
    name: 'Entretenimiento',
    color: AppColors.catEntertainment,
    icon: Icons.movie_rounded,
    type: WalletCategoryType.expense,
    sortOrder: 3,
    isDefault: true,
  ),
  const WalletCategory(
    id: 'wc5',
    name: 'Salud',
    color: AppColors.catHealth,
    icon: Icons.favorite_rounded,
    type: WalletCategoryType.expense,
    sortOrder: 4,
    isDefault: true,
  ),
  const WalletCategory(
    id: 'wc6',
    name: 'Otro',
    color: AppColors.catOther,
    icon: Icons.category_rounded,
    type: WalletCategoryType.expense,
    sortOrder: 5,
    isDefault: true,
  ),
  const WalletCategory(
    id: 'wc7',
    name: 'Salario',
    color: AppColors.emerald,
    icon: Icons.work_rounded,
    type: WalletCategoryType.income,
    sortOrder: 0,
    isDefault: true,
  ),
  const WalletCategory(
    id: 'wc8',
    name: 'Freelance',
    color: AppColors.petroleum,
    icon: Icons.laptop_rounded,
    type: WalletCategoryType.income,
    sortOrder: 1,
    isDefault: true,
  ),
];

class WalletCategoriesNotifier extends StateNotifier<List<WalletCategory>> {
  WalletCategoriesNotifier(this._ref, this._isar) : super(_defaultCategories) {
    _load();
  }

  final Ref _ref;
  final Isar _isar;
  bool _isLoaded = false;

  Future<void> _load() async {
    if (_isLoaded) return;
    _isLoaded = true;
    try {
      final records = await _isar.isarWalletCategorys.where().findAll();
      if (records.isEmpty) {
        await _isar.writeTxn(() => _isar.isarWalletCategorys
            .putAll(state.map(_catToIsar).toList()));
      } else {
        state = records.map(_isarToCat).toList();
      }
    } catch (e) {
      debugPrint('WalletCategoriesNotifier._load failed: $e');
      _isLoaded = false;
      rethrow;
    }
  }

  Future<void> add(WalletCategory category) async {
    _isLoaded = true;
    state = [...state, category];
    await _isar.writeTxn(() => _isar.isarWalletCategorys.put(_catToIsar(category)));
  }

  Future<void> update(WalletCategory updated) async {
    _isLoaded = true;
    state = [
      for (final c in state) if (c.id == updated.id) updated else c,
    ];
    await _isar.writeTxn(
      () => _isar.isarWalletCategorys.putByCategoryId(_catToIsar(updated)),
    );
  }

  Future<void> delete(String id) async {
    _isLoaded = true;
    state = state.where((c) => c.id != id).toList();
    await _isar.writeTxn(() => _isar.isarWalletCategorys.deleteByCategoryId(id));
    // Cascade: las subcategorías huérfanas se eliminan junto al padre.
    await _ref.read(subcategoriesProvider.notifier).deleteByCategory(id);
  }

  Future<void> reorder(int oldIndex, int newIndex, WalletCategoryType type) async {
    _isLoaded = true;
    final filtered = state
        .where((c) => c.type == type)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final item = filtered.removeAt(oldIndex);
    filtered.insert(newIndex, item);

    final reordered = filtered.asMap().entries.map((e) {
      return e.value.copyWith(sortOrder: e.key);
    }).toList();

    state = [
      ...state.where((c) => c.type != type),
      ...reordered,
    ];
    await _isar.writeTxn(
      () => _isar.isarWalletCategorys
          .putAllByCategoryId(reordered.map(_catToIsar).toList()),
    );
  }
}

final walletCategoriesProvider =
    StateNotifierProvider<WalletCategoriesNotifier, List<WalletCategory>>(
  (ref) => WalletCategoriesNotifier(ref, ref.watch(isarProvider)),
);

final expenseCategoriesProvider = Provider<List<WalletCategory>>((ref) {
  return ref
      .watch(walletCategoriesProvider)
      .where((c) => c.type == WalletCategoryType.expense)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final incomeCategoriesProvider = Provider<List<WalletCategory>>((ref) {
  return ref
      .watch(walletCategoriesProvider)
      .where((c) => c.type == WalletCategoryType.income)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});
