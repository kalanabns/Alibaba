enum GoalType {
  targetRevenue('Target Monthly Revenue', '\$'),
  targetProfitMargin('Target Profit Margin', '%'),
  targetCashReserve('Target Cash Reserve', '\$'),
  expenseLimit('Monthly Expense Limit', '\$'),
  debtReduction('Debt Reduction Target', '\$');

  const GoalType(this.label, this.defaultUnit);
  final String label;
  final String defaultUnit;
}

enum GoalStatus { onTrack, behindTarget, achieved }

class FinancialGoal {
  const FinancialGoal({
    required this.id,
    required this.businessId,
    required this.title,
    required this.goalType,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    this.targetDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String businessId;
  final String title;
  final GoalType goalType;
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime? targetDate;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Deterministic progress ratio (0.0 to 1.0+)
  double get progressRatio {
    if (targetValue <= 0) return 0.0;
    if (goalType == GoalType.expenseLimit) {
      // For expense limit: staying under target is good (progress = target / current when over, or current / target)
      return (currentValue / targetValue).clamp(0.0, 2.0);
    }
    return (currentValue / targetValue).clamp(0.0, 2.0);
  }

  double get difference => targetValue - currentValue;

  bool get isAchieved => status == GoalStatus.achieved;

  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      title: json['title'] as String,
      goalType: GoalType.values.firstWhere(
        (e) => e.name == json['goal_type'],
        orElse: () => GoalType.targetRevenue,
      ),
      targetValue: (json['target_value'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '\$',
      targetDate: json['target_date'] != null
          ? DateTime.tryParse(json['target_date'] as String)
          : null,
      status: GoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalStatus.onTrack,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'title': title,
      'goal_type': goalType.name,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'target_date': targetDate?.toIso8601String().split('T').first,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FinancialGoal copyWith({
    String? title,
    GoalType? goalType,
    double? targetValue,
    double? currentValue,
    String? unit,
    DateTime? targetDate,
    GoalStatus? status,
    DateTime? updatedAt,
  }) {
    return FinancialGoal(
      id: id,
      businessId: businessId,
      title: title ?? this.title,
      goalType: goalType ?? this.goalType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Evaluates goal status against new current value deterministically
  static GoalStatus evaluateStatus(GoalType type, double target, double current) {
    if (type == GoalType.expenseLimit) {
      if (current <= target) return GoalStatus.achieved;
      if (current <= target * 1.1) return GoalStatus.onTrack;
      return GoalStatus.behindTarget;
    } else {
      if (current >= target) return GoalStatus.achieved;
      if (current >= target * 0.85) return GoalStatus.onTrack;
      return GoalStatus.behindTarget;
    }
  }
}
