import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/core/utilities/uuid_generator.dart';
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
      expect(reply, contains('Recommended Actions'));
      expect(reply, contains('HIGH'));
    });

    test('generates hiring affordability decision advice', () {
      final reply = AICFORepository.generateAdvisoryResponse(
        message: 'Can I afford to hire a new staff member?',
        metric: testMetric,
        business: testBiz,
      );

      expect(reply, contains('What Happened'));
      expect(reply, contains('payroll'));
      expect(reply, contains('What-If Simulator'));
      expect(reply, contains('Recommended Actions'));
    });

    test('generates forward cash forecast advice', () {
      final reply = AICFORepository.generateAdvisoryResponse(
        message: 'How much cash will I have next month?',
        metric: testMetric,
        business: testBiz,
      );

      expect(reply, contains('Forecasts'));
      expect(reply, contains('receivables'));
      expect(reply, contains('Expected Impact'));
    });

    test('generates pricing scenario advice for 5% price increase', () {
      final reply = AICFORepository.generateAdvisoryResponse(
        message: 'What happens if I increase prices by 5%?',
        metric: testMetric,
        business: testBiz,
      );

      expect(reply, contains('5% price adjustment'));
      expect(reply, contains('What-If Simulator'));
      expect(reply, contains('Top Risks'));
    });

    test('handles insufficient data gracefully without throwing', () {
      final reply = AICFORepository.generateAdvisoryResponse(
        message: 'How is my business doing?',
        metric: null,
        business: testBiz,
      );

      expect(reply, contains('insufficient financial history'));
      expect(reply, contains('Transactions'));
    });

    test('controller session reset clears conversation turns and generates valid UUID', () {
      final controller = AICFOController();
      final initialSession = controller.sessionId;

      expect(UuidUtils.isValidUuid(initialSession), isTrue);

      controller.resetSession(businessId);

      expect(controller.sessionId, isNot(equals(initialSession)));
      expect(UuidUtils.isValidUuid(controller.sessionId), isTrue);
      expect(controller.messages, isEmpty);
      expect(controller.errorMessage, isNull);
    });

    test('controller handles invalid session ID by normalizing to valid UUID', () {
      final controller = AICFOController(sessionId: 'sess_1788505271405_305756');
      expect(UuidUtils.isValidUuid(controller.sessionId), isTrue);
      expect(controller.sessionId, isNot(contains('sess_')));
    });

    test('UuidUtils generates compliant RFC 4122 v4 UUID and validates correctly', () {
      final uuid = UuidUtils.generate();
      expect(UuidUtils.isValidUuid(uuid), isTrue);
      expect(uuid.length, equals(36));
      expect(uuid[14], equals('4')); // Version 4
      expect(['8', '9', 'a', 'b'], contains(uuid[19].toLowerCase())); // Variant 1

      expect(UuidUtils.isValidUuid('sess_1788505271405_305756'), isFalse);
      expect(UuidUtils.isValidUuid(''), isFalse);
      expect(UuidUtils.isValidUuid(null), isFalse);
      expect(UuidUtils.isValidUuid('12345'), isFalse);
    });
  });
}
