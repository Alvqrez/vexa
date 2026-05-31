import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health.dart';
import '../../../home/presentation/providers/home_provider.dart';

final financialHealthProvider = Provider<FinancialHealth>((ref) {
  final income = ref.watch(monthlyIncomeProvider);
  final expenses = ref.watch(monthlyExpensesProvider);
  final savings = ref.watch(monthlySavingsProvider);

  return FinancialHealth.compute(
    income: income,
    expenses: expenses,
    savings: savings,
  );
});
