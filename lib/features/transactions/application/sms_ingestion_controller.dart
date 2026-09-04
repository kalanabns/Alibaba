import 'package:flutter/foundation.dart';
import '../data/sms_reader_service.dart';
import '../data/sms_transaction_parser.dart';
import '../data/transaction_repository.dart';
import '../domain/sms_candidate.dart';
import '../domain/transaction.dart';

class SmsIngestionController extends ChangeNotifier {
  SmsIngestionController({
    SmsReaderService? readerService,
    TransactionRepository? transactionRepository,
    this.onTransactionsChanged,
  })  : _readerService = readerService ?? SmsReaderService(),
        _transactionRepository = transactionRepository ?? TransactionRepository();

  final SmsReaderService _readerService;
  final TransactionRepository _transactionRepository;
  final VoidCallback? onTransactionsChanged;

  bool _isIngestionEnabled = true;
  bool _isLoading = false;
  String? _errorMessage;
  List<SmsTransactionCandidate> _candidates = [];

  bool get isIngestionEnabled => _isIngestionEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SmsTransactionCandidate> get candidates => _candidates;

  List<SmsTransactionCandidate> get pendingCandidates =>
      _candidates.where((c) => c.isPending && !c.isDuplicate).toList();

  List<SmsTransactionCandidate> get highConfidencePending =>
      _candidates.where((c) => c.isPending && c.isHighConfidence && !c.isDuplicate).toList();

  List<SmsTransactionCandidate> get approvedCandidates =>
      _candidates.where((c) => c.isApproved).toList();

  List<SmsTransactionCandidate> get duplicateCandidates =>
      _candidates.where((c) => c.isDuplicate).toList();

  void toggleIngestion(bool enabled) {
    _isIngestionEnabled = enabled;
    notifyListeners();
  }

  /// Scans device SMS inbox, parses financial transaction candidates, and filters duplicates.
  Future<void> scanInbox({
    required String businessId,
    required List<Transaction> existingTransactions,
    List<SmsRawMessage>? mockMessagesForTest,
  }) async {
    if (!_isIngestionEnabled) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<SmsRawMessage> messages;

      if (mockMessagesForTest != null) {
        messages = mockMessagesForTest;
      } else {
        bool hasPermission = await _readerService.checkPermission();
        if (!hasPermission) {
          hasPermission = await _readerService.requestPermission();
        }

        if (!hasPermission) {
          _errorMessage =
              'SMS read permission is required to detect financial transactions on Android. You can still import CSVs or add records manually.';
          _isLoading = false;
          notifyListeners();
          return;
        }

        messages = await _readerService.readInbox(limit: 60);
      }

      final List<SmsTransactionCandidate> parsedList = [];

      for (final raw in messages) {
        final parsed = SmsTransactionParser.parse(raw);
        if (parsed != null) {
          // Check for duplicate against existing Supabase transactions
          final isDup = _isDuplicateTransaction(parsed, existingTransactions);
          final candidate = isDup
              ? parsed.copyWith(status: SmsCandidateStatus.duplicate)
              : parsed;
          parsedList.add(candidate);
        }
      }

      _candidates = parsedList;
    } catch (e) {
      _errorMessage = 'Failed to scan SMS inbox: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approves a single transaction candidate and saves it to Supabase.
  Future<void> approveCandidate({
    required String businessId,
    required String currency,
    required SmsTransactionCandidate candidate,
  }) async {
    try {
      final transaction = candidate.toTransaction(
        businessId: businessId,
        currency: currency,
      );

      await _transactionRepository.createTransaction(
        businessId: transaction.businessId,
        transactionDate: transaction.transactionDate,
        transactionType: transaction.transactionType,
        category: transaction.category,
        subcategory: transaction.subcategory,
        amount: transaction.amount,
        currency: transaction.currency,
        description: transaction.description,
        merchantName: transaction.merchantName,
        customerName: transaction.customerName,
        supplierName: transaction.supplierName,
        paymentStatus: transaction.paymentStatus,
        source: transaction.source,
        externalReference: transaction.externalReference,
        rawText: transaction.rawText,
      );

      final index = _candidates.indexWhere((c) => c.id == candidate.id);
      if (index != -1) {
        _candidates[index] = _candidates[index].copyWith(
          status: SmsCandidateStatus.approved,
        );
        notifyListeners();
      }

      onTransactionsChanged?.call();
    } catch (e) {
      _errorMessage = 'Failed to approve SMS transaction: $e';
      notifyListeners();
    }
  }

  /// Batch approves all high-confidence pending candidates.
  Future<int> approveAllHighConfidence({
    required String businessId,
    required String currency,
  }) async {
    final toApprove = highConfidencePending;
    if (toApprove.isEmpty) return 0;

    _isLoading = true;
    notifyListeners();

    try {
      final transactions = toApprove
          .map((c) => c.toTransaction(businessId: businessId, currency: currency))
          .toList();

      final inserted = await _transactionRepository.createTransactionsBatch(
        businessId: businessId,
        transactions: transactions,
      );

      for (final item in toApprove) {
        final index = _candidates.indexWhere((c) => c.id == item.id);
        if (index != -1) {
          _candidates[index] = _candidates[index].copyWith(
            status: SmsCandidateStatus.approved,
          );
        }
      }

      onTransactionsChanged?.call();
      return inserted;
    } catch (e) {
      _errorMessage = 'Batch approval failed: $e';
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ignores or rejects an SMS candidate.
  void ignoreCandidate(String candidateId) {
    final index = _candidates.indexWhere((c) => c.id == candidateId);
    if (index != -1) {
      _candidates[index] = _candidates[index].copyWith(
        status: SmsCandidateStatus.ignored,
      );
      notifyListeners();
    }
  }

  bool _isDuplicateTransaction(
    SmsTransactionCandidate candidate,
    List<Transaction> existing,
  ) {
    for (final t in existing) {
      // 1. Check external reference match
      if (candidate.referenceId != null &&
          candidate.referenceId!.isNotEmpty &&
          t.externalReference != null &&
          t.externalReference!.toLowerCase() == candidate.referenceId!.toLowerCase()) {
        return true;
      }

      // 2. Fuzzy match on date, amount, and merchant
      final isSameDay = t.transactionDate.year == candidate.smsDate.year &&
          t.transactionDate.month == candidate.smsDate.month &&
          t.transactionDate.day == candidate.smsDate.day;
      final isSameAmount = (t.amount - candidate.amount).abs() < 0.01;
      final isSameType = t.transactionType == candidate.transactionType;

      if (isSameDay && isSameAmount && isSameType) {
        if (candidate.merchantName != null &&
            t.merchantName != null &&
            t.merchantName!.toLowerCase().contains(candidate.merchantName!.toLowerCase())) {
          return true;
        }
      }
    }
    return false;
  }
}
