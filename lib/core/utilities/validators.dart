class Validators {
  const Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final email = value.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? validateStartingCash(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Starting cash is required.';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid numeric amount.';
    }
    if (parsed < 0) {
      return 'Starting cash cannot be negative.';
    }
    return null;
  }

  static double parseStartingCash(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      throw FormatException('Invalid starting cash amount: $value');
    }
    return parsed;
  }

  static int monthNameToInteger(String month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final index = months.indexOf(month.trim());
    if (index == -1) {
      return 1;
    }
    return index + 1;
  }
}
