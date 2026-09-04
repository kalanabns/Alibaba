enum HealthScoreBand { excellent, healthy, watch, atRisk, critical }

class HealthScoreComponent {
  const HealthScoreComponent({
    required this.name,
    required this.score,
    required this.maxScore,
    required this.description,
    required this.insight,
  });

  final String name;
  final double score;
  final double maxScore;
  final String description;
  final String insight;

  double get percentage =>
      maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
}

class HealthScoreBreakdown {
  const HealthScoreBreakdown({
    required this.totalScore,
    required this.band,
    required this.bandLabel,
    required this.summary,
    required this.profitability,
    required this.cashFlow,
    required this.revenueTrend,
    required this.expenseControl,
    required this.workingCapital,
  });

  final double totalScore; // 0 - 100
  final HealthScoreBand band;
  final String bandLabel;
  final String summary;

  final HealthScoreComponent profitability; // max 30
  final HealthScoreComponent cashFlow; // max 25
  final HealthScoreComponent revenueTrend; // max 15
  final HealthScoreComponent expenseControl; // max 15
  final HealthScoreComponent workingCapital; // max 15

  List<HealthScoreComponent> get components => [
    profitability,
    cashFlow,
    revenueTrend,
    expenseControl,
    workingCapital,
  ];
}
