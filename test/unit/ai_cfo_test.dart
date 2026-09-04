import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/ai_cfo/application/ai_cfo_controller.dart';
import 'package:alibaba/features/ai_cfo/data/ai_cfo_repository.dart';
import 'package:alibaba/features/alerts/domain/alert.dart';
import 'package:alibaba/features/businesses/domain/business.dart';
import 'package:alibaba/features/financial_health/domain/financial_metric.dart';

void main() {
  group('AI CFO Advisory & Controller', () {
    const businessId = 'test-biz-789';
    final now = DateTime.now();

    final testBiz = Business(
      id: businessId,
      ownerId: 'user-1',
      name: 'BrightWave Logistics',
      industry: 'Transportation',
      country: 'United States',
      currency: 'USD',
      fiscalYearStartMonth: 1,
      startingCash: 10000,
      createdAt: now,
      updatedAt: now,
    );

    final testMetric = FinancialMetric(
      id: 'metric-1',
      businessId: businessId,
      periodStart: now.subtract(const Duration(days: 30)),
      periodEnd: now,
      revenue: 50000,
      expenses: 32000,
      profit: 18000,
      profitMargin: 36.0,
      cashInflow: 48000,
      cashOutflow: 32000,
      netCashFlow: 16000,
      debt: 0,
      receivables: 2000,
      payables: 0,
      revenueGrowth: 12.0,
      expenseGrowth: 6.0,
      healthScore: 88.0,
      createdAt: now,
      updatedAt: now,
    );

    test(
      'generates grounded dashboard executive brief without throwing errors',
      () async {
        final controller = AICFOController(repository: AICFORepository());

        await controller.generateDashboardSummary(
          businessId: businessId,
          currentMetrics: testMetric,
          business: testBiz,
          force: true,
        );

        expect(controller.cachedDashboardSummary, isNotNull);
        expect(
          controller.cachedDashboardSummary,
          contains('BrightWave Logistics'),
        );
        expect(controller.cachedDashboardSummary, contains('88/100'));
      },
    );

    test('generates structured advisory reply for alert explanation', () {
      final alert = Alert(
        id: 'alert-1',
        businessId: businessId,
        alertType: AlertType.risk,
        severity: AlertSeverity.high,
        title: 'Negative Operating Cash Flow',
        description: 'Cash outflow exceeded inflow by \$4,000.',
        recommendation:
            'Delay non-essential disbursements and accelerate collections.',
        createdAt: now,
      );

      final reply = AICFORepository.generateAdvisoryResponse(
        message: 'Explain this signal',
        alert: alert,
        metric: testMetric,
        business: testBiz,
      );

      expect(reply, contains('What Happened'));
      expect(reply, contains('Why It Matters'));
      expect(reply, contains('What I Recommend'));
      expect(reply, contains('HIGH'));
    });

    test('controller session reset clears conversation turns', () {
      final controller = AICFOController();
      final initialSession = controller.sessionId;

      controller.resetSession(businessId);

      expect(controller.sessionId, isNot(equals(initialSession)));
      expect(controller.messages, isEmpty);
      expect(controller.errorMessage, isNull);
    });
  });
}
