import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utilities/money_formatter.dart';
import '../../../ai_cfo/domain/cfo_briefing.dart';
import '../../../alerts/domain/alert.dart';
import '../../../alerts/domain/priority_ranking_engine.dart';
import '../../../businesses/domain/business.dart';
import '../../../forecasts/domain/forecast.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../domain/financial_engine.dart';
import '../../domain/financial_metric.dart';
import '../../domain/health_score_breakdown.dart';
import 'health_score_card.dart';
import 'kpi_metric_card.dart';

enum TrendChartMetric { revenueVsExpenses, netProfit, cashFlow }

enum TrendTimeRange {
  oneMonth('30 Days', 1),
  threeMonths('3 Months', 3),
  sixMonths('6 Months', 6),
  twelveMonths('12 Months', 12);

  const TrendTimeRange(this.label, this.months);
  final String label;
  final int months;
}

class FinancialCommandCenter extends StatefulWidget {
  const FinancialCommandCenter({
    super.key,
    required this.business,
    required this.metric,
    required this.previousMetric,
    required this.breakdown,
    required this.buckets,
    required this.activeAlerts,
    required this.forecasts,
    required this.recentTransactions,
    required this.briefing,
    required this.onNavigateToTransactions,
    required this.onNavigateToAlerts,
    required this.onNavigateToAiCfo,
    required this.onNavigateToForecasts,
    required this.onNavigateToSimulations,
    required this.onOpenAddTransaction,
    required this.onOpenCsvImport,
    required this.onExecuteAction,
    this.onExplainAlert,
    this.isDemoMode = false,
  });

  final Business business;
  final FinancialMetric? metric;
  final FinancialMetric? previousMetric;
  final HealthScoreBreakdown? breakdown;
  final List<MonthlyFinancialBucket> buckets;
  final List<Alert> activeAlerts;
  final List<Forecast> forecasts;
  final List<Transaction> recentTransactions;
  final CfoBriefing? briefing;
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onNavigateToAlerts;
  final VoidCallback onNavigateToAiCfo;
  final VoidCallback onNavigateToForecasts;
  final VoidCallback onNavigateToSimulations;
  final VoidCallback onOpenAddTransaction;
  final VoidCallback onOpenCsvImport;
  final void Function(PrioritizedFinancialIssue issue) onExecuteAction;
  final void Function(Alert alert)? onExplainAlert;
  final bool isDemoMode;

  @override
  State<FinancialCommandCenter> createState() => _FinancialCommandCenterState();
}

class _FinancialCommandCenterState extends State<FinancialCommandCenter> {
  TrendChartMetric _selectedChartMetric = TrendChartMetric.revenueVsExpenses;
  TrendTimeRange _selectedTimeRange = TrendTimeRange.sixMonths;

  @override
  Widget build(BuildContext context) {
    final hasTransactions = widget.recentTransactions.isNotEmpty;
    final currency = widget.business.currency;
    final metric = widget.metric;
    final breakdown = widget.breakdown;

    if (!hasTransactions) {
      return _buildEmptyOnboardingState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. DEMO MODE BADGE (If active)
        if (widget.isDemoMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.science_outlined, color: AppTheme.primaryLight, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DEMO MODE • Pacific Coast Roasters (Sample Scenario)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 2. FINANCIAL HEALTH HERO (10-second Answer: "How is my business doing?")
        if (breakdown != null) ...[
          HealthScoreCard(breakdown: breakdown),
          const SizedBox(height: 16),
        ],

        // 3. PROACTIVE CFO BRIEFING (10-second Answer: "What should I do?")
        if (widget.briefing != null) ...[
          _buildCfoBriefingCard(widget.briefing!),
          const SizedBox(height: 16),
        ],

        // 4. PRIMARY KPI GRID (10-second Answer: "What changed?")
        _buildKpiGrid(metric, currency),
        const SizedBox(height: 16),

        // 5. RISK & OPPORTUNITY SNAPSHOT (10-second Answer: "What is dangerous?")
        _buildRiskOpportunitySnapshot(),
        const SizedBox(height: 16),

        // 6. FORECAST SNAPSHOT (10-second Answer: "What is likely to happen next?")
        _buildForecastSnapshot(currency),
        const SizedBox(height: 16),

        // 7. FINANCIAL TREND VISUALIZATION (Actuals vs Forecast with 30d/3m/6m/12m)
        _buildTrendVisualizer(currency),
        const SizedBox(height: 16),

        // 8. WHAT-IF SCENARIO SIMULATOR LAUNCHER
        _buildWhatIfSimulatorLauncher(),
        const SizedBox(height: 20),

        // 9. RECENT FINANCIAL ACTIVITY
        _buildRecentActivitySection(currency),
      ],
    );
  }

  // ==========================================
  // 1. CFO BRIEFING CARD
  // ==========================================
  Widget _buildCfoBriefingCard(CfoBriefing briefing) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      Icons.psychology_rounded,
                      color: AppTheme.primaryLight,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI CFO Daily Briefing',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: widget.onNavigateToAiCfo,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Open Chat',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 15, color: AppTheme.primaryNavy),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            briefing.todayStatus,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flash_on_rounded, color: AppTheme.warningColor, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Key Shift: ${briefing.mostImportantChange}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (briefing.prioritizedIssues.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => widget.onExecuteAction(briefing.prioritizedIssues.first),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryLight, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recommended: ${briefing.recommendedAction}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 2. PRIMARY KPI GRID
  // ==========================================
  Widget _buildKpiGrid(FinancialMetric? metric, String currency) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 500;
        final crossAxisCount = isTablet ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isTablet ? 1.5 : 1.2,
          children: [
            KpiMetricCard(
              title: 'Revenue',
              amount: metric?.revenue ?? 0.0,
              previousAmount: widget.previousMetric?.revenue,
              currency: currency,
              growth: metric?.revenueGrowth,
              icon: Icons.trending_up_rounded,
              accentColor: AppTheme.accentColor,
            ),
            KpiMetricCard(
              title: 'Expenses',
              amount: metric?.expenses ?? 0.0,
              previousAmount: widget.previousMetric?.expenses,
              currency: currency,
              growth: metric?.expenseGrowth,
              icon: Icons.trending_down_rounded,
              accentColor: AppTheme.errorColor,
              isExpenseType: true,
            ),
            KpiMetricCard(
              title: 'Net Profit',
              amount: metric?.profit ?? 0.0,
              previousAmount: widget.previousMetric?.profit,
              currency: currency,
              subtitle: 'Margin: ${MoneyFormatter.formatPercent(metric?.profitMargin ?? 0.0, showSign: false)}',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: (metric?.profit ?? 0) >= 0 ? AppTheme.accentColor : AppTheme.errorColor,
            ),
            KpiMetricCard(
              title: 'Net Cash Flow',
              amount: metric?.netCashFlow ?? 0.0,
              previousAmount: widget.previousMetric?.netCashFlow,
              currency: currency,
              subtitle: (metric?.netCashFlow ?? 0) >= 0 ? 'Cash Positive' : 'Cash Burn',
              icon: Icons.water_drop_outlined,
              accentColor: (metric?.netCashFlow ?? 0) >= 0 ? AppTheme.primaryLight : AppTheme.warningColor,
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 3. RISK & OPPORTUNITY SNAPSHOT
  // ==========================================
  Widget _buildRiskOpportunitySnapshot() {
    final topRisk = widget.activeAlerts.where((a) => a.isRisk && !a.isRead).toList();
    final topOpp = widget.activeAlerts.where((a) => a.isOpportunity && !a.isRead).toList();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: AppTheme.warningColor),
                  SizedBox(width: 6),
                  Text(
                    'Signals & Action Triggers',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onNavigateToAlerts,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Action Center'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topRisk.isEmpty && topOpp.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.accentColor, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'All signals nominal. No critical bottlenecks active.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (topRisk.isNotEmpty) ...[
              _buildSignalTile(
                alert: topRisk.first,
                isRisk: true,
                onTap: () {
                  if (widget.onExplainAlert != null) {
                    widget.onExplainAlert!(topRisk.first);
                  } else {
                    widget.onNavigateToAlerts();
                  }
                },
              ),
            ],
            if (topOpp.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSignalTile(
                alert: topOpp.first,
                isRisk: false,
                onTap: () {
                  if (widget.onExplainAlert != null) {
                    widget.onExplainAlert!(topOpp.first);
                  } else {
                    widget.onNavigateToAlerts();
                  }
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSignalTile({
    required Alert alert,
    required bool isRisk,
    required VoidCallback onTap,
  }) {
    final color = isRisk ? alert.severityColor : AppTheme.accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isRisk ? 'RISK' : 'OPPORTUNITY',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    alert.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. FORECAST SNAPSHOT
  // ==========================================
  Widget _buildForecastSnapshot(String currency) {
    final hasEnoughData = widget.buckets.length >= 2;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_graph_rounded, size: 18, color: AppTheme.primaryLight),
                  SizedBox(width: 6),
                  Text(
                    'Forward Forecast Snapshot',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onNavigateToForecasts,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Full Outlook'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasEnoughData) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Not enough historical data for a reliable forecast (requires 2+ monthly periods).',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildForecastMetricChip(
                    label: 'Projected Next Mo. Revenue',
                    amount: _getForecastAmount(ForecastType.revenue),
                    currency: currency,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildForecastMetricChip(
                    label: 'Projected Next Mo. Burn/Flow',
                    amount: _getForecastAmount(ForecastType.cashFlow),
                    currency: currency,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double? _getForecastAmount(ForecastType type) {
    final matches = widget.forecasts.where((f) => f.forecastType == type).toList();
    if (matches.isEmpty) return null;
    return matches.first.predictedValue;
  }

  Widget _buildForecastMetricChip({
    required String label,
    required double? amount,
    required String currency,
    required Color color,
  }) {
    final formatted = amount != null
        ? MoneyFormatter.format(amount, currency: currency, compact: true)
        : 'Estimating...';

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
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            formatted,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. TREND VISUALIZER (ACTUALS VS FORECAST)
  // ==========================================
  Widget _buildTrendVisualizer(String currency) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric Selector & Time Range Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Financial Trends',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              _buildTimeRangeToggle(),
            ],
          ),
          const SizedBox(height: 12),
          // Metric Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMetricChip(
                  label: 'Revenue vs Expenses',
                  metric: TrendChartMetric.revenueVsExpenses,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  label: 'Profit Margin',
                  metric: TrendChartMetric.netProfit,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  label: 'Cash Flow',
                  metric: TrendChartMetric.cashFlow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Chart Rendering Canvas
          _renderChartCanvas(currency),
        ],
      ),
    );
  }

  Widget _buildTimeRangeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TrendTimeRange.values.map((range) {
          final isSelected = range == _selectedTimeRange;
          return InkWell(
            onTap: () => setState(() => _selectedTimeRange = range),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryNavy : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                range.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required TrendChartMetric metric,
  }) {
    final isSelected = _selectedChartMetric == metric;

    return InkWell(
      onTap: () => setState(() => _selectedChartMetric = metric),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNavy.withValues(alpha: 0.1) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryNavy : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primaryNavy : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _renderChartCanvas(String currency) {
    final filteredBuckets = widget.buckets.take(_selectedTimeRange.months).toList().reversed.toList();

    if (filteredBuckets.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('No historical periods available', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ),
      );
    }

    double maxVal = 100.0;
    for (final b in filteredBuckets) {
      maxVal = math.max(maxVal, math.max(b.revenue, b.expenses));
      maxVal = math.max(maxVal, b.netCashFlow.abs());
    }

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: filteredBuckets.map((bucket) {
          final revRatio = (bucket.revenue / maxVal).clamp(0.0, 1.0);
          final expRatio = (bucket.expenses / maxVal).clamp(0.0, 1.0);
          final cashRatio = (bucket.netCashFlow.abs() / maxVal).clamp(0.0, 1.0);
          final isCashPositive = bucket.netCashFlow >= 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _selectedChartMetric == TrendChartMetric.revenueVsExpenses
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 10,
                                  height: math.max(4.0, 95.0 * revRatio),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accentColor,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Container(
                                  width: 10,
                                  height: math.max(4.0, 95.0 * expRatio),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.errorColor,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                              ],
                            )
                          : _selectedChartMetric == TrendChartMetric.cashFlow
                              ? Container(
                                  width: 14,
                                  height: math.max(4.0, 95.0 * cashRatio),
                                  decoration: BoxDecoration(
                                    color: isCashPositive ? AppTheme.primaryLight : AppTheme.errorColor,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                )
                              : Container(
                                  width: 14,
                                  height: math.max(4.0, 95.0 * (bucket.revenue > 0 ? (bucket.profit / bucket.revenue).clamp(0.0, 1.0) : 0.05)),
                                  decoration: BoxDecoration(
                                    color: bucket.profit >= 0 ? AppTheme.accentColor : AppTheme.errorColor,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bucket.label.split(' ').first,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // 6. WHAT-IF SIMULATOR LAUNCHER
  // ==========================================
  Widget _buildWhatIfSimulatorLauncher() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: AppTheme.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What-If Scenario Simulator',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Simulate pricing shifts (+5%), staff hiring, or expense reductions.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: widget.onNavigateToSimulations,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            child: const Text('Simulate'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. RECENT FINANCIAL ACTIVITY
  // ==========================================
  Widget _buildRecentActivitySection(String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: widget.onNavigateToTransactions,
              child: const Text('View All Transactions'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.recentTransactions.take(5).map((t) {
          return TransactionTile(
            transaction: t,
            currency: currency,
            onTap: widget.onNavigateToTransactions,
          );
        }),
      ],
    );
  }

  // ==========================================
  // 8. EMPTY ONBOARDING STATE
  // ==========================================
  Widget _buildEmptyOnboardingState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppTheme.primaryNavy,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_rounded, size: 32, color: AppTheme.primaryLight),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to ${widget.business.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Import your transaction history to activate deterministic Financial Health scoring, automated risk alerts, and your AI CFO.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onOpenCsvImport,
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Import Bank CSV Statement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.onOpenAddTransaction,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Manual Transaction'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryNavy,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }
}
