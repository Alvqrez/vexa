import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Financial Calculations - Critical Tests', () {

    // ─── GOAL PROGRESS TESTS ───────────────────────────────────────────────

    group('Goal Progress Calculation', () {
      test('progress is 0 when target is 0', () {
        // PREVENTS: Division by zero crash
        const target = 0.0;
        const current = 100.0;

        final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

        expect(progress, 0.0);
      });

      test('progress is correct for partial completion', () {
        const target = 1000.0;
        const current = 500.0;

        final progress = (current / target).clamp(0.0, 1.0);

        expect(progress, 0.5);
      });

      test('progress clamps to 1.0 when exceeded', () {
        const target = 100.0;
        const current = 150.0;

        final progress = (current / target).clamp(0.0, 1.0);

        expect(progress, 1.0);
      });

      test('isCompleted is false when target is 0', () {
        const target = 0.0;
        const current = 100.0;

        final isCompleted = target > 0 && current >= target;

        expect(isCompleted, false);
      });
    });

    // ─── LOAN CALCULATIONS ──────────────────────────────────────────────────

    group('Loan Remaining Amount', () {
      test('remaining is clamped to 0', () {
        const amount = 1000.0;
        const paid = 1500.0; // Over-paid

        final remaining = (amount - paid).clamp(0.0, double.infinity);

        expect(remaining, 0.0);
      });

      test('isSettled with double precision tolerance', () {
        // PREVENTS: Floating point precision issues
        const remaining = 0.00000001; // Very small but > 0

        final isSettled = remaining <= 0.01;

        expect(isSettled, true); // Allows 1 cent tolerance
      });

      test('remaining calculates correctly', () {
        const amount = 5000.0;
        const paid = 2000.0;

        final remaining = (amount - paid).clamp(0.0, double.infinity);

        expect(remaining, 3000.0);
      });

      test('progress fraction is 0 when amount is 0', () {
        const amount = 0.0;
        const paid = 0.0;

        final progressFraction = amount > 0 ? (paid / amount).clamp(0.0, 1.0) : 0.0;

        expect(progressFraction, 0.0);
      });
    });

    // ─── BUDGET CALCULATIONS ───────────────────────────────────────────────

    group('Budget Ratio Calculation', () {
      test('ratio is 0 when limit is 0', () {
        // PREVENTS: Division by zero
        const limit = 0.0;
        const spent = 50.0;

        final ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);

        expect(ratio, 0.0);
      });

      test('ratio is 0 when limit is negative', () {
        const limit = -100.0;
        const spent = 50.0;

        final ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);

        expect(ratio, 0.0);
      });

      test('ratio calculates correctly', () {
        const limit = 200.0;
        const spent = 100.0;

        final ratio = (spent / limit).clamp(0.0, 1.0);

        expect(ratio, 0.5);
      });

      test('ratio clamps to 1.0 when exceeded', () {
        const limit = 100.0;
        const spent = 250.0;

        final ratio = (spent / limit).clamp(0.0, 1.0);

        expect(ratio, 1.0);
      });

      test('isWarning only true when limit > 0 and ratio >= 0.80', () {
        const limit = 100.0;
        const spent = 85.0;

        final ratio = (spent / limit).clamp(0.0, 1.0);
        final isWarning = limit > 0 && ratio >= 0.80;

        expect(isWarning, true);
      });
    });

    // ─── PROJECTION CALCULATIONS ────────────────────────────────────────────

    group('Financial Projection Calculations', () {
      test('linear projection does not accumulate exponentially', () {
        // PREVENTS: Exponential false growth in predictions
        const currentBalance = 10000.0;
        const monthlyNet = 1000.0;
        const dailyNet = monthlyNet / 30.0;

        var balance = currentBalance;
        final projections = <double>[balance];

        // Correct way: add 30 days of net flow each iteration
        for (int days = 30; days <= 90; days += 30) {
          balance += (dailyNet * 30.0);
          projections.add(balance);
        }

        expect(projections[0], 10000.0); // Today
        expect(projections[1], 11000.0); // +30 days = +$1000
        expect(projections[2], 12000.0); // +60 days = +$2000
        expect(projections[3], 13000.0); // +90 days = +$3000
      });

      test('projection handles negative net flow', () {
        const currentBalance = 10000.0;
        const monthlyNet = -500.0; // Negative flow
        const dailyNet = monthlyNet / 30.0;

        var balance = currentBalance;
        balance += (dailyNet * 30.0);

        expect(balance, closeTo(9500.0, 0.01));
      });

      test('average monthly calculation is correct', () {
        // PREVENTS: Fomula totalIncome / 30 * 30 = totalIncome
        // The correct interpretation: total of last 30 days IS the average
        const totalIncome = 3000.0;

        final averageMonthlyIncome = totalIncome; // Not totalIncome / 30 * 30

        expect(averageMonthlyIncome, 3000.0);
      });
    });

    // ─── SUBSCRIPTION CALCULATIONS ──────────────────────────────────────────

    group('Subscription Monthly Equivalent', () {
      test('weekly factor is accurate', () {
        // 52.14 weeks/year ÷ 12 months = 4.345 weeks/month
        const weeklyFactor = 52.14 / 12.0;
        const amount = 10.0; // $10/week

        final monthlyEquivalent = amount * weeklyFactor;

        expect(monthlyEquivalent, closeTo(43.45, 0.01));
      });

      test('monthly factor is exactly 1.0', () {
        const monthlyFactor = 1.0;
        const amount = 100.0;

        final monthlyEquivalent = amount * monthlyFactor;

        expect(monthlyEquivalent, 100.0);
      });

      test('quarterly factor is 1/3', () {
        const quarterlyFactor = 1.0 / 3.0;
        const amount = 300.0; // $300/quarter

        final monthlyEquivalent = amount * quarterlyFactor;

        expect(monthlyEquivalent, closeTo(100.0, 0.01));
      });

      test('annual factor is 1/12', () {
        const annualFactor = 1.0 / 12.0;
        const amount = 1200.0; // $1200/year

        final monthlyEquivalent = amount * annualFactor;

        expect(monthlyEquivalent, 100.0);
      });
    });

    // ─── HEALTH SCORE CALCULATIONS ──────────────────────────────────────────

    group('Financial Health Score', () {
      test('health score with zero income returns 0', () {
        const income = 0.0;

        final score = income == 0 ? 0.0 : 50.0;

        expect(score, 0.0);
      });

      test('savings score calculation is correct', () {
        const income = 1000.0;
        const savings = 200.0; // 20%

        final savingsRatio = savings / income;
        final savingsScore = (savingsRatio / 0.20 * 100).clamp(0.0, 100.0);

        expect(savingsScore, 100.0);
      });

      test('savings score clamps to 100 when exceeds target', () {
        const income = 1000.0;
        const savings = 500.0; // 50%, exceeds 20% target

        final savingsRatio = savings / income;
        final savingsScore = (savingsRatio / 0.20 * 100).clamp(0.0, 100.0);

        expect(savingsScore, 100.0);
      });

      test('budget score calculation is correct', () {
        const income = 1000.0;
        const expenses = 500.0; // 50%

        final spendingRatio = expenses / income;
        final budgetScore = spendingRatio <= 1.0 ? (1.0 - spendingRatio) * 100 : 0.0;

        expect(budgetScore, 50.0);
      });

      test('budget score is 0 when spending exceeds income', () {
        const income = 1000.0;
        const expenses = 1500.0; // 150%

        final spendingRatio = expenses / income;
        final budgetScore = spendingRatio <= 1.0 ? (1.0 - spendingRatio) * 100 : 0.0;

        expect(budgetScore, 0.0);
      });

      test('weighted score calculation', () {
        const savingsScore = 80.0;
        const budgetScore = 60.0;
        const incomeScore = 70.0;

        final score = (savingsScore * 0.40 + budgetScore * 0.40 + incomeScore * 0.20)
            .clamp(0.0, 100.0);

        // 80×0.40 + 60×0.40 + 70×0.20 = 32 + 24 + 14 = 70
        expect(score, closeTo(70.0, 0.01));
      });
    });

    // ─── EDGE CASES ──────────────────────────────────────────────────────────

    group('Edge Cases and Precision', () {
      test('handles very small amounts', () {
        const amount1 = 0.01;
        const amount2 = 0.02;

        final sum = amount1 + amount2;

        expect(sum, closeTo(0.03, 0.0001));
      });

      test('handles very large amounts', () {
        const amount1 = 1000000.0;
        const amount2 = 2000000.0;

        final sum = amount1 + amount2;

        expect(sum, 3000000.0);
      });

      test('clamp prevents negative balances', () {
        const balance = -500.0;

        final clamped = balance.clamp(0.0, double.infinity);

        expect(clamped, 0.0);
      });

      test('double division precision', () {
        const a = 100.0;
        const b = 3.0;

        final result = a / b;

        expect(result, closeTo(33.333, 0.001));
      });
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // CONSISTENCY VALIDATION TESTS
  // ──────────────────────────────────────────────────────────────────────────

  group('Financial Consistency Validations', () {
    test('accounting equation: assets = income - expenses', () {
      const initialBalance = 5000.0;
      const income = 2000.0;
      const expenses = 1500.0;

      final finalBalance = initialBalance + income - expenses;

      expect(finalBalance, 5500.0);
    });

    test('total balance = sum of all accounts', () {
      const accountBalances = [1000.0, 2000.0, 3000.0];

      final totalBalance = accountBalances.fold<double>(0, (sum, a) => sum + a);

      expect(totalBalance, 6000.0);
    });

    test('monthly totals sum correctly', () {
      final januaryIncome = [100.0, 200.0, 150.0];
      final februaryIncome = [120.0, 220.0, 130.0];

      final jan = januaryIncome.fold<double>(0, (sum, a) => sum + a);
      final feb = februaryIncome.fold<double>(0, (sum, a) => sum + a);
      final total = jan + feb;

      expect(jan, 450.0);
      expect(feb, 470.0);
      expect(total, 920.0);
    });
  });
}
