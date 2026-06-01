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
  late DateTime date;
  String? accountId;
  String? note;
  late List<String> tags;
}
