import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/money_formatter.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_loading_indicator.dart';
import '../../businesses/domain/business.dart';
import '../../transactions/application/transaction_controller.dart';
import '../../transactions/presentation/add_edit_transaction_dialog.dart';
import '../../transactions/presentation/csv_import_flow.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';
import '../application/financial_health_controller.dart';
import 'widgets/financial_charts.dart';
import 'widgets/health_score_card.dart';
import 'widgets/kpi_metric_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.healthController,
    required this.transactionController,
    required this.business,
    required this.onNavigateToTransactions,
  });

  final FinancialHealthController healthController;
  final TransactionController transactionController;
  final Business business;
  final VoidCallback onNavigateToTransactions;

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
  }

  void _openAddTransactionModal() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditTransactionDialog(
        businessId: widget.business.id,
        currency: widget.business.currency,
        onSave: (transaction) async {
          return widget.transactionController.addTransaction(
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
          return widget.transactionController.importBatch(
            businessId: widget.business.id,
            transactions: transactions,
          );
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
            backgroundColor: AppTheme.surfaceElevated,
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
                            'Financial Overview',
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
                      // Period Range Selector
                      _buildPeriodSelector(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!hasTransactions) ...[
                    // Empty Financial State
                    _buildEmptyFinancialState(),
                  ] else ...[
                    // 1. Health Score Card
                    if (breakdown != null) ...[
                      HealthScoreCard(breakdown: breakdown),
                      const SizedBox(height: 18),
                    ],

                    // 2. Primary KPI Grid
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
                          childAspectRatio: isTablet ? 1.3 : 1.15,
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
                    const SizedBox(height: 14),

                    // Working Capital Summary Banner
                    if ((metric?.receivables ?? 0) > 0 ||
                        (metric?.payables ?? 0) > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.outbox,
                                  size: 16,
                                  color: AppTheme.infoColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Receivables: ${MoneyFormatter.format(metric?.receivables ?? 0.0, currency: currency)}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.inbox,
                                  size: 16,
                                  color: AppTheme.warningColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Payables: ${MoneyFormatter.format(metric?.payables ?? 0.0, currency: currency)}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 3. Financial Charts
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

                    // 4. Recent Transactions Section
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
                    const SizedBox(height: 20),

                    // 5. AI CFO Preview Banner (Stage 6 notice)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.psychology_outlined,
                              color: AppTheme.primaryLight,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI CFO Advisory',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Qoder Cloud Agents will analyze these calculated metrics in Stage 6.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                range.shortLabel,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF042F2E)
                      : AppTheme.textSecondary,
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
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
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
            'Import a CSV bank export or record your first transaction to instantly generate your financial health score, KPI ratios, and charts.',
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
}
