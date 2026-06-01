import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar/isar_transaction.dart';
import 'isar/isar_account.dart';
import 'isar/isar_wallet_category.dart';
import 'isar/isar_subscription.dart';
import 'isar/isar_financial_goal.dart';
import 'isar/isar_budget_item.dart';

export 'isar/isar_transaction.dart';
export 'isar/isar_account.dart';
export 'isar/isar_wallet_category.dart';
export 'isar/isar_subscription.dart';
export 'isar/isar_financial_goal.dart';
export 'isar/isar_budget_item.dart';

Future<Isar> openIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      IsarTransactionSchema,
      IsarAccountSchema,
      IsarWalletCategorySchema,
      IsarSubscriptionSchema,
      IsarFinancialGoalSchema,
      IsarBudgetItemSchema,
    ],
    directory: dir.path,
    name: 'vexa_finance',
  );
}
