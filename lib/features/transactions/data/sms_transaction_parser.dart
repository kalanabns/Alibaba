import '../domain/sms_candidate.dart';
import '../domain/transaction.dart';
import 'sms_reader_service.dart';

class SmsTransactionParser {
  // Regex to match monetary amounts across global currency formats
  static final RegExp _amountRegex = RegExp(
    r'(?:(?:[\$€£₹]|USD|EUR|GBP|INR|Rs\.?|AUD|CAD|AED|SGD)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)|(?:amount(?:\s+of)?\s*:?\s*(?:[\$€£₹]|USD|EUR|GBP|INR|Rs\.?)?\s*([0-9,]+(?:\.[0-9]{1,2})?))|([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)\s*(?:USD|EUR|GBP|INR|AED|SGD))',
    caseSensitive: false,
  );

  // Regex patterns for transaction types
  static final RegExp _debitRegex = RegExp(
    r'\b(?:debited|spent|paid|payment(?:\s+of)?|charged|purchase|sent\s+to|withdrawn|pos\s+txn|autopay|deducted)\b',
    caseSensitive: false,
  );

  static final RegExp _creditRegex = RegExp(
    r'\b(?:credited|received|deposited|refunded|salary|cashback|added\s+to|inward\s+remitt|funds?\s+received)\b',
    caseSensitive: false,
  );

  static final RegExp _transferRegex = RegExp(
    r'\b(?:transferred\s+to\s+(?:self|own)|a/c\s+to\s+a/c|internal\s+transfer|own\s+account)\b',
    caseSensitive: false,
  );

  // OTP / Verification filter (skip non-transaction OTPs)
  static final RegExp _otpFilterRegex = RegExp(
    r'\b(?:otp|one\s*time\s*password|verification\s*code|security\s*code|login\s*code|do\s*not\s*share)\b',
    caseSensitive: false,
  );

  // Reference / Transaction ID regex
  static final RegExp _refRegex = RegExp(
    r'(?:ref(?:\s*no\.?)?|reference|txn(?:\s*id)?|rrn|upi(?:\s*ref)?|id)[\s:#]*([A-Za-z0-9]{6,25})',
    caseSensitive: false,
  );

  // Account / Card mask regex
  static final RegExp _accountRegex = RegExp(
    r'(?:a/c|acct|account|card|ending(?:\s+in)?)\s*[:#\*\s]*([0-9xX\*]{3,8})',
    caseSensitive: false,
  );

  // Merchant / Counterparty regex
  static final RegExp _merchantRegex = RegExp(
    r'(?:at|to|for|vpa|info|merchant)\s+([A-Za-z0-9\.\-\s]{3,28}?)(?:\s+on|\s+ref|\s+txn|\s+avl|\s+bal|\s+via|\.|\,|$)',
    caseSensitive: false,
  );

  /// Parses an incoming SMS message. Returns [SmsTransactionCandidate] if the message is a valid financial transaction,
  /// or `null` if the message is non-financial (e.g. OTP, promotional, social text).
  static SmsTransactionCandidate? parse(SmsRawMessage sms) {
    final body = sms.body.trim();
    if (body.isEmpty) return null;

    // 1. Skip non-transactional OTP messages
    if (_otpFilterRegex.hasMatch(body) && !_debitRegex.hasMatch(body) && !_creditRegex.hasMatch(body)) {
      return null;
    }

    // 2. Extract Amount
    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    // 3. Determine Transaction Type
    TransactionType type = TransactionType.expense;
    double confidenceScore = 0.40; // Base score for valid amount

    if (_transferRegex.hasMatch(body)) {
      type = TransactionType.transfer;
      confidenceScore += 0.30;
    } else if (_creditRegex.hasMatch(body)) {
      type = TransactionType.income;
      confidenceScore += 0.30;
    } else if (_debitRegex.hasMatch(body)) {
      type = TransactionType.expense;
      confidenceScore += 0.30;
    } else {
      // Ambiguous type without clear debit/credit word
      confidenceScore -= 0.10;
    }

    // 4. Extract Reference ID
    final refMatch = _refRegex.firstMatch(body);
    final referenceId = refMatch?.group(1)?.trim();
    if (referenceId != null && referenceId.isNotEmpty) {
      confidenceScore += 0.15;
    }

    // 5. Extract Account Mask
    final acctMatch = _accountRegex.firstMatch(body);
    final accountMask = acctMatch?.group(1)?.trim();
    if (accountMask != null && accountMask.isNotEmpty) {
      confidenceScore += 0.10;
    }

    // 6. Extract Merchant / Beneficiary
    final merchantMatch = _merchantRegex.firstMatch(body);
    String? merchant = merchantMatch?.group(1)?.trim();
    if (merchant != null && (merchant.toLowerCase().startsWith('ref') || merchant.length < 2)) {
      merchant = null;
    }
    if (merchant != null && merchant.isNotEmpty) {
      confidenceScore += 0.05;
    }

    // 7. Classify Category
    final category = _classifyCategory(body, merchant, type);

    final clampedConfidence = confidenceScore.clamp(0.10, 1.00);

    return SmsTransactionCandidate(
      id: sms.id.isNotEmpty ? sms.id : 'sms_${sms.timestamp.millisecondsSinceEpoch}',
      senderAddress: sms.senderAddress,
      rawBody: body,
      smsDate: sms.timestamp,
      amount: amount,
      transactionType: type,
      category: category,
      merchantName: merchant,
      accountMask: accountMask,
      referenceId: referenceId,
      confidence: clampedConfidence,
      status: SmsCandidateStatus.pending,
    );
  }

  static double? _extractAmount(String text) {
    final match = _amountRegex.firstMatch(text);
    if (match == null) return null;

    final rawStr = match.group(1) ?? match.group(2) ?? match.group(3);
    if (rawStr == null) return null;

    final cleaned = rawStr.replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }

  static String _classifyCategory(String body, String? merchant, TransactionType type) {
    final combined = '${body.toLowerCase()} ${merchant?.toLowerCase() ?? ""}';

    if (type == TransactionType.income) {
      if (combined.contains('salary') || combined.contains('payroll')) return 'Payroll & Salary';
      if (combined.contains('refund') || combined.contains('cashback')) return 'Refunds & Returns';
      if (combined.contains('invoice') || combined.contains('client') || combined.contains('payment from')) {
        return 'Client Services';
      }
      return 'Sales Revenue';
    }

    if (combined.contains('aws') ||
        combined.contains('google cloud') ||
        combined.contains('github') ||
        combined.contains('figma') ||
        combined.contains('slack') ||
        combined.contains('zoom') ||
        combined.contains('software') ||
        combined.contains('microsoft') ||
        combined.contains('apple.com')) {
      return 'Software & Subscriptions';
    }

    if (combined.contains('uber') ||
        combined.contains('lyft') ||
        combined.contains('airline') ||
        combined.contains('flight') ||
        combined.contains('hotel') ||
        combined.contains('fuel') ||
        combined.contains('petrol') ||
        combined.contains('gas')) {
      return 'Travel & Logistics';
    }

    if (combined.contains('meta') ||
        combined.contains('facebook ads') ||
        combined.contains('google ads') ||
        combined.contains('advertising') ||
        combined.contains('marketing') ||
        combined.contains('adwords')) {
      return 'Marketing & Advertising';
    }

    if (combined.contains('rent') ||
        combined.contains('lease') ||
        combined.contains('electric') ||
        combined.contains('utility') ||
        combined.contains('power') ||
        combined.contains('water')) {
      return 'Rent & Facilities';
    }

    if (combined.contains('food') ||
        combined.contains('restaurant') ||
        combined.contains('cafe') ||
        combined.contains('coffee') ||
        combined.contains('doordash') ||
        combined.contains('starbucks')) {
      return 'Food & Beverage';
    }

    if (combined.contains('amazon') ||
        combined.contains('staples') ||
        combined.contains('hardware') ||
        combined.contains('office') ||
        combined.contains('supplies')) {
      return 'Office Supplies';
    }

    return 'Operations';
  }
}
