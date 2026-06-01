import 'package:isar/isar.dart';
part 'isar_subscription.g.dart';

@collection
class IsarSubscription {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String subscriptionId;
  late String name;
  late double amount;
  late DateTime nextBillingDate;
  late String categoryStr;    // TransactionCategory.name
  late int iconCodePoint;
  late int colorValue;
  late String frequencyStr;   // SubscriptionFrequency.name
  late bool isActive;
  String? note;
}
