import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/money_formatter.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_loading_indicator.dart';
import '../../ai_cfo/application/ai_cfo_controller.dart';
import '../../alerts/application/alerts_controller.dart';
import '../../alerts/domain/alert.dart';
import '../../businesses/domain/business.dart';
import '../../transactions/application/transaction_controller.dart';
import '../../transactions/presentation/add_edit_transaction_dialog.dart';
import '../../transactions/presentation/csv_import_flow.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';
import '../application/financial_health_controller.dart';
import '../../forecasts/application/forecast_controller.dart';
import '../../forecasts/presentation/forecast_screen.dart';
import '../../simulations/presentation/simulations_screen.dart';
import 'widgets/ai_summary_card.dart';
import 'widgets/financial_charts.dart';
import 'widgets/financial_outlook_card.dart';
import 'widgets/financial_signals_preview.dart';
import 'widgets/health_score_card.dart';
import 'widgets/kpi_metric_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.healthController,
    required this.transactionController,
    required this.alertsController,
    required this.aiCfoController,
    this.forecastController,
    required this.business,
    required this.onNavigateToTransactions,
    required this.onNavigateToAlerts,
    required this.onNavigateToAiCfo,
    this.onNavigateToForecasts,
    this.onNavigateToSimulations,
    this.onExplainAlert,
  });

  final FinancialHealthController healthController;
  final TransactionController transactionController;
  final AlertsController alertsController;
  final AICFOController aiCfoController;
  final ForecastController? forecastController;
  final Business business;
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onNavigateToAlerts;
  final VoidCallback onNavigateToAiCfo;
  final VoidCallback? onNavigateToForecasts;
  final VoidCallback? onNavigateToSimulations;
  final void Function(Alert alert)? onExplainAlert;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    widget.healthController.recalculate(
      businessId: widget.business.id,
      allTransactions: widget.transactionController.transactions,
    );

    final currentMetric = widget.healthController.currentMetric;
    if (currentMetric != null) {
      widget.alertsController.evaluateAndSync(
        businessId: widget.business.id,
        currentMetrics: currentMetric,
        currentTransactions: widget.transactionController.transactions,
        startingCash: widget.business.startingCash,
      );

      widget.aiCfoController.generateDashboardSummary(
        businessId: widget.business.id,
        currentMetrics: currentMetric,
        business: widget.business,
        activeAlerts: widget.alertsController.allAlerts,
      );

      widget.forecastController?.generateAndSyncForecasts(
        businessId: widget.business.id,
        buckets: widget.healthController.monthlyBuckets,
        startingCash: widget.business.startingCash,
        silent: true,
      );
    }
  }

  void _openAddTransactionModal() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditTransactionDialog(
        businessId: widget.business.id,
        currency: widget.business.currency,
        onSave: (transaction) async {
          final success = await widget.transactionController.addTransaction(
            businessId: widget.business.id,
            transactionDate: transaction.transactionDate,
            transactionType: transaction.transactionType,
            category: transaction.category,
            amount: transaction.amount,
            subcategory: transaction.subcategory,
            currency: widget.business.currency,
            description: transaction.description,
            merchantName: transaction.merchantName,
            customerName: transaction.customerName,
            supplierName: transaction.supplierName,
            paymentStatus: transaction.paymentStatus,
            externalReference: transaction.externalReference,
          );
          if (success) _loadData();
          return success;
        },
      ),
    );
  }

  void _openCsvImportWizard() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CsvImportFlow(
        businessId: widget.business.id,
        currency: widget.business.currency,
        existingTransactions: widget.transactionController.transactions,
        onImportComplete: (transactions) async {
          final count = await widget.transactionController.importBatch(
            businessId: widget.business.id,
            transactions: transactions,
          );
          if (count > 0) _loadData();
          return count;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.healthController,
        widget.transactionController,
        widget.alertsController,
        widget.aiCfoController,
      ]),
      builder: (context, _) {
        final isLoading = widget.healthController.isLoading;
        final error = widget.healthController.errorMessage;
        final metric = widget.healthController.currentMetric;
        final breakdown = widget.healthController.healthBreakdown;
        final hasTransactions =
            widget.transactionController.transactions.isNotEmpty;
        final currency = widget.business.currency;

        if (isLoading && metric == null) {
          return const Scaffold(
            body: Center(
              child: FinoraLoadingIndicator(
                message: 'Calculating financial health...',
              ),
            ),
          );
        }

        if (error != null && metric == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FinoraErrorView(message: error, onRetry: _loadData),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: RefreshIndicator(
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.surface,
            onRefresh: () async {
              await widget.transactionController.loadTransactions(
                businessId: widget.business.id,
              );
              _loadData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Business Header & Period Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Financial Health Overview',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.business.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      _buildPeriodSelector(),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (!hasTransactions) ...[
                    // Empty Financial State
                    _buildEmptyFinancialState(),
                  ] else ...[
                    // 1. Health Score Card (Navy / Teal Hero Accent)
                    if (breakdown != null) ...[
                      HealthScoreCard(breakdown: breakdown),
                      const SizedBox(height: 16),
                    ],

                    // 2. AI CFO Executive Brief Card
                    AISummaryCard(
                      summary: widget.aiCfoController.cachedDashboardSummary,
                      isLoading: widget.aiCfoController.isGeneratingSummary,
                      onOpenChat: widget.onNavigateToAiCfo,
                      onRefresh: () {
                        widget.aiCfoController.generateDashboardSummary(
                          businessId: widget.business.id,
                          currentMetrics: metric,
                          business: widget.business,
                          activeAlerts: widget.alertsController.allAlerts,
                          force: true,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Primary KPI Grid (Crisp 60% White Cards)
                    LayoutBuilder(
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
                              currency: currency,
                              growth: metric?.revenueGrowth,
                              icon: Icons.trending_up_rounded,
                              accentColor: AppTheme.accentColor,
                            ),
                            KpiMetricCard(
                              title: 'Expenses',
                              amount: metric?.expenses ?? 0.0,
                              currency: currency,
                              growth: metric?.expenseGrowth,
                              icon: Icons.trending_down_rounded,
                              accentColor: AppTheme.errorColor,
                              isExpenseType: true,
                            ),
                            KpiMetricCard(
                              title: 'Net Profit',
                              amount: metric?.profit ?? 0.0,
                              currency: currency,
                              subtitle:
                                  'Margin: ${MoneyFormatter.formatPercent(metric?.profitMargin ?? 0.0, showSign: false)}',
                              icon: Icons.account_balance_wallet_outlined,
                              accentColor: (metric?.profit ?? 0) >= 0
                                  ? AppTheme.accentColor
                                  : AppTheme.errorColor,
                            ),
                            KpiMetricCard(
                              title: 'Net Cash Flow',
                              amount: metric?.netCashFlow ?? 0.0,
                              currency: currency,
                              subtitle: (metric?.netCashFlow ?? 0) >= 0
                                  ? 'Cash Positive'
                                  : 'Cash Burn',
                              icon: Icons.water_drop_outlined,
                              accentColor: (metric?.netCashFlow ?? 0) >= 0
                                  ? AppTheme.primaryLight
                                  : AppTheme.warningColor,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. Financial Signals Preview (Risks & Opportunities)
                    FinancialSignalsPreview(
                      risks: widget.alertsController.topRisks,
                      opportunities: widget.alertsController.topOpportunities,
                      onViewAll: widget.onNavigateToAlerts,
                      onExplainAlert: widget.onExplainAlert,
                    ),
                    const SizedBox(height: 16),

                    // 5. Forward-Looking Financial Outlook (Stage 7)
                    if (widget.forecastController != null &&
                        widget.forecastController!.evaluation.isSufficient) ...[
                      FinancialOutlookCard(
                        evaluation: widget.forecastController!.evaluation,
                        currency: currency,
                        onViewFullForecast: () {
                          if (widget.onNavigateToForecasts != null) {
                            widget.onNavigateToForecasts!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForecastScreen(
                                  controller: widget.forecastController!,
                                  business: widget.business,
                                  historicalBuckets:
                                      widget.healthController.monthlyBuckets,
                                  onAskAiAboutForecast: (query) {
                                    widget.onNavigateToAiCfo();
                                    widget.aiCfoController.sendMessage(
                                      message: query,
                                      businessId: widget.business.id,
                                      currentMetrics:
                                          widget.healthController.currentMetric,
                                      business: widget.business,
                                      activeAlerts:
                                          widget.alertsController.allAlerts,
                                      recentTransactions: widget
                                          .transactionController
                                          .transactions,
                                    );
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 6. What-If Scenario Simulator Card (Stage 8)
                    _buildWhatIfSimulatorLauncher(context),
                    const SizedBox(height: 16),

                    // 7. Financial Charts
                    RevenueExpensesChart(
                      buckets: widget.healthController.monthlyBuckets,
                      currency: currency,
                    ),
                    const SizedBox(height: 14),
                    CashFlowTrendChart(
                      buckets: widget.healthController.monthlyBuckets,
                      currency: currency,
                    ),
                    const SizedBox(height: 20),

                    // 8. Recent Transactions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToTransactions,
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...widget.transactionController.transactions.take(5).map((
                      t,
                    ) {
                      return TransactionTile(
                        transaction: t,
                        currency: currency,
                        onTap: widget.onNavigateToTransactions,
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    final current = widget.healthController.selectedPeriod;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: FinancialPeriodRange.values.map((range) {
          final isSelected = range == current;

          return InkWell(
            onTap: () {
              widget.healthController.setPeriod(
                range,
                businessId: widget.business.id,
                allTransactions: widget.transactionController.transactions,
              );
              final metric = widget.healthController.currentMetric;
              if (metric != null) {
                widget.alertsController.evaluateAndSync(
                  businessId: widget.business.id,
                  currentMetrics: metric,
                  currentTransactions:
                      widget.transactionController.transactions,
                  startingCash: widget.business.startingCash,
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryNavy : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                range.shortLabel,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFinancialState() {
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
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 32,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your financial picture starts with transactions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Import a CSV bank export or record your first transaction to instantly generate your financial health score, risk/opportunity signals, and AI CFO analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _openCsvImportWizard,
                icon: const Icon(Icons.file_upload_outlined, size: 18),
                label: const Text('Import CSV'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openAddTransactionModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Transaction'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIfSimulatorLauncher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.navyPrimary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppTheme.navyPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'What-If Scenario Simulator',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navyDeep,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Simulate revenue changes, cost cuts, or hiring before making decisions.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (widget.onNavigateToSimulations != null) {
                widget.onNavigateToSimulations!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SimulationsScreen(
                      business: widget.business,
                      transactionsController: widget.transactionController,
                      currentMetric: widget.healthController.currentMetric,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navyPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Simulate'),
          ),
        ],
      ),
    );
  }
}
