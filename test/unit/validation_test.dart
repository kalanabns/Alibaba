import 'package:alibaba/core/utilities/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators — Email', () {
    test('returns error for empty email', () {
      expect(Validators.validateEmail(''), 'Email is required.');
      expect(Validators.validateEmail(null), 'Email is required.');
    });

    test('returns error for invalid email format', () {
      expect(Validators.validateEmail('invalid-email'), 'Please enter a valid email address.');
      expect(Validators.validateEmail('user@domain'), 'Please enter a valid email address.');
      expect(Validators.validateEmail('@domain.com'), 'Please enter a valid email address.');
    });

    test('returns null for valid email address', () {
      expect(Validators.validateEmail('owner@business.com'), null);
      expect(Validators.validateEmail('  test.user@company.co.uk  '), null);
    });
  });

  group('Validators — Password', () {
    test('returns error for empty password', () {
      expect(Validators.validatePassword(''), 'Password is required.');
      expect(Validators.validatePassword(null), 'Password is required.');
    });

    test('returns error for short password (<6 chars)', () {
      expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters long.');
    });

    test('returns null for valid password (>=6 chars)', () {
      expect(Validators.validatePassword('secret123'), null);
    });

    test('validates password matching', () {
      expect(
        Validators.validateConfirmPassword('secret123', 'different'),
        'Passwords do not match.',
      );
      expect(
        Validators.validateConfirmPassword('secret123', 'secret123'),
        null,
      );
    });
  });

  group('Validators — Starting Cash & Currency Parsing', () {
    test('returns error for invalid or negative starting cash', () {
      expect(Validators.validateStartingCash(''), 'Starting cash is required.');
      expect(Validators.validateStartingCash('abc'), 'Please enter a valid numeric amount.');
      expect(Validators.validateStartingCash('-500'), 'Starting cash cannot be negative.');
    });

    test('returns null for valid non-negative starting cash', () {
      expect(Validators.validateStartingCash('0'), null);
      expect(Validators.validateStartingCash('25000.50'), null);
    });

    test('correctly parses starting cash into double', () {
      expect(Validators.parseStartingCash('15000.75'), 15000.75);
      expect(Validators.parseStartingCash('0'), 0.0);
    });
  });

  group('Validators — Fiscal Year Month Mapping', () {
    test('maps month names to integers 1..12', () {
      expect(Validators.monthNameToInteger('January'), 1);
      expect(Validators.monthNameToInteger('April'), 4);
      expect(Validators.monthNameToInteger('December'), 12);
      expect(Validators.monthNameToInteger('Unknown'), 1);
    });
  });
}
