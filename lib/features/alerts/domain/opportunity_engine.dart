import '../../financial_health/domain/financial_metric.dart';
import '../../transactions/domain/transaction.dart';
import 'alert.dart';

class OpportunityEngine {
  const OpportunityEngine._();

  /// Deterministically evaluates transaction patterns and financial metrics to find strategic opportunities.
  static List<Alert> evaluateOpportunities({
    required String businessId,
    required FinancialMetric currentMetrics,
    FinancialMetric? previousMetrics,
    required List<Transaction> currentTransactions,
  }) {
    final opportunities = <Alert>[];
    final now = DateTime.now().toUtc();

    final revenue = currentMetrics.revenue;
    final expenses = currentMetrics.expenses;
    final receivables = currentMetrics.receivables;

    // 1. COLLECTIONS IMPROVEMENT OPPORTUNITY
    if (receivables > 300) {
      final overduePortion = currentTransactions
          .where(
            (t) =>
                t.transactionType == TransactionType.income &&
                t.paymentStatus == PaymentStatus.overdue,
          )
          .fold<double>(0.0, (acc, t) => acc + t.amount);

      opportunities.add(
        Alert(
          id: 'opp_collections_boost_$businessId',
          businessId: businessId,
          alertType: AlertType.opportunity,
          severity: AlertSeverity.low,
          title: 'Accelerate Receivables Collection',
          description:
              'Collecting \$${receivables.toStringAsFixed(2)} in pending and overdue customer invoices could directly boost available cash reserves.',
          recommendation: overduePortion > 0
              ? 'Prioritize recovery of \$${overduePortion.toStringAsFixed(2)} in overdue payments and offer early-settlement discounts for remaining pending balances.'
              : 'Implement automated invoice reminders 3 days prior to due date to maintain high cash conversion velocity.',
          metricName: 'receivables',
          metricValue: receivables,
          thresholdValue: 300.0,
          createdAt: now,
        ),
      );
    }

    // 2. COST REDUCTION & SPENDING CONCENTRATION AUDIT
    if (expenses > 500 && currentTransactions.isNotEmpty) {
      final expenseTransactions = currentTransactions
          .where((t) => t.transactionType == TransactionType.expense)
          .toList();

      final categoryTotals = <String, double>{};
      for (final t in expenseTransactions) {
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0.0) + t.amount;
      }

      // Sort categories by expenditure
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedCategories.isNotEmpty) {
        final largestCat = sortedCategories.first;
        final share = (largestCat.value / expenses) * 100;

        if (share >= 25.0) {
          opportunities.add(
            Alert(
              id: 'opp_cost_reduction_${largestCat.key.toLowerCase().replaceAll(" ", "_")}_$businessId',
              businessId: businessId,
              alertType: AlertType.opportunity,
              severity: AlertSeverity.low,
              title: 'Cost Optimization: ${largestCat.key}',
              description:
                  '${largestCat.key} is your largest expense line at \$${largestCat.value.toStringAsFixed(2)}, accounting for ${share.toStringAsFixed(0)}% of total periodic expenses.',
              recommendation:
                  'Review vendor contracts, request tiered volume pricing, or explore alternative suppliers to reduce cost basis by 5–10%.',
              metricName: 'expense_category_share',
              metricValue: share,
              thresholdValue: 25.0,
              createdAt: now,
            ),
          );
        }
      }
    }

    // 3. RECURRING EXPENSE & SUBSCRIPTION REVIEW
    if (currentTransactions.isNotEmpty) {
      const recurringKeywords = [
        'software',
        'subscription',
        'saas',
        'tools',
        'cloud',
        'hosting',
        'internet',
        'retainer',
        'telecom',
      ];

      double recurringTotal = 0.0;
      final recurringItems = <Transaction>[];

      for (final t in currentTransactions) {
        if (t.transactionType == TransactionType.expense) {
          final catLower = t.category.toLowerCase();
          final descLower = (t.description ?? '').toLowerCase();
          final merchantLower = (t.merchantName ?? '').toLowerCase();

          final isRecurring = recurringKeywords.any(
            (kw) =>
                catLower.contains(kw) ||
                descLower.contains(kw) ||
                merchantLower.contains(kw),
          );

          if (isRecurring) {
            recurringTotal += t.amount;
            recurringItems.add(t);
          }
        }
      }

      if (recurringTotal >= 200 && recurringItems.length >= 2) {
        opportunities.add(
          Alert(
            id: 'opp_recurring_expense_review_$businessId',
            businessId: businessId,
            alertType: AlertType.opportunity,
            severity: AlertSeverity.low,
            title: 'Audit Recurring Subscriptions & Services',
            description:
                'Identified ${recurringItems.length} recurring SaaS / service expenses totaling \$${recurringTotal.toStringAsFixed(2)}.',
            recommendation:
                'Audit active user licenses, eliminate redundant tool subscriptions, and consider annual billing discounts to save 15–20%.',
            metricName: 'recurring_expenses',
            metricValue: recurringTotal,
            thresholdValue: 200.0,
            createdAt: now,
          ),
        );
      }
    }

    // 4. HIGH-PERFORMING REVENUE LINE EXPANSION
    if (revenue > 1000 && currentTransactions.isNotEmpty) {
      final incomeTransactions = currentTransactions
          .where((t) => t.transactionType == TransactionType.income)
          .toList();

      final categoryRevenue = <String, double>{};
      for (final t in incomeTransactions) {
        categoryRevenue[t.category] =
            (categoryRevenue[t.category] ?? 0.0) + t.amount;
      }

      final sortedIncomeCats = categoryRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedIncomeCats.isNotEmpty) {
        final topIncomeCat = sortedIncomeCats.first;
        final share = (topIncomeCat.value / revenue) * 100;

        if (share >= 40.0 && sortedIncomeCats.length > 1) {
          opportunities.add(
            Alert(
              id: 'opp_revenue_expansion_${topIncomeCat.key.toLowerCase().replaceAll(" ", "_")}_$businessId',
              businessId: businessId,
              alertType: AlertType.opportunity,
              severity: AlertSeverity.low,
              title: 'Scale Top Revenue Driver: ${topIncomeCat.key}',
              description:
                  '${topIncomeCat.key} generated \$${topIncomeCat.value.toStringAsFixed(2)} (${share.toStringAsFixed(0)}% of total income) with strong customer demand.',
              recommendation:
                  'Focus sales and marketing resources to expand market share in this high-performing revenue line.',
              metricName: 'revenue_category_share',
              metricValue: share,
              thresholdValue: 40.0,
              createdAt: now,
            ),
          );
        }
      }
    }

    return opportunities;
  }
}
