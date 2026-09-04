import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/financial_health/domain/financial_metric.dart';
import 'package:alibaba/features/simulations/domain/simulation_engine.dart';
import 'package:alibaba/features/transactions/domain/transaction.dart';

void main() {
  group('SimulationEngine — Deterministic Scenario Simulations', () {
    final now = DateTime.now();
    final baseline = FinancialMetric(
      id: 'metric-1',
      businessId: 'biz-1',
      periodStart: now.subtract(const Duration(days: 30)),
      periodEnd: now,
      revenue: 50000.0,
      expenses: 35000.0,
      profit: 15000.0,
      profitMargin: 30.0,
      cashInflow: 50000.0,
      cashOutflow: 35000.0,
      netCashFlow: 15000.0,
      receivables: 5000.0,
      payables: 2000.0,
      healthScore: 78.0,
      createdAt: now,
      updatedAt: now,
    );

    test('simulates +10% revenue expansion correctly', () {
      const assumption = ScenarioAssumption(
        type: ScenarioType.revenueDelta,
        name: 'Growth +10%',
        description: 'Grow top line 10%',
        percentageDelta: 10.0,
      );

      final result = SimulationEngine.simulate(
        baselineMetric: baseline,
        assumption: assumption,
      );

      expect(result.baselineRevenue, 50000.0);
      expect(result.projectedRevenue, closeTo(55000.0, 0.01));
      expect(result.revenueDelta, closeTo(5000.0, 0.01));
      expect(
        result.projectedExpenses,
        closeTo(35000.0, 0.01),
      ); // Expenses unchanged
      expect(result.projectedProfit, closeTo(20000.0, 0.01));
      expect(result.profitDelta, closeTo(5000.0, 0.01));
      expect(
        result.projectedMargin,
        closeTo((20000.0 / 55000.0) * 100.0, 0.01),
      );
      expect(result.projectedCashFlow, closeTo(20000.0, 0.01));
      expect(result.tradeOffs.isNotEmpty, true);
    });

    test(
      'simulates -15% revenue downturn and evaluates margin contraction',
      () {
        const assumption = ScenarioAssumption(
          type: ScenarioType.revenueDelta,
          name: 'Downturn -15%',
          description: 'Revenue drops by 15%',
          percentageDelta: -15.0,
        );

        final result = SimulationEngine.simulate(
          baselineMetric: baseline,
          assumption: assumption,
        );

        expect(result.projectedRevenue, closeTo(42500.0, 0.01));
        expect(result.revenueDelta, closeTo(-7500.0, 0.01));
        expect(result.projectedProfit, closeTo(7500.0, 0.01));
        expect(result.profitDelta, closeTo(-7500.0, 0.01));
        expect(
          result.projectedMargin,
          closeTo((7500.0 / 42500.0) * 100.0, 0.01),
        );
        expect(result.healthScoreDelta, lessThan(0.0));
      },
    );

    test('simulates -10% general expense reduction and margin enhancement', () {
      const assumption = ScenarioAssumption(
        type: ScenarioType.expenseDelta,
        name: 'Cost Cutting -10%',
        description: 'Reduce general overhead by 10%',
        percentageDelta: -10.0,
      );

      final result = SimulationEngine.simulate(
        baselineMetric: baseline,
        assumption: assumption,
      );

      expect(
        result.projectedRevenue,
        closeTo(50000.0, 0.01),
      ); // Revenue unchanged
      expect(result.projectedExpenses, closeTo(31500.0, 0.01)); // 35000 - 3500
      expect(result.expensesDelta, closeTo(-3500.0, 0.01));
      expect(result.projectedProfit, closeTo(18500.0, 0.01));
      expect(result.profitDelta, closeTo(3500.0, 0.01));
      expect(
        result.projectedMargin,
        closeTo((18500.0 / 50000.0) * 100.0, 0.01),
      );
      expect(result.projectedCashFlow, closeTo(18500.0, 0.01));
    });

    test(
      'simulates targeted category expense reduction with transaction history',
      () {
        final transactions = [
          Transaction(
            id: 't-1',
            businessId: 'biz-1',
            transactionDate: now,
            transactionType: TransactionType.expense,
            category: 'Marketing',
            amount: 8000.0,
            currency: 'USD',
            createdAt: now,
            updatedAt: now,
          ),
          Transaction(
            id: 't-2',
            businessId: 'biz-1',
            transactionDate: now,
            transactionType: TransactionType.expense,
            category: 'Software',
            amount: 2000.0,
            currency: 'USD',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        const assumption = ScenarioAssumption(
          type: ScenarioType.categoryExpenseDelta,
          name: 'Optimize Marketing -25%',
          description: 'Reduce marketing budget by 25%',
          targetCategory: 'Marketing',
          percentageDelta: -25.0,
        );

        final result = SimulationEngine.simulate(
          baselineMetric: baseline,
          assumption: assumption,
          transactions: transactions,
        );

        // Marketing is $8000 -> -25% saves $2000 -> projected expenses = 35000 - 2000 = 33000
        expect(result.projectedExpenses, closeTo(33000.0, 0.01));
        expect(result.expensesDelta, closeTo(-2000.0, 0.01));
        expect(result.projectedProfit, closeTo(17000.0, 0.01));
        expect(result.profitDelta, closeTo(2000.0, 0.01));
      },
    );

    test('simulates hiring new staff with fixed monthly cost', () {
      const assumption = ScenarioAssumption(
        type: ScenarioType.headcountAddition,
        name: 'Hire Senior Engineer',
        description: 'Add staff with \$5,000 monthly cost',
        fixedAmountDelta: 5000.0,
      );

      final result = SimulationEngine.simulate(
        baselineMetric: baseline,
        assumption: assumption,
      );

      expect(result.projectedRevenue, closeTo(50000.0, 0.01));
      expect(result.projectedExpenses, closeTo(40000.0, 0.01)); // 35000 + 5000
      expect(result.expensesDelta, closeTo(5000.0, 0.01));
      expect(result.projectedProfit, closeTo(10000.0, 0.01));
      expect(result.profitDelta, closeTo(-5000.0, 0.01));
      expect(
        result.projectedMargin,
        closeTo((10000.0 / 50000.0) * 100.0, 0.01),
      );
    });

    test('preserves baseline metric immutability during simulation', () {
      const assumption = ScenarioAssumption(
        type: ScenarioType.revenueDelta,
        name: 'Test',
        description: 'Test',
        percentageDelta: 50.0,
      );

      SimulationEngine.simulate(
        baselineMetric: baseline,
        assumption: assumption,
      );

      expect(baseline.revenue, 50000.0);
      expect(baseline.expenses, 35000.0);
      expect(baseline.profit, 15000.0);
      expect(baseline.healthScore, 78.0);
    });
  });
}
