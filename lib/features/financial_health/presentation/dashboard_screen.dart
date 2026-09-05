import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_loading_indicator.dart';
import '../../ai_cfo/application/ai_cfo_controller.dart';
import '../../ai_cfo/domain/cfo_briefing.dart';
import '../../alerts/application/alerts_controller.dart';
import '../../alerts/domain/alert.dart';
import '../../alerts/domain/priority_ranking_engine.dart';
import '../../businesses/domain/business.dart';
import '../../transactions/application/transaction_controller.dart';
import '../../transactions/presentation/add_edit_transaction_dialog.dart';
import '../../transactions/presentation/csv_import_flow.dart';
import '../application/financial_health_controller.dart';
import '../../forecasts/application/forecast_controller.dart';
import 'widgets/financial_command_center.dart';

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
        currency: widget.business.currency,
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Overview Title & Period Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXECUTIVE RADAR',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.business.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                      _buildPeriodSelector(),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Financial Command Center Component
                  FinancialCommandCenter(
                    business: widget.business,
                    metric: metric,
                    previousMetric: widget.healthController.monthlyBuckets.length >= 2
                        ? null
                        : null,
                    breakdown: breakdown,
                    buckets: widget.healthController.monthlyBuckets,
                    activeAlerts: widget.alertsController.allAlerts,
                    forecasts: widget.forecastController?.forecasts ?? [],
                    recentTransactions: widget.transactionController.transactions,
                    briefing: CfoBriefing.generate(
                      business: widget.business,
                      metric: metric,
                      activeAlerts: widget.alertsController.allAlerts,
                      forecasts: widget.forecastController?.forecasts,
                    ),
                    onNavigateToTransactions: widget.onNavigateToTransactions,
                    onNavigateToAlerts: widget.onNavigateToAlerts,
                    onNavigateToAiCfo: widget.onNavigateToAiCfo,
                    onNavigateToForecasts: widget.onNavigateToForecasts ?? () {},
                    onNavigateToSimulations: widget.onNavigateToSimulations ?? () {},
                    onOpenAddTransaction: _openAddTransactionModal,
                    onOpenCsvImport: _openCsvImportWizard,
                    onExecuteAction: (issue) {
                      switch (issue.actionType) {
                        case ActionLinkType.reviewExpenses:
                        case ActionLinkType.collectReceivables:
                        case ActionLinkType.viewTransactions:
                          widget.onNavigateToTransactions();
                          break;
                        case ActionLinkType.runScenario:
                          if (widget.onNavigateToSimulations != null) {
                            widget.onNavigateToSimulations!();
                          }
                          break;
                        case ActionLinkType.askAiCfo:
                          widget.onNavigateToAiCfo();
                          widget.aiCfoController.sendMessage(
                            message: 'How do I address "${issue.title}"? Please outline practical steps.',
                            businessId: widget.business.id,
                            currentMetrics: metric,
                            business: widget.business,
                            activeAlerts: widget.alertsController.allAlerts,
                            recentTransactions: widget.transactionController.transactions,
                          );
                          break;
                        case ActionLinkType.reviewForecast:
                          if (widget.onNavigateToForecasts != null) {
                            widget.onNavigateToForecasts!();
                          }
                          break;
                      }
                    },
                    onExplainAlert: widget.onExplainAlert,
                  ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.8)),
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
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                borderRadius: BorderRadius.circular(9),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                range.shortLabel,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
