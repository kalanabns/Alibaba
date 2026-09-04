import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/financial_health/domain/financial_engine.dart';
import 'package:alibaba/features/transactions/domain/transaction.dart';

void main() {
  group('FinancialEngine — Deterministic Metrics Calculations', () {
    final now = DateTime.utc(2026, 8, 15);

    test('calculates revenue, expenses, profit, and margin correctly', () {
      final transactions = [
        Transaction(
          id: 't-1',
          businessId: 'biz-1',
          transactionDate: DateTime.utc(2026, 8, 5),
          transactionType: TransactionType.income,
          category: 'Sales Revenue',
          amount: 80000.00,
          paymentStatus: PaymentStatus.paid,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 't-2',
          businessId: 'biz-1',
          transactionDate: DateTime.utc(2026, 8, 10),
          transactionType: TransactionType.expense,
          category: 'Payroll',
          amount: 50000.00,
          paymentStatus: PaymentStatus.paid,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 't-3',
          businessId: 'biz-1',
          transactionDate: DateTime.utc(2026, 8, 12),
          transactionType: TransactionType.transfer,
          category: 'Internal Transfer',
          amount: 10000.00,
          paymentStatus: PaymentStatus.paid,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final metrics = FinancialEngine.calculatePeriodMetrics(
        businessId: 'biz-1',
        periodStart: DateTime.utc(2026, 8, 1),
        periodEnd: DateTime.utc(2026, 8, 31),
        currentTransactions: transactions,
      );

      expect(metrics.revenue, 80000.00);
      expect(metrics.expenses, 50000.00);
      expect(metrics.profit, 30000.00);
      expect(
        metrics.profitMargin,
        closeTo(37.5, 0.01),
      ); // 30000 / 80000 * 100 = 37.5%
      expect(metrics.cashInflow, 80000.00);
      expect(metrics.cashOutflow, 50000.00);
      expect(metrics.netCashFlow, 30000.00);
      expect(metrics.receivables, 0.0);
      expect(metrics.payables, 0.0);
    });

    test('excludes transfers from revenue and expenses calculations', () {
      final transactions = [
        Transaction(
          id: 't-1',
          businessId: 'biz-1',
          transactionDate: DateTime.utc(2026, 8, 5),
          transactionType: TransactionType.transfer,
          category: 'Internal Transfer',
          amount: 50000.00,
          paymentStatus: PaymentStatus.paid,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final metrics = FinancialEngine.calculatePeriodMetrics(
        businessId: 'biz-1',
        periodStart: DateTime.utc(2026, 8, 1),
        periodEnd: DateTime.utc(2026, 8, 31),
        currentTransactions: transactions,
      );

      expect(metrics.revenue, 0.0);
      expect(metrics.expenses, 0.0);
      expect(metrics.profit, 0.0);
      expect(metrics.profitMargin, 0.0);
    });

    test(
      'correctly assigns receivables and payables for pending and overdue states',
      () {
        final transactions = [
          Transaction(
            id: 't-1',
            businessId: 'biz-1',
            transactionDate: DateTime.utc(2026, 8, 5),
            transactionType: TransactionType.income,
            category: 'Sales Revenue',
            amount: 25000.00,
            paymentStatus: PaymentStatus.pending, // Pending Receivable
            createdAt: now,
            updatedAt: now,
          ),
          Transaction(
            id: 't-2',
            businessId: 'biz-1',
            transactionDate: DateTime.utc(2026, 8, 10),
            transactionType: TransactionType.expense,
            category: 'Inventory',
            amount: 15000.00,
            paymentStatus: PaymentStatus.overdue, // Overdue Payable
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final metrics = FinancialEngine.calculatePeriodMetrics(
          businessId: 'biz-1',
          periodStart: DateTime.utc(2026, 8, 1),
          periodEnd: DateTime.utc(2026, 8, 31),
          currentTransactions: transactions,
        );

        expect(metrics.revenue, 25000.00);
        expect(metrics.expenses, 15000.00);
        expect(metrics.receivables, 25000.00);
        expect(metrics.payables, 15000.00);
        expect(metrics.cashInflow, 0.0); // Not paid yet
        expect(metrics.cashOutflow, 0.0); // Not paid yet
        expect(metrics.netCashFlow, 0.0);
      },
    );

    test('handles zero revenue safely without division by zero', () {
      final transactions = [
        Transaction(
          id: 't-1',
          businessId: 'biz-1',
          transactionDate: DateTime.utc(2026, 8, 5),
          transactionType: TransactionType.expense,
          category: 'Software',
          amount: 500.00,
          paymentStatus: PaymentStatus.paid,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final metrics = FinancialEngine.calculatePeriodMetrics(
        businessId: 'biz-1',
        periodStart: DateTime.utc(2026, 8, 1),
        periodEnd: DateTime.utc(2026, 8, 31),
        currentTransactions: transactions,
      );

      expect(metrics.revenue, 0.0);
      expect(metrics.expenses, 500.00);
      expect(metrics.profit, -500.00);
      expect(metrics.profitMargin, -100.0);
      expect(metrics.profitMargin.isNaN, false);
      expect(metrics.profitMargin.isInfinite, false);
    });

    test('calculates period-over-period growth rates accurately', () {
      final previousTransactions = [
        Transaction(
          id: 'prev-1',
          businessId: 'biz-1',
          transactionDate: DateTime.utc(2026, 7, 10),
          transactionType: TransactionType.income,
          category: 'Sales Revenue',
          amount: 50000.00,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'prev-2',
          businessId: 'biz-1',
          transactionDate: DateTime.utc(2026, 7, 15),
          transactionType: TransactionType.expense,
          category: 'Payroll',
          amount: 40000.00,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final currentTransactions = [
        Transaction(
          id: 'curr-1',
          businessId: 'biz-1',
          transactionDate: DateTime.utc(2026, 8, 10),
          transactionType: TransactionType.income,
          category: 'Sales Revenue',
          amount: 60000.00, // +20%
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'curr-2',
          businessId: 'biz-1',
          transactionDate: DateTime.utc(2026, 8, 15),
          transactionType: TransactionType.expense,
          category: 'Payroll',
          amount: 44000.00, // +10%
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final metrics = FinancialEngine.calculatePeriodMetrics(
        businessId: 'biz-1',
        periodStart: DateTime.utc(2026, 8, 1),
        periodEnd: DateTime.utc(2026, 8, 31),
        currentTransactions: currentTransactions,
        previousTransactions: previousTransactions,
      );

      expect(metrics.revenueGrowth, closeTo(20.0, 0.01));
      expect(metrics.expenseGrowth, closeTo(10.0, 0.01));
    });
  });
}
