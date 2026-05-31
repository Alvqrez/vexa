enum HealthStatus { excellent, regular, risky }

extension HealthStatusX on HealthStatus {
  String get label => switch (this) {
        HealthStatus.excellent => 'Excelente',
        HealthStatus.regular => 'Regular',
        HealthStatus.risky => 'Riesgoso',
      };

  String get emoji => switch (this) {
        HealthStatus.excellent => '🟢',
        HealthStatus.regular => '🟡',
        HealthStatus.risky => '🔴',
      };

  String get description => switch (this) {
        HealthStatus.excellent =>
          'Tus finanzas están en gran forma. Sigue así.',
        HealthStatus.regular =>
          'Vas bien pero hay áreas de mejora.',
        HealthStatus.risky =>
          'Atención: tus gastos superan tus ingresos.',
      };
}

class FinancialHealth {
  const FinancialHealth({
    required this.score,
    required this.savingsScore,
    required this.budgetScore,
    required this.incomeScore,
  });

  final double score; // 0–100
  final double savingsScore; // 0–100
  final double budgetScore; // 0–100
  final double incomeScore; // 0–100

  HealthStatus get status => score >= 70
      ? HealthStatus.excellent
      : score >= 40
          ? HealthStatus.regular
          : HealthStatus.risky;

  static FinancialHealth compute({
    required double income,
    required double expenses,
    required double savings,
  }) {
    if (income == 0) {
      return const FinancialHealth(
        score: 0,
        savingsScore: 0,
        budgetScore: 0,
        incomeScore: 0,
      );
    }

    // Savings score: 0% = 0pts, 20%+ = 100pts
    final savingsRatio = savings / income;
    final savingsScore = (savingsRatio / 0.20 * 100).clamp(0.0, 100.0);

    // Budget score: spending less than income = good
    final spendingRatio = expenses / income;
    final budgetScore =
        spendingRatio <= 1.0 ? (1.0 - spendingRatio) * 100 : 0.0;

    // Income score: having income at all = good baseline
    final incomeScore = income > 0 ? 70.0 : 0.0;

    final score =
        (savingsScore * 0.40 + budgetScore * 0.40 + incomeScore * 0.20)
            .clamp(0.0, 100.0);

    return FinancialHealth(
      score: score,
      savingsScore: savingsScore,
      budgetScore: budgetScore,
      incomeScore: incomeScore,
    );
  }

  static const FinancialHealth empty = FinancialHealth(
    score: 0,
    savingsScore: 0,
    budgetScore: 0,
    incomeScore: 0,
  );
}
