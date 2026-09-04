import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/alerts/domain/alert.dart';
import 'package:alibaba/features/alerts/domain/risk_engine.dart';
import 'package:alibaba/features/financial_health/domain/financial_metric.dart';
import 'package:alibaba/features/transactions/domain/transaction.dart';

void main() {
  group('RiskEngine — Deterministic Risk Detection', () {
    const businessId = 'test-biz-123';
    final now = DateTime.now();

    test(
      'detects critical cash flow shortage when outflow exceeds inflow and burn is high',
      () {
        final currentMetrics = FinancialMetric(
          id: '',
          businessId: businessId,
          periodStart: now.subtract(const Duration(days: 30)),
          periodEnd: now,
          revenue: 5000,
          expenses: 12000,
          profit: -7000,
          profitMargin: -140.0,
          cashInflow: 3000,
          cashOutflow: 11000,
          netCashFlow: -8000,
          debt: 0,
          receivables: 2000,
          payables: 1000,
          revenueGrowth: 0,
          expenseGrowth: 0,
          createdAt: now,
          updatedAt: now,
        );

        final risks = RiskEngine.evaluateRisks(
          businessId: businessId,
          currentMetrics: currentMetrics,
          currentTransactions: [],
          startingCash: 5000, // startingCash + netCashFlow <= 0
        );

        final cashFlowRisk = risks.firstWhere(
          (r) => r.metricName == 'net_cash_flow',
        );
        expect(cashFlowRisk.severity, AlertSeverity.critical);
        expect(cashFlowRisk.title, contains('Cash Flow Shortage'));
      },
    );

    test('detects severe revenue contraction vs prior period', () {
      final prevMetrics = FinancialMetric(
        id: '',
        businessId: businessId,
        periodStart: now.subtract(const Duration(days: 60)),
        periodEnd: now.subtract(const Duration(days: 31)),
        revenue: 20000,
        expenses: 10000,
        profit: 10000,
        profitMargin: 50.0,
        cashInflow: 20000,
        cashOutflow: 10000,
        netCashFlow: 10000,
        debt: 0,
        receivables: 0,
        payables: 0,
        revenueGrowth: 0,
        expenseGrowth: 0,
        createdAt: now,
        updatedAt: now,
      );

      final currentMetrics = FinancialMetric(
        id: '',
        businessId: businessId,
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        revenue: 12000, // -40% drop
        expenses: 10000,
        profit: 2000,
        profitMargin: 16.6,
        cashInflow: 12000,
        cashOutflow: 10000,
        netCashFlow: 2000,
        debt: 0,
        receivables: 0,
        payables: 0,
        revenueGrowth: -40.0,
        expenseGrowth: 0,
        createdAt: now,
        updatedAt: now,
      );

      final risks = RiskEngine.evaluateRisks(
        businessId: businessId,
        currentMetrics: currentMetrics,
        previousMetrics: prevMetrics,
        currentTransactions: [],
      );

      final revRisk = risks.firstWhere((r) => r.metricName == 'revenue_growth');
      expect(revRisk.severity, AlertSeverity.critical);
      expect(revRisk.title, contains('Revenue Contraction'));
    });

    test('detects expenses outpacing revenue growth', () {
      final prevMetrics = FinancialMetric(
        id: '',
        businessId: businessId,
        periodStart: now.subtract(const Duration(days: 60)),
        periodEnd: now.subtract(const Duration(days: 31)),
        revenue: 10000,
        expenses: 6000,
        profit: 4000,
        profitMargin: 40.0,
        cashInflow: 10000,
        cashOutflow: 6000,
        netCashFlow: 4000,
        debt: 0,
        receivables: 0,
        payables: 0,
        revenueGrowth: 0,
        expenseGrowth: 0,
        createdAt: now,
        updatedAt: now,
      );

      final currentMetrics = FinancialMetric(
        id: '',
        businessId: businessId,
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        revenue: 10500, // +5%
        expenses: 9000, // +50%
        profit: 1500,
        profitMargin: 14.2,
        cashInflow: 10500,
        cashOutflow: 9000,
        netCashFlow: 1500,
        debt: 0,
        receivables: 0,
        payables: 0,
        revenueGrowth: 5.0,
        expenseGrowth: 50.0,
        createdAt: now,
        updatedAt: now,
      );

      final risks = RiskEngine.evaluateRisks(
        businessId: businessId,
        currentMetrics: currentMetrics,
        previousMetrics: prevMetrics,
        currentTransactions: [],
      );

      final expRisk = risks.firstWhere((r) => r.metricName == 'expense_growth');
      expect(expRisk.severity, AlertSeverity.high);
      expect(expRisk.title, contains('Expenses Outpacing'));
    });

    test(
      'detects high uncollected receivables and overdue customer invoices',
      () {
        final overdueTx = Transaction(
          id: 'tx-overdue-1',
          businessId: businessId,
          transactionDate: now.subtract(const Duration(days: 15)),
          transactionType: TransactionType.income,
          category: 'Sales',
          amount: 3500,
          currency: 'USD',
          paymentStatus: PaymentStatus.overdue,
          createdAt: now,
          updatedAt: now,
        );

        final currentMetrics = FinancialMetric(
          id: '',
          businessId: businessId,
          periodStart: now.subtract(const Duration(days: 30)),
          periodEnd: now,
          revenue: 7000,
          expenses: 3000,
          profit: 4000,
          profitMargin: 57.1,
          cashInflow: 3500,
          cashOutflow: 3000,
          netCashFlow: 500,
          debt: 0,
          receivables: 3500, // 50% of revenue
          payables: 0,
          revenueGrowth: 0,
          expenseGrowth: 0,
          createdAt: now,
          updatedAt: now,
        );

        final risks = RiskEngine.evaluateRisks(
          businessId: businessId,
          currentMetrics: currentMetrics,
          currentTransactions: [overdueTx],
        );

        expect(risks.any((r) => r.metricName == 'receivables'), isTrue);
        expect(risks.any((r) => r.metricName == 'overdue_receivables'), isTrue);
      },
    );

    test('healthy business produces zero critical/high alerts', () {
      final currentMetrics = FinancialMetric(
        id: '',
        businessId: businessId,
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        revenue: 25000,
        expenses: 12000,
        profit: 13000,
        profitMargin: 52.0,
        cashInflow: 25000,
        cashOutflow: 12000,
        netCashFlow: 13000,
        debt: 0,
        receivables: 0,
        payables: 0,
        revenueGrowth: 15.0,
        expenseGrowth: 5.0,
        createdAt: now,
        updatedAt: now,
      );

      final risks = RiskEngine.evaluateRisks(
        businessId: businessId,
        currentMetrics: currentMetrics,
        currentTransactions: [],
        startingCash: 20000,
      );

      expect(risks.where((r) => r.severity == AlertSeverity.critical), isEmpty);
      expect(risks.where((r) => r.severity == AlertSeverity.high), isEmpty);
    });
  });
}
