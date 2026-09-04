import '../domain/transaction.dart';

enum SmsCandidateStatus { pending, approved, ignored, duplicate }

class SmsTransactionCandidate {
  const SmsTransactionCandidate({
    required this.id,
    required this.senderAddress,
    required this.rawBody,
    required this.smsDate,
    required this.amount,
    required this.transactionType,
    required this.category,
    this.merchantName,
    this.accountMask,
    this.referenceId,
    required this.confidence,
    this.status = SmsCandidateStatus.pending,
  });

  final String id;
  final String senderAddress;
  final String rawBody;
  final DateTime smsDate;
  final double amount;
  final TransactionType transactionType;
  final String category;
  final String? merchantName;
  final String? accountMask;
  final String? referenceId;
  final double confidence; // 0.0 to 1.0
  final SmsCandidateStatus status;

  bool get isHighConfidence => confidence >= 0.75;
  bool get isPending => status == SmsCandidateStatus.pending;
  bool get isApproved => status == SmsCandidateStatus.approved;
  bool get isIgnored => status == SmsCandidateStatus.ignored;
  bool get isDuplicate => status == SmsCandidateStatus.duplicate;

  SmsTransactionCandidate copyWith({
    String? id,
    String? senderAddress,
    String? rawBody,
    DateTime? smsDate,
    double? amount,
    TransactionType? transactionType,
    String? category,
    String? merchantName,
    String? accountMask,
    String? referenceId,
    double? confidence,
    SmsCandidateStatus? status,
  }) {
    return SmsTransactionCandidate(
      id: id ?? this.id,
      senderAddress: senderAddress ?? this.senderAddress,
      rawBody: rawBody ?? this.rawBody,
      smsDate: smsDate ?? this.smsDate,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      merchantName: merchantName ?? this.merchantName,
      accountMask: accountMask ?? this.accountMask,
      referenceId: referenceId ?? this.referenceId,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
    );
  }

  /// Converts this candidate into an approved domain [Transaction].
  Transaction toTransaction({
    required String businessId,
    required String currency,
  }) {
    return Transaction(
      id: '', // Will be assigned by database gen_random_uuid()
      businessId: businessId,
      transactionDate: smsDate,
      transactionType: transactionType,
      category: category,
      amount: amount,
      currency: currency,
      description: merchantName != null
          ? '$category payment: $merchantName'
          : '$category transaction via SMS',
      merchantName: transactionType == TransactionType.expense ? merchantName : null,
      customerName: transactionType == TransactionType.income ? merchantName : null,
      paymentStatus: PaymentStatus.paid,
      source: TransactionSource.sms,
      externalReference: referenceId ?? id,
      rawText: rawBody,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
