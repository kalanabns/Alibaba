import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/ai_cfo/application/cfo_action_plan_controller.dart';
import 'package:alibaba/features/ai_cfo/domain/cfo_action_item.dart';
import 'package:alibaba/features/alerts/domain/alert.dart';
import 'package:alibaba/features/alerts/domain/priority_ranking_engine.dart';
import 'package:alibaba/features/financial_health/domain/financial_goal.dart';
import 'package:alibaba/features/financial_health/domain/financial_metric.dart';

void main() {
  group('CFO Strategic Action Plan & Roadmap Intelligence', () {
    const businessId = 'biz_test_roadmap';
    final now = DateTime.now();

    final testMetric = FinancialMetric(
      id: 'metric_1',
      businessId: businessId,
      periodStart: now.subtract(const Duration(days: 30)),
      periodEnd: now,
      revenue: 70000.0,
      expenses: 65000.0,
      profit: 5000.0,
      profitMargin: 7.14,
      cashInflow: 60000.0,
      cashOutflow: 65000.0,
      netCashFlow: -5000.0,
      receivables: 18000.0,
      payables: 8000.0,
      revenueGrowth: 4.0,
      expenseGrowth: 18.0,
      healthScore: 55.0,
      createdAt: now,
      updatedAt: now,
    );

    final testAlerts = [
      Alert(
        id: 'a1',
        businessId: businessId,
        alertType: AlertType.risk,
        severity: AlertSeverity.critical,
        title: 'Negative Operating Cash Flow (-\$5,000)',
        description: 'Outflows exceed collections',
        recommendation: 'Collect receivables and cut expenses',
        metricName: 'Cash Flow',
        metricValue: -5000.0,
        createdAt: now,
      ),
      Alert(
        id: 'a2',
        businessId: businessId,
        alertType: AlertType.opportunity,
        severity: AlertSeverity.medium,
        title: 'Uncollected Invoices (\$18,000)',
        description: 'Invoices pending over 30 days',
        recommendation: 'Send payment reminders',
        metricName: 'Receivables',
        metricValue: 18000.0,
        createdAt: now,
      ),
    ];

    final testGoals = [
      FinancialGoal(
        id: 'g1',
        businessId: businessId,
        title: 'Increase Margin to 15%',
        goalType: GoalType.targetProfitMargin,
        targetValue: 15.0,
        currentValue: 7.14,
        unit: '%',
        status: GoalStatus.behindTarget,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('generates deterministic 30-day and 90-day strategic roadmap from metrics and alerts', () {
      final roadmap = MonthlyStrategicRoadmap.generateFromContext(
        businessId: businessId,
        metric: testMetric,
        alerts: testAlerts,
        goals: testGoals,
      );

      expect(roadmap.thirtyDayPlan, isNotEmpty);
      expect(roadmap.ninetyDayPlan, isNotEmpty);
      expect(roadmap.activeStrategicInitiatives.length, greaterThanOrEqualTo(2));

      // 30-day plan should prioritize critical cash flow risks
      final criticalActions = roadmap.thirtyDayPlan.where((a) => a.priority == PriorityLevel.critical).toList();
      expect(criticalActions, isNotEmpty);
      expect(criticalActions.any((a) => a.title.contains('Cash') || a.title.contains('Receivable')), isTrue);
    });

    test('CfoActionPlanController updates action statuses and tracks progress accurately', () async {
      final controller = CfoActionPlanController();

      final initialItems = [
        CfoActionItem(
          id: 'action_1',
          businessId: businessId,
          title: 'Collect Overdue Invoices',
          reason: 'Cash deficit',
          priority: PriorityLevel.critical,
          urgency: 'Immediate',
          relatedMetric: 'Accounts Receivable',
          recommendedNextStep: 'Send reminders',
          actionType: ActionLinkType.collectReceivables,
          status: CfoActionStatus.todo,
          createdAt: now,
        ),
        CfoActionItem(
          id: 'action_2',
          businessId: businessId,
          title: 'Trim Software Subscriptions',
          reason: 'Excess expenses',
          priority: PriorityLevel.high,
          urgency: 'Within 30 Days',
          relatedMetric: 'Operating Expenses',
          recommendedNextStep: 'Cancel unused seats',
          actionType: ActionLinkType.reviewExpenses,
          status: CfoActionStatus.inProgress,
          createdAt: now,
        ),
      ];

      controller.loadInMemoryActionItems(initialItems);

      expect(controller.pendingCount, 2);
      expect(controller.completedCount, 0);

      // Complete action 1
      await controller.updateActionStatus('action_1', CfoActionStatus.completed);

      expect(controller.pendingCount, 1);
      expect(controller.completedCount, 1);
      expect(controller.actionItems.first.isCompleted, isTrue);
      expect(controller.actionItems.first.completedAt, isNotNull);
    });
  });
}
