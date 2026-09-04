import 'dart:math' as math;
import '../../financial_health/domain/financial_engine.dart';
import '../../financial_health/domain/financial_metric.dart';
import '../../transactions/domain/transaction.dart';

enum ScenarioType {
  revenueDelta,
  expenseDelta,
  categoryExpenseDelta,
  pricingAdjustment,
  headcountAddition,
}

class ScenarioAssumption {
  const ScenarioAssumption({
    required this.type,
    required this.name,
    required this.description,
    this.percentageDelta = 0.0,
    this.targetCategory,
    this.fixedAmountDelta = 0.0,
    this.assumptionNote,
  });

  final ScenarioType type;
  final String name;
  final String description;
  final double percentageDelta; // e.g. +10.0 for +10%
  final String? targetCategory; // e.g. "Marketing"
  final double fixedAmountDelta; // e.g. +3500 for monthly employee cost
  final String? assumptionNote;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'percentage_delta': percentageDelta,
      'target_category': targetCategory,
      'fixed_amount_delta': fixedAmountDelta,
      'assumption_note': assumptionNote,
    };
  }

  factory ScenarioAssumption.fromJson(Map<String, dynamic> json) {
    return ScenarioAssumption(
      type: ScenarioType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ScenarioType.revenueDelta,
      ),
      name: json['name'] as String? ?? 'Custom Scenario',
      description: json['description'] as String? ?? '',
      percentageDelta: (json['percentage_delta'] as num?)?.toDouble() ?? 0.0,
      targetCategory: json['target_category'] as String?,
      fixedAmountDelta: (json['fixed_amount_delta'] as num?)?.toDouble() ?? 0.0,
      assumptionNote: json['assumption_note'] as String?,
    );
  }
}

class SimulationResult {
  const SimulationResult({
    required this.assumption,
    required this.baselineRevenue,
    required this.baselineExpenses,
    required this.baselineProfit,
    required this.baselineMargin,
    required this.baselineCashFlow,
    required this.baselineHealthScore,
    required this.projectedRevenue,
    required this.projectedExpenses,
    required this.projectedProfit,
    required this.projectedMargin,
    required this.projectedCashFlow,
    required this.projectedHealthScore,
    required this.revenueDelta,
    required this.expensesDelta,
    required this.profitDelta,
    required this.marginDelta,
    required this.cashFlowDelta,
    required this.healthScoreDelta,
    required this.executiveSummary,
    required this.tradeOffs,
  });

  final ScenarioAssumption assumption;

  // Baselines
  final double baselineRevenue;
  final double baselineExpenses;
  final double baselineProfit;
  final double baselineMargin;
  final double baselineCashFlow;
  final double baselineHealthScore;

  // Projecteds
  final double projectedRevenue;
  final double projectedExpenses;
  final double projectedProfit;
  final double projectedMargin;
  final double projectedCashFlow;
  final double projectedHealthScore;

  // Deltas
  final double revenueDelta;
  final double expensesDelta;
  final double profitDelta;
  final double marginDelta;
  final double cashFlowDelta;
  final double healthScoreDelta;

  final String executiveSummary;
  final List<String> tradeOffs;

  Map<String, dynamic> baselineToJson() {
    return {
      'revenue': baselineRevenue,
      'expenses': baselineExpenses,
      'profit': baselineProfit,
      'profit_margin': baselineMargin,
      'net_cash_flow': baselineCashFlow,
      'health_score': baselineHealthScore,
    };
  }

  Map<String, dynamic> projectedToJson() {
    return {
      'revenue': projectedRevenue,
      'expenses': projectedExpenses,
      'profit': projectedProfit,
      'profit_margin': projectedMargin,
      'net_cash_flow': projectedCashFlow,
      'health_score': projectedHealthScore,
      'profit_delta': profitDelta,
      'margin_delta': marginDelta,
    };
  }
}

class SimulationEngine {
  const SimulationEngine._();

  /// Deterministically evaluates a What-If scenario against current baseline metrics
  /// and transaction history.
  static SimulationResult simulate({
    required FinancialMetric baselineMetric,
    required ScenarioAssumption assumption,
    List<Transaction> transactions = const [],
  }) {
    final baseRev = baselineMetric.revenue;
    final baseExp = baselineMetric.expenses;
    final baseProfit = baselineMetric.profit;
    final baseMargin = baselineMetric.profitMargin;
    final baseCash = baselineMetric.netCashFlow;
    final baseHealth = baselineMetric.healthScore ?? 50.0;

    double projRev = baseRev;
    double projExp = baseExp;
    final tradeOffs = <String>[];
    String summary = '';

    switch (assumption.type) {
      case ScenarioType.revenueDelta:
        final multiplier = 1.0 + (assumption.percentageDelta / 100.0);
        projRev = math.max(0.0, baseRev * multiplier);
        final deltaPct = assumption.percentageDelta;
        if (deltaPct >= 0) {
          summary =
              'Increasing top-line revenue by ${deltaPct.toStringAsFixed(1)}% expands net monthly earnings.';
          tradeOffs.add(
            'Ensure operational fulfillment capacity and staff can scale with higher volume.',
          );
        } else {
          summary =
              'A ${(-deltaPct).toStringAsFixed(1)}% drop in revenue tests your operating cushion.';
          tradeOffs.add(
            'May require overhead reductions to preserve positive cash flow under lower demand.',
          );
        }
        break;

      case ScenarioType.expenseDelta:
        final multiplier = 1.0 + (assumption.percentageDelta / 100.0);
        projExp = math.max(0.0, baseExp * multiplier);
        final deltaPct = assumption.percentageDelta;
        if (deltaPct <= 0) {
          summary =
              'Reducing general overhead by ${(-deltaPct).toStringAsFixed(1)}% immediately enhances profit margins.';
          tradeOffs.add(
            'Ensure essential business tools, client support, or product quality are not compromised.',
          );
        } else {
          summary =
              'A ${deltaPct.toStringAsFixed(1)}% increase in operating expenses narrows your profit margin.';
          tradeOffs.add(
            'Requires top-line revenue expansion to maintain historical profitability ratios.',
          );
        }
        break;

      case ScenarioType.categoryExpenseDelta:
        final category = assumption.targetCategory ?? 'Marketing';
        final catSpending = transactions
            .where(
              (t) =>
                  t.transactionType == TransactionType.expense &&
                  t.category.toLowerCase() == category.toLowerCase(),
            )
            .fold<double>(0.0, (acc, t) => acc + t.amount);

        final catBase = catSpending > 0 ? catSpending : (baseExp * 0.20);
        final catNew = math.max(
          0.0,
          catBase * (1.0 + (assumption.percentageDelta / 100.0)),
        );
        final savingOrCost = catNew - catBase;
        projExp = math.max(0.0, baseExp + savingOrCost);

        if (savingOrCost <= 0) {
          summary =
              'Optimizing $category budget saves \$${(-savingOrCost).toStringAsFixed(2)} per reporting period.';
          tradeOffs.add(
            'Audit vendor contracts to capture savings without slowing customer acquisition or delivery.',
          );
        } else {
          summary =
              'Expanding $category budget adds \$${savingOrCost.toStringAsFixed(2)} in periodic overhead.';
          tradeOffs.add(
            'Monitor return on investment (ROI) closely to confirm the additional spending generates matching revenue.',
          );
        }
        break;

      case ScenarioType.pricingAdjustment:
        final priceDelta = assumption.percentageDelta;
        final multiplier = 1.0 + (priceDelta / 100.0);
        projRev = math.max(0.0, baseRev * multiplier);
        summary =
            'Adjusting prices by ${priceDelta >= 0 ? '+' : ''}${priceDelta.toStringAsFixed(1)}% (assuming volume remains unchanged).';
        tradeOffs.add(
          'Assumption: Customer transaction volume remains constant. Watch for potential price sensitivity or client churn.',
        );
        break;

      case ScenarioType.headcountAddition:
        final monthlyCost = assumption.fixedAmountDelta;
        projExp = baseExp + monthlyCost;
        summary =
            'Adding headcount increases monthly payroll obligations by \$${monthlyCost.toStringAsFixed(2)}.';
        tradeOffs.add(
          'Consider ramp-up time before the new hire generates offsetting productivity or revenue.',
        );
        break;
    }

    final projProfit = projRev - projExp;
    final projMargin = projRev > 0
        ? (projProfit / projRev) * 100.0
        : (projExp > 0 ? -100.0 : 0.0);

    // Cash flow estimation
    final revChange = projRev - baseRev;
    final expChange = projExp - baseExp;
    final projCash = baseCash + (revChange - expChange);

    // Recompute Health Score deterministically
    final healthBreakdown = FinancialEngine.calculateHealthScore(
      revenue: projRev,
      expenses: projExp,
      profit: projProfit,
      profitMargin: projMargin,
      cashInflow: math.max(0.0, baselineMetric.cashInflow + revChange),
      cashOutflow: math.max(0.0, baselineMetric.cashOutflow + expChange),
      netCashFlow: projCash,
      receivables: baselineMetric.receivables,
      payables: baselineMetric.payables,
      revenueGrowth: baseRev > 0 ? (revChange / baseRev) * 100.0 : 0.0,
      expenseGrowth: baseExp > 0 ? (expChange / baseExp) * 100.0 : 0.0,
      hasPreviousPeriod: true,
    );

    final projHealth = healthBreakdown.totalScore;

    return SimulationResult(
      assumption: assumption,
      baselineRevenue: baseRev,
      baselineExpenses: baseExp,
      baselineProfit: baseProfit,
      baselineMargin: baseMargin,
      baselineCashFlow: baseCash,
      baselineHealthScore: baseHealth,
      projectedRevenue: projRev,
      projectedExpenses: projExp,
      projectedProfit: projProfit,
      projectedMargin: projMargin,
      projectedCashFlow: projCash,
      projectedHealthScore: projHealth,
      revenueDelta: projRev - baseRev,
      expensesDelta: projExp - baseExp,
      profitDelta: projProfit - baseProfit,
      marginDelta: projMargin - baseMargin,
      cashFlowDelta: projCash - baseCash,
      healthScoreDelta: projHealth - baseHealth,
      executiveSummary: summary,
      tradeOffs: tradeOffs,
    );
  }
}
