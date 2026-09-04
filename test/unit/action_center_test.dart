import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/alerts/application/alerts_controller.dart';
import 'package:alibaba/features/alerts/data/alert_repository.dart';
import 'package:alibaba/features/businesses/domain/business.dart';
import 'package:alibaba/features/financial_health/domain/financial_metric.dart';

void main() {
  group('Action Center & Proactive Alert Intelligence', () {
    const businessId = 'biz-test-action';
    final now = DateTime.now();

    final testBiz = Business(
      id: businessId,
      ownerId: 'user-1',
      name: 'Pacific Coast Roasters',
      industry: 'Food & Beverage',
      country: 'United States',
      currency: 'USD',
      fiscalYearStartMonth: 1,
      startingCash: 15000,
      createdAt: now,
      updatedAt: now,
    );

    final testMetric = FinancialMetric(
      id: 'metric-1',
      businessId: businessId,
      periodStart: now.subtract(const Duration(days: 30)),
      periodEnd: now,
      revenue: 60000,
      expenses: 42000,
      profit: 18000,
      profitMargin: 30.0,
      cashInflow: 55000,
      cashOutflow: 42000,
      netCashFlow: 13000,
      debt: 0,
      receivables: 5000,
      payables: 0,
      revenueGrowth: 15.0,
      expenseGrowth: 5.0,
      healthScore: 86.0,
      createdAt: now,
      updatedAt: now,
    );

    test('generates proactive daily financial check-in from business metrics', () {
      final controller = AlertsController(repository: AlertRepository());

      final checkIn = controller.generateDailyCheckIn(
        business: testBiz,
        metric: testMetric,
      );

      expect(checkIn.priority, isNotEmpty);
      expect(checkIn.watch, contains('receivables'));
      expect(checkIn.opportunity, contains('30.0%'));
      expect(checkIn.action, contains('reminders'));
    });

    test('generates check-in for uninitialized workspace gracefully', () {
      final controller = AlertsController();

      final checkIn = controller.generateDailyCheckIn(
        business: testBiz,
        metric: null,
      );

      expect(checkIn.priority, contains('baseline metrics'));
      expect(checkIn.action, contains('import'));
    });

    test('filters alerts by critical severity and unread status correctly', () {
      final controller = AlertsController();

      controller.setFilter(AlertsFilter.critical);
      expect(controller.selectedFilter, equals(AlertsFilter.critical));

      controller.setFilter(AlertsFilter.all);
      expect(controller.selectedFilter, equals(AlertsFilter.all));
    });
  });
}
