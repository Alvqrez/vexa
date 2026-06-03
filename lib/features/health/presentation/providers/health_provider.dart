import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/financial_health.dart';
import '../../../home/presentation/providers/home_provider.dart';

final financialHealthProvider = Provider<FinancialHealth>((ref) {
  final income = ref.watch(monthlyIncomeProvider);
  final expenses = ref.watch(monthlyExpensesProvider);
  // Health score uses net (income − expenses), not savings transfers,
  // so it reflects actual spending discipline regardless of whether the
  // user has a savings account configured.
  final net = income - expenses;

  return FinancialHealth.compute(
    income: income,
    expenses: expenses,
    savings: net,
  );
});
