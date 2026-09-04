import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/financial_health/domain/financial_engine.dart';
import 'package:alibaba/features/financial_health/domain/health_score_breakdown.dart';

void main() {
  group('FinancialEngine — Health Score Deterministic Algorithm', () {
    test(
      'healthy flourishing business scores high in Excellent or Healthy band',
      () {
        final breakdown = FinancialEngine.calculateHealthScore(
          revenue: 100000.0,
          expenses: 65000.0,
          profit: 35000.0,
          profitMargin: 35.0, // >30% margin
          cashInflow: 95000.0,
          cashOutflow: 60000.0,
          netCashFlow: 35000.0,
          receivables: 10000.0,
          payables: 5000.0,
          revenueGrowth: 18.0,
          expenseGrowth: 8.0,
          hasPreviousPeriod: true,
        );

        expect(breakdown.totalScore, greaterThanOrEqualTo(80.0));
        expect(breakdown.totalScore, lessThanOrEqualTo(100.0));
        expect(breakdown.band, HealthScoreBand.excellent);
        expect(breakdown.profitability.score, 30.0);
        expect(breakdown.cashFlow.score, 25.0);
        expect(breakdown.revenueTrend.score, 15.0);
        expect(breakdown.expenseControl.score, 14.0);
        expect(breakdown.workingCapital.score, 15.0);
      },
    );

    test(
      'distressed business with high burn and declining revenue scores low in At Risk or Critical band',
      () {
        final breakdown = FinancialEngine.calculateHealthScore(
          revenue: 20000.0,
          expenses: 50000.0,
          profit: -30000.0,
          profitMargin: -150.0, // High negative margin
          cashInflow: 15000.0,
          cashOutflow: 48000.0,
          netCashFlow: -33000.0, // Severe cash burn
          receivables: 2000.0,
          payables: 25000.0, // Heavy overdue liabilities
          revenueGrowth: -25.0, // Contraction
          expenseGrowth: 20.0, // Rising expenses
          hasPreviousPeriod: true,
        );

        expect(breakdown.totalScore, lessThan(40.0));
        expect(
          breakdown.band == HealthScoreBand.atRisk ||
              breakdown.band == HealthScoreBand.critical,
          true,
        );
      },
    );

    test(
      'score is strictly clamped between 0 and 100 even with extreme inputs',
      () {
        final extremeNegative = FinancialEngine.calculateHealthScore(
          revenue: 0.0,
          expenses: 1000000.0,
          profit: -1000000.0,
          profitMargin: -100.0,
          cashInflow: 0.0,
          cashOutflow: 1000000.0,
          netCashFlow: -1000000.0,
          receivables: 0.0,
          payables: 500000.0,
          revenueGrowth: -90.0,
          expenseGrowth: 200.0,
          hasPreviousPeriod: true,
        );

        expect(extremeNegative.totalScore, greaterThanOrEqualTo(0.0));
        expect(extremeNegative.totalScore, lessThanOrEqualTo(100.0));

        final extremePositive = FinancialEngine.calculateHealthScore(
          revenue: 1000000.0,
          expenses: 10000.0,
          profit: 990000.0,
          profitMargin: 99.0,
          cashInflow: 1000000.0,
          cashOutflow: 10000.0,
          netCashFlow: 990000.0,
          receivables: 100000.0,
          payables: 0.0,
          revenueGrowth: 300.0,
          expenseGrowth: -20.0,
          hasPreviousPeriod: true,
        );

        expect(extremePositive.totalScore, greaterThanOrEqualTo(0.0));
        expect(extremePositive.totalScore, lessThanOrEqualTo(100.0));
      },
    );

    test('handles empty starting baseline without crashing', () {
      final emptyState = FinancialEngine.calculateHealthScore(
        revenue: 0.0,
        expenses: 0.0,
        profit: 0.0,
        profitMargin: 0.0,
        cashInflow: 0.0,
        cashOutflow: 0.0,
        netCashFlow: 0.0,
        receivables: 0.0,
        payables: 0.0,
        revenueGrowth: 0.0,
        expenseGrowth: 0.0,
        hasPreviousPeriod: false,
      );

      expect(emptyState.totalScore, greaterThan(0.0));
      expect(emptyState.totalScore.isNaN, false);
      expect(emptyState.band, HealthScoreBand.healthy);
    });
  });
}
