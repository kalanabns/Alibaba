import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../alerts/domain/priority_ranking_engine.dart';

class AiCfoActionCard extends StatelessWidget {
  const AiCfoActionCard({
    super.key,
    required this.issue,
    required this.currency,
    required this.onExecuteAction,
  });

  final PrioritizedFinancialIssue issue;
  final String currency;
  final void Function(PrioritizedFinancialIssue issue) onExecuteAction;

  Color _getPriorityColor() {
    switch (issue.priorityLevel) {
      case PriorityLevel.critical:
        return AppTheme.errorColor;
      case PriorityLevel.high:
        return const Color(0xFFEA580C);
      case PriorityLevel.medium:
        return AppTheme.warningColor;
      case PriorityLevel.low:
        return AppTheme.primaryLight;
      case PriorityLevel.informational:
        return AppTheme.infoColor;
    }
  }

  String _getActionBtnLabel() {
    switch (issue.actionType) {
      case ActionLinkType.reviewExpenses:
        return 'Review Operating Expenses';
      case ActionLinkType.collectReceivables:
        return 'Review Unpaid Invoices';
      case ActionLinkType.runScenario:
        return 'Test in What-If Simulator';
      case ActionLinkType.askAiCfo:
        return 'Ask AI CFO to Advise';
      case ActionLinkType.reviewForecast:
        return 'Inspect Forecast Model';
      case ActionLinkType.viewTransactions:
        return 'Inspect Transactions';
    }
  }

  IconData _getActionBtnIcon() {
    switch (issue.actionType) {
      case ActionLinkType.reviewExpenses:
        return Icons.pie_chart_outline_rounded;
      case ActionLinkType.collectReceivables:
        return Icons.receipt_long_rounded;
      case ActionLinkType.runScenario:
        return Icons.tune_rounded;
      case ActionLinkType.askAiCfo:
        return Icons.psychology_rounded;
      case ActionLinkType.reviewForecast:
        return Icons.auto_graph_rounded;
      case ActionLinkType.viewTransactions:
        return Icons.list_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: issue.isCritical
              ? AppTheme.errorColor.withValues(alpha: 0.5)
              : AppTheme.borderColor.withValues(alpha: 0.8),
          width: issue.isCritical ? 1.5 : 1.0,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Color Bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              // Main Card Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with Priority Badge and Urgency
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              issue.priorityBadgeLabel,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                issue.urgency,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        issue.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Why It Matters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WHY IT MATTERS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              issue.whyItMatters,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Recommended Action & Expected Impact
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.arrow_right_alt_rounded,
                                color: AppTheme.primaryLight,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                    children: [
                                      const TextSpan(
                                        text: 'Action: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: issue.recommendedAction),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppTheme.accentColor,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    children: [
                                      const TextSpan(
                                        text: 'Expected Impact: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.accentColor,
                                        ),
                                      ),
                                      TextSpan(text: issue.expectedImpact),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppTheme.borderColor),

                    // Action Link Execution Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Source: ${issue.sourceMetric}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          InkWell(
                            onTap: () => onExecuteAction(issue),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryNavy,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getActionBtnIcon(), size: 13, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getActionBtnLabel(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
