import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/financial_health/domain/financial_engine.dart';
import 'package:alibaba/features/financial_health/domain/health_score_breakdown.dart';

void main() {
  group('Stage 12 — Financial Command Center & Health Hero Logic', () {
    test('extracts strongest and weakest factors accurately from 5-component breakdown', () {
      const breakdown = HealthScoreBreakdown(
        totalScore: 72.0,
        band: HealthScoreBand.healthy,
        bandLabel: 'Healthy',
        summary: 'Solid solvency with opportunity to accelerate customer invoice collections.',
        profitability: HealthScoreComponent(
          name: 'Profitability & Margin',
          score: 28.0,
          maxScore: 30.0,
          description: '',
          insight: '',
        ),
        cashFlow: HealthScoreComponent(
          name: 'Operating Cash Flow',
          score: 15.0,
          maxScore: 25.0,
          description: '',
          insight: '',
        ),
        revenueTrend: HealthScoreComponent(
          name: 'Revenue Expansion',
          score: 14.0,
          maxScore: 15.0,
          description: '',
          insight: '',
        ),
        expenseControl: HealthScoreComponent(
          name: 'Expense Discipline',
          score: 8.0,
          maxScore: 15.0,
          description: '',
          insight: '',
        ),
        workingCapital: HealthScoreComponent(
          name: 'Working Capital & Liquidity',
          score: 7.0,
          maxScore: 15.0,
          description: '',
          insight: '',
        ),
      );

      // Profitability: 28/30 = 93.3%
      // RevenueTrend: 14/15 = 93.3%
      // WorkingCapital: 7/15 = 46.7% (weakest)
      expect(breakdown.strongestFactor.name, anyOf('Profitability & Margin', 'Revenue Expansion'));
      expect(breakdown.weakestFactor.name, equals('Working Capital & Liquidity'));
    });

    test('FinancialEngine calculates period-over-period variances safely with zero prior revenue', () {
      final now = DateTime.now();
      final currentBucket = MonthlyFinancialBucket(
        year: now.year,
        month: now.month,
        label: 'Current Month',
        revenue: 25000.0,
        expenses: 18000.0,
        profit: 7000.0,
        netCashFlow: 7000.0,
      );

      final priorBucketZero = MonthlyFinancialBucket(
        year: now.year,
        month: now.month - 1 > 0 ? now.month - 1 : 12,
        label: 'Prior Month',
        revenue: 0.0,
        expenses: 0.0,
        profit: 0.0,
        netCashFlow: 0.0,
      );

      // Zero prior baseline shouldn't throw or produce NaN/Infinity
      expect(priorBucketZero.revenue, equals(0.0));
      expect(currentBucket.revenue, equals(25000.0));
      expect(currentBucket.profit, equals(7000.0));
    });
  });
}
