import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/models/transaction.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../loans/presentation/providers/loans_provider.dart';
import '../../../loans/domain/models/loan.dart';
import '../../../goals/presentation/providers/goals_provider.dart';

// Prefijos de comercio que la propia app asigna a las transacciones generadas
// por préstamos (ver LoansNotifier). Se usan para excluir esos movimientos
// puntuales del promedio diario, ya que se proyectan como eventos discretos.
bool _isLoanTx(Transaction t) =>
    t.merchant.startsWith('Préstamo: ') ||
    t.merchant.startsWith('Cobro préstamo: ') ||
    t.merchant.startsWith('Pago deuda: ');

/// Desglose de un horizonte de proyección (30, 60 o 90 días).
class CashflowWindow {
  const CashflowWindow({
    required this.days,
    required this.expectedIncome,
    required this.variableExpenses,
    required this.subscriptionCosts,
    required this.subscriptionCount,
    required this.loanInflows,
    required this.loanOutflows,
    required this.projectedBalance,
  });

  final int days;
  final double expectedIncome; // ingresos estimados (promedio histórico)
  final double variableExpenses; // gasto variable estimado
  final double subscriptionCosts; // cobros de suscripciones en la ventana
  final int subscriptionCount;
  final double loanInflows; // préstamos por cobrar que vencen
  final double loanOutflows; // préstamos por pagar que vencen
  final double projectedBalance;

  double get netFlow =>
      expectedIncome + loanInflows -
      variableExpenses -
      subscriptionCosts -
      loanOutflows;
}

/// Proyección completa de flujo de caja con puntos diarios para graficar.
class CashflowProjection {
  const CashflowProjection({
    required this.currentBalance,
    required this.windows,
    required this.dailyBalances,
    required this.avgDailyIncome,
    required this.avgDailyExpense,
    required this.activeGoalsTarget,
    required this.activeGoalsSaved,
    required this.hasHistory,
  });

  final double currentBalance;

  /// Ventanas a 30, 60 y 90 días.
  final List<CashflowWindow> windows;

  /// Balance proyectado por día (índice 0 = hoy) para los próximos 90 días.
  final List<double> dailyBalances;

  final double avgDailyIncome;
  final double avgDailyExpense;
  final double activeGoalsTarget;
  final double activeGoalsSaved;
  final bool hasHistory;

  bool get isTrendingPositive =>
      dailyBalances.isNotEmpty && dailyBalances.last >= currentBalance;
}

final cashflowProjectionProvider = Provider<CashflowProjection>((ref) {
  final accounts = ref.watch(accountsProvider);
  final transactions = ref.watch(transactionsProvider);
  final subscriptions =
      ref.watch(subscriptionsProvider).where((s) => s.isActive).toList();
  final loans = ref.watch(loansProvider).where((l) => !l.isSettled).toList();
  final goals = ref.watch(activeGoalsProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final currentBalance =
      accounts.fold<double>(0, (sum, a) => sum + a.balance);

  // ── Promedios históricos (últimos 60 días, sin contar hoy a medias) ────────
  final sixtyAgo = today.subtract(const Duration(days: 60));
  final recent =
      transactions.where((t) => t.date.isAfter(sixtyAgo)).toList();

  // Span real de datos: días entre la transacción más antigua de la ventana y
  // hoy. `recent` viene ordenado por fecha desc, así que `last` es la más vieja.
  final histDays = recent.isEmpty
      ? 0
      : today
              .difference(DateTime(
                recent.last.date.year,
                recent.last.date.month,
                recent.last.date.day,
              ))
              .inDays
              .clamp(1, 60);

  // El promedio diario debe reflejar SOLO el gasto/ingreso variable recurrente.
  // Las suscripciones y los préstamos se modelan como eventos discretos más
  // abajo; si además quedaran en el promedio se contarían dos veces:
  //  • Préstamos: la app crea transacciones con prefijos conocidos al originar
  //    o pagar un préstamo → se excluyen aquí (son movimientos puntuales).
  //  • Suscripciones: sus cargos sí son transacciones normales y no se pueden
  //    identificar de forma fiable, así que se descuenta su equivalente
  //    mensual amortizado del promedio de gasto.
  double totalIncome = 0;
  double totalExpense = 0;
  for (final t in recent) {
    if (_isLoanTx(t)) continue; // modelado discretamente (loanIn/Out)
    if (t.isIncome) {
      totalIncome += t.amount;
    } else {
      totalExpense += t.amount;
    }
  }
  final rawAvgDailyIncome = histDays > 0 ? totalIncome / histDays : 0.0;
  final rawAvgDailyExpense = histDays > 0 ? totalExpense / histDays : 0.0;

  final monthlySubsTotal =
      subscriptions.fold<double>(0, (s, sub) => s + sub.monthlyEquivalent);
  final dailySubs = monthlySubsTotal / 30.44; // días promedio por mes
  final avgDailyIncome = rawAvgDailyIncome;
  // Resta la parte amortizada de suscripciones para no doble-contarlas.
  final avgDailyExpense =
      (rawAvgDailyExpense - dailySubs).clamp(0.0, double.infinity);

  // ── Eventos puntuales: suscripciones y préstamos por día ───────────────────
  // outflowOn[d] / inflowOn[d]: movimientos del día `d` (1..90)
  final outflowOn = List<double>.filled(91, 0);
  final inflowOn = List<double>.filled(91, 0);
  final subCountByWindow = <int, int>{30: 0, 60: 0, 90: 0};
  final subCostByWindow = <int, double>{30: 0, 60: 0, 90: 0};

  for (final sub in subscriptions) {
    var billing = sub.nextBillingDate;
    // Normalizar fechas pasadas: la primera factura cuenta como inmediata
    var guard = 0;
    while (billing.isBefore(today) && guard < 24) {
      billing = sub.copyWith(nextBillingDate: billing).nextAfterCurrent;
      guard++;
    }
    while (guard < 24) {
      final offset = DateTime(billing.year, billing.month, billing.day)
          .difference(today)
          .inDays;
      if (offset > 90) break;
      if (offset >= 0) {
        outflowOn[offset == 0 ? 1 : offset] += sub.amount;
        for (final w in [30, 60, 90]) {
          if (offset <= w) {
            subCostByWindow[w] = subCostByWindow[w]! + sub.amount;
            subCountByWindow[w] = subCountByWindow[w]! + 1;
          }
        }
      }
      billing = sub.copyWith(nextBillingDate: billing).nextAfterCurrent;
      guard++;
    }
  }

  final loanInByWindow = <int, double>{30: 0, 60: 0, 90: 0};
  final loanOutByWindow = <int, double>{30: 0, 60: 0, 90: 0};
  for (final loan in loans) {
    final due = loan.dueDate;
    if (due == null) continue;
    final offset =
        DateTime(due.year, due.month, due.day).difference(today).inDays;
    if (offset < 0 || offset > 90) continue;
    final day = offset == 0 ? 1 : offset;
    if (loan.type == LoanType.lentByMe) {
      inflowOn[day] += loan.remainingAmount;
    } else {
      outflowOn[day] += loan.remainingAmount;
    }
    for (final w in [30, 60, 90]) {
      if (offset <= w) {
        if (loan.type == LoanType.lentByMe) {
          loanInByWindow[w] = loanInByWindow[w]! + loan.remainingAmount;
        } else {
          loanOutByWindow[w] = loanOutByWindow[w]! + loan.remainingAmount;
        }
      }
    }
  }

  // ── Curva diaria de balance ─────────────────────────────────────────────────
  final dailyBalances = List<double>.filled(91, 0);
  dailyBalances[0] = currentBalance;
  for (var d = 1; d <= 90; d++) {
    dailyBalances[d] = dailyBalances[d - 1] +
        avgDailyIncome -
        avgDailyExpense +
        inflowOn[d] -
        outflowOn[d];
  }

  // ── Ventanas 30/60/90 ───────────────────────────────────────────────────────
  final windows = [30, 60, 90].map((w) {
    return CashflowWindow(
      days: w,
      expectedIncome: avgDailyIncome * w,
      variableExpenses: avgDailyExpense * w,
      subscriptionCosts: subCostByWindow[w]!,
      subscriptionCount: subCountByWindow[w]!,
      loanInflows: loanInByWindow[w]!,
      loanOutflows: loanOutByWindow[w]!,
      projectedBalance: dailyBalances[w],
    );
  }).toList();

  final goalsTarget = goals.fold(0.0, (s, g) => s + g.target);
  final goalsSaved = goals.fold(0.0, (s, g) => s + g.current);

  return CashflowProjection(
    currentBalance: currentBalance,
    windows: windows,
    dailyBalances: dailyBalances,
    avgDailyIncome: avgDailyIncome,
    avgDailyExpense: avgDailyExpense,
    activeGoalsTarget: goalsTarget,
    activeGoalsSaved: goalsSaved,
    // Requiere un historial REAL: al menos 5 movimientos repartidos en ≥14
    // días. Con datos concentrados en 1-2 días, dividir por un span minúsculo
    // dispararía los promedios y la proyección sería irreal.
    hasHistory: recent.length >= 5 && histDays >= 14,
  );
});
