enum TransactionType { income, expense }

class Transaction {
  const Transaction({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.type,
    required this.category,
    this.subcategoryId,
    required this.date,
    this.accountId,
    this.note,
    this.tags = const [],
    this.imagePaths = const [],
  });

  final String id;
  final String merchant;
  final double amount;
  final TransactionType type;
  /// WalletCategory.id (e.g. 'wc1'). Stored as-is in Isar.
  final String category;
  /// Subcategory.id — null cuando la transacción no tiene subcategoría.
  final String? subcategoryId;
  final DateTime date;
  final String? accountId;
  final String? note;
  final List<String> tags;
  /// Absolute paths to attached receipt/ticket photos on local storage.
  final List<String> imagePaths;

  bool get isIncome => type == TransactionType.income;

  String formattedWith(String symbol) {
    final sign = isIncome ? '+' : '-';
    return '$sign$symbol${amount.toStringAsFixed(2)}';
  }

  Transaction copyWith({
    String? merchant,
    double? amount,
    TransactionType? type,
    String? category,
    String? subcategoryId,
    DateTime? date,
    String? accountId,
    String? note,
    List<String>? tags,
    List<String>? imagePaths,
    bool clearNote = false,
    bool clearSubcategory = false,
  }) {
    return Transaction(
      id: id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      subcategoryId:
          clearSubcategory ? null : (subcategoryId ?? this.subcategoryId),
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      note: clearNote ? null : (note ?? this.note),
      tags: tags ?? this.tags,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
