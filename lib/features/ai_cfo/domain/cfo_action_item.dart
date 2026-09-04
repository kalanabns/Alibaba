import '../../alerts/domain/alert.dart';
import '../../alerts/domain/priority_ranking_engine.dart';
import '../../financial_health/domain/financial_goal.dart';
import '../../financial_health/domain/financial_metric.dart';

enum CfoActionStatus { todo, inProgress, completed, dismissed }

class CfoActionItem {
  const CfoActionItem({
    required this.id,
    required this.businessId,
    required this.title,
    required this.reason,
    required this.priority,
    required this.urgency,
    required this.relatedMetric,
    required this.recommendedNextStep,
    required this.actionType,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String businessId;
  final String title;
  final String reason;
  final PriorityLevel priority;
  final String urgency;
  final String relatedMetric;
  final String recommendedNextStep;
  final ActionLinkType actionType;
  final CfoActionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get isCompleted => status == CfoActionStatus.completed;
  bool get isDismissed => status == CfoActionStatus.dismissed;
  bool get isActive => status == CfoActionStatus.todo || status == CfoActionStatus.inProgress;

  factory CfoActionItem.fromJson(Map<String, dynamic> json) {
    return CfoActionItem(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      title: json['title'] as String,
      reason: json['reason'] as String,
      priority: PriorityLevel.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => PriorityLevel.medium,
      ),
      urgency: json['urgency'] as String? ?? 'Normal',
      relatedMetric: json['related_metric'] as String? ?? 'Financial Health',
      recommendedNextStep: json['recommended_next_step'] as String? ?? 'Review details',
      actionType: ActionLinkType.values.firstWhere(
        (e) => e.name == json['action_type'],
        orElse: () => ActionLinkType.reviewExpenses,
      ),
      status: CfoActionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CfoActionStatus.todo,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'title': title,
      'reason': reason,
      'priority': priority.name,
      'urgency': urgency,
      'related_metric': relatedMetric,
      'recommended_next_step': recommendedNextStep,
      'action_type': actionType.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  CfoActionItem copyWith({
    CfoActionStatus? status,
    DateTime? completedAt,
  }) {
    return CfoActionItem(
      id: id,
      businessId: businessId,
      title: title,
      reason: reason,
      priority: priority,
      urgency: urgency,
      relatedMetric: relatedMetric,
      recommendedNextStep: recommendedNextStep,
      actionType: actionType,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class MonthlyStrategicRoadmap {
  const MonthlyStrategicRoadmap({
    required this.thisMonthPriorities,
    required this.next30Days,
    required this.next90Days,
    this.thirtyDayPlan = const [],
    this.ninetyDayPlan = const [],
  });

  final List<String> thisMonthPriorities;
  final List<String> next30Days;
  final List<String> next90Days;
  final List<CfoActionItem> thirtyDayPlan;
  final List<CfoActionItem> ninetyDayPlan;

  List<String> get activeStrategicInitiatives => thisMonthPriorities;

  /// Synthesizes deterministic 30/90-day roadmap from current metrics, alerts, and goals
  factory MonthlyStrategicRoadmap.generate({
    required FinancialMetric? metric,
    required List<Alert> activeAlerts,
    required List<FinancialGoal> goals,
    String businessId = 'default_biz',
  }) {
    final thisMonth = <String>[];
    final next30 = <String>[];
    final next90 = <String>[];
    final thirtyDayActions = <CfoActionItem>[];
    final ninetyDayActions = <CfoActionItem>[];
    final now = DateTime.now();

    if (metric != null) {
      if (metric.netCashFlow < 0) {
        thisMonth.add('Protect liquidity: curtail non-essential category expenses to arrest -\$${(-metric.netCashFlow).toStringAsFixed(0)} cash burn.');
        thirtyDayActions.add(CfoActionItem(
          id: 'action_cash_protect',
          businessId: businessId,
          title: 'Arrest Negative Cash Burn (-\$${(-metric.netCashFlow).toStringAsFixed(0)})',
          reason: 'Operating cash flow is negative, drawing down reserves.',
          priority: PriorityLevel.critical,
          urgency: 'Next 7 Days',
          relatedMetric: 'Operating Cash Flow',
          recommendedNextStep: 'Curtail non-essential spend and simulate cost reductions.',
          actionType: ActionLinkType.runScenario,
          status: CfoActionStatus.todo,
          createdAt: now,
        ));
      }
      if (metric.receivables > 0) {
        thisMonth.add('Accelerate receivables: follow up on \$${metric.receivables.toStringAsFixed(0)} in outstanding customer balances.');
        thirtyDayActions.add(CfoActionItem(
          id: 'action_collect_recv',
          businessId: businessId,
          title: 'Collect \$${metric.receivables.toStringAsFixed(0)} in Overdue Receivables',
          reason: 'Uncollected balances are constraining liquid cash.',
          priority: PriorityLevel.high,
          urgency: 'Immediate',
          relatedMetric: 'Accounts Receivable',
          recommendedNextStep: 'Send reminders and offer 2% early settlement discount.',
          actionType: ActionLinkType.collectReceivables,
          status: CfoActionStatus.todo,
          createdAt: now,
        ));
      }
      if (metric.expenseGrowth > metric.revenueGrowth && metric.expenseGrowth > 5) {
        thisMonth.add('Audit overhead: operating expenses grew ${metric.expenseGrowth.toStringAsFixed(1)}% vs ${metric.revenueGrowth.toStringAsFixed(1)}% revenue.');
        thirtyDayActions.add(CfoActionItem(
          id: 'action_audit_overhead',
          businessId: businessId,
          title: 'Audit Discretionary Vendor Overheads',
          reason: 'Expense growth (+${metric.expenseGrowth.toStringAsFixed(1)}%) outpaces revenue (+${metric.revenueGrowth.toStringAsFixed(1)}%).',
          priority: PriorityLevel.high,
          urgency: 'Within 14 Days',
          relatedMetric: 'Operating Expenses',
          recommendedNextStep: 'Review subscriptions and supplier contracts in Ledger.',
          actionType: ActionLinkType.reviewExpenses,
          status: CfoActionStatus.todo,
          createdAt: now,
        ));
      }
    }

    if (thisMonth.isEmpty) {
      thisMonth.add('Maintain steady baseline reconciliations and verify weekly bank statements.');
    }

    next30.add('Conduct a supplier & recurring vendor cost audit across top 3 overhead categories.');
    next30.add('Establish invoice reminder cadences to reduce Days Sales Outstanding (DSO).');
    next30.add('Review forward 3-month forecast trajectory and runway buffer.');

    ninetyDayActions.add(CfoActionItem(
      id: 'action_pricing_review',
      businessId: businessId,
      title: 'Review Gross Margin & Pricing Strategy',
      reason: 'Enhance operating leverage across core product lines.',
      priority: PriorityLevel.medium,
      urgency: 'Within 60 Days',
      relatedMetric: 'Profit Margin',
      recommendedNextStep: 'Model pricing adjustment scenarios in What-If Simulator.',
      actionType: ActionLinkType.runScenario,
      status: CfoActionStatus.todo,
      createdAt: now,
    ));

    next90.add('Target 2-3 percentage point gross margin expansion through strategic pricing adjustments.');
    next90.add('Build cash reserves equivalent to at least 2 months of average operating expenses.');
    next90.add('Evaluate hiring affordability and capacity expansion in What-If Simulator.');

    return MonthlyStrategicRoadmap(
      thisMonthPriorities: thisMonth,
      next30Days: next30,
      next90Days: next90,
      thirtyDayPlan: thirtyDayActions,
      ninetyDayPlan: ninetyDayActions,
    );
  }

  factory MonthlyStrategicRoadmap.generateFromContext({
    required String businessId,
    required FinancialMetric? metric,
    required List<Alert> alerts,
    required List<FinancialGoal> goals,
  }) {
    return MonthlyStrategicRoadmap.generate(
      metric: metric,
      activeAlerts: alerts,
      goals: goals,
      businessId: businessId,
    );
  }
}
