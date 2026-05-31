import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/wallet_category.dart';
import '../../../../core/theme/app_colors.dart';

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
  WalletCategoriesNotifier() : super(_defaultCategories);

  void add(WalletCategory category) {
    state = [...state, category];
  }

  void update(WalletCategory updated) {
    state = [
      for (final c in state) if (c.id == updated.id) updated else c,
    ];
  }

  void delete(String id) {
    state = state.where((c) => c.id != id && c.isDefault == false).toList();
  }

  void reorder(int oldIndex, int newIndex, WalletCategoryType type) {
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
  }
}

final walletCategoriesProvider =
    StateNotifierProvider<WalletCategoriesNotifier, List<WalletCategory>>(
  (ref) => WalletCategoriesNotifier(),
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
