import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/finora_error_view.dart';
import '../../../shared/widgets/finora_loading_indicator.dart';
import '../application/transaction_controller.dart';
import '../data/csv_parser.dart';
import '../domain/transaction.dart';
import 'add_edit_transaction_dialog.dart';
import 'csv_import_flow.dart';
import 'widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.controller,
    required this.businessId,
    required this.currency,
  });

  final TransactionController controller;
  final String businessId;
  final String currency;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.state == TransactionListState.initial) {
      widget.controller.loadTransactions(businessId: widget.businessId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTransactionModal() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditTransactionDialog(
        businessId: widget.businessId,
        currency: widget.currency,
        onSave: (transaction) async {
          return widget.controller.addTransaction(
            businessId: widget.businessId,
            transactionDate: transaction.transactionDate,
            transactionType: transaction.transactionType,
            category: transaction.category,
            amount: transaction.amount,
            subcategory: transaction.subcategory,
            currency: widget.currency,
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

  void _openEditTransactionModal(Transaction transaction) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditTransactionDialog(
        businessId: widget.businessId,
        currency: widget.currency,
        initialTransaction: transaction,
        onSave: (updated) async {
          return widget.controller.updateTransaction(updated);
        },
        onDelete: (id) async {
          return widget.controller.deleteTransaction(
            id: id,
            businessId: widget.businessId,
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
        businessId: widget.businessId,
        currency: widget.currency,
        existingTransactions: widget.controller.transactions,
        onImportComplete: (transactions) async {
          return widget.controller.importBatch(
            businessId: widget.businessId,
            transactions: transactions,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: RefreshIndicator(
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.surfaceElevated,
            onRefresh: () => widget.controller.loadTransactions(
              businessId: widget.businessId,
            ),
            child: CustomScrollView(
              slivers: [
                // Top Action Bar & Filters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Action Buttons Header
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openCsvImportWizard,
                                icon: const Icon(
                                  Icons.file_upload_outlined,
                                  size: 18,
                                  color: AppTheme.primaryLight,
                                ),
                                label: const Text('Import CSV'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openAddTransactionModal,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Manual'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Search by memo, category, or counterparty...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      widget.controller.setSearchQuery(
                                        '',
                                        businessId: widget.businessId,
                                      );
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (val) {
                            widget.controller.setSearchQuery(
                              val,
                              businessId: widget.businessId,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Type Filter Chips & Category Dropdown
                        Row(
                          children: [
                            _buildFilterChip(
                              label: 'All',
                              isSelected:
                                  widget.controller.selectedTypeFilter == null,
                              onTap: () => widget.controller.setTypeFilter(
                                null,
                                businessId: widget.businessId,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Income',
                              isSelected:
                                  widget.controller.selectedTypeFilter ==
                                  TransactionType.income,
                              onTap: () => widget.controller.setTypeFilter(
                                TransactionType.income,
                                businessId: widget.businessId,
                              ),
                              activeColor: AppTheme.accentColor,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Expenses',
                              isSelected:
                                  widget.controller.selectedTypeFilter ==
                                  TransactionType.expense,
                              onTap: () => widget.controller.setTypeFilter(
                                TransactionType.expense,
                                businessId: widget.businessId,
                              ),
                              activeColor: AppTheme.errorColor,
                            ),
                            const Spacer(),
                            // Category Selector Menu
                            _buildCategoryMenu(),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Transaction List / States
                if (state == TransactionListState.loading &&
                    widget.controller.transactions.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: FinoraLoadingIndicator(
                        message: 'Loading transactions...',
                      ),
                    ),
                  )
                else if (state == TransactionListState.error &&
                    widget.controller.transactions.isEmpty)
                  SliverFillRemaining(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: FinoraErrorView(
                          message:
                              widget.controller.errorMessage ??
                              'Failed to load transactions.',
                          onRetry: () => widget.controller.loadTransactions(
                            businessId: widget.businessId,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (widget.controller.transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final transaction =
                            widget.controller.transactions[index];
                        return TransactionTile(
                          transaction: transaction,
                          currency: widget.currency,
                          onTap: () => _openEditTransactionModal(transaction),
                        );
                      }, childCount: widget.controller.transactions.length),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (activeColor ?? AppTheme.primaryLight)
                : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryMenu() {
    final allCategories = [
      'All',
      ...TransactionCategories.incomeCategories,
      ...TransactionCategories.expenseCategories,
      ...TransactionCategories.transferCategories,
    ];

    return PopupMenuButton<String>(
      tooltip: 'Filter by Category',
      initialValue: widget.controller.selectedCategory,
      onSelected: (cat) => widget.controller.setCategoryFilter(
        cat,
        businessId: widget.businessId,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.filter_list,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              widget.controller.selectedCategory == 'All'
                  ? 'Categories'
                  : widget.controller.selectedCategory,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return allCategories.map((cat) {
          return PopupMenuItem<String>(
            value: cat,
            child: Text(
              cat,
              style: TextStyle(
                fontSize: 13,
                color: cat == widget.controller.selectedCategory
                    ? AppTheme.primaryLight
                    : AppTheme.textPrimary,
                fontWeight: cat == widget.controller.selectedCategory
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildEmptyState() {
    final isFiltered =
        widget.controller.selectedTypeFilter != null ||
        widget.controller.selectedCategory != 'All' ||
        widget.controller.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No matching transactions' : 'No transactions yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try clearing your search query or filters to see all records.'
                  : 'Your financial picture starts with transactions. Import a CSV bank export or manually log your first transaction.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (isFiltered) ...[
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  widget.controller.setSearchQuery(
                    '',
                    businessId: widget.businessId,
                  );
                  widget.controller.setTypeFilter(
                    null,
                    businessId: widget.businessId,
                  );
                  widget.controller.setCategoryFilter(
                    'All',
                    businessId: widget.businessId,
                  );
                },
                child: const Text('Reset All Filters'),
              ),
            ] else ...[
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
          ],
        ),
      ),
    );
  }
}
