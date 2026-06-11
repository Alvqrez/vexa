import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/domain/models/transaction.dart';
import '../../wallet/domain/models/wallet_category.dart';

enum InsightType { positive, warning, neutral }

class CoachInsight {
  const CoachInsight({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final InsightType type;

  /// Mayor = más relevante. Se usa para ordenar y recortar.
  final int priority;
}

/// Motor local de insights: analiza las transacciones con reglas y
/// estadísticas — sin IA externa. Cada insight requiere datos suficientes;
/// si no los hay, simplemente no se genera (nada de mensajes genéricos).
class InsightsEngine {
  const InsightsEngine({
    required this.transactions,
    required this.categories,
    required this.monthlySavings,
    required this.currency,
    this.nowOverride,
  });

  final List<Transaction> transactions;
  final List<WalletCategory> categories;
  final double monthlySavings;
  final String currency;

  /// Permite fijar la fecha en tests.
  final DateTime? nowOverride;

  DateTime get now => nowOverride ?? DateTime.now();

  String _fmt(double v) => v >= 1000
      ? '$currency${(v / 1000).toStringAsFixed(1)}k'
      : '$currency${v.toStringAsFixed(0)}';

  Iterable<Transaction> _inMonth(int year, int month) => transactions
      .where((t) => t.date.year == year && t.date.month == month);

  double _expensesOf(int year, int month) => _inMonth(year, month)
      .where((t) => !t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double _incomeOf(int year, int month) => _inMonth(year, month)
      .where((t) => t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  (int year, int month) _monthsAgo(int n) {
    var y = now.year;
    var m = now.month - n;
    while (m <= 0) {
      m += 12;
      y--;
    }
    return (y, m);
  }

  List<CoachInsight> build() {
    final insights = <CoachInsight>[
      ..._categoryChangeVsLastMonth(),
      ..._mostExpensiveWeekday(),
      ..._bestSavingsMonth(),
      ..._dailyAverageDelta(),
      ..._dominantCategory(),
      ..._unusualExpense(),
      ..._weekendShare(),
      ..._spendingVelocity(),
      ..._monthEndProjection(),
      ..._savingsAction(),
    ];
    insights.sort((a, b) => b.priority.compareTo(a.priority));
    return insights.take(6).toList();
  }

  // ── Cambio de categoría vs mes anterior ─────────────────────────────────────

  List<CoachInsight> _categoryChangeVsLastMonth() {
    final (py, pm) = _monthsAgo(1);
    final current = <String, double>{};
    final previous = <String, double>{};
    for (final t in _inMonth(now.year, now.month)) {
      if (!t.isIncome) current[t.category] = (current[t.category] ?? 0) + t.amount;
    }
    for (final t in _inMonth(py, pm)) {
      if (!t.isIncome) previous[t.category] = (previous[t.category] ?? 0) + t.amount;
    }
    if (previous.isEmpty || current.isEmpty) return [];

    // Mayor variación relativa con monto significativo
    String? topCat;
    double topDelta = 0;
    for (final e in current.entries) {
      final prev = previous[e.key] ?? 0;
      if (prev < 30 || e.value < 30) continue;
      final delta = (e.value - prev) / prev;
      if (delta.abs() > topDelta.abs() && delta.abs() >= 0.15) {
        topDelta = delta;
        topCat = e.key;
      }
    }
    if (topCat == null) return [];

    final cat = resolveCategory(topCat, categories);
    final pct = (topDelta * 100).abs().round();
    final rising = topDelta > 0;
    return [
      CoachInsight(
        icon: cat.icon,
        color: rising ? AppColors.negative : AppColors.positive,
        title: rising
            ? '${cat.name} subió $pct%'
            : '${cat.name} bajó $pct%',
        body: rising
            ? 'Tu gasto en ${cat.name.toLowerCase()} aumentó $pct% respecto al mes pasado '
                '(${_fmt(previous[topCat] ?? 0)} → ${_fmt(current[topCat] ?? 0)}). Revisa qué cambió.'
            : 'Tu gasto en ${cat.name.toLowerCase()} bajó $pct% respecto al mes pasado '
                '(${_fmt(previous[topCat] ?? 0)} → ${_fmt(current[topCat] ?? 0)}). Buen trabajo.',
        type: rising ? InsightType.warning : InsightType.positive,
        priority: 80 + pct.clamp(0, 19),
      ),
    ];
  }

  // ── Día de la semana más costoso ────────────────────────────────────────────

  List<CoachInsight> _mostExpensiveWeekday() {
    final sixtyAgo = now.subtract(const Duration(days: 60));
    final expenses = transactions
        .where((t) => !t.isIncome && t.date.isAfter(sixtyAgo))
        .toList();
    if (expenses.length < 12) return [];

    final byDay = List<double>.filled(8, 0); // 1..7
    final countByDay = List<int>.filled(8, 0);
    for (final t in expenses) {
      byDay[t.date.weekday] += t.amount;
      countByDay[t.date.weekday]++;
    }
    var maxDay = 1;
    for (var d = 2; d <= 7; d++) {
      if (byDay[d] > byDay[maxDay]) maxDay = d;
    }
    final total = byDay.reduce((a, b) => a + b);
    if (total == 0) return [];
    final share = byDay[maxDay] / total;
    if (share < 0.25) return []; // no hay un día claramente dominante

    const dayNames = [
      '', 'Los lunes', 'Los martes', 'Los miércoles', 'Los jueves',
      'Los viernes', 'Los sábados', 'Los domingos',
    ];
    return [
      CoachInsight(
        icon: Icons.calendar_view_week_rounded,
        color: AppColors.catEntertainment,
        title: '${dayNames[maxDay]} son tu día más costoso',
        body: 'En los últimos 2 meses, el ${(share * 100).round()}% de tu gasto '
            'ocurre ese día (${_fmt(byDay[maxDay])}). Saberlo es la mitad de controlarlo.',
        type: InsightType.neutral,
        priority: 60 + (share * 20).round(),
      ),
    ];
  }

  // ── Mejor mes de ahorro ─────────────────────────────────────────────────────

  List<CoachInsight> _bestSavingsMonth() {
    final currentNet =
        _incomeOf(now.year, now.month) - _expensesOf(now.year, now.month);
    if (currentNet <= 0) return [];

    var monthsBeaten = 0;
    for (var i = 1; i <= 5; i++) {
      final (y, m) = _monthsAgo(i);
      final income = _incomeOf(y, m);
      final expenses = _expensesOf(y, m);
      if (income == 0 && expenses == 0) break; // sin más historial
      if (currentNet > income - expenses) {
        monthsBeaten++;
      } else {
        return []; // no es el mejor — no decir nada
      }
    }
    if (monthsBeaten < 2) return [];

    return [
      CoachInsight(
        icon: Icons.emoji_events_rounded,
        color: AppColors.emerald,
        title: 'Tu mejor mes en ${monthsBeaten + 1} meses',
        body: 'Este mes llevas ${_fmt(currentNet)} de balance positivo — '
            'el mejor resultado de los últimos ${monthsBeaten + 1} meses. Mantén el ritmo.',
        type: InsightType.positive,
        priority: 85,
      ),
    ];
  }

  // ── Gasto promedio diario vs mes anterior ───────────────────────────────────

  List<CoachInsight> _dailyAverageDelta() {
    final (py, pm) = _monthsAgo(1);
    final prevExpenses = _expensesOf(py, pm);
    final curExpenses = _expensesOf(now.year, now.month);
    if (prevExpenses < 50 || curExpenses < 20) return [];

    final prevDays = DateTime(py, pm + 1, 0).day;
    final prevAvg = prevExpenses / prevDays;
    final curAvg = curExpenses / now.day;
    if (prevAvg == 0) return [];

    final delta = (curAvg - prevAvg) / prevAvg;
    if (delta.abs() < 0.10) return [];

    final pct = (delta * 100).abs().round();
    final rising = delta > 0;
    return [
      CoachInsight(
        icon: rising ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        color: rising ? AppColors.warning : AppColors.positive,
        title: rising
            ? 'Tu gasto diario subió $pct%'
            : 'Tu gasto diario bajó $pct%',
        body: 'Promedias ${_fmt(curAvg)}/día este mes vs ${_fmt(prevAvg)}/día '
            'el mes pasado. ${rising ? 'A este ritmo gastarás ${_fmt(curAvg * 30)} en 30 días.' : 'Eso equivale a ${_fmt((prevAvg - curAvg) * 30)} menos al mes.'}',
        type: rising ? InsightType.warning : InsightType.positive,
        priority: 70 + pct.clamp(0, 15),
      ),
    ];
  }

  // ── Categoría dominante ─────────────────────────────────────────────────────

  List<CoachInsight> _dominantCategory() {
    final byCat = <String, double>{};
    for (final t in _inMonth(now.year, now.month)) {
      if (!t.isIncome) byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
    }
    if (byCat.length < 2) return [];
    final total = byCat.values.fold(0.0, (a, b) => a + b);
    if (total < 50) return [];

    final top = byCat.entries.reduce((a, b) => a.value > b.value ? a : b);
    final share = top.value / total;
    if (share < 0.40) return [];

    final cat = resolveCategory(top.key, categories);
    final reduction = top.value * 0.10;
    return [
      CoachInsight(
        icon: cat.icon,
        color: cat.color,
        title: '${cat.name} concentra el ${(share * 100).round()}% de tu gasto',
        body: 'Llevas ${_fmt(top.value)} este mes. Reducir solo un 10% '
            '(${_fmt(reduction)}) te daría ${_fmt(reduction * 12)} extra al año.',
        type: InsightType.neutral,
        priority: 55 + (share * 20).round(),
      ),
    ];
  }

  // ── Gasto inusualmente alto ─────────────────────────────────────────────────

  List<CoachInsight> _unusualExpense() {
    final thirtyAgo = now.subtract(const Duration(days: 30));
    final recent = transactions
        .where((t) => !t.isIncome && t.date.isAfter(thirtyAgo))
        .toList();
    if (recent.length < 8) return [];

    final amounts = recent.map((t) => t.amount).toList()..sort();
    final median = amounts[amounts.length ~/ 2];
    if (median <= 0) return [];

    final outliers = recent
        .where((t) => t.amount > median * 4 && t.amount > 100)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    if (outliers.isEmpty) return [];

    final top = outliers.first;
    final times = (top.amount / median).round();
    return [
      CoachInsight(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        title: 'Gasto atípico detectado',
        body: '"${top.merchant}" (${_fmt(top.amount)}) fue ${times}x tu gasto '
            'típico de los últimos 30 días. Si fue planeado, perfecto — '
            'si no, vale la pena revisarlo.',
        type: InsightType.warning,
        priority: 65,
      ),
    ];
  }

  // ── Fin de semana vs entre semana ───────────────────────────────────────────

  List<CoachInsight> _weekendShare() {
    final sixtyAgo = now.subtract(const Duration(days: 60));
    final expenses = transactions
        .where((t) => !t.isIncome && t.date.isAfter(sixtyAgo))
        .toList();
    if (expenses.length < 15) return [];

    final total = expenses.fold(0.0, (s, t) => s + t.amount);
    final weekend = expenses
        .where((t) => t.date.weekday >= DateTime.saturday)
        .fold(0.0, (s, t) => s + t.amount);
    if (total == 0) return [];

    final share = weekend / total;
    // 2 de 7 días = 28.6% esperado; reportar solo desviaciones fuertes
    if (share < 0.45) return [];

    return [
      CoachInsight(
        icon: Icons.weekend_outlined,
        color: AppColors.catShopping,
        title: 'El ${(share * 100).round()}% de tu gasto es en fin de semana',
        body: 'Sábado y domingo concentran ${_fmt(weekend)} de tus últimos '
            '2 meses. Planear esos días con un límite te daría el mayor ahorro.',
        type: InsightType.neutral,
        priority: 58,
      ),
    ];
  }

  // ── Velocidad de gasto vs avance del mes ────────────────────────────────────

  List<CoachInsight> _spendingVelocity() {
    final income = _incomeOf(now.year, now.month);
    final expenses = _expensesOf(now.year, now.month);
    if (income <= 0 || expenses <= 0) return [];

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthProgress = now.day / daysInMonth;
    final spendingProgress = expenses / income;
    if (spendingProgress <= monthProgress + 0.15) return [];

    final daysAhead =
        ((spendingProgress - monthProgress) * daysInMonth).round();
    return [
      CoachInsight(
        icon: Icons.speed_rounded,
        color: AppColors.negative,
        title: 'Gastas más rápido de lo que avanza el mes',
        body: 'Llevas el ${(spendingProgress * 100).round()}% del ingreso '
            'gastado con solo el ${(monthProgress * 100).round()}% del mes. '
            'Vas $daysAhead días adelantado — frena compras no esenciales.',
        type: InsightType.warning,
        priority: 90,
      ),
    ];
  }

  // ── Proyección de fin de mes ────────────────────────────────────────────────

  List<CoachInsight> _monthEndProjection() {
    final income = _incomeOf(now.year, now.month);
    final expenses = _expensesOf(now.year, now.month);
    if (income <= 0 && expenses <= 0) return [];

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;
    final dailyAvg = now.day > 0 ? expenses / now.day : 0.0;
    final projected = expenses + dailyAvg * daysLeft;
    final balance = income - projected;

    if (income > 0 && balance > 0) {
      return [
        CoachInsight(
          icon: Icons.calendar_today_rounded,
          color: AppColors.positive,
          title: 'Cerrarás el mes con ${_fmt(balance)}',
          body: 'Con ${_fmt(dailyAvg)}/día de gasto promedio y tus ingresos de '
              '${_fmt(income)}, terminarás el mes con saldo a favor.',
          type: InsightType.positive,
          priority: 75,
        ),
      ];
    }
    if (income > 0) {
      final overrun = projected - income;
      return [
        CoachInsight(
          icon: Icons.running_with_errors_rounded,
          color: AppColors.negative,
          title: 'Proyección: ${_fmt(overrun)} en rojo',
          body: 'A ${_fmt(dailyAvg)}/día gastarás más de lo que ganas este mes. '
              'Recortar ${_fmt(dailyAvg * 0.15)}/día te deja en equilibrio.',
          type: InsightType.warning,
          priority: 92,
        ),
      ];
    }
    return [];
  }

  // ── Acción de ahorro concreta ───────────────────────────────────────────────

  List<CoachInsight> _savingsAction() {
    final income = _incomeOf(now.year, now.month);
    if (income <= 0) return [];
    final target = income * 0.20;

    if (monthlySavings >= target) {
      return [
        CoachInsight(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.positive,
          title: 'Objetivo de ahorro cumplido',
          body: 'Ahorraste ${_fmt(monthlySavings)} '
              '(${(monthlySavings / income * 100).round()}% de tus ingresos). '
              'Superaste el 20% recomendado.',
          type: InsightType.positive,
          priority: 50,
        ),
      ];
    }
    if (monthlySavings == 0) {
      return [
        CoachInsight(
          icon: Icons.savings_rounded,
          color: AppColors.warning,
          title: 'Aún no ahorras este mes',
          body: 'Transfiere ${_fmt(target)} (20% de tus ingresos) a tu cuenta '
              'de Ahorro. El mejor momento es el día de cobro.',
          type: InsightType.warning,
          priority: 62,
        ),
      ];
    }
    final missing = target - monthlySavings;
    return [
      CoachInsight(
        icon: Icons.savings_rounded,
        color: AppColors.petroleum,
        title: 'Te faltan ${_fmt(missing)} para el 20%',
        body: 'Llevas ${_fmt(monthlySavings)} ahorrados. Una transferencia más '
            'de ${_fmt(missing)} y cumples el objetivo del mes.',
        type: InsightType.neutral,
        priority: 48,
      ),
    ];
  }
}
