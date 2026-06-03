import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum TransactionType { income, expense }

enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  health,
  salary,
  other,
}

extension TransactionCategoryX on TransactionCategory {
  String get label => switch (this) {
        TransactionCategory.food => 'Comida',
        TransactionCategory.transport => 'Transporte',
        TransactionCategory.shopping => 'Compras',
        TransactionCategory.entertainment => 'Entretenimiento',
        TransactionCategory.health => 'Salud',
        TransactionCategory.salary => 'Salario',
        TransactionCategory.other => 'Otro',
      };

  IconData get icon => switch (this) {
        TransactionCategory.food => Icons.fork_right_rounded,
        TransactionCategory.transport => Icons.directions_car_rounded,
        TransactionCategory.shopping => Icons.shopping_bag_rounded,
        TransactionCategory.entertainment => Icons.movie_rounded,
        TransactionCategory.health => Icons.favorite_rounded,
        TransactionCategory.salary => Icons.work_rounded,
        TransactionCategory.other => Icons.category_rounded,
      };

  Color get color => switch (this) {
        TransactionCategory.food => AppColors.catFood,
        TransactionCategory.transport => AppColors.catTransport,
        TransactionCategory.shopping => AppColors.catShopping,
        TransactionCategory.entertainment => AppColors.catEntertainment,
        TransactionCategory.health => AppColors.catHealth,
        TransactionCategory.salary => AppColors.emerald,
        TransactionCategory.other => AppColors.catOther,
      };

  Color get surface => switch (this) {
        TransactionCategory.food => AppColors.catFoodSurface,
        TransactionCategory.transport => AppColors.catTransportSurface,
        TransactionCategory.shopping => AppColors.catShoppingSurface,
        TransactionCategory.entertainment => AppColors.catEntertainmentSurface,
        TransactionCategory.health => AppColors.catHealthSurface,
        TransactionCategory.salary => AppColors.emeraldSurface,
        TransactionCategory.other => AppColors.catOtherSurface,
      };
}

class Transaction {
  const Transaction({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.accountId,
    this.note,
    this.tags = const [],
  });

  final String id;
  final String merchant;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? accountId;
  final String? note;
  final List<String> tags;

  bool get isIncome => type == TransactionType.income;

  String formattedWith(String symbol) {
    final sign = isIncome ? '+' : '-';
    return '$sign$symbol${amount.toStringAsFixed(2)}';
  }

  Transaction copyWith({
    String? merchant,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? accountId,
    String? note,
    List<String>? tags,
    bool clearNote = false,
  }) {
    return Transaction(
      id: id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      note: clearNote ? null : (note ?? this.note),
      tags: tags ?? this.tags,
    );
  }
}
