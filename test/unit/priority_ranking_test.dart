import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/ai_cfo/domain/cfo_briefing.dart';
import 'package:alibaba/features/alerts/domain/alert.dart';
import 'package:alibaba/features/alerts/domain/priority_ranking_engine.dart';
import 'package:alibaba/features/businesses/domain/business.dart';
import 'package:alibaba/features/financial_health/domain/financial_metric.dart';

void main() {
  group('Stage 13 — Priority Ranking Engine & CFO Briefing', () {
    const businessId = 'biz_test_p13';
    final now = DateTime.now();

    final testBusiness = Business(
      id: businessId,
      ownerId: 'user_1',
      name: 'Blue Harbor Coffee',
      industry: 'Food & Beverage',
      currency: 'USD',
      fiscalYearStartMonth: 1,
      startingCash: 20000.0,
      createdAt: now,
      updatedAt: now,
    );

    final testMetric = FinancialMetric(
      id: 'metric_1',
      businessId: businessId,
      periodStart: now.subtract(const Duration(days: 30)),
      periodEnd: now,
      revenue: 50000.0,
      expenses: 42000.0,
      profit: 8000.0,
      profitMargin: 16.0,
      cashInflow: 45000.0,
      cashOutflow: 48000.0,
      netCashFlow: -3000.0,
      receivables: 15000.0,
      payables: 5000.0,
      revenueGrowth: 5.0,
      expenseGrowth: 18.0,
      healthScore: 61.0,
      createdAt: now,
      updatedAt: now,
    );

    final testAlerts = [
      Alert(
        id: 'alert_burn',
        businessId: businessId,
        alertType: AlertType.risk,
        severity: AlertSeverity.critical,
        title: 'Severe Monthly Cash Burn (-\$3,000)',
        description: 'Operating cash flow is negative and depleting reserve balances.',
        recommendation: 'Audit discretionary vendor costs immediately.',
        metricName: 'Net Cash Flow',
        metricValue: 3000.0,
        createdAt: now,
      ),
      Alert(
        id: 'alert_receivables',
        businessId: businessId,
        alertType: AlertType.opportunity,
        severity: AlertSeverity.medium,
        title: 'Overdue Receivables Acceleration (\$15,000)',
        description: '\$15,000 uncollected in customer invoice accounts.',
        recommendation: 'Issue 2% Net-10 early payment discounts.',
        metricName: 'Accounts Receivable',
        metricValue: 15000.0,
        createdAt: now,
      ),
    ];

    test('ranks critical cash burn ahead of medium opportunity issues', () {
      final issues = PriorityRankingEngine.rankFinancialIssues(
        business: testBusiness,
        metric: testMetric,
        activeAlerts: testAlerts,
      );

      expect(issues, isNotEmpty);
      expect(issues.first.priorityLevel, equals(PriorityLevel.critical));
      expect(issues.first.rank, equals(1));
      expect(issues.first.title, contains('Cash Burn'));
    });

    test('generates grounded 6-section CFO Briefing from engine metrics and alerts', () {
      final briefing = CfoBriefing.generate(
        business: testBusiness,
        metric: testMetric,
        activeAlerts: testAlerts,
      );

      expect(briefing.todayStatus, contains('Blue Harbor Coffee'));
      expect(briefing.todayStatus, contains('tightening'));
      expect(briefing.mostImportantChange, contains('18.0%'));
      expect(briefing.biggestRisk, contains('Cash Burn'));
      expect(briefing.bestOpportunity, isNotEmpty);
      expect(briefing.recommendedAction, isNotEmpty);
      expect(briefing.prioritizedIssues, isNotEmpty);
    });
  });
}
