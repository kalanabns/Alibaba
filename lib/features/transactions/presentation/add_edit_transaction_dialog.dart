import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utilities/money_formatter.dart';
import '../../../shared/widgets/finora_primary_button.dart';
import '../../../shared/widgets/finora_text_field.dart';
import '../data/csv_parser.dart';
import '../domain/transaction.dart';

class AddEditTransactionDialog extends StatefulWidget {
  const AddEditTransactionDialog({
    super.key,
    required this.businessId,
    required this.currency,
    this.initialTransaction,
    required this.onSave,
    this.onDelete,
  });

  final String businessId;
  final String currency;
  final Transaction? initialTransaction;
  final Future<bool> Function(Transaction transaction) onSave;
  final Future<bool> Function(String transactionId)? onDelete;

  @override
  State<AddEditTransactionDialog> createState() =>
      _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState extends State<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _selectedType;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late PaymentStatus _selectedPaymentStatus;

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _merchantController;
  late final TextEditingController _referenceController;

  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  bool get isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTransaction;

    _selectedType = init?.transactionType ?? TransactionType.expense;
    _selectedDate = init?.transactionDate ?? DateTime.now();
    _selectedPaymentStatus = init?.paymentStatus ?? PaymentStatus.paid;

    final categories = TransactionCategories.getCategoriesForType(
      _selectedType,
    );
    _selectedCategory =
        init?.category != null && categories.contains(init!.category)
        ? init.category
        : categories.first;

    _amountController = TextEditingController(
      text: init != null ? init.amount.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(
      text: init?.description ?? '',
    );
    _merchantController = TextEditingController(
      text:
          init?.merchantName ?? init?.customerName ?? init?.supplierName ?? '',
    );
    _referenceController = TextEditingController(
      text: init?.externalReference ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    setState(() {
      _selectedType = newType;
      final categories = TransactionCategories.getCategoriesForType(newType);
      _selectedCategory = categories.first;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(data: AppTheme.lightTheme, child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = CsvParser.parseMoney(_amountController.text);
    if (rawAmount == null || rawAmount <= 0) {
      setState(() {
        _errorMessage = 'Amount must be a positive number greater than 0.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final now = DateTime.now().toUtc();
    final transaction = Transaction(
      id: widget.initialTransaction?.id ?? '',
      businessId: widget.businessId,
      transactionDate: _selectedDate,
      transactionType: _selectedType,
      category: _selectedCategory,
      amount: rawAmount,
      currency: widget.currency,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      merchantName:
          _selectedType == TransactionType.expense &&
              _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : null,
      customerName:
          _selectedType == TransactionType.income &&
              _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : null,
      paymentStatus: _selectedPaymentStatus,
      source: widget.initialTransaction?.source ?? TransactionSource.manual,
      externalReference: _referenceController.text.trim().isNotEmpty
          ? _referenceController.text.trim()
          : null,
      createdAt: widget.initialTransaction?.createdAt ?? now,
      updatedAt: now,
    );

    final success = await widget.onSave(transaction);
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.initialTransaction == null || widget.onDelete == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action will update your financial metrics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isDeleting = true;
      });
      final success = await widget.onDelete!(widget.initialTransaction!.id);
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        if (success) {
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = TransactionCategories.getCategoriesForType(
      _selectedType,
    );
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final currencySymbol = MoneyFormatter.getCurrencySymbol(widget.currency);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Transaction' : 'New Transaction',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const Divider(height: 16),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                // Transaction Type Selector
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeSegment(
                        type: TransactionType.expense,
                        label: 'Expense',
                        icon: Icons.arrow_upward_rounded,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeSegment(
                        type: TransactionType.income,
                        label: 'Income',
                        icon: Icons.arrow_downward_rounded,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeSegment(
                        type: TransactionType.transfer,
                        label: 'Transfer',
                        icon: Icons.swap_horiz_rounded,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Amount Field
                FinoraTextField(
                  controller: _amountController,
                  label: 'Amount ($currencySymbol)',
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.attach_money,
                  enabled: !_isSaving && !_isDeleting,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Amount is required.';
                    }
                    final parsed = CsvParser.parseMoney(val);
                    if (parsed == null || parsed <= 0) {
                      return 'Please enter a valid positive amount.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Date & Payment Status in Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: (_isSaving || _isDeleting) ? null : _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                          ),
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<PaymentStatus>(
                        initialValue: _selectedPaymentStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                        ),
                        items: PaymentStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.name.toUpperCase(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (_isSaving || _isDeleting)
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() => _selectedPaymentStatus = val);
                                }
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: categories.contains(_selectedCategory)
                      ? _selectedCategory
                      : categories.first,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.label_outline, size: 18),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (_isSaving || _isDeleting)
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                ),
                const SizedBox(height: 14),
                // Description
                FinoraTextField(
                  controller: _descriptionController,
                  label: 'Description / Memo',
                  hint: 'e.g. Monthly cloud server costs',
                  prefixIcon: Icons.notes_outlined,
                  enabled: !_isSaving && !_isDeleting,
                ),
                const SizedBox(height: 14),
                // Merchant / Customer / Counterparty
                FinoraTextField(
                  controller: _merchantController,
                  label: _selectedType == TransactionType.income
                      ? 'Customer'
                      : 'Merchant / Payee',
                  hint: 'e.g. Acme Tech, Inc.',
                  prefixIcon: Icons.person_outline,
                  enabled: !_isSaving && !_isDeleting,
                ),
                const SizedBox(height: 14),
                // Reference Number
                FinoraTextField(
                  controller: _referenceController,
                  label: 'Reference Number (Optional)',
                  hint: 'e.g. INV-2026-004',
                  prefixIcon: Icons.tag,
                  enabled: !_isSaving && !_isDeleting,
                ),
                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  children: [
                    if (isEditing && widget.onDelete != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_isSaving || _isDeleting)
                              ? null
                              : _handleDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                          ),
                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: FinoraPrimaryButton(
                        text: isEditing
                            ? 'Update Transaction'
                            : 'Save Transaction',
                        isLoading: _isSaving,
                        onPressed: _handleSave,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required TransactionType type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: (_isSaving || _isDeleting) ? null : () => _onTypeChanged(type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
