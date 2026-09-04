enum TransactionType { income, expense, transfer }

enum PaymentStatus { paid, pending, overdue, unknown }

enum TransactionSource { csv, sms, manual }

class Transaction {
  const Transaction({
    required this.id,
    required this.businessId,
    required this.transactionDate,
    required this.transactionType,
    required this.category,
    this.subcategory,
    required this.amount,
    this.currency = 'USD',
    this.description,
    this.merchantName,
    this.customerName,
    this.supplierName,
    this.paymentStatus = PaymentStatus.unknown,
    this.source = TransactionSource.manual,
    this.externalReference,
    this.rawText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      transactionType: TransactionType.values.firstWhere(
        (e) => e.name == json['transaction_type'],
        orElse: () => TransactionType.expense,
      ),
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'USD',
      description: json['description'] as String?,
      merchantName: json['merchant_name'] as String?,
      customerName: json['customer_name'] as String?,
      supplierName: json['supplier_name'] as String?,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.unknown,
      ),
      source: TransactionSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => TransactionSource.manual,
      ),
      externalReference: json['external_reference'] as String?,
      rawText: json['raw_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String businessId;
  final DateTime transactionDate;
  final TransactionType transactionType;
  final String category;
  final String? subcategory;
  final double amount;
  final String currency;
  final String? description;
  final String? merchantName;
  final String? customerName;
  final String? supplierName;
  final PaymentStatus paymentStatus;
  final TransactionSource source;
  final String? externalReference;
  final String? rawText;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'transaction_date': transactionDate.toIso8601String(),
      'transaction_type': transactionType.name,
      'category': category,
      'subcategory': subcategory,
      'amount': amount,
      'currency': currency,
      'description': description,
      'merchant_name': merchantName,
      'customer_name': customerName,
      'supplier_name': supplierName,
      'payment_status': paymentStatus.name,
      'source': source.name,
      'external_reference': externalReference,
      'raw_text': rawText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
