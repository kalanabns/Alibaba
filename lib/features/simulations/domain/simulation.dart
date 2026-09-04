class Simulation {
  const Simulation({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.name,
    this.assumptions = const {},
    this.baselineMetrics = const {},
    this.projectedMetrics = const {},
    this.aiAnalysis,
    required this.createdAt,
  });

  factory Simulation.fromJson(Map<String, dynamic> json) {
    return Simulation(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      assumptions: (json['assumptions'] as Map<String, dynamic>?) ?? const {},
      baselineMetrics: (json['baseline_metrics'] as Map<String, dynamic>?) ?? const {},
      projectedMetrics: (json['projected_metrics'] as Map<String, dynamic>?) ?? const {},
      aiAnalysis: json['ai_analysis'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String businessId;
  final String userId;
  final String name;
  final Map<String, dynamic> assumptions;
  final Map<String, dynamic> baselineMetrics;
  final Map<String, dynamic> projectedMetrics;
  final String? aiAnalysis;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_id': userId,
      'name': name,
      'assumptions': assumptions,
      'baseline_metrics': baselineMetrics,
      'projected_metrics': projectedMetrics,
      'ai_analysis': aiAnalysis,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
