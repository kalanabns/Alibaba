import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/money_formatter.dart';
import '../../../shared/widgets/finora_empty_state.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_loading_indicator.dart';
import '../../alerts/domain/alert.dart';
import '../../businesses/domain/business.dart';
import '../../financial_health/domain/financial_engine.dart';
import '../application/forecast_controller.dart';
import '../domain/forecast.dart';
import 'widgets/forecast_chart.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({
    super.key,
    required this.controller,
    required this.business,
    required this.historicalBuckets,
    this.onAskAiAboutForecast,
  });

  final ForecastController controller;
  final Business business;
  final List<MonthlyFinancialBucket> historicalBuckets;
  final void Function(String query)? onAskAiAboutForecast;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isLoading = controller.isLoading;
        final error = controller.errorMessage;
        final eval = controller.evaluation;

        if (isLoading) {
          return const Scaffold(
            body: Center(
              child: FinoraLoadingIndicator(
                message: 'Evaluating trend momentum and projections...',
              ),
            ),
          );
        }

        if (error != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FinoraErrorView(
                  message: error,
                  onRetry: () => controller.generateAndSyncForecasts(
                    businessId: business.id,
                    buckets: historicalBuckets,
                    startingCash: business.startingCash,
                    currency: business.currency,
                  ),
                ),
              ),
            ),
          );
        }

        if (!eval.isSufficient) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: FinoraEmptyState(
              icon: Icons.trending_up_rounded,
              title: 'Insufficient Forecast Baseline',
              message: eval.message,
            ),
          );
        }

        final currency = business.currency;
        final confidencePct = (eval.confidenceScore * 100).toStringAsFixed(0);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 40% Navy Header & Confidence Level Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryNavy, AppTheme.secondaryNavy],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNavy.withValues(alpha: 0.16),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_graph_rounded,
                            color: AppTheme.primaryLight,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Financial Outlook & Forecasting',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryLight.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            child: Text(
                              '$confidencePct% CONFIDENCE',
                              style: const TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        eval.trendExplanation ??
                            'Forward-looking statistical trend analysis based on verified ledger transactions.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFF1F5F9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4 Key Outlook KPI Cards (60% White Surface Area)
                Row(
                  children: [
                    Expanded(
                      child: _buildOutlookCard(
                        title: 'Projected Revenue',
                        value: eval.revenueForecastNextMonth ?? 0.0,
                        currency: currency,
                        subtitle: 'Next Month Target',
                        color: AppTheme.accentColor,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOutlookCard(
                        title: 'Projected Expenses',
                        value: eval.expensesForecastNextMonth ?? 0.0,
                        currency: currency,
                        subtitle: 'Estimated Overhead',
                        color: AppTheme.errorColor,
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildOutlookCard(
                        title: 'Projected Net Cash',
                        value: eval.cashFlowForecastNextMonth ?? 0.0,
                        currency: currency,
                        subtitle: (eval.cashFlowForecastNextMonth ?? 0) >= 0
                            ? 'Positive Cash Flow'
                            : 'Projected Burn',
                        color: (eval.cashFlowForecastNextMonth ?? 0) >= 0
                            ? AppTheme.primaryLight
                            : AppTheme.warningColor,
                        icon: Icons.water_drop_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOutlookCard(
                        title: 'Estimated Balance',
                        value: eval.estimatedCashBalanceNextMonth ?? 0.0,
                        currency: currency,
                        subtitle: 'End of Next Month',
                        color: (eval.estimatedCashBalanceNextMonth ?? 0) >= 0
                            ? AppTheme.primaryColor
                            : AppTheme.errorColor,
                        icon: Icons.account_balance_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Forward-Looking Forecast Risk Signals (if any)
                if (eval.forecastRisks.isNotEmpty) ...[
                  ...eval.forecastRisks.map(
                    (risk) => _buildForecastRiskBanner(context, risk),
                  ),
                  const SizedBox(height: 18),
                ],

                // Charts Section
                ForecastChart(
                  historicalBuckets: historicalBuckets,
                  forecasts: eval.forecasts,
                  currency: currency,
                  forecastType: ForecastType.revenue,
                  title: 'Revenue Trajectory & Forecast',
                  accentColor: AppTheme.accentColor,
                ),
                const SizedBox(height: 14),
                ForecastChart(
                  historicalBuckets: historicalBuckets,
                  forecasts: eval.forecasts,
                  currency: currency,
                  forecastType: ForecastType.expenses,
                  title: 'Operating Expenses Trajectory & Forecast',
                  accentColor: AppTheme.errorColor,
                ),
                const SizedBox(height: 14),
                ForecastChart(
                  historicalBuckets: historicalBuckets,
                  forecasts: eval.forecasts,
                  currency: currency,
                  forecastType: ForecastType.cashFlow,
                  title: 'Net Cash Flow Trajectory & Forecast',
                  accentColor: AppTheme.primaryLight,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutlookCard({
    required String title,
    required double value,
    required String currency,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyFormatter.format(
                value,
                currency: currency,
                compact: value.abs() >= 100000,
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRiskBanner(BuildContext context, Alert risk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: risk.severityColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: risk.severityColor.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: risk.severityColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  risk.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  risk.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onAskAiAboutForecast != null)
            TextButton(
              onPressed: () => onAskAiAboutForecast!(
                'What does this forecast risk mean for my business: "${risk.title}"?',
              ),
              child: const Text('Ask AI', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
