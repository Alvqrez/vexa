import 'package:isar/isar.dart';
part 'isar_account.g.dart';

@collection
class IsarAccount {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String accountId;
  late String name;
  late double balance;
  late int colorValue;   // Color.toARGB32()
  late String iconStr;   // AccountIcon.name
}
