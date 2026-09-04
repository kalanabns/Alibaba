import '../../transactions/domain/transaction.dart';
import 'financial_metric.dart';
import 'health_score_breakdown.dart';

class MonthlyFinancialBucket {
  const MonthlyFinancialBucket({
    required this.year,
    required this.month,
    required this.label,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.netCashFlow,
  });

  final int year;
  final int month;
  final String label; // e.g. "Aug 2026"
  final double revenue;
  final double expenses;
  final double profit;
  final double netCashFlow;
}

class FinancialEngine {
  const FinancialEngine._();

  /// Filters transactions falling strictly within [periodStart] and [periodEnd] inclusive.
  static List<Transaction> filterTransactionsForPeriod(
    List<Transaction> transactions,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return transactions.where((t) {
      final date = t.transactionDate;
      return (date.isAfter(periodStart) ||
              date.isAtSameMomentAs(periodStart)) &&
          (date.isBefore(periodEnd) || date.isAtSameMomentAs(periodEnd));
    }).toList();
  }

  /// Calculates deterministic financial metrics for a specific time range.
  static FinancialMetric calculatePeriodMetrics({
    required String businessId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<Transaction> currentTransactions,
    List<Transaction>? previousTransactions,
    DateTime? createdAt,
  }) {
    double revenue = 0.0;
    double expenses = 0.0;
    double cashInflow = 0.0;
    double cashOutflow = 0.0;
    double receivables = 0.0;
    double payables = 0.0;

    for (final t in currentTransactions) {
      if (t.transactionType == TransactionType.income) {
        revenue += t.amount;
        if (t.paymentStatus == PaymentStatus.pending ||
            t.paymentStatus == PaymentStatus.overdue) {
          receivables += t.amount;
        } else {
          // Paid or default received
          cashInflow += t.amount;
        }
      } else if (t.transactionType == TransactionType.expense) {
        expenses += t.amount;
        if (t.paymentStatus == PaymentStatus.pending ||
            t.paymentStatus == PaymentStatus.overdue) {
          payables += t.amount;
        } else {
          // Paid or default disbursed
          cashOutflow += t.amount;
        }
      }
    }

    final profit = revenue - expenses;
    final profitMargin = revenue > 0
        ? (profit / revenue) * 100
        : (expenses > 0 ? -100.0 : 0.0);
    final netCashFlow = cashInflow - cashOutflow;

    // Growth calculations compared to previous period if available
    double revenueGrowth = 0.0;
    double expenseGrowth = 0.0;
    bool hasPreviousData = false;

    if (previousTransactions != null && previousTransactions.isNotEmpty) {
      hasPreviousData = true;
      double prevRevenue = 0.0;
      double prevExpenses = 0.0;

      for (final t in previousTransactions) {
        if (t.transactionType == TransactionType.income) {
          prevRevenue += t.amount;
        } else if (t.transactionType == TransactionType.expense) {
          prevExpenses += t.amount;
        }
      }

      if (prevRevenue > 0) {
        revenueGrowth = ((revenue - prevRevenue) / prevRevenue) * 100;
      } else if (revenue > 0) {
        revenueGrowth = 100.0;
      }

      if (prevExpenses > 0) {
        expenseGrowth = ((expenses - prevExpenses) / prevExpenses) * 100;
      } else if (expenses > 0) {
        expenseGrowth = 100.0;
      }
    }

    final breakdown = calculateHealthScore(
      revenue: revenue,
      expenses: expenses,
      profit: profit,
      profitMargin: profitMargin,
      cashInflow: cashInflow,
      cashOutflow: cashOutflow,
      netCashFlow: netCashFlow,
      receivables: receivables,
      payables: payables,
      revenueGrowth: revenueGrowth,
      expenseGrowth: expenseGrowth,
      hasPreviousPeriod: hasPreviousData,
    );

    final now = DateTime.now().toUtc();

    return FinancialMetric(
      id: '',
      businessId: businessId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      revenue: revenue,
      expenses: expenses,
      profit: profit,
      profitMargin: profitMargin,
      cashInflow: cashInflow,
      cashOutflow: cashOutflow,
      netCashFlow: netCashFlow,
      debt: 0.0,
      receivables: receivables,
      payables: payables,
      revenueGrowth: revenueGrowth,
      expenseGrowth: expenseGrowth,
      healthScore: breakdown.totalScore,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  /// Evaluates Finora's deterministic 0–100 Financial Health Score.
  static HealthScoreBreakdown calculateHealthScore({
    required double revenue,
    required double expenses,
    required double profit,
    required double profitMargin,
    required double cashInflow,
    required double cashOutflow,
    required double netCashFlow,
    required double receivables,
    required double payables,
    required double revenueGrowth,
    required double expenseGrowth,
    bool hasPreviousPeriod = false,
  }) {
    // 1. Profitability (Max: 30 Points)
    double profitScore;
    String profitInsight;

    if (revenue == 0 && expenses == 0) {
      profitScore = 15.0;
      profitInsight = 'No revenue or expenses recorded for this period.';
    } else if (revenue == 0 && expenses > 0) {
      profitScore = 5.0;
      profitInsight = 'Operating with expenses but generating zero revenue.';
    } else if (profitMargin >= 30.0) {
      profitScore = 30.0;
      profitInsight = 'Exceptional profitability margin above 30%.';
    } else if (profitMargin >= 20.0) {
      profitScore = 26.0;
      profitInsight = 'Strong profit margin supporting sustainable growth.';
    } else if (profitMargin >= 10.0) {
      profitScore = 22.0;
      profitInsight = 'Healthy profit margin within standard operating range.';
    } else if (profitMargin >= 0.0) {
      profitScore = 17.0;
      profitInsight = 'Breaking even. Opportunities exist to optimize margin.';
    } else if (profitMargin >= -20.0) {
      profitScore = 10.0;
      profitInsight = 'Modest operating deficit. Monitor cost structures.';
    } else {
      profitScore = 3.0;
      profitInsight = 'High loss margin. Immediate cost reduction required.';
    }

    final profitabilityComponent = HealthScoreComponent(
      name: 'Profitability',
      score: profitScore,
      maxScore: 30.0,
      description: 'Operating efficiency and margin health.',
      insight: profitInsight,
    );

    // 2. Cash Flow (Max: 25 Points)
    double cashScore;
    String cashInsight;

    if (cashInflow == 0 && cashOutflow == 0) {
      cashScore = 14.0;
      cashInsight = 'Neutral cash flow with no cash movements recorded.';
    } else if (netCashFlow > 0) {
      final ratio = cashOutflow > 0 ? (cashInflow / cashOutflow) : 2.0;
      if (ratio >= 1.5) {
        cashScore = 25.0;
        cashInsight = 'Strong positive cash flow coverage.';
      } else if (ratio >= 1.2) {
        cashScore = 22.0;
        cashInsight = 'Positive cash flow with sufficient operating coverage.';
      } else {
        cashScore = 18.0;
        cashInsight = 'Cash inflow slightly exceeds outflow.';
      }
    } else if (netCashFlow == 0) {
      cashScore = 14.0;
      cashInsight = 'Balanced cash flow with zero net burn.';
    } else {
      // Negative Cash Flow
      final ratio = cashInflow > 0 ? (cashOutflow / cashInflow) : 3.0;
      if (ratio <= 1.2) {
        cashScore = 10.0;
        cashInsight = 'Minor cash deficit manageable in short term.';
      } else if (ratio <= 1.5) {
        cashScore = 6.0;
        cashInsight = 'Elevated cash burn compared to incoming cash.';
      } else {
        cashScore = 2.0;
        cashInsight = 'Critical cash outflow exceeding inflows significantly.';
      }
    }

    final cashFlowComponent = HealthScoreComponent(
      name: 'Cash Flow',
      score: cashScore,
      maxScore: 25.0,
      description: 'Liquidity, cash inflows, and net burn rate.',
      insight: cashInsight,
    );

    // 3. Revenue Trend (Max: 15 Points)
    double trendScore;
    String trendInsight;

    if (!hasPreviousPeriod) {
      trendScore = 11.0;
      trendInsight =
          'Baseline established. Trend score will update with multi-month history.';
    } else if (revenueGrowth >= 15.0) {
      trendScore = 15.0;
      trendInsight = 'Accelerating revenue growth above 15%.';
    } else if (revenueGrowth >= 5.0) {
      trendScore = 13.0;
      trendInsight = 'Steady revenue expansion period-over-period.';
    } else if (revenueGrowth >= 0.0) {
      trendScore = 11.0;
      trendInsight = 'Stable revenue trajectory with minimal variation.';
    } else if (revenueGrowth >= -10.0) {
      trendScore = 7.0;
      trendInsight = 'Mild revenue contraction observed.';
    } else {
      trendScore = 3.0;
      trendInsight =
          'Significant revenue decline. Action needed to revive sales.';
    }

    final revenueTrendComponent = HealthScoreComponent(
      name: 'Revenue Trend',
      score: trendScore,
      maxScore: 15.0,
      description: 'Top-line growth trajectory and momentum.',
      insight: trendInsight,
    );

    // 4. Expense Control (Max: 15 Points)
    double expenseScore;
    String expenseInsight;

    if (!hasPreviousPeriod) {
      expenseScore = 11.0;
      expenseInsight = 'Initial period expenses established.';
    } else if (expenseGrowth <= 0.0) {
      expenseScore = 15.0;
      expenseInsight = 'Disciplined expense reduction or flat overhead.';
    } else if (expenseGrowth <= revenueGrowth) {
      expenseScore = 14.0;
      expenseInsight = 'Expense growth is well aligned within revenue growth.';
    } else if (expenseGrowth <= revenueGrowth + 5.0) {
      expenseScore = 11.0;
      expenseInsight = 'Expenses grew slightly faster than top-line revenue.';
    } else if (expenseGrowth <= revenueGrowth + 15.0) {
      expenseScore = 7.0;
      expenseInsight =
          'Expenses outpacing revenue growth. Review discretionary costs.';
    } else {
      expenseScore = 3.0;
      expenseInsight = 'Uncontrolled expense acceleration.';
    }

    final expenseControlComponent = HealthScoreComponent(
      name: 'Expense Control',
      score: expenseScore,
      maxScore: 15.0,
      description: 'Cost structure efficiency and spending discipline.',
      insight: expenseInsight,
    );

    // 5. Working Capital / Receivables & Payables (Max: 15 Points)
    double workingCapitalScore;
    String workingCapitalInsight;

    if (receivables == 0 && payables == 0) {
      workingCapitalScore = 15.0;
      workingCapitalInsight = 'No pending receivables or payable obligations.';
    } else if (payables == 0 && receivables > 0) {
      workingCapitalScore = 14.0;
      workingCapitalInsight =
          'Zero payable liabilities with outstanding receivables to collect.';
    } else if (receivables >= payables * 1.2) {
      workingCapitalScore = 15.0;
      workingCapitalInsight =
          'Healthy receivables buffer exceeding short-term payables.';
    } else if (receivables >= payables) {
      workingCapitalScore = 12.0;
      workingCapitalInsight = 'Receivables cover pending payable liabilities.';
    } else if (payables > receivables * 1.5) {
      workingCapitalScore = 6.0;
      workingCapitalInsight =
          'Pending payable obligations significantly exceed receivables.';
    } else {
      workingCapitalScore = 9.0;
      workingCapitalInsight =
          'Payable commitments exceed incoming receivables.';
    }

    final workingCapitalComponent = HealthScoreComponent(
      name: 'Working Capital',
      score: workingCapitalScore,
      maxScore: 15.0,
      description: 'Short-term receivables versus payable commitments.',
      insight: workingCapitalInsight,
    );

    // Calculate clamped total score
    final rawTotal =
        profitScore +
        cashScore +
        trendScore +
        expenseScore +
        workingCapitalScore;
    final totalScore = rawTotal.clamp(0.0, 100.0);

    final HealthScoreBand band;
    final String bandLabel;
    final String summary;

    if (totalScore >= 80.0) {
      band = HealthScoreBand.excellent;
      bandLabel = 'Excellent';
      summary =
          'Your business is operating with outstanding profitability, strong cash flow, and healthy growth indicators.';
    } else if (totalScore >= 65.0) {
      band = HealthScoreBand.healthy;
      bandLabel = 'Healthy';
      summary =
          'Solid financial fundamentals with sound margins and stable cash operations.';
    } else if (totalScore >= 50.0) {
      band = HealthScoreBand.watch;
      bandLabel = 'Watch';
      summary =
          'Financial performance is acceptable, but key areas like margin or expense growth warrant monitoring.';
    } else if (totalScore >= 35.0) {
      band = HealthScoreBand.atRisk;
      bandLabel = 'At Risk';
      summary =
          'Elevated operating pressures or cash deficits require strategic adjustments.';
    } else {
      band = HealthScoreBand.critical;
      bandLabel = 'Critical';
      summary =
          'Severe financial distress. Urgent cost restructuring and cash preservation needed.';
    }

    return HealthScoreBreakdown(
      totalScore: totalScore,
      band: band,
      bandLabel: bandLabel,
      summary: summary,
      profitability: profitabilityComponent,
      cashFlow: cashFlowComponent,
      revenueTrend: revenueTrendComponent,
      expenseControl: expenseControlComponent,
      workingCapital: workingCapitalComponent,
    );
  }

  /// Groups transactions into month-by-month buckets for chart rendering.
  static List<MonthlyFinancialBucket> buildMonthlyBuckets(
    List<Transaction> transactions, {
    int monthCount = 6,
  }) {
    final now = DateTime.now().toUtc();
    final buckets = <MonthlyFinancialBucket>[];

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    for (int i = monthCount - 1; i >= 0; i--) {
      // Calculate month and year for this bucket
      int targetMonth = now.month - i;
      int targetYear = now.year;
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }

      double monthRevenue = 0.0;
      double monthExpenses = 0.0;
      double monthInflow = 0.0;
      double monthOutflow = 0.0;

      for (final t in transactions) {
        if (t.transactionDate.year == targetYear &&
            t.transactionDate.month == targetMonth) {
          if (t.transactionType == TransactionType.income) {
            monthRevenue += t.amount;
            if (t.paymentStatus != PaymentStatus.pending &&
                t.paymentStatus != PaymentStatus.overdue) {
              monthInflow += t.amount;
            }
          } else if (t.transactionType == TransactionType.expense) {
            monthExpenses += t.amount;
            if (t.paymentStatus != PaymentStatus.pending &&
                t.paymentStatus != PaymentStatus.overdue) {
              monthOutflow += t.amount;
            }
          }
        }
      }

      final label = '${monthNames[targetMonth - 1]} $targetYear';
      buckets.add(
        MonthlyFinancialBucket(
          year: targetYear,
          month: targetMonth,
          label: label,
          revenue: monthRevenue,
          expenses: monthExpenses,
          profit: monthRevenue - monthExpenses,
          netCashFlow: monthInflow - monthOutflow,
        ),
      );
    }

    return buckets;
  }
}
