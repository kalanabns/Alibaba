import 'package:flutter/foundation.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

enum TransactionListState { initial, loading, loaded, error }

class TransactionController extends ChangeNotifier {
  TransactionController({
    TransactionRepository? repository,
    this.onTransactionsChanged,
  }) : _repository = repository ?? TransactionRepository();

  final TransactionRepository _repository;
  final VoidCallback? onTransactionsChanged;

  TransactionListState _state = TransactionListState.initial;
  List<Transaction> _transactions = [];
  String? _errorMessage;
  bool _isPerformingAction = false;

  // Filters
  TransactionType? _selectedTypeFilter;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  TransactionListState get state => _state;
  List<Transaction> get transactions => _transactions;
  String? get errorMessage => _errorMessage;
  bool get isPerformingAction => _isPerformingAction;
  TransactionType? get selectedTypeFilter => _selectedTypeFilter;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> loadTransactions({
    required String businessId,
    bool silent = false,
  }) async {
    if (!silent) {
      _state = TransactionListState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final list = await _repository.getTransactions(
        businessId: businessId,
        type: _selectedTypeFilter,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        limit: 250,
      );

      _transactions = list;
      _state = TransactionListState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = TransactionListState.error;
    }

    notifyListeners();
  }

  void setTypeFilter(TransactionType? type, {required String businessId}) {
    _selectedTypeFilter = type;
    loadTransactions(businessId: businessId);
  }

  void setCategoryFilter(String category, {required String businessId}) {
    _selectedCategory = category;
    loadTransactions(businessId: businessId);
  }

  void setSearchQuery(String query, {required String businessId}) {
    _searchQuery = query;
    loadTransactions(businessId: businessId);
  }

  Future<bool> addTransaction({
    required String businessId,
    required DateTime transactionDate,
    required TransactionType transactionType,
    required String category,
    required double amount,
    String? subcategory,
    String currency = 'USD',
    String? description,
    String? merchantName,
    String? customerName,
    String? supplierName,
    PaymentStatus paymentStatus = PaymentStatus.unknown,
    String? externalReference,
  }) async {
    _isPerformingAction = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createTransaction(
        businessId: businessId,
        transactionDate: transactionDate,
        transactionType: transactionType,
        category: category,
        amount: amount,
        subcategory: subcategory,
        currency: currency,
        description: description,
        merchantName: merchantName,
        customerName: customerName,
        supplierName: supplierName,
        paymentStatus: paymentStatus,
        source: TransactionSource.manual,
        externalReference: externalReference,
      );

      _isPerformingAction = false;
      await loadTransactions(businessId: businessId, silent: true);
      onTransactionsChanged?.call();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    _isPerformingAction = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateTransaction(transaction);
      _isPerformingAction = false;
      await loadTransactions(businessId: transaction.businessId, silent: true);
      onTransactionsChanged?.call();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction({
    required String id,
    required String businessId,
  }) async {
    _isPerformingAction = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteTransaction(id: id, businessId: businessId);
      _isPerformingAction = false;
      await loadTransactions(businessId: businessId, silent: true);
      onTransactionsChanged?.call();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isPerformingAction = false;
      notifyListeners();
      return false;
    }
  }

  Future<int> importBatch({
    required String businessId,
    required List<Transaction> transactions,
  }) async {
    _isPerformingAction = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final insertedCount = await _repository.createTransactionsBatch(
        businessId: businessId,
        transactions: transactions,
      );

      _isPerformingAction = false;
      await loadTransactions(businessId: businessId, silent: true);
      onTransactionsChanged?.call();
      notifyListeners();
      return insertedCount;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isPerformingAction = false;
      notifyListeners();
      rethrow;
    }
  }
}
