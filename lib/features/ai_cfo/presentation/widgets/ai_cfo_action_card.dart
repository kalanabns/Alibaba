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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: issue.isCritical
              ? AppTheme.errorColor.withValues(alpha: 0.5)
              : AppTheme.borderColor,
          width: issue.isCritical ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    issue.priorityBadgeLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Why It Matters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WHY IT MATTERS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    issue.whyItMatters,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

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
                    const SizedBox(width: 4),
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
                      Icons.auto_awesome,
                      color: AppTheme.accentColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Source: ${issue.sourceMetric}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onExecuteAction(issue),
                  icon: Icon(_getActionBtnIcon(), size: 15),
                  label: Text(_getActionBtnLabel()),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryNavy,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
