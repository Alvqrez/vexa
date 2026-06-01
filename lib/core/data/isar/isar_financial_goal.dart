import 'package:isar/isar.dart';
part 'isar_financial_goal.g.dart';

@collection
class IsarFinancialGoal {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String goalId;
  late String title;
  late int iconCodePoint;
  late int colorValue;
  late double current;
  late double target;
  late DateTime deadline;
  late bool completed;
}
