import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/financial_health/application/financial_goals_controller.dart';
import 'package:alibaba/features/financial_health/domain/financial_goal.dart';
import 'package:alibaba/features/financial_health/domain/financial_metric.dart';

void main() {
  group('Financial Goals Intelligence & Tracking', () {
    final now = DateTime.now();

    test('evaluates target revenue goal status correctly', () {
      final achievedGoal = FinancialGoal(
        id: 'g1',
        businessId: 'biz_1',
        title: 'Reach \$50k Monthly Sales',
        goalType: GoalType.targetRevenue,
        targetValue: 50000.0,
        currentValue: 52000.0,
        unit: '\$',
        status: FinancialGoal.evaluateStatus(GoalType.targetRevenue, 50000.0, 52000.0),
        createdAt: now,
        updatedAt: now,
      );

      expect(achievedGoal.status, GoalStatus.achieved);
      expect(achievedGoal.progressRatio, greaterThanOrEqualTo(1.0));
      expect(achievedGoal.difference, lessThanOrEqualTo(0.0));

      final onTrackGoal = FinancialGoal(
        id: 'g2',
        businessId: 'biz_1',
        title: 'Reach \$50k Monthly Sales',
        goalType: GoalType.targetRevenue,
        targetValue: 50000.0,
        currentValue: 45000.0,
        unit: '\$',
        status: FinancialGoal.evaluateStatus(GoalType.targetRevenue, 50000.0, 45000.0),
        createdAt: now,
        updatedAt: now,
      );

      expect(onTrackGoal.status, GoalStatus.onTrack);
      expect(onTrackGoal.progressRatio, closeTo(0.90, 0.01));

      final behindGoal = FinancialGoal(
        id: 'g3',
        businessId: 'biz_1',
        title: 'Reach \$50k Monthly Sales',
        goalType: GoalType.targetRevenue,
        targetValue: 50000.0,
        currentValue: 20000.0,
        unit: '\$',
        status: FinancialGoal.evaluateStatus(GoalType.targetRevenue, 50000.0, 20000.0),
        createdAt: now,
        updatedAt: now,
      );

      expect(behindGoal.status, GoalStatus.behindTarget);
      expect(behindGoal.progressRatio, 0.4);
    });

    test('evaluates expense limit goal status correctly', () {
      // Under limit is achieved
      final underLimitStatus = FinancialGoal.evaluateStatus(
        GoalType.expenseLimit,
        20000.0,
        18000.0,
      );
      expect(underLimitStatus, GoalStatus.achieved);

      // Slightly over limit (within 10%) is on-track
      final slightlyOverStatus = FinancialGoal.evaluateStatus(
        GoalType.expenseLimit,
        20000.0,
        21000.0,
      );
      expect(slightlyOverStatus, GoalStatus.onTrack);

      // Over limit is behind target
      final overLimitStatus = FinancialGoal.evaluateStatus(
        GoalType.expenseLimit,
        20000.0,
        25000.0,
      );
      expect(overLimitStatus, GoalStatus.behindTarget);
    });

    test('FinancialGoalsController synchronizes goals with latest financial metrics', () {
      final controller = FinancialGoalsController();

      final initialGoals = [
        FinancialGoal(
          id: 'g_rev',
          businessId: 'biz_1',
          title: 'Target Revenue',
          goalType: GoalType.targetRevenue,
          targetValue: 50000.0,
          currentValue: 30000.0,
          unit: '\$',
          status: GoalStatus.behindTarget,
          createdAt: now,
          updatedAt: now,
        ),
        FinancialGoal(
          id: 'g_margin',
          businessId: 'biz_1',
          title: 'Target Margin',
          goalType: GoalType.targetProfitMargin,
          targetValue: 25.0,
          currentValue: 10.0,
          unit: '%',
          status: GoalStatus.behindTarget,
          createdAt: now,
          updatedAt: now,
        ),
        FinancialGoal(
          id: 'g_cash',
          businessId: 'biz_1',
          title: 'Target Cash Reserve',
          goalType: GoalType.targetCashReserve,
          targetValue: 30000.0,
          currentValue: 15000.0,
          unit: '\$',
          status: GoalStatus.behindTarget,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      controller.loadInMemoryGoals(initialGoals);
      expect(controller.goals.length, 3);

      final updatedMetric = FinancialMetric(
        id: 'm1',
        businessId: 'biz_1',
        periodStart: now.subtract(const Duration(days: 30)),
        periodEnd: now,
        revenue: 55000.0, // Exceeds target -> Achieved
        expenses: 40000.0,
        profit: 15000.0,
        profitMargin: 27.27, // Exceeds target -> Achieved
        cashInflow: 55000.0,
        cashOutflow: 40000.0,
        netCashFlow: 15000.0,
        createdAt: now,
        updatedAt: now,
      );

      controller.syncGoalsWithMetrics(updatedMetric, startingCash: 35000.0);

      final revGoal = controller.goals.firstWhere((g) => g.goalType == GoalType.targetRevenue);
      expect(revGoal.currentValue, 55000.0);
      expect(revGoal.status, GoalStatus.achieved);

      final marginGoal = controller.goals.firstWhere((g) => g.goalType == GoalType.targetProfitMargin);
      expect(marginGoal.currentValue, 27.27);
      expect(marginGoal.status, GoalStatus.achieved);

      final cashGoal = controller.goals.firstWhere((g) => g.goalType == GoalType.targetCashReserve);
      expect(cashGoal.currentValue, 50000.0);
      expect(cashGoal.status, GoalStatus.achieved);
    });
  });
}
