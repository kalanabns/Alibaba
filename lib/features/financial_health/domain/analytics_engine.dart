import '../../transactions/domain/transaction.dart';
import 'financial_engine.dart';
import 'financial_metric.dart';

enum InsightSignificance { critical, warning, positive, info }

class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    this.growthRate = 0.0,
    this.isRecurring = false,
  });

  final String category;
  final double amount;
  final double percentage; // 0.0 to 1.0
  final int transactionCount;
  final double growthRate;
  final bool isRecurring;

  double get totalAmount => amount;
  double get percentageOfTotal => percentage * 100.0;
}

class PeriodComparisonMetric {
  const PeriodComparisonMetric({
    required this.name,
    required this.currentValue,
    required this.previousValue,
    required this.absoluteChange,
    required this.percentageChange,
    required this.isPositiveTrend,
    required this.unit,
  });

  final String name;
  final double currentValue;
  final double previousValue;
  final double absoluteChange;
  final double? percentageChange;
  final bool isPositiveTrend;
  final String unit;

  double get revenueDelta => absoluteChange;
  double get revenueGrowthPct => percentageChange ?? 0.0;
  double get expenseDelta => absoluteChange;
  double get expenseGrowthPct => percentageChange ?? 0.0;
  double get profitDelta => absoluteChange;
  double get profitGrowthPct => percentageChange ?? 0.0;
}

class MarginDecompositionDriver {
  const MarginDecompositionDriver({
    required this.name,
    required this.impactPercentage,
    required this.description,
  });

  final String name;
  final double impactPercentage;
  final String description;
}

class MarginDecomposition {
  const MarginDecomposition({
    required this.currentMargin,
    required this.previousMargin,
    required this.marginDelta,
    required this.revenueGrowth,
    required this.expenseGrowth,
    required this.explanation,
    required this.primaryDriver,
    this.drivers = const [],
  });

  final double currentMargin;
  final double previousMargin;
  final double marginDelta;
  final double revenueGrowth;
  final double expenseGrowth;
  final String explanation;
  final String primaryDriver;
  final List<MarginDecompositionDriver> drivers;
}

class BusinessInsight {
  const BusinessInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.significance,
    this.actionRoute,
    this.actionLabel,
  });

  final String id;
  final String title;
  final String description;
  final String metric;
  final InsightSignificance significance;
  final String? actionRoute;
  final String? actionLabel;
}

class PeriodComparisonSummary {
  const PeriodComparisonSummary({
    required this.revenueDelta,
    required this.revenueGrowthPct,
    required this.expenseDelta,
    required this.expenseGrowthPct,
    required this.profitDelta,
    required this.profitGrowthPct,
    required this.metrics,
  });

  final double revenueDelta;
  final double revenueGrowthPct;
  final double expenseDelta;
  final double expenseGrowthPct;
  final double profitDelta;
  final double profitGrowthPct;
  final List<PeriodComparisonMetric> metrics;
}

class AnalyticsReport {
  const AnalyticsReport({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.netCashFlow,
    required this.cashInflow,
    required this.cashOutflow,
    required this.receivables,
    required this.payables,
    required this.expenseCategories,
    required this.revenueCategories,
    required this.periodComparisons,
    required this.marginDecomposition,
    required this.insights,
    required this.monthlyBuckets,
  });

  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double profitMargin;
  final double netCashFlow;
  final double cashInflow;
  final double cashOutflow;
  final double receivables;
  final double payables;
  final List<CategoryBreakdown> expenseCategories;
  final List<CategoryBreakdown> revenueCategories;
  final List<PeriodComparisonMetric> periodComparisons;
  final MarginDecomposition marginDecomposition;
  final List<BusinessInsight> insights;
  final List<MonthlyFinancialBucket> monthlyBuckets;
}

class AnalyticsEngine {
  const AnalyticsEngine._();

  /// Computes category breakdowns for expenses or revenues.
  static List<CategoryBreakdown> computeCategoryBreakdowns({
    required List<Transaction> transactions,
    required bool isExpense,
    List<Transaction> previousTransactions = const [],
  }) {
    final filtered = transactions.where((t) => isExpense ? t.isExpense : t.isIncome).toList();
    final total = filtered.fold<double>(0.0, (sum, t) => sum + t.amount);
    return _calculateCategoryBreakdowns(
      transactions: filtered,
      totalAmount: total,
      previousTransactions: previousTransactions.where((t) => isExpense ? t.isExpense : t.isIncome).toList(),
    );
  }

  /// Compares two periods and returns a comparison summary.
  static PeriodComparisonSummary comparePeriods({
    required FinancialMetric current,
    required FinancialMetric previous,
  }) {
    final revDelta = current.revenue - previous.revenue;
    final revGrowth = previous.revenue > 0 ? (revDelta / previous.revenue) * 100.0 : 0.0;

    final expDelta = current.expenses - previous.expenses;
    final expGrowth = previous.expenses > 0 ? (expDelta / previous.expenses) * 100.0 : 0.0;

    final profitDelta = current.profit - previous.profit;
    final profitGrowth = previous.profit.abs() > 0 ? (profitDelta / previous.profit.abs()) * 100.0 : 0.0;

    final metrics = [
      _buildComparison('Revenue', current.revenue, previous.revenue, '\$', isExpense: false),
      _buildComparison('Expenses', current.expenses, previous.expenses, '\$', isExpense: true),
      _buildComparison('Net Profit', current.profit, previous.profit, '\$', isExpense: false),
      _buildComparison('Profit Margin', current.profitMargin, previous.profitMargin, '%', isExpense: false),
      _buildComparison('Net Cash Flow', current.netCashFlow, previous.netCashFlow, '\$', isExpense: false),
    ];

    return PeriodComparisonSummary(
      revenueDelta: revDelta,
      revenueGrowthPct: revGrowth,
      expenseDelta: expDelta,
      expenseGrowthPct: expGrowth,
      profitDelta: profitDelta,
      profitGrowthPct: profitGrowth,
      metrics: metrics,
    );
  }

  /// Decomposes operating margin into driver components.
  static List<MarginDecompositionDriver> decomposeMargin({
    required FinancialMetric current,
    required FinancialMetric previous,
    required List<Transaction> currentTransactions,
    List<Transaction> previousTransactions = const [],
  }) {
    final drivers = <MarginDecompositionDriver>[];
    final marginShift = current.profitMargin - previous.profitMargin;

    if (current.expenseGrowth > current.revenueGrowth && current.expenseGrowth > 5.0) {
      drivers.add(MarginDecompositionDriver(
        name: 'Expense Surge vs Revenue',
        impactPercentage: marginShift,
        description: 'Expenses grew by ${current.expenseGrowth.toStringAsFixed(1)}%, faster than revenue (+${current.revenueGrowth.toStringAsFixed(1)}%).',
      ));
    } else if (current.revenueGrowth > current.expenseGrowth && current.revenueGrowth > 5.0) {
      drivers.add(MarginDecompositionDriver(
        name: 'Operating Leverage Expansion',
        impactPercentage: marginShift,
        description: 'Revenue growth (+${current.revenueGrowth.toStringAsFixed(1)}%) outpaced overhead growth (+${current.expenseGrowth.toStringAsFixed(1)}%).',
      ));
    } else {
      drivers.add(MarginDecompositionDriver(
        name: 'Stable Operating Baseline',
        impactPercentage: marginShift,
        description: 'Margins remained steady within nominal variations.',
      ));
    }

    return drivers;
  }

  /// Discovers automated business insights from metrics, buckets, and transactions.
  static List<BusinessInsight> discoverInsights({
    required FinancialMetric current,
    List<MonthlyFinancialBucket> buckets = const [],
    required List<Transaction> transactions,
  }) {
    final expenseCats = computeCategoryBreakdowns(transactions: transactions, isExpense: true);
    final revenueCats = computeCategoryBreakdowns(transactions: transactions, isExpense: false);

    final insights = _generateInsights(
      metric: current,
      expenseCategories: expenseCats,
      revenueCategories: revenueCats,
      revGrowth: current.revenueGrowth,
      expGrowth: current.expenseGrowth,
    );

    // If multi-period momentum detected from buckets
    if (buckets.length >= 2) {
      final latest = buckets.last;
      final prior = buckets[buckets.length - 2];
      if (latest.revenue > prior.revenue) {
        insights.insert(
          0,
          BusinessInsight(
            id: 'revenue_momentum',
            title: 'Positive Revenue Momentum',
            description: 'Top-line sales expanded month-over-month to \$${latest.revenue.toStringAsFixed(0)}.',
            metric: 'Revenue Growth',
            significance: InsightSignificance.positive,
          ),
        );
      }
    }

    return insights;
  }

  /// Computes a comprehensive Business Intelligence Analytics Report from transactions and buckets.
  static AnalyticsReport generateReport({
    required List<Transaction> currentTransactions,
    List<Transaction> previousTransactions = const [],
    List<MonthlyFinancialBucket> monthlyBuckets = const [],
    FinancialMetric? currentMetric,
    FinancialMetric? previousMetric,
  }) {
    // 1. Current Aggregates
    final calculatedMetric = currentMetric ??
        FinancialEngine.calculatePeriodMetrics(
          businessId: currentTransactions.isNotEmpty
              ? currentTransactions.first.businessId
              : 'unknown',
          periodStart: DateTime.now().subtract(const Duration(days: 30)),
          periodEnd: DateTime.now(),
          currentTransactions: currentTransactions,
          previousTransactions: previousTransactions,
        );

    final totalRev = calculatedMetric.revenue;
    final totalExp = calculatedMetric.expenses;
    final profit = calculatedMetric.profit;
    final margin = calculatedMetric.profitMargin;
    final cashFlow = calculatedMetric.netCashFlow;
    final cashIn = calculatedMetric.cashInflow;
    final cashOut = calculatedMetric.cashOutflow;
    final recv = calculatedMetric.receivables;
    final pay = calculatedMetric.payables;

    // 2. Expense Category Breakdown
    final expenseCategories = _calculateCategoryBreakdowns(
      transactions: currentTransactions.where((t) => t.isExpense).toList(),
      totalAmount: totalExp,
      previousTransactions: previousTransactions.where((t) => t.isExpense).toList(),
    );

    // 3. Revenue Category Breakdown
    final revenueCategories = _calculateCategoryBreakdowns(
      transactions: currentTransactions.where((t) => t.isIncome).toList(),
      totalAmount: totalRev,
      previousTransactions: previousTransactions.where((t) => t.isIncome).toList(),
    );

    // 4. Period Comparisons
    final prevRev = previousMetric?.revenue ?? 0.0;
    final prevExp = previousMetric?.expenses ?? 0.0;
    final prevProfit = previousMetric?.profit ?? 0.0;
    final prevMargin = previousMetric?.profitMargin ?? 0.0;
    final prevCash = previousMetric?.netCashFlow ?? 0.0;

    final periodComparisons = [
      _buildComparison('Revenue', totalRev, prevRev, '\$', isExpense: false),
      _buildComparison('Expenses', totalExp, prevExp, '\$', isExpense: true),
      _buildComparison('Net Profit', profit, prevProfit, '\$', isExpense: false),
      _buildComparison('Profit Margin', margin, prevMargin, '%', isExpense: false),
      _buildComparison('Net Cash Flow', cashFlow, prevCash, '\$', isExpense: false),
    ];

    // 5. Margin Decomposition
    final revGrowth = calculatedMetric.revenueGrowth;
    final expGrowth = calculatedMetric.expenseGrowth;
    final marginDelta = margin - prevMargin;

    String marginExplanation;
    String primaryDriver;

    if (expGrowth > revGrowth && expGrowth > 5.0) {
      marginExplanation =
          'Operating margin shifted by ${marginDelta >= 0 ? '+' : ''}${marginDelta.toStringAsFixed(1)}% because expense growth (${expGrowth.toStringAsFixed(1)}%) outpaced revenue growth (${revGrowth.toStringAsFixed(1)}%).';
      primaryDriver = expenseCategories.isNotEmpty
          ? 'Rising ${expenseCategories.first.category} Expenses'
          : 'Expense Inflation';
    } else if (revGrowth > expGrowth && revGrowth > 5.0) {
      marginExplanation =
          'Operating margin expanded by ${marginDelta.toStringAsFixed(1)}% as revenue growth (${revGrowth.toStringAsFixed(1)}%) outscaled cost expansion (${expGrowth.toStringAsFixed(1)}%).';
      primaryDriver = 'Top-Line Revenue Expansion';
    } else if (totalRev == 0 && totalExp > 0) {
      marginExplanation = 'Negative operating margin driven by ongoing overhead with zero current period revenue.';
      primaryDriver = 'Fixed Overhead';
    } else {
      marginExplanation =
          'Operating margins remained relatively stable at ${margin.toStringAsFixed(1)}% across the evaluated cycle.';
      primaryDriver = 'Stable Operating Baseline';
    }

    final marginDecomposition = MarginDecomposition(
      currentMargin: margin,
      previousMargin: prevMargin,
      marginDelta: marginDelta,
      revenueGrowth: revGrowth,
      expenseGrowth: expGrowth,
      explanation: marginExplanation,
      primaryDriver: primaryDriver,
    );

    // 6. Generate Deterministic Business Insights
    final insights = _generateInsights(
      metric: calculatedMetric,
      expenseCategories: expenseCategories,
      revenueCategories: revenueCategories,
      revGrowth: revGrowth,
      expGrowth: expGrowth,
    );

    return AnalyticsReport(
      totalRevenue: totalRev,
      totalExpenses: totalExp,
      netProfit: profit,
      profitMargin: margin,
      netCashFlow: cashFlow,
      cashInflow: cashIn,
      cashOutflow: cashOut,
      receivables: recv,
      payables: pay,
      expenseCategories: expenseCategories,
      revenueCategories: revenueCategories,
      periodComparisons: periodComparisons,
      marginDecomposition: marginDecomposition,
      insights: insights,
      monthlyBuckets: monthlyBuckets,
    );
  }

  static List<CategoryBreakdown> _calculateCategoryBreakdowns({
    required List<Transaction> transactions,
    required double totalAmount,
    required List<Transaction> previousTransactions,
  }) {
    if (transactions.isEmpty || totalAmount <= 0) return [];

    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};
    final recurringMap = <String, bool>{};

    for (final tx in transactions) {
      final cat = tx.category.isEmpty ? 'General' : tx.category;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + tx.amount;
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;

      // Simple heuristic for recurring items
      if (cat.toLowerCase().contains('software') ||
          cat.toLowerCase().contains('rent') ||
          cat.toLowerCase().contains('subscription') ||
          cat.toLowerCase().contains('utilities') ||
          cat.toLowerCase().contains('payroll')) {
        recurringMap[cat] = true;
      }
    }

    // Previous category totals for growth comparison
    final prevCategoryTotals = <String, double>{};
    for (final tx in previousTransactions) {
      final cat = tx.category.isEmpty ? 'General' : tx.category;
      prevCategoryTotals[cat] = (prevCategoryTotals[cat] ?? 0.0) + tx.amount;
    }

    final results = <CategoryBreakdown>[];
    categoryTotals.forEach((cat, amount) {
      final pct = (amount / totalAmount).clamp(0.0, 1.0);
      final prevAmount = prevCategoryTotals[cat] ?? 0.0;
      final growth = prevAmount > 0 ? ((amount - prevAmount) / prevAmount) * 100.0 : 0.0;

      results.add(CategoryBreakdown(
        category: cat,
        amount: amount,
        percentage: pct,
        transactionCount: categoryCounts[cat] ?? 1,
        growthRate: growth,
        isRecurring: recurringMap[cat] ?? false,
      ));
    });

    // Sort largest first
    results.sort((a, b) => b.amount.compareTo(a.amount));
    return results;
  }

  static PeriodComparisonMetric _buildComparison(
    String name,
    double current,
    double previous,
    String unit, {
    required bool isExpense,
  }) {
    final diff = current - previous;
    double? pct;
    if (previous.abs() > 0.001) {
      pct = (diff / previous.abs()) * 100.0;
    }

    // Determine if positive trend
    final bool isPositive;
    if (isExpense) {
      isPositive = diff <= 0; // Lower expense is good
    } else {
      isPositive = diff >= 0; // Higher revenue/profit/cash is good
    }

    return PeriodComparisonMetric(
      name: name,
      currentValue: current,
      previousValue: previous,
      absoluteChange: diff,
      percentageChange: pct,
      isPositiveTrend: isPositive,
      unit: unit,
    );
  }

  static List<BusinessInsight> _generateInsights({
    required FinancialMetric metric,
    required List<CategoryBreakdown> expenseCategories,
    required List<CategoryBreakdown> revenueCategories,
    required double revGrowth,
    required double expGrowth,
  }) {
    final insights = <BusinessInsight>[];

    // 1. Growth Outpace Insight
    if (expGrowth > revGrowth && expGrowth > 10.0) {
      insights.add(BusinessInsight(
        id: 'exp_outpace',
        title: 'Expenses Growing Faster Than Revenue',
        description:
            'Operating expenses expanded by ${expGrowth.toStringAsFixed(1)}% while top-line revenue increased by ${revGrowth.toStringAsFixed(1)}%, creating margin pressure.',
        metric: 'Expense Trajectory',
        significance: InsightSignificance.critical,
        actionRoute: 'simulations',
        actionLabel: 'Simulate Cost Reduction',
      ));
    } else if (revGrowth > expGrowth && revGrowth > 10.0) {
      insights.add(BusinessInsight(
        id: 'rev_growth_strong',
        title: 'Healthy Revenue Growth Dynamics',
        description:
            'Revenue expansion (${revGrowth.toStringAsFixed(1)}%) is exceeding overhead cost inflation (${expGrowth.toStringAsFixed(1)}%), boosting operating leverage.',
        metric: 'Revenue Growth',
        significance: InsightSignificance.positive,
      ));
    }

    // 2. Dominant Expense Category Concentration
    if (expenseCategories.isNotEmpty && expenseCategories.first.percentage >= 0.40) {
      final top = expenseCategories.first;
      insights.add(BusinessInsight(
        id: 'category_concentration',
        title: 'High ${top.category} Cost Concentration',
        description:
            '${top.category} accounts for ${(top.percentage * 100).toStringAsFixed(1)}% (\$${top.amount.toStringAsFixed(0)}) of total operating outflow.',
        metric: 'Category Concentration',
        significance: InsightSignificance.warning,
        actionRoute: 'ledger',
        actionLabel: 'Audit ${top.category}',
      ));
    }

    // 3. Receivables Cash Drag
    if (metric.receivables > 0 && metric.revenue > 0 && (metric.receivables / metric.revenue) >= 0.25) {
      insights.add(BusinessInsight(
        id: 'receivables_drag',
        title: 'Significant Uncollected Receivables',
        description:
            '\$${metric.receivables.toStringAsFixed(0)} is uncollected in accounts receivable, tying up ${(metric.receivables / metric.revenue * 100).toStringAsFixed(1)}% of cycle revenue.',
        metric: 'Receivables Solvency',
        significance: InsightSignificance.warning,
        actionRoute: 'ledger',
        actionLabel: 'View Unpaid Invoices',
      ));
    }

    // 4. Cash Flow Health
    if (metric.netCashFlow < 0) {
      insights.add(BusinessInsight(
        id: 'cash_burn',
        title: 'Negative Operating Cash Outflow',
        description:
            'Net burn of -\$${(-metric.netCashFlow).toStringAsFixed(0)} this period is draining cash reserves despite paper profitability.',
        metric: 'Cash Flow',
        significance: InsightSignificance.critical,
        actionRoute: 'forecasts',
        actionLabel: 'Inspect Cash Runway',
      ));
    } else if (metric.netCashFlow > 0) {
      insights.add(BusinessInsight(
        id: 'cash_positive',
        title: 'Positive Operating Cash Generation',
        description:
            'Operating activities injected +\$${metric.netCashFlow.toStringAsFixed(0)} in net liquidity over the period.',
        metric: 'Cash Flow',
        significance: InsightSignificance.positive,
      ));
    }

    return insights;
  }
}
