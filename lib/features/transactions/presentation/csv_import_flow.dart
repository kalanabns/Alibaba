import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/money_formatter.dart';
import '../../../shared/widgets/finora_primary_button.dart';
import '../data/csv_parser.dart';
import '../domain/transaction.dart';

class CsvImportFlow extends StatefulWidget {
  const CsvImportFlow({
    super.key,
    required this.businessId,
    required this.currency,
    this.existingTransactions,
    required this.onImportComplete,
  });

  final String businessId;
  final String currency;
  final List<Transaction>? existingTransactions;
  final Future<int> Function(List<Transaction> transactions) onImportComplete;

  @override
  State<CsvImportFlow> createState() => _CsvImportFlowState();
}

class _CsvImportFlowState extends State<CsvImportFlow> {
  int _currentStep =
      0; // 0: Select/Input, 1: Map Columns, 2: Validate & Preview, 3: Completed
  final _csvTextController = TextEditingController();

  List<String> _headers = [];
  List<List<String>> _rawRows = [];
  late CsvColumnMapping _mapping;
  CsvParseResult? _parseResult;

  bool _isImporting = false;
  String? _errorMessage;
  int _importedCount = 0;

  static const String _demoCsvData =
      '''Date,Description,Category,Amount,Reference
2026-08-01,Enterprise Client Retainer,Sales Revenue,14500.00,INV-8801
2026-08-03,Office Space Lease,Rent,-3200.00,RENT-AUG
2026-08-05,Product Engineering Payroll,Payroll,-12800.00,PAY-260805
2026-08-08,SaaS Platform Subscriptions,Software,-650.00,SUB-2026
2026-08-10,Direct Service Consulting,Service Revenue,8900.00,INV-8802
2026-08-12,Electricity & Fiber Internet,Utilities,-420.00,UTIL-AUG
2026-08-15,Digital Marketing Campaign,Marketing,-1850.00,MKT-0815
2026-08-18,Wholesale Inventory Supplies,Inventory,-4500.00,PO-9912
2026-08-20,Quarterly Business Insurance,Insurance,-850.00,INS-Q3
2026-08-22,Client Milestone Delivery,Sales Revenue,16800.00,INV-8803
2026-08-25,Equipment Maintenance & Office,Supplies,-380.00,SUP-884
2026-08-28,Legal & Accounting Advisory,Professional Services,-1200.00,ADV-AUG
2026-08-30,E-commerce Sales Payout,Sales Revenue,11250.00,PAYOUT-889''';

  @override
  void dispose() {
    _csvTextController.dispose();
    super.dispose();
  }

  void _loadDemoData() {
    setState(() {
      _csvTextController.text = _demoCsvData;
    });
  }

  void _processCsvText() {
    final text = _csvTextController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please paste CSV content or load sample data.';
      });
      return;
    }

    try {
      final parsed = CsvParser.parseCsvString(text);
      if (parsed.isEmpty) {
        setState(() {
          _errorMessage = 'CSV content is empty or unreadable.';
        });
        return;
      }

      final headers = parsed.first;
      final rows = parsed.skip(1).toList();

      if (rows.isEmpty) {
        setState(() {
          _errorMessage = 'CSV contains only headers and no transaction rows.';
        });
        return;
      }

      final autoMapping = CsvParser.autoDetectMapping(headers);

      setState(() {
        _headers = headers;
        _rawRows = rows;
        _mapping = autoMapping;
        _errorMessage = null;
        _currentStep = 1; // Move to mapping step
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to parse CSV: $e';
      });
    }
  }

  void _runValidation() {
    if (!_mapping.isValid()) {
      setState(() {
        _errorMessage =
            'Please ensure Date and Amount column mappings are selected.';
      });
      return;
    }

    final result = CsvParser.processRows(
      headers: _headers,
      rawRows: _rawRows,
      mapping: _mapping,
      businessId: widget.businessId,
      currency: widget.currency,
      existingTransactions: widget.existingTransactions,
    );

    setState(() {
      _parseResult = result;
      _errorMessage = null;
      _currentStep = 2; // Move to preview & validation step
    });
  }

  Future<void> _executeImport() async {
    if (_parseResult == null || _parseResult!.validRows.isEmpty) return;

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    final validTransactions = _parseResult!.validRows
        .map((r) => r.transaction!)
        .toList();

    try {
      final count = await widget.onImportComplete(validTransactions);
      setState(() {
        _importedCount = count;
        _isImporting = false;
        _currentStep = 3; // Completed step
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _errorMessage = 'Import failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stepper Header
            _buildStepperHeader(),
            const Divider(height: 24),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Step Body
            Expanded(child: _buildCurrentStepBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final stepTitles = ['Select Data', 'Map Columns', 'Validate', 'Complete'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: List.generate(stepTitles.length, (index) {
            final isDone = _currentStep > index;
            final isCurrent = _currentStep == index;
            final color = isDone || isCurrent
                ? AppTheme.primaryColor
                : AppTheme.textMuted;

            return Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.primaryColor
                        : (isCurrent
                              ? AppTheme.primaryColor.withValues(alpha: 0.2)
                              : AppTheme.surfaceElevated),
                    shape: BoxShape.circle,
                    border: Border.all(color: color),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Color(0xFF042F2E),
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppTheme.primaryLight
                                  : AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  stepTitles[index],
                  style: TextStyle(
                    color: isCurrent
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (index < stepTitles.length - 1) ...[
                  Container(
                    width: 20,
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: AppTheme.borderColor,
                  ),
                ],
              ],
            );
          }),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          onPressed: () => Navigator.of(context).pop(_currentStep == 3),
        ),
      ],
    );
  }

  Widget _buildCurrentStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildStep1SelectData();
      case 1:
        return _buildStep2MapColumns();
      case 2:
        return _buildStep3ValidateAndPreview();
      case 3:
        return _buildStep4Summary();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Paste or Load CSV
  Widget _buildStep1SelectData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Import Bank or Accounting CSV',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Paste your CSV export or test with Finora realistic sample transactions.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _csvTextController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Date,Description,Category,Amount\n2026-08-01,Client Retainer,Sales Revenue,4250.00...',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _loadDemoData,
              icon: const Icon(
                Icons.auto_fix_high,
                size: 18,
                color: AppTheme.primaryLight,
              ),
              label: const Text('Load Demo CSV Sample'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _processCsvText,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continue to Mapping'),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 2: Map Columns
  Widget _buildStep2MapColumns() {
    final previewRows = _rawRows.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Confirm Column Mappings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Finora auto-detected the headers below. Adjust if necessary.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          // Strategy selection
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Amount Strategy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStrategyTile(
                  strategy: CsvAmountStrategy.singleSignedAmount,
                  title:
                      'Single Signed Amount (Positive = Income, Negative = Expense)',
                ),
                const SizedBox(height: 6),
                _buildStrategyTile(
                  strategy: CsvAmountStrategy.separateDebitCreditColumns,
                  title:
                      'Separate Debit and Credit Columns (Standard Bank Format)',
                ),
                const SizedBox(height: 6),
                _buildStrategyTile(
                  strategy: CsvAmountStrategy.singleAmountWithTypeColumn,
                  title: 'Single Amount Column with Direction / Type Column',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Mapping Dropdowns
          _buildDropdownField(
            label: 'Transaction Date Column *',
            value: _mapping.dateColumn,
            onChanged: (val) => setState(() => _mapping.dateColumn = val ?? ''),
          ),
          const SizedBox(height: 12),
          if (_mapping.amountStrategy ==
              CsvAmountStrategy.separateDebitCreditColumns) ...[
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    label: 'Debit (Expense) Column *',
                    value: _mapping.debitColumn,
                    onChanged: (val) =>
                        setState(() => _mapping.debitColumn = val ?? ''),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownField(
                    label: 'Credit (Income) Column *',
                    value: _mapping.creditColumn,
                    onChanged: (val) =>
                        setState(() => _mapping.creditColumn = val ?? ''),
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildDropdownField(
              label: 'Amount Column *',
              value: _mapping.amountColumn,
              onChanged: (val) =>
                  setState(() => _mapping.amountColumn = val ?? ''),
            ),
          ],
          if (_mapping.amountStrategy ==
              CsvAmountStrategy.singleAmountWithTypeColumn) ...[
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Transaction Type Column *',
              value: _mapping.typeColumn,
              onChanged: (val) =>
                  setState(() => _mapping.typeColumn = val ?? ''),
            ),
          ],
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Description / Narration Column',
            value: _mapping.descriptionColumn,
            onChanged: (val) =>
                setState(() => _mapping.descriptionColumn = val ?? ''),
            allowEmpty: true,
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Category Column',
            value: _mapping.categoryColumn,
            onChanged: (val) =>
                setState(() => _mapping.categoryColumn = val ?? ''),
            allowEmpty: true,
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Reference / Transaction ID Column',
            value: _mapping.referenceColumn,
            onChanged: (val) =>
                setState(() => _mapping.referenceColumn = val ?? ''),
            allowEmpty: true,
          ),
          const SizedBox(height: 16),
          // Raw Preview Table
          const Text(
            'Raw Data Preview (First 5 Rows)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 36,
                columns: _headers
                    .map(
                      (h) => DataColumn(
                        label: Text(
                          h,
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: previewRows.map((row) {
                  return DataRow(
                    cells: List.generate(_headers.length, (colIdx) {
                      final cellText = colIdx < row.length ? row[colIdx] : '';
                      return DataCell(
                        Text(
                          cellText,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: const Text('Back'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _runValidation,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Validate & Preview'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyTile({
    required CsvAmountStrategy strategy,
    required String title,
  }) {
    final isSelected = _mapping.amountStrategy == strategy;
    return InkWell(
      onTap: () => setState(() => _mapping.amountStrategy = strategy),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
    bool allowEmpty = false,
  }) {
    final items = <DropdownMenuItem<String>>[];
    if (allowEmpty) {
      items.add(const DropdownMenuItem(value: '', child: Text('— None —')));
    }
    for (final h in _headers) {
      items.add(DropdownMenuItem(value: h, child: Text(h)));
    }

    final selectedValue = items.any((item) => item.value == value)
        ? value
        : (allowEmpty ? '' : _headers.first);

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // STEP 3: Validate & Preview
  Widget _buildStep3ValidateAndPreview() {
    final res = _parseResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary KPI Banner
        Row(
          children: [
            Expanded(
              child: _buildBadgeCard(
                title: 'Total Rows',
                value: '${res.totalCount}',
                color: AppTheme.textPrimary,
                icon: Icons.list_alt,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBadgeCard(
                title: 'Valid Rows',
                value: '${res.validCount}',
                color: AppTheme.accentColor,
                icon: Icons.check_circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBadgeCard(
                title: 'Invalid Rows',
                value: '${res.invalidCount}',
                color: res.invalidCount > 0
                    ? AppTheme.errorColor
                    : AppTheme.textMuted,
                icon: Icons.warning_amber,
              ),
            ),
          ],
        ),
        if (res.duplicateCount > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.warningColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${res.duplicateCount} probable duplicate transactions detected in your existing records.',
                  style: const TextStyle(
                    color: AppTheme.warningColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Valid Transactions Preview
        const Text(
          'Transactions to Import',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: res.rows.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final row = res.rows[idx];
                if (!row.isValid) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.error,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    title: Text(
                      'Row #${row.rowIndex}: ${row.errorMessage}',
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      row.rawRow.values.join(' | '),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }

                final t = row.transaction!;
                final isIncome = t.isIncome;
                final dateStr =
                    '${t.transactionDate.year}-${t.transactionDate.month.toString().padLeft(2, '0')}-${t.transactionDate.day.toString().padLeft(2, '0')}';

                return ListTile(
                  dense: true,
                  leading: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome
                        ? AppTheme.accentColor
                        : AppTheme.errorColor,
                    size: 18,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.displayTitle,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}${MoneyFormatter.format(t.amount, currency: widget.currency)}',
                        style: TextStyle(
                          color: isIncome
                              ? AppTheme.accentColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.category,
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 11,
                        ),
                      ),
                      if (row.isDuplicate) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DUPLICATE?',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(
              onPressed: _isImporting
                  ? null
                  : () => setState(() => _currentStep = 1),
              child: const Text('Back to Mapping'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: (_isImporting || res.validCount == 0)
                  ? null
                  : _executeImport,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(
                _isImporting
                    ? 'Importing...'
                    : 'Import ${res.validCount} Transactions',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 4: Summary
  Widget _buildStep4Summary() {
    final res = _parseResult!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.accentColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Import Complete!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_importedCount transactions successfully imported into your Finora workspace.',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Imported Count',
                  '$_importedCount transactions',
                ),
                const Divider(),
                _buildSummaryRow(
                  'Total Income',
                  '+${MoneyFormatter.format(res.totalIncome, currency: widget.currency)}',
                  color: AppTheme.accentColor,
                ),
                const Divider(),
                _buildSummaryRow(
                  'Total Expenses',
                  '-${MoneyFormatter.format(res.totalExpenses, currency: widget.currency)}',
                  color: AppTheme.errorColor,
                ),
                if (res.invalidCount > 0) ...[
                  const Divider(),
                  _buildSummaryRow(
                    'Skipped (Invalid)',
                    '${res.invalidCount} rows',
                    color: AppTheme.warningColor,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          FinoraPrimaryButton(
            text: 'View in Transactions',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
