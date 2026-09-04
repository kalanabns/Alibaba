import 'package:flutter_test/flutter_test.dart';
import 'package:alibaba/features/transactions/data/sms_reader_service.dart';
import 'package:alibaba/features/transactions/data/sms_transaction_parser.dart';
import 'package:alibaba/features/transactions/domain/sms_candidate.dart';
import 'package:alibaba/features/transactions/domain/transaction.dart';

void main() {
  group('SmsTransactionParser — Financial SMS Detection', () {
    final now = DateTime.now();

    test('parses standard debit expense SMS with amount, merchant, and card mask', () {
      final raw = SmsRawMessage(
        id: 'sms-1',
        senderAddress: 'CHASE-BANK',
        body: 'Alert: \$85.50 was spent at Starbucks on card ending in 4821. Ref: CH9847291. Avl bal: \$4,210.00',
        timestamp: now,
      );

      final candidate = SmsTransactionParser.parse(raw);

      expect(candidate, isNotNull);
      expect(candidate!.amount, equals(85.50));
      expect(candidate.transactionType, equals(TransactionType.expense));
      expect(candidate.merchantName, contains('Starbucks'));
      expect(candidate.accountMask, equals('4821'));
      expect(candidate.referenceId, equals('CH9847291'));
      expect(candidate.category, equals('Food & Beverage'));
      expect(candidate.isHighConfidence, isTrue);
    });

    test('parses credit/salary income SMS correctly', () {
      final raw = SmsRawMessage(
        id: 'sms-2',
        senderAddress: 'WELLS-FARGO',
        body: 'Your account **5678 has been credited with USD 4,500.00 for Salary on 04-Sep. Txn ID: WF8839201.',
        timestamp: now,
      );

      final candidate = SmsTransactionParser.parse(raw);

      expect(candidate, isNotNull);
      expect(candidate!.amount, equals(4500.00));
      expect(candidate.transactionType, equals(TransactionType.income));
      expect(candidate.category, equals('Payroll & Salary'));
      expect(candidate.referenceId, equals('WF8839201'));
      expect(candidate.isHighConfidence, isTrue);
    });

    test('parses software SaaS cloud subscription expense', () {
      final raw = SmsRawMessage(
        id: 'sms-3',
        senderAddress: 'CITI',
        body: 'Paid USD 240.00 to AWS Cloud Services using card XX1092. Ref: AWS993821.',
        timestamp: now,
      );

      final candidate = SmsTransactionParser.parse(raw);

      expect(candidate, isNotNull);
      expect(candidate!.amount, equals(240.00));
      expect(candidate.transactionType, equals(TransactionType.expense));
      expect(candidate.category, equals('Software & Subscriptions'));
    });

    test('filters out non-financial OTP security messages', () {
      final raw = SmsRawMessage(
        id: 'sms-4',
        senderAddress: 'GOOGLE',
        body: 'G-492019 is your Google verification code. Do not share your OTP with anyone.',
        timestamp: now,
      );

      final candidate = SmsTransactionParser.parse(raw);
      expect(candidate, isNull);
    });

    test('candidate converts cleanly to domain Transaction model', () {
      final candidate = SmsTransactionCandidate(
        id: 'cand-1',
        senderAddress: 'BANK',
        rawBody: 'Paid \$150.00 at Staples',
        smsDate: now,
        amount: 150.00,
        transactionType: TransactionType.expense,
        category: 'Office Supplies',
        merchantName: 'Staples',
        referenceId: 'STP99201',
        confidence: 0.90,
      );

      final transaction = candidate.toTransaction(
        businessId: 'biz-123',
        currency: 'USD',
      );

      expect(transaction.businessId, equals('biz-123'));
      expect(transaction.amount, equals(150.00));
      expect(transaction.category, equals('Office Supplies'));
      expect(transaction.merchantName, equals('Staples'));
      expect(transaction.source, equals(TransactionSource.sms));
      expect(transaction.externalReference, equals('STP99201'));
      expect(transaction.paymentStatus, equals(PaymentStatus.paid));
    });
  });
}
