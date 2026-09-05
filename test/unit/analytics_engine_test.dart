import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/financial_health/domain/analytics_engine.dart';
import 'package:alibaba/features/financial_health/domain/financial_engine.dart';
import 'package:alibaba/features/financial_health/domain/financial_metric.dart';
import 'package:alibaba/features/transactions/domain/transaction.dart';

void main() {
  group('AnalyticsEngine Deterministic Intelligence', () {
    final now = DateTime.now();

    final testTransactions = [
      Transaction(
        id: 'tx_1',
        businessId: 'biz_1',
        transactionDate: now.subtract(const Duration(days: 2)),
        transactionType: TransactionType.income,
        category: 'Sales',
        amount: 10000.0,
        currency: 'USD',
        description: 'Wholesale product sales',
        paymentStatus: PaymentStatus.paid,
        createdAt: now,
        updatedAt: now,
      ),
      Transaction(
        id: 'tx_2',
        businessId: 'biz_1',
        transactionDate: now.subtract(const Duration(days: 3)),
        transactionType: TransactionType.income,
        category: 'Consulting',
        amount: 5000.0,
        currency: 'USD',
        description: 'Client retainer',
        paymentStatus: PaymentStatus.paid,
        createdAt: now,
        updatedAt: now,
      ),
      Transaction(
        id: 'tx_3',
        businessId: 'biz_1',
        transactionDate: now.subtract(const Duration(days: 4)),
        transactionType: TransactionType.expense,
        category: 'Payroll',
        amount: 6000.0,
        currency: 'USD',
        description: 'Staff compensation',
        paymentStatus: PaymentStatus.paid,
        createdAt: now,
        updatedAt: now,
      ),
      Transaction(
        id: 'tx_4',
        businessId: 'biz_1',
        transactionDate: now.subtract(const Duration(days: 5)),
        transactionType: TransactionType.expense,
        category: 'Software',
        amount: 2000.0,
        currency: 'USD',
        description: 'Cloud subscriptions',
        paymentStatus: PaymentStatus.paid,
        createdAt: now,
        updatedAt: now,
      ),
      Transaction(
        id: 'tx_5',
        businessId: 'biz_1',
        transactionDate: now.subtract(const Duration(days: 6)),
        transactionType: TransactionType.expense,
        category: 'Marketing',
        amount: 2000.0,
        currency: 'USD',
        description: 'Ad campaign',
        paymentStatus: PaymentStatus.paid,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('computes accurate category breakdown for expenses and revenue', () {
      final expenseBreakdowns = AnalyticsEngine.computeCategoryBreakdowns(
        transactions: testTransactions,
        isExpense: true,
      );

      expect(expenseBreakdowns.length, 3);
      // Top expense should be Payroll ($6000 of $10000 = 60.0%)
      expect(expenseBreakdowns.first.category, 'Payroll');
      expect(expenseBreakdowns.first.totalAmount, 6000.0);
      expect(expenseBreakdowns.first.percentageOfTotal, 60.0);

      final revenueBreakdowns = AnalyticsEngine.computeCategoryBreakdowns(
        transactions: testTransactions,
        isExpense: false,
      );

      expect(revenueBreakdowns.length, 2);
      // Top revenue should be Sales ($10000 of $15000 = 66.7%)
      expect(revenueBreakdowns.first.category, 'Sales');
      expect(revenueBreakdowns.first.totalAmount, 10000.0);
      expect(revenueBreakdowns.first.percentageOfTotal, closeTo(66.67, 0.1));
    });

    test('computes deterministic period comparisons with delta percentages', () {
      final current = FinancialMetric(
        id: 'curr',
        businessId: 'biz_1',
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        revenue: 15000.0,
        expenses: 10000.0,
        profit: 5000.0,
        profitMargin: 33.33,
        cashInflow: 15000.0,
        cashOutflow: 10000.0,
        netCashFlow: 5000.0,
        receivables: 2000.0,
        payables: 1000.0,
        healthScore: 82.0,
        createdAt: now,
        updatedAt: now,
      );

      final previous = FinancialMetric(
        id: 'prev',
        businessId: 'biz_1',
        periodStart: now.subtract(const Duration(days: 60)),
        periodEnd: now.subtract(const Duration(days: 30)),
        revenue: 12000.0,
        expenses: 8000.0,
        profit: 4000.0,
        profitMargin: 33.33,
        cashInflow: 12000.0,
        cashOutflow: 8000.0,
        netCashFlow: 4000.0,
        receivables: 3000.0,
        payables: 1500.0,
        healthScore: 78.0,
        createdAt: now,
        updatedAt: now,
      );

      final comparison = AnalyticsEngine.comparePeriods(
        current: current,
        previous: previous,
      );

      expect(comparison.revenueDelta, 3000.0);
      expect(comparison.revenueGrowthPct, 25.0); // (15000 - 12000) / 12000 * 100
      expect(comparison.expenseDelta, 2000.0);
      expect(comparison.expenseGrowthPct, 25.0); // (10000 - 8000) / 8000 * 100
      expect(comparison.profitDelta, 1000.0);
      expect(comparison.profitGrowthPct, 25.0);
    });

    test('generates margin decomposition drivers correctly', () {
      final current = FinancialMetric(
        id: 'curr',
        businessId: 'biz_1',
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        revenue: 20000.0,
        expenses: 16000.0,
        profit: 4000.0,
        profitMargin: 20.0,
        cashInflow: 20000.0,
        cashOutflow: 16000.0,
        netCashFlow: 4000.0,
        revenueGrowth: 0.0,
        expenseGrowth: 14.3,
        createdAt: now,
        updatedAt: now,
      );

      final previous = FinancialMetric(
        id: 'prev',
        businessId: 'biz_1',
        periodStart: now.subtract(const Duration(days: 60)),
        periodEnd: now.subtract(const Duration(days: 30)),
        revenue: 20000.0,
        expenses: 14000.0,
        profit: 6000.0,
        profitMargin: 30.0,
        cashInflow: 20000.0,
        cashOutflow: 14000.0,
        netCashFlow: 6000.0,
        createdAt: now,
        updatedAt: now,
      );

      final drivers = AnalyticsEngine.decomposeMargin(
        current: current,
        previous: previous,
        currentTransactions: testTransactions,
      );

      expect(drivers, isNotEmpty);
      expect(drivers.any((d) => d.name.contains('Expense Surge')), isTrue);
    });

    test('discovers automated financial insights based on transactions and buckets', () {
      final buckets = [
        MonthlyFinancialBucket(
          year: 2026,
          month: 1,
          label: 'Jan',
          revenue: 10000,
          expenses: 7000,
          profit: 3000,
          netCashFlow: 3000,
        ),
        MonthlyFinancialBucket(
          year: 2026,
          month: 2,
          label: 'Feb',
          revenue: 12000,
          expenses: 8000,
          profit: 4000,
          netCashFlow: 4000,
        ),
        MonthlyFinancialBucket(
          year: 2026,
          month: 3,
          label: 'Mar',
          revenue: 15000,
          expenses: 10000,
          profit: 5000,
          netCashFlow: 5000,
        ),
      ];

      final current = FinancialMetric(
        id: 'curr',
        businessId: 'biz_1',
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        revenue: 15000.0,
        expenses: 10000.0,
        profit: 5000.0,
        profitMargin: 33.33,
        cashInflow: 15000.0,
        cashOutflow: 10000.0,
        netCashFlow: 5000.0,
        createdAt: now,
        updatedAt: now,
      );

      final insights = AnalyticsEngine.discoverInsights(
        current: current,
        buckets: buckets,
        transactions: testTransactions,
      );

      expect(insights, isNotEmpty);
      expect(insights.any((i) => i.title.contains('Revenue Momentum')), isTrue);
    });
  });
}
