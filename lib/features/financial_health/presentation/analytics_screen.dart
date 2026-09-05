import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/money_formatter.dart';
import '../../businesses/domain/business.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/analytics_engine.dart';
import '../domain/financial_engine.dart';
import '../domain/financial_metric.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.business,
    required this.currentTransactions,
    this.previousTransactions = const [],
    this.monthlyBuckets = const [],
    this.currentMetric,
    this.previousMetric,
    this.onNavigateToSimulations,
    this.onNavigateToForecasts,
    this.onNavigateToTransactions,
  });

  final Business business;
  final List<Transaction> currentTransactions;
  final List<Transaction> previousTransactions;
  final List<MonthlyFinancialBucket> monthlyBuckets;
  final FinancialMetric? currentMetric;
  final FinancialMetric? previousMetric;
  final VoidCallback? onNavigateToSimulations;
  final VoidCallback? onNavigateToForecasts;
  final VoidCallback? onNavigateToTransactions;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late AnalyticsReport _report;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _computeReport();
  }

  @override
  void didUpdateWidget(AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTransactions != widget.currentTransactions ||
        oldWidget.currentMetric != widget.currentMetric) {
      _computeReport();
    }
  }

  void _computeReport() {
    _report = AnalyticsEngine.generateReport(
      currentTransactions: widget.currentTransactions,
      previousTransactions: widget.previousTransactions,
      monthlyBuckets: widget.monthlyBuckets,
      currentMetric: widget.currentMetric,
      previousMetric: widget.previousMetric,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.business.currency;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            border: const Border(
              bottom: BorderSide(color: Color(0x3538BDF8), width: 1.2),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Business Analytics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            '${widget.business.name} • Deep Financial Intelligence',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppTheme.primaryLight,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Expenses'),
                    Tab(text: 'Revenue'),
                    Tab(text: 'Profitability'),
                    Tab(text: 'Cash Flow'),
                    Tab(text: 'Period Matrix'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(currency),
          _buildExpensesTab(currency),
          _buildRevenueTab(currency),
          _buildProfitabilityTab(currency),
          _buildCashFlowTab(currency),
          _buildPeriodMatrixTab(currency),
        ],
      ),
    );
  }

  // 1. OVERVIEW & INSIGHTS TAB
  Widget _buildOverviewTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Margin Decomposition Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x3538BDF8), width: 1.2),
            boxShadow: AppTheme.heroShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PROFIT MARGIN DYNAMICS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _report.marginDecomposition.primaryDriver.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_report.profitMargin.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '(${_report.marginDecomposition.marginDelta >= 0 ? '+' : ''}${_report.marginDecomposition.marginDelta.toStringAsFixed(1)}% vs prior)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _report.marginDecomposition.marginDelta >= 0
                          ? AppTheme.accentColor
                          : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _report.marginDecomposition.explanation,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Business Insight Cards
        const Text(
          'Deterministic Operational Insights',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        if (_report.insights.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.accentColor, size: 18),
                SizedBox(width: 10),
                Text(
                  'All key financial metrics nominal for this cycle.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          )
        else
          ..._report.insights.map((insight) => _buildInsightCard(insight)),
      ],
    );
  }

  Widget _buildInsightCard(BusinessInsight insight) {
    Color color;
    IconData icon;
    switch (insight.significance) {
      case InsightSignificance.critical:
        color = AppTheme.errorColor;
        icon = Icons.error_outline_rounded;
        break;
      case InsightSignificance.warning:
        color = AppTheme.warningColor;
        icon = Icons.warning_amber_rounded;
        break;
      case InsightSignificance.positive:
        color = AppTheme.accentColor;
        icon = Icons.check_circle_outline_rounded;
        break;
      case InsightSignificance.info:
        color = AppTheme.infoColor;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.description,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          if (insight.actionLabel != null && insight.actionRoute != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                if (insight.actionRoute == 'simulations' && widget.onNavigateToSimulations != null) {
                  widget.onNavigateToSimulations!();
                } else if (insight.actionRoute == 'forecasts' && widget.onNavigateToForecasts != null) {
                  widget.onNavigateToForecasts!();
                } else if (insight.actionRoute == 'ledger' && widget.onNavigateToTransactions != null) {
                  widget.onNavigateToTransactions!();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      insight.actionLabel!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 2. EXPENSES INTELLIGENCE TAB
  Widget _buildExpensesTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Total Expenses KPI Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Operating Outflow',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                MoneyFormatter.format(_report.totalExpenses, currency: currency),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.errorColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${_report.expenseCategories.length} active cost categories in current evaluation cycle.',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Expense Category Distribution',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        if (_report.expenseCategories.isEmpty)
          const Text('No recorded expenses for this period.', style: TextStyle(color: AppTheme.textSecondary))
        else
          ..._report.expenseCategories.map((cat) => _buildCategoryTile(cat, currency, isExpense: true)),
      ],
    );
  }

  // 3. REVENUE INTELLIGENCE TAB
  Widget _buildRevenueTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Total Revenue Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Recognized Revenue',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                MoneyFormatter.format(_report.totalRevenue, currency: currency),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.accentColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${_report.revenueCategories.length} revenue streams recorded.',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Revenue Stream Diversification',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        if (_report.revenueCategories.isEmpty)
          const Text('No recorded revenue for this period.', style: TextStyle(color: AppTheme.textSecondary))
        else
          ..._report.revenueCategories.map((cat) => _buildCategoryTile(cat, currency, isExpense: false)),
      ],
    );
  }

  Widget _buildCategoryTile(CategoryBreakdown cat, String currency, {required bool isExpense}) {
    final color = isExpense ? AppTheme.errorColor : AppTheme.accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    cat.category,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  if (cat.isRecurring) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'RECURRING',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                MoneyFormatter.format(cat.amount, currency: currency),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cat.percentage,
              minHeight: 6,
              backgroundColor: AppTheme.borderColor.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(cat.percentage * 100).toStringAsFixed(1)}% of total • ${cat.transactionCount} transactions',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              if (cat.growthRate != 0)
                Text(
                  '${cat.growthRate >= 0 ? '+' : ''}${cat.growthRate.toStringAsFixed(1)}% vs prior',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cat.growthRate > 0 ? AppTheme.errorColor : AppTheme.accentColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. PROFITABILITY TAB
  Widget _buildProfitabilityTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Net Operating Profit', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(
                MoneyFormatter.format(_report.netProfit, currency: currency),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _report.netProfit >= 0 ? AppTheme.accentColor : AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('Gross Revenue', MoneyFormatter.format(_report.totalRevenue, currency: currency)),
                  _buildMiniStat('Total Overhead', MoneyFormatter.format(_report.totalExpenses, currency: currency)),
                  _buildMiniStat('Margin', '${_report.profitMargin.toStringAsFixed(1)}%'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. CASH FLOW TAB
  Widget _buildCashFlowTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Net Cash Flow Velocity', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(
                MoneyFormatter.format(_report.netCashFlow, currency: currency),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _report.netCashFlow >= 0 ? AppTheme.primaryLight : AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('Cash Inflow', MoneyFormatter.format(_report.cashInflow, currency: currency)),
                  _buildMiniStat('Cash Outflow', MoneyFormatter.format(_report.cashOutflow, currency: currency)),
                  _buildMiniStat('Receivables', MoneyFormatter.format(_report.receivables, currency: currency)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 6. PERIOD MATRIX TAB
  Widget _buildPeriodMatrixTab(String currency) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Cycle Variance Matrix',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 14),
        ..._report.periodComparisons.map((m) => _buildPeriodComparisonRow(m, currency)),
      ],
    );
  }

  Widget _buildPeriodComparisonRow(PeriodComparisonMetric metric, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Current: ${metric.unit == '%' ? '${metric.currentValue.toStringAsFixed(1)}%' : MoneyFormatter.format(metric.currentValue, currency: currency)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${metric.absoluteChange >= 0 ? '+' : ''}${metric.unit == '%' ? '${metric.absoluteChange.toStringAsFixed(1)}%' : MoneyFormatter.format(metric.absoluteChange, currency: currency)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: metric.isPositiveTrend ? AppTheme.accentColor : AppTheme.errorColor,
                ),
              ),
              if (metric.percentageChange != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${metric.percentageChange! >= 0 ? '+' : ''}${metric.percentageChange!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: metric.isPositiveTrend ? AppTheme.accentColor : AppTheme.errorColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }
}
