import 'package:isar/isar.dart';
part 'isar_subcategory.g.dart';

@collection
class IsarSubcategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String subId;

  @Index()
  late String categoryId;

  late String name;
  late int iconCodePoint;
  int? colorValue; // null → hereda el color de la categoría padre
  late int sortOrder;
  late DateTime createdAt;
  late bool isDefault;
}
