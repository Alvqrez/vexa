import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum WalletCategoryType { income, expense }

extension WalletCategoryTypeX on WalletCategoryType {
  String get label => switch (this) {
        WalletCategoryType.income => 'Ingreso',
        WalletCategoryType.expense => 'Gasto',
      };
}

class WalletCategory {
  const WalletCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.type,
    required this.sortOrder,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final WalletCategoryType type;
  final int sortOrder;
  final bool isDefault;

  Color get surface => color.withValues(alpha: 0.18);

  static WalletCategory unknown(String id) => WalletCategory(
        id: id,
        name: id,
        color: AppColors.catOther,
        icon: Icons.category_rounded,
        type: WalletCategoryType.expense,
        sortOrder: 99,
      );

  WalletCategory copyWith({
    String? name,
    Color? color,
    IconData? icon,
    WalletCategoryType? type,
    int? sortOrder,
  }) {
    return WalletCategory(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault,
    );
  }
}

/// Resolves a WalletCategory by ID. Falls back to [WalletCategory.unknown] if not found.
WalletCategory resolveCategory(String id, List<WalletCategory> cats) {
  return cats.firstWhere((c) => c.id == id, orElse: () => WalletCategory.unknown(id));
}
