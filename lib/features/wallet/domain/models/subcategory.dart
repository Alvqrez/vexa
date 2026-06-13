import 'package:flutter/material.dart';

/// Subcategoría de una [WalletCategory]. Vive bajo una categoría padre
/// (categoryId) y puede tener color propio o heredar el del padre.
class Subcategory {
  const Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.icon,
    this.color,
    required this.sortOrder,
    required this.createdAt,
    this.isDefault = false,
  });

  final String id;
  final String categoryId;
  final String name;
  final IconData icon;

  /// Color propio. Si es null, la UI usa el color de la categoría padre.
  final Color? color;
  final int sortOrder;
  final DateTime createdAt;
  final bool isDefault;

  /// Color efectivo dado el color de la categoría padre.
  Color effectiveColor(Color parentColor) => color ?? parentColor;

  Subcategory copyWith({
    String? name,
    IconData? icon,
    Color? color,
    int? sortOrder,
    String? categoryId,
    bool clearColor = false,
  }) {
    return Subcategory(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: clearColor ? null : (color ?? this.color),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      isDefault: isDefault,
    );
  }
}

/// Resuelve una subcategoría por ID. Devuelve null si no existe (p. ej. fue
/// eliminada) — la UI debe ocultar la subcategoría con elegancia en ese caso.
Subcategory? resolveSubcategory(String? id, List<Subcategory> subs) {
  if (id == null) return null;
  for (final s in subs) {
    if (s.id == id) return s;
  }
  return null;
}
