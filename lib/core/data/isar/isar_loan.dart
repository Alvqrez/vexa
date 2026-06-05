import 'package:isar/isar.dart';
part 'isar_loan.g.dart';

@collection
class IsarLoan {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String loanId;
  late String name;
  late double amount;
  late double paidAmount;
  late String typeStr;
  late DateTime date;
  String? accountId;
  DateTime? dueDate;
  late int iconCodePoint;
  late int colorValue;
  String? note;
}
