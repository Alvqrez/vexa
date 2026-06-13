import 'package:isar/isar.dart';
part 'isar_transaction.g.dart';

@collection
class IsarTransaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String txId;
  late String merchant;
  late double amount;
  late String typeStr;      // 'income' | 'expense'
  late String categoryStr;  // TransactionCategory.name
  String? subcategoryId;    // Subcategory.id — null para transacciones sin subcategoría
  late DateTime date;
  String? accountId;
  String? note;
  late List<String> tags = [];
  late List<String> imagePaths = [];
}
