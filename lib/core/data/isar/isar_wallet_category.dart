import 'package:isar/isar.dart';
part 'isar_wallet_category.g.dart';

@collection
class IsarWalletCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String categoryId;
  late String name;
  late int colorValue;
  late int iconCodePoint;
  late String typeStr;   // WalletCategoryType.name
  late int sortOrder;
  late bool isDefault;
}
