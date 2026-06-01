import 'package:isar/isar.dart';
part 'isar_budget_item.g.dart';

@collection
class IsarBudgetItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String budgetId;
  late String name;
  late int iconCodePoint;
  late int colorValue;
  late double limit;
  String? categoryStr;  // TransactionCategory.name — null for custom
}
