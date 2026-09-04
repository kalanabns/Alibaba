import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/money_formatter.dart';
import '../../../forecasts/domain/forecast_engine.dart';

class FinancialOutlookCard extends StatelessWidget {
  const FinancialOutlookCard({
    super.key,
    required this.evaluation,
    required this.currency,
    required this.onViewFullForecast,
  });

  final ForecastEvaluation evaluation;
  final String currency;
  final VoidCallback onViewFullForecast;

  @override
  Widget build(BuildContext context) {
    if (!evaluation.isSufficient) {
      return const SizedBox.shrink();
    }

    final confPct = (evaluation.confidenceScore * 100).toStringAsFixed(0);
    final nextRev = evaluation.revenueForecastNextMonth ?? 0.0;
    final nextExp = evaluation.expensesForecastNextMonth ?? 0.0;
    final nextCash = evaluation.cashFlowForecastNextMonth ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      color: AppTheme.primaryLight,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Next Month Outlook',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$confPct% Confidence',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Metric Tiles in Row
          Row(
            children: [
              Expanded(
                child: _buildTile(
                  label: 'Revenue',
                  amount: nextRev,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTile(
                  label: 'Expenses',
                  amount: nextExp,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTile(
                  label: 'Net Cash',
                  amount: nextCash,
                  color: nextCash >= 0
                      ? AppTheme.primaryLight
                      : AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // View Full Outlook Action
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onViewFullForecast,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View 3-Month Forecast',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            MoneyFormatter.format(amount, currency: currency, compact: true),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
