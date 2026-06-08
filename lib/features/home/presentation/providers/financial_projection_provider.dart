import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import 'home_provider.dart';

class ProjectionPoint {
  const ProjectionPoint({
    required this.date,
    required this.balance,
    required this.label,
  });

  final DateTime date;
  final double balance;
  final String label;
}

class FinancialProjection {
  const FinancialProjection({
    required this.projections,
    required this.averageMonthlyIncome,
    required this.averageMonthlyExpense,
    required this.upcomingSubscriptions,
  });

  final List<ProjectionPoint> projections;
  final double averageMonthlyIncome;
  final double averageMonthlyExpense;
  final int upcomingSubscriptions;

  double get monthlyNet => averageMonthlyIncome - averageMonthlyExpense;
  bool get isTrendingPositive => monthlyNet > 0;
}

final financialProjectionProvider = Provider<FinancialProjection>((ref) {
  final accounts = ref.watch(accountsProvider);
  final transactions = ref.watch(transactionsProvider);
  final subscriptions = ref.watch(subscriptionsProvider);

  // Calcular balance total actual
  final currentBalance = accounts.fold<double>(0, (sum, a) => sum + a.balance);

  // Análisis de transacciones últimos 30 días
  final thirtyDaysAgo =
      DateTime.now().subtract(const Duration(days: 30));
  final recentTransactions =
      transactions.where((t) => t.date.isAfter(thirtyDaysAgo)).toList();

  // Calcular ingresos y gastos promedio
  double totalIncome = 0;
  double totalExpense = 0;
  for (final tx in recentTransactions) {
    if (tx.isIncome) {
      totalIncome += tx.amount;
    } else {
      totalExpense += tx.amount;
    }
  }

  final averageMonthlyIncome =
      ((totalIncome / 30 * 30).clamp(0, double.infinity) as double);
  final averageMonthlyExpense =
      ((totalExpense / 30 * 30).clamp(0, double.infinity) as double);

  // Contar suscripciones activas en próximos 30 días
  final now = DateTime.now();
  final thirtyDaysFromNow = now.add(const Duration(days: 30));
  int upcomingSubscriptions = 0;

  for (final sub in subscriptions) {
    if (!sub.isActive) continue;
    final nextDate = DateTime.utc(
      sub.nextBillingDate.year,
      sub.nextBillingDate.month,
      sub.nextBillingDate.day,
    );
    final today = DateTime.utc(now.year, now.month, now.day);
    final inThirtyDays = DateTime.utc(
      thirtyDaysFromNow.year,
      thirtyDaysFromNow.month,
      thirtyDaysFromNow.day,
    );

    if ((nextDate.isAfter(today) || nextDate.isAtSameMomentAs(today)) &&
        nextDate.isBefore(inThirtyDays) ||
        nextDate.isAtSameMomentAs(inThirtyDays)) {
      upcomingSubscriptions++;
    }
  }

  // Generar proyecciones para próximos 90 días
  final projections = <ProjectionPoint>[];
  var projectedBalance = currentBalance;
  final monthlyNet = averageMonthlyIncome - averageMonthlyExpense;
  final dailyNet = monthlyNet / 30;

  projections.add(ProjectionPoint(
    date: now,
    balance: currentBalance,
    label: 'Hoy',
  ));

  for (int i = 1; i <= 90; i += 30) {
    final projectedDate = now.add(Duration(days: i));
    projectedBalance += (dailyNet * i);
    projections.add(ProjectionPoint(
      date: projectedDate,
      balance: projectedBalance,
      label: '${i}d',
    ));
  }

  return FinancialProjection(
    projections: projections,
    averageMonthlyIncome: averageMonthlyIncome,
    averageMonthlyExpense: averageMonthlyExpense,
    upcomingSubscriptions: upcomingSubscriptions,
  );
});
