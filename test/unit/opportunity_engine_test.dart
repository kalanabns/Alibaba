import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/alerts/domain/alert.dart';
import 'package:alibaba/features/alerts/domain/opportunity_engine.dart';
import 'package:alibaba/features/financial_health/domain/financial_metric.dart';
import 'package:alibaba/features/transactions/domain/transaction.dart';

void main() {
  group('OpportunityEngine — Deterministic Opportunity Discovery', () {
    const businessId = 'test-biz-456';
    final now = DateTime.now();

    test('identifies receivables collections acceleration opportunity', () {
      final currentMetrics = FinancialMetric(
        id: '',
        businessId: businessId,
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        revenue: 10000,
        expenses: 6000,
        profit: 4000,
        profitMargin: 40.0,
        cashInflow: 7500,
        cashOutflow: 6000,
        netCashFlow: 1500,
        debt: 0,
        receivables: 2500, // > 300
        payables: 0,
        revenueGrowth: 0,
        expenseGrowth: 0,
        createdAt: now,
        updatedAt: now,
      );

      final opportunities = OpportunityEngine.evaluateOpportunities(
        businessId: businessId,
        currentMetrics: currentMetrics,
        currentTransactions: [],
      );

      final colOpp = opportunities.firstWhere(
        (o) => o.metricName == 'receivables',
      );
      expect(colOpp.alertType, AlertType.opportunity);
      expect(colOpp.title, contains('Accelerate Receivables'));
    });

    test(
      'identifies cost reduction opportunity for dominant expense category',
      () {
        final currentMetrics = FinancialMetric(
          id: '',
          businessId: businessId,
          periodStart: now.subtract(const Duration(days: 30)),
          periodEnd: now,
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

        final txList = [
          Transaction(
            id: 'tx-1',
            businessId: businessId,
            transactionDate: now,
            transactionType: TransactionType.expense,
            category: 'Marketing',
            amount: 5500, // 55% of expenses (>25%)
            currency: 'USD',
            createdAt: now,
            updatedAt: now,
          ),
          Transaction(
            id: 'tx-2',
            businessId: businessId,
            transactionDate: now,
            transactionType: TransactionType.expense,
            category: 'Utilities',
            amount: 4500,
            currency: 'USD',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final opportunities = OpportunityEngine.evaluateOpportunities(
          businessId: businessId,
          currentMetrics: currentMetrics,
          currentTransactions: txList,
        );

        expect(opportunities.any((o) => o.title.contains('Marketing')), isTrue);
      },
    );

    test(
      'identifies recurring SaaS & software subscriptions audit opportunity',
      () {
        final currentMetrics = FinancialMetric(
          id: '',
          businessId: businessId,
          periodStart: now.subtract(const Duration(days: 30)),
          periodEnd: now,
          revenue: 15000,
          expenses: 5000,
          profit: 10000,
          profitMargin: 66.6,
          cashInflow: 15000,
          cashOutflow: 5000,
          netCashFlow: 10000,
          debt: 0,
          receivables: 0,
          payables: 0,
          revenueGrowth: 0,
          expenseGrowth: 0,
          createdAt: now,
          updatedAt: now,
        );

        final txList = [
          Transaction(
            id: 'tx-sub-1',
            businessId: businessId,
            transactionDate: now,
            transactionType: TransactionType.expense,
            category: 'Software',
            description: 'Cloud hosting AWS',
            amount: 300,
            currency: 'USD',
            createdAt: now,
            updatedAt: now,
          ),
          Transaction(
            id: 'tx-sub-2',
            businessId: businessId,
            transactionDate: now,
            transactionType: TransactionType.expense,
            category: 'Operations',
            description: 'Monthly CRM Subscription',
            amount: 250,
            currency: 'USD',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final opportunities = OpportunityEngine.evaluateOpportunities(
          businessId: businessId,
          currentMetrics: currentMetrics,
          currentTransactions: txList,
        );

        expect(
          opportunities.any((o) => o.metricName == 'recurring_expenses'),
          isTrue,
        );
      },
    );
  });
}
