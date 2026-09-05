class MoneyFormatter {
  const MoneyFormatter._();

  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'AED': 'AED ',
    'SGD': 'S\$',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'LKR': 'Rs. ',
  };

  static String getCurrencySymbol(String currencyCode) {
    final code = currencyCode.toUpperCase().trim();
    return _currencySymbols[code] ?? '$code ';
  }

  /// Formats amount with comma grouping and 2 decimal places.
  /// Example: format(1250.50, currency: 'USD') -> "$1,250.50"
  /// Example: format(-780, currency: 'USD', showSign: true) -> "-$780.00"
  /// Example: format(4250, currency: 'USD', showSign: true) -> "+$4,250.00"
  static String format(
    double amount, {
    String currency = 'USD',
    bool showSign = false,
    int decimals = 2,
    bool compact = false,
  }) {
    if (compact) {
      return formatCompact(amount, currency: currency, showSign: showSign);
    }

    final symbol = getCurrencySymbol(currency);
    final isNegative = amount < 0;
    final isPositive = amount > 0;
    final absAmount = amount.abs();

    final parts = absAmount.toStringAsFixed(decimals).split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    final buffer = StringBuffer();
    final length = integerPart.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    final formattedNumber = decimals > 0
        ? '${buffer.toString()}.$decimalPart'
        : buffer.toString();

    if (isNegative) {
      return '-$symbol$formattedNumber';
    } else if (showSign && isPositive) {
      return '+$symbol$formattedNumber';
    }
    return '$symbol$formattedNumber';
  }

  /// Formats large numbers compactly for dashboard KPI cards (e.g. $84.2K, $1.5M).
  static String formatCompact(
    double amount, {
    String currency = 'USD',
    bool showSign = false,
  }) {
    final symbol = getCurrencySymbol(currency);
    final isNegative = amount < 0;
    final isPositive = amount > 0;
    final absAmount = amount.abs();

    String formatted;
    if (absAmount >= 1000000000) {
      formatted = '${(absAmount / 1000000000).toStringAsFixed(1)}B';
    } else if (absAmount >= 1000000) {
      formatted = '${(absAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 10000) {
      formatted = '${(absAmount / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = absAmount.toStringAsFixed(0);
    }

    // Clean up trailing .0 in compact (e.g. 1.0K -> 1K)
    if (formatted.contains('.0')) {
      formatted = formatted.replaceFirst('.0', '');
    }

    if (isNegative) {
      return '-$symbol$formatted';
    } else if (showSign && isPositive) {
      return '+$symbol$formatted';
    }
    return '$symbol$formatted';
  }

  /// Formats a percentage with optional sign.
  /// Example: formatPercent(8.43, showSign: true) -> "+8.4%"
  static String formatPercent(
    double percent, {
    bool showSign = true,
    int decimals = 1,
  }) {
    if (percent.isNaN || percent.isInfinite) {
      return '0.0%';
    }
    final formatted = percent.abs().toStringAsFixed(decimals);
    if (percent < 0) {
      return '-$formatted%';
    } else if (showSign && percent > 0) {
      return '+$formatted%';
    }
    return '$formatted%';
  }
}
