import '../../financial_health/domain/financial_metric.dart';
import '../../transactions/domain/transaction.dart';
import 'alert.dart';

class RiskEngine {
  const RiskEngine._();

  /// Deterministically evaluates transaction data and period metrics to identify financial risks.
  static List<Alert> evaluateRisks({
    required String businessId,
    required FinancialMetric currentMetrics,
    FinancialMetric? previousMetrics,
    required List<Transaction> currentTransactions,
    double startingCash = 0.0,
  }) {
    final risks = <Alert>[];
    final now = DateTime.now().toUtc();

    final revenue = currentMetrics.revenue;
    final expenses = currentMetrics.expenses;
    final profit = currentMetrics.profit;
    final margin = currentMetrics.profitMargin;
    final cashInflow = currentMetrics.cashInflow;
    final cashOutflow = currentMetrics.cashOutflow;
    final netCashFlow = currentMetrics.netCashFlow;
    final receivables = currentMetrics.receivables;
    final payables = currentMetrics.payables;
    final revenueGrowth = currentMetrics.revenueGrowth;
    final expenseGrowth = currentMetrics.expenseGrowth;

    // 1. CASH FLOW SHORTAGE
    if (netCashFlow < 0) {
      final outflowToInflowRatio = cashInflow > 0
          ? (cashOutflow / cashInflow)
          : 3.0;
      final estimatedCashRemaining = startingCash + netCashFlow;

      if (estimatedCashRemaining <= 0 || outflowToInflowRatio >= 2.0) {
        risks.add(
          Alert(
            id: 'risk_cash_flow_critical_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.critical,
            title: 'Critical Cash Flow Shortage',
            description:
                'Cash outflow (\$${cashOutflow.toStringAsFixed(2)}) severely exceeds cash inflow (\$${cashInflow.toStringAsFixed(2)}). Current net burn is -\$${(-netCashFlow).toStringAsFixed(2)}.',
            recommendation:
                'Immediate cash preservation required: delay non-essential disbursements, accelerate accounts receivable collections, and review supplier payment terms.',
            metricName: 'net_cash_flow',
            metricValue: netCashFlow,
            thresholdValue: 0.0,
            createdAt: now,
          ),
        );
      } else if (outflowToInflowRatio >= 1.25) {
        risks.add(
          Alert(
            id: 'risk_cash_flow_high_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.high,
            title: 'Negative Operating Cash Flow',
            description:
                'Cash outflow exceeded inflow by \$${(-netCashFlow).toStringAsFixed(2)} for this period (${(outflowToInflowRatio * 100).toStringAsFixed(0)}% of inflow).',
            recommendation:
                'Monitor short-term liquidity buffers and audit recurring vendor commitments to restore positive operational cash flow.',
            metricName: 'net_cash_flow',
            metricValue: netCashFlow,
            thresholdValue: 0.0,
            createdAt: now,
          ),
        );
      }
    }

    // 2. REVENUE DECLINE
    if (previousMetrics != null && previousMetrics.revenue > 0) {
      if (revenueGrowth <= -25.0) {
        risks.add(
          Alert(
            id: 'risk_revenue_decline_critical_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.critical,
            title: 'Severe Revenue Contraction',
            description:
                'Top-line revenue declined by ${(-revenueGrowth).toStringAsFixed(1)}% compared to the prior period (\$${revenue.toStringAsFixed(2)} vs \$${previousMetrics.revenue.toStringAsFixed(2)}).',
            recommendation:
                'Audit client churn, pipeline drop-offs, and pricing structures to address root causes of revenue contraction.',
            metricName: 'revenue_growth',
            metricValue: revenueGrowth,
            thresholdValue: -15.0,
            createdAt: now,
          ),
        );
      } else if (revenueGrowth <= -12.0) {
        risks.add(
          Alert(
            id: 'risk_revenue_decline_medium_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.medium,
            title: 'Revenue Contraction Detected',
            description:
                'Revenue decreased by ${(-revenueGrowth).toStringAsFixed(1)}% from \$${previousMetrics.revenue.toStringAsFixed(2)} to \$${revenue.toStringAsFixed(2)}.',
            recommendation:
                'Review recent sales conversion velocity and explore upsell opportunities across existing accounts.',
            metricName: 'revenue_growth',
            metricValue: revenueGrowth,
            thresholdValue: -10.0,
            createdAt: now,
          ),
        );
      }
    }

    // 3. EXPENSE GROWTH
    if (previousMetrics != null && previousMetrics.expenses > 0) {
      if (expenseGrowth >= 20.0 && expenseGrowth > revenueGrowth + 10.0) {
        risks.add(
          Alert(
            id: 'risk_expense_growth_high_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.high,
            title: 'Expenses Outpacing Revenue Growth',
            description:
                'Operating expenses surged by ${expenseGrowth.toStringAsFixed(1)}%, outpacing top-line revenue trajectory (${revenueGrowth.toStringAsFixed(1)}%).',
            recommendation:
                'Conduct category-level overhead audit to eliminate unnecessary expansion costs and re-align unit economics.',
            metricName: 'expense_growth',
            metricValue: expenseGrowth,
            thresholdValue: revenueGrowth + 10.0,
            createdAt: now,
          ),
        );
      } else if (expenseGrowth >= 15.0 && revenueGrowth <= 0.0) {
        risks.add(
          Alert(
            id: 'risk_expense_growth_medium_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.medium,
            title: 'Rising Overhead on Flat/Declining Sales',
            description:
                'Expenses increased by ${expenseGrowth.toStringAsFixed(1)}% while top-line revenue remained flat or contracted (${revenueGrowth.toStringAsFixed(1)}%).',
            recommendation:
                'Freeze non-essential discretionary expenditures until top-line stabilization is achieved.',
            metricName: 'expense_growth',
            metricValue: expenseGrowth,
            thresholdValue: 10.0,
            createdAt: now,
          ),
        );
      }
    }

    // 4. PROFIT MARGIN DECLINE
    if (previousMetrics != null && previousMetrics.revenue > 0) {
      final marginDiff = margin - previousMetrics.profitMargin;
      if (marginDiff <= -8.0) {
        risks.add(
          Alert(
            id: 'risk_margin_decline_high_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.high,
            title: 'Profit Margin Deterioration',
            description:
                'Profit margin compressed by ${(-marginDiff).toStringAsFixed(1)} percentage points (from ${previousMetrics.profitMargin.toStringAsFixed(1)}% down to ${margin.toStringAsFixed(1)}%).',
            recommendation:
                'Inspect direct cost of goods/services and supplier pricing increases to protect net operating margins.',
            metricName: 'profit_margin',
            metricValue: margin,
            thresholdValue: previousMetrics.profitMargin - 5.0,
            createdAt: now,
          ),
        );
      }
    }

    // 5. NEGATIVE PROFIT / OPERATING LOSS
    if (profit < 0 && (revenue > 0 || expenses > 0)) {
      if (margin < -30.0 || (revenue == 0 && expenses > 500)) {
        risks.add(
          Alert(
            id: 'risk_negative_profit_critical_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.critical,
            title: 'Significant Net Operating Deficit',
            description:
                'The business generated a net loss of -\$${(-profit).toStringAsFixed(2)} with a margin of ${margin.toStringAsFixed(1)}%.',
            recommendation:
                'Implement urgent cost control and re-evaluate direct product/service delivery margins.',
            metricName: 'profit',
            metricValue: profit,
            thresholdValue: 0.0,
            createdAt: now,
          ),
        );
      } else {
        risks.add(
          Alert(
            id: 'risk_negative_profit_high_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.high,
            title: 'Operating Loss Recorded',
            description:
                'Total expenses (\$${expenses.toStringAsFixed(2)}) exceeded revenue (\$${revenue.toStringAsFixed(2)}) by -\$${(-profit).toStringAsFixed(2)}.',
            recommendation:
                'Identify quick-win expense reductions and optimize pricing or billing cycles to return to profitability.',
            metricName: 'profit',
            metricValue: profit,
            thresholdValue: 0.0,
            createdAt: now,
          ),
        );
      }
    }

    // 6. EXCESSIVE RECEIVABLES
    if (receivables > 0 && revenue > 0) {
      final receivableRatio = receivables / revenue;
      if (receivableRatio >= 0.40) {
        risks.add(
          Alert(
            id: 'risk_excessive_receivables_high_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.high,
            title: 'High Uncollected Receivables Exposure',
            description:
                'Outstanding receivables of \$${receivables.toStringAsFixed(2)} represent ${(receivableRatio * 100).toStringAsFixed(0)}% of total period revenue.',
            recommendation:
                'Accelerate follow-ups on pending invoices and enforce strict credit terms with repeat late-paying accounts.',
            metricName: 'receivables',
            metricValue: receivables,
            thresholdValue: revenue * 0.30,
            createdAt: now,
          ),
        );
      } else if (receivableRatio >= 0.25) {
        risks.add(
          Alert(
            id: 'risk_excessive_receivables_medium_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.medium,
            title: 'Moderate Pending Invoices Pending Collection',
            description:
                '\$${receivables.toStringAsFixed(2)} in pending customer payments represents ${(receivableRatio * 100).toStringAsFixed(0)}% of periodic revenue.',
            recommendation:
                'Issue automated invoice reminders prior to payment due dates to prevent aging.',
            metricName: 'receivables',
            metricValue: receivables,
            thresholdValue: revenue * 0.20,
            createdAt: now,
          ),
        );
      }
    }

    // 7. EXCESSIVE PAYABLES
    if (payables > 0) {
      if (cashInflow > 0 && payables > cashInflow * 0.60) {
        risks.add(
          Alert(
            id: 'risk_excessive_payables_high_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.high,
            title: 'Elevated Short-Term Payable Obligations',
            description:
                'Pending payable liabilities (\$${payables.toStringAsFixed(2)}) represent ${((payables / cashInflow) * 100).toStringAsFixed(0)}% of periodic cash inflow.',
            recommendation:
                'Review supplier payment scheduling to prevent liquidity crunches on settlement dates.',
            metricName: 'payables',
            metricValue: payables,
            thresholdValue: cashInflow * 0.50,
            createdAt: now,
          ),
        );
      }
    }

    // 8. OVERDUE PAYMENT RISKS
    final overdueTransactions = currentTransactions
        .where((t) => t.paymentStatus == PaymentStatus.overdue)
        .toList();

    if (overdueTransactions.isNotEmpty) {
      double overdueIncome = 0.0;
      double overdueExpenses = 0.0;

      for (final t in overdueTransactions) {
        if (t.transactionType == TransactionType.income) {
          overdueIncome += t.amount;
        } else if (t.transactionType == TransactionType.expense) {
          overdueExpenses += t.amount;
        }
      }

      if (overdueIncome > 0) {
        risks.add(
          Alert(
            id: 'risk_overdue_income_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: overdueIncome > 2000
                ? AlertSeverity.high
                : AlertSeverity.medium,
            title: 'Overdue Customer Receivables',
            description:
                'Found ${overdueTransactions.where((t) => t.transactionType == TransactionType.income).length} overdue customer invoice(s) totaling \$${overdueIncome.toStringAsFixed(2)}.',
            recommendation:
                'Initiate formal collections contact and consider pausing credit terms until overdue balances settle.',
            metricName: 'overdue_receivables',
            metricValue: overdueIncome,
            thresholdValue: 0.0,
            createdAt: now,
          ),
        );
      }

      if (overdueExpenses > 0) {
        risks.add(
          Alert(
            id: 'risk_overdue_expenses_$businessId',
            businessId: businessId,
            alertType: AlertType.risk,
            severity: AlertSeverity.high,
            title: 'Overdue Vendor Liabilities',
            description:
                '\$${overdueExpenses.toStringAsFixed(2)} in vendor payments are past their scheduled due dates.',
            recommendation:
                'Settle critical vendor obligations promptly to avoid service disruption or late penalty charges.',
            metricName: 'overdue_payables',
            metricValue: overdueExpenses,
            thresholdValue: 0.0,
            createdAt: now,
          ),
        );
      }
    }

    // 9. UNUSUAL EXPENSE SPIKES
    if (expenses > 0 && currentTransactions.isNotEmpty) {
      final expenseItems = currentTransactions
          .where((t) => t.transactionType == TransactionType.expense)
          .toList();

      final categoryTotals = <String, double>{};
      final categoryCounts = <String, int>{};

      for (final t in expenseItems) {
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0.0) + t.amount;
        categoryCounts[t.category] = (categoryCounts[t.category] ?? 0) + 1;
      }

      for (final t in expenseItems) {
        final totalInCat = categoryTotals[t.category] ?? 0.0;
        final countInCat = categoryCounts[t.category] ?? 1;
        final avgInCat = totalInCat / countInCat;

        // If a single transaction is > 2.5x category average (when multiple entries exist) or > 35% total monthly expenses
        if (countInCat >= 3 && t.amount > avgInCat * 2.5 && t.amount > 500) {
          risks.add(
            Alert(
              id: 'risk_unusual_expense_${t.id}',
              businessId: businessId,
              alertType: AlertType.risk,
              severity: AlertSeverity.medium,
              title: 'Unusual Expense in ${t.category}',
              description:
                  'Transaction "${t.displayTitle}" of \$${t.amount.toStringAsFixed(2)} is ${(t.amount / avgInCat).toStringAsFixed(1)}x higher than the category average (\$${avgInCat.toStringAsFixed(2)}).',
              recommendation:
                  'Verify whether this is a one-time capital investment or an anomaly in recurring operating expenses.',
              metricName: 'unusual_transaction',
              metricValue: t.amount,
              thresholdValue: avgInCat * 2.0,
              createdAt: now,
            ),
          );
          break; // Flag at most 1 dominant unusual spike per period
        }
      }
    }

    // 10. DEBT PRESSURE
    // Documented limitation: If the business model does not record loan/debt liabilities, safely omitted.

    return risks;
  }
}
