import 'package:flutter/material.dart';

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
