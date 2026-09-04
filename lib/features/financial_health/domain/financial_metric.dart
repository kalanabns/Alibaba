class FinancialMetric {
  const FinancialMetric({
    required this.id,
    required this.businessId,
    required this.periodStart,
    required this.periodEnd,
    this.revenue = 0.0,
    this.expenses = 0.0,
    this.profit = 0.0,
    this.profitMargin = 0.0,
    this.cashInflow = 0.0,
    this.cashOutflow = 0.0,
    this.netCashFlow = 0.0,
    this.debt = 0.0,
    this.receivables = 0.0,
    this.payables = 0.0,
    this.revenueGrowth = 0.0,
    this.expenseGrowth = 0.0,
    this.healthScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FinancialMetric.fromJson(Map<String, dynamic> json) {
    return FinancialMetric(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      cashInflow: (json['cash_inflow'] as num?)?.toDouble() ?? 0.0,
      cashOutflow: (json['cash_outflow'] as num?)?.toDouble() ?? 0.0,
      netCashFlow: (json['net_cash_flow'] as num?)?.toDouble() ?? 0.0,
      debt: (json['debt'] as num?)?.toDouble() ?? 0.0,
      receivables: (json['receivables'] as num?)?.toDouble() ?? 0.0,
      payables: (json['payables'] as num?)?.toDouble() ?? 0.0,
      revenueGrowth: (json['revenue_growth'] as num?)?.toDouble() ?? 0.0,
      expenseGrowth: (json['expense_growth'] as num?)?.toDouble() ?? 0.0,
      healthScore: (json['health_score'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String businessId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double revenue;
  final double expenses;
  final double profit;
  final double profitMargin;
  final double cashInflow;
  final double cashOutflow;
  final double netCashFlow;
  final double debt;
  final double receivables;
  final double payables;
  final double revenueGrowth;
  final double expenseGrowth;
  final double? healthScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'period_start': periodStart.toIso8601String().split('T').first,
      'period_end': periodEnd.toIso8601String().split('T').first,
      'revenue': revenue,
      'expenses': expenses,
      'profit': profit,
      'profit_margin': profitMargin,
      'cash_inflow': cashInflow,
      'cash_outflow': cashOutflow,
      'net_cash_flow': netCashFlow,
      'debt': debt,
      'receivables': receivables,
      'payables': payables,
      'revenue_growth': revenueGrowth,
      'expense_growth': expenseGrowth,
      'health_score': healthScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
