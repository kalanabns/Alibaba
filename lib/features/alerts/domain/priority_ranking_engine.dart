import '../../businesses/domain/business.dart';
import '../../financial_health/domain/financial_metric.dart';
import '../../forecasts/domain/forecast.dart';
import '../../transactions/domain/transaction.dart';
import 'alert.dart';

enum PriorityLevel { critical, high, medium, low, informational }

enum ActionLinkType {
  reviewExpenses,
  collectReceivables,
  runScenario,
  askAiCfo,
  reviewForecast,
  viewTransactions,
}

class PrioritizedFinancialIssue {
  const PrioritizedFinancialIssue({
    required this.id,
    required this.rank,
    required this.priorityLevel,
    required this.title,
    required this.whyItMatters,
    required this.recommendedAction,
    required this.expectedImpact,
    required this.urgency,
    required this.sourceMetric,
    required this.actionType,
    this.score = 0.0,
    this.financialAmount,
    this.relatedAlert,
    this.actionPayload,
  });

  final String id;
  final int rank;
  final PriorityLevel priorityLevel;
  final String title;
  final String whyItMatters;
  final String recommendedAction;
  final String expectedImpact;
  final String urgency;
  final String sourceMetric;
  final ActionLinkType actionType;
  final double score;
  final double? financialAmount;
  final Alert? relatedAlert;
  final Map<String, dynamic>? actionPayload;

  bool get isCritical => priorityLevel == PriorityLevel.critical;
  bool get isHigh => priorityLevel == PriorityLevel.high;

  String get priorityBadgeLabel {
    switch (priorityLevel) {
      case PriorityLevel.critical:
        return 'P1 • CRITICAL';
      case PriorityLevel.high:
        return 'P2 • HIGH';
      case PriorityLevel.medium:
        return 'P3 • MEDIUM';
      case PriorityLevel.low:
        return 'P4 • LOW';
      case PriorityLevel.informational:
        return 'P5 • INFO';
    }
  }
}

class PriorityRankingEngine {
  const PriorityRankingEngine._();

  /// Deterministically ranks active alerts and metric signals by financial gravity.
  static List<PrioritizedFinancialIssue> rankFinancialIssues({
    required Business business,
    required FinancialMetric? metric,
    required List<Alert> activeAlerts,
    List<Forecast>? forecasts,
    List<Transaction>? transactions,
  }) {
    final List<_ScoredCandidate> candidates = [];

    // 1. Process active alerts
    for (final alert in activeAlerts.where((a) => !a.isRead)) {
      double baseScore = 0.0;
      PriorityLevel level = PriorityLevel.low;
      String urgency = 'This Month';
      ActionLinkType actionType = ActionLinkType.askAiCfo;

      switch (alert.severity) {
        case AlertSeverity.critical:
          baseScore = 100.0;
          level = PriorityLevel.critical;
          urgency = 'Immediate (< 48 hrs)';
          break;
        case AlertSeverity.high:
          baseScore = 75.0;
          level = PriorityLevel.high;
          urgency = 'This Week';
          break;
        case AlertSeverity.medium:
          baseScore = 50.0;
          level = PriorityLevel.medium;
          urgency = 'Next 14 Days';
          break;
        case AlertSeverity.low:
          baseScore = 25.0;
          level = PriorityLevel.low;
          urgency = 'Strategic';
          break;
      }

      // Add financial exposure weight
      if (alert.metricValue != null && alert.metricValue! > 0) {
        baseScore += (alert.metricValue! / 1000.0).clamp(0.0, 30.0);
      }

      // Infer optimal action link
      final lowerTitle = alert.title.toLowerCase();
      final lowerDesc = alert.description.toLowerCase();

      if (lowerTitle.contains('receivable') ||
          lowerTitle.contains('invoice') ||
          lowerDesc.contains('receivable')) {
        actionType = ActionLinkType.collectReceivables;
      } else if (lowerTitle.contains('expense') ||
          lowerTitle.contains('cost') ||
          lowerTitle.contains('subscription') ||
          lowerDesc.contains('operating expenses')) {
        actionType = ActionLinkType.reviewExpenses;
      } else if (lowerTitle.contains('cash') ||
          lowerTitle.contains('burn') ||
          lowerTitle.contains('runway')) {
        actionType = ActionLinkType.runScenario;
      }

      final impact = alert.recommendation ??
          'Mitigates solvency risk and protects working capital liquidity.';

      candidates.add(
        _ScoredCandidate(
          id: alert.id,
          score: baseScore,
          priorityLevel: level,
          title: alert.title,
          whyItMatters: alert.description,
          recommendedAction: alert.recommendation ?? 'Review transaction records and adjust budgets.',
          expectedImpact: impact,
          urgency: urgency,
          sourceMetric: alert.metricName ?? 'Financial Health',
          actionType: actionType,
          financialAmount: alert.metricValue,
          relatedAlert: alert,
        ),
      );
    }

    // 2. Synthesize baseline metric risks if not covered by active alerts
    if (metric != null) {
      // Cash burn check
      if (metric.netCashFlow < 0 &&
          !candidates.any((c) => c.title.toLowerCase().contains('cash burn') || c.title.toLowerCase().contains('shortage') || c.title.toLowerCase().contains('deficit'))) {
        final monthlyBurn = -metric.netCashFlow;
        candidates.add(
          _ScoredCandidate(
            id: 'synth_cash_burn_${metric.id}',
            score: 85.0 + (monthlyBurn / 1000.0).clamp(0.0, 20.0),
            priorityLevel: monthlyBurn > 10000 ? PriorityLevel.critical : PriorityLevel.high,
            title: 'Operating Cash Flow Deficit',
            whyItMatters: 'Monthly cash outflows exceed inflows by ${business.currency} ${monthlyBurn.toStringAsFixed(2)}.',
            recommendedAction: 'Audit overhead commitments and accelerate overdue customer invoice collections.',
            expectedImpact: 'Preserves runway and stabilizes operating cash reserves.',
            urgency: 'Immediate (< 7 Days)',
            sourceMetric: 'Net Cash Flow',
            actionType: ActionLinkType.runScenario,
            financialAmount: monthlyBurn,
            actionPayload: {'preset': 'expense_reduction'},
          ),
        );
      }

      // Receivables check
      if (metric.receivables > 0 &&
          metric.revenue > 0 &&
          (metric.receivables / metric.revenue) > 0.25 &&
          !candidates.any((c) => c.title.toLowerCase().contains('receivable'))) {
        candidates.add(
          _ScoredCandidate(
            id: 'synth_receivables_${metric.id}',
            score: 70.0 + (metric.receivables / 2000.0).clamp(0.0, 15.0),
            priorityLevel: PriorityLevel.high,
            title: 'Elevated Uncollected Receivables',
            whyItMatters: '${business.currency} ${metric.receivables.toStringAsFixed(2)} is locked in unpaid customer invoices.',
            recommendedAction: 'Issue automated payment reminders and offer early settlement discounts.',
            expectedImpact: 'Directly injects up to ${business.currency} ${metric.receivables.toStringAsFixed(2)} into cash balance.',
            urgency: 'This Week',
            sourceMetric: 'Accounts Receivable',
            actionType: ActionLinkType.collectReceivables,
            financialAmount: metric.receivables,
          ),
        );
      }
    }

    // Sort descending by calculated score
    candidates.sort((a, b) => b.score.compareTo(a.score));

    // Assign sequential ranks 1..N
    return List.generate(candidates.length, (index) {
      final c = candidates[index];
      return PrioritizedFinancialIssue(
        id: c.id,
        rank: index + 1,
        priorityLevel: c.priorityLevel,
        title: c.title,
        whyItMatters: c.whyItMatters,
        recommendedAction: c.recommendedAction,
        expectedImpact: c.expectedImpact,
        urgency: c.urgency,
        sourceMetric: c.sourceMetric,
        actionType: c.actionType,
        score: c.score,
        financialAmount: c.financialAmount,
        relatedAlert: c.relatedAlert,
        actionPayload: c.actionPayload,
      );
    });
  }
}

class _ScoredCandidate {
  _ScoredCandidate({
    required this.id,
    required this.score,
    required this.priorityLevel,
    required this.title,
    required this.whyItMatters,
    required this.recommendedAction,
    required this.expectedImpact,
    required this.urgency,
    required this.sourceMetric,
    required this.actionType,
    this.financialAmount,
    this.relatedAlert,
    this.actionPayload,
  });

  final String id;
  final double score;
  final PriorityLevel priorityLevel;
  final String title;
  final String whyItMatters;
  final String recommendedAction;
  final String expectedImpact;
  final String urgency;
  final String sourceMetric;
  final ActionLinkType actionType;
  final double? financialAmount;
  final Alert? relatedAlert;
  final Map<String, dynamic>? actionPayload;
}
