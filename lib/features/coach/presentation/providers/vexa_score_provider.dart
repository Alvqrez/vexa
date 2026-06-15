import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/local_prefs_service.dart';
import '../../domain/models/vexa_score.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../budget/presentation/providers/budget_provider.dart';

/// Calcula el Vexa Score con reglas y estadísticas locales.
final vexaScoreProvider = Provider<VexaScore>((ref) {
  final income = ref.watch(monthlyIncomeProvider);
  final expenses = ref.watch(monthlyExpensesProvider);
  final savings = ref.watch(monthlySavingsProvider);
  final transactions = ref.watch(transactionsProvider);
  final budgets = ref.watch(budgetWithSpentProvider);

  final hasData = transactions.isNotEmpty;
  if (!hasData) return VexaScore.empty;

  // ── 1. Ahorro (25%): neto + transferencias a ahorro vs objetivo 20% ────────
  double savingsScore;
  if (income > 0) {
    final net = (income - expenses).clamp(0.0, double.infinity);
    final effectiveSavings = savings > net ? savings : net;
    savingsScore =
        ((effectiveSavings / income) / 0.20 * 100).clamp(0.0, 100.0);
  } else {
    savingsScore = 0;
  }

  // ── 2. Presupuesto (25%): cumplimiento promedio de límites ─────────────────
  double budgetScore;
  if (budgets.isNotEmpty) {
    var total = 0.0;
    for (final b in budgets) {
      final ratio = b.ratio;
      if (ratio <= 0.8) {
        total += 100;
      } else if (ratio <= 1.0) {
        total += 100 - (ratio - 0.8) * 200; // 100 → 60
      } else {
        total += (60 - (ratio - 1.0) * 120).clamp(0.0, 60.0);
      }
    }
    budgetScore = total / budgets.length;
  } else {
    // Sin presupuestos: usar relación gasto/ingreso como aproximación
    budgetScore = income > 0
        ? ((1 - expenses / income) * 100).clamp(0.0, 100.0)
        : 40;
  }

  // ── 3. Consistencia (20%): días con registros en los últimos 30 ────────────
  final now = DateTime.now();
  final thirtyAgo = now.subtract(const Duration(days: 30));
  final activeDays = transactions
      .where((t) => t.date.isAfter(thirtyAgo))
      .map((t) => '${t.date.year}-${t.date.month}-${t.date.day}')
      .toSet()
      .length;
  // 12+ días activos en el mes = constancia plena
  final consistencyScore = (activeDays / 12 * 100).clamp(0.0, 100.0);

  // ── 4. Control de excesos (15%): días de gasto desproporcionado ────────────
  final dayTotals = <String, double>{};
  for (final t in transactions) {
    if (t.isIncome) continue;
    if (t.date.month != now.month || t.date.year != now.year) continue;
    final key = '${t.date.day}';
    dayTotals[key] = (dayTotals[key] ?? 0) + t.amount;
  }
  double excessScore = 100;
  if (dayTotals.length >= 3) {
    final values = dayTotals.values.toList()..sort();
    final median = values[values.length ~/ 2];
    if (median > 0) {
      final excessDays =
          values.where((v) => v > median * 2.5 && v > 50).length;
      excessScore = (100.0 - excessDays * 25).clamp(0.0, 100.0);
    }
  }

  // ── 5. Salud general (15%) ──────────────────────────────────────────────────
  double healthScore = 0;
  if (income > 0) healthScore += 40;
  if (income >= expenses) healthScore += 35;
  if (savings > 0) healthScore += 25;

  final score = (savingsScore * 0.25 +
          budgetScore * 0.25 +
          consistencyScore * 0.20 +
          excessScore * 0.15 +
          healthScore * 0.15)
      .clamp(0.0, 100.0);

  return VexaScore(
    score: score,
    savingsScore: savingsScore,
    budgetScore: budgetScore,
    consistencyScore: consistencyScore,
    excessScore: excessScore,
    healthScore: healthScore,
    hasData: true,
  );
});

String _weekKey(DateTime d) {
  // Lunes de la semana como clave estable
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

/// Diferencia del score contra la semana pasada. Persiste el valor semanal
/// en LocalPrefs y devuelve null si todavía no hay historial comparable.
final vexaScoreDeltaProvider = FutureProvider<double?>((ref) async {
  final score = ref.watch(vexaScoreProvider).score;
  const storageKey = 'vexa_score_history';

  Map<String, dynamic> history = {};
  try {
    final raw = await LocalPrefsService.getString(storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) history = decoded;
    }
  } catch (e) {
    debugPrint('vexaScoreDeltaProvider: error reading history: $e');
  }

  final now = DateTime.now();
  final thisWeek = _weekKey(now);
  final lastWeek = _weekKey(now.subtract(const Duration(days: 7)));
  final prevValue = (history[lastWeek] as num?)?.toDouble();

  final roundedScore = double.parse(score.toStringAsFixed(1));
  final alreadyStored = (history[thisWeek] as num?)?.toDouble();

  // Only persist when the score actually changed — avoids a disk write on every rebuild.
  if (alreadyStored != roundedScore) {
    history[thisWeek] = roundedScore;

    // Conservar solo las últimas 26 semanas
    if (history.length > 26) {
      final keys = history.keys.toList()..sort();
      while (keys.length > 26) {
        history.remove(keys.removeAt(0));
      }
    }

    try {
      await LocalPrefsService.setString(storageKey, jsonEncode(history));
    } catch (e) {
      debugPrint('vexaScoreDeltaProvider: error saving history: $e');
    }
  }

  return prevValue == null ? null : score - prevValue;
});
