import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/utils/currency_formatter.dart';

void main() {
  group('Finance Integer Precision & Currency Formatter Suite', () {
    test('Converts user string inputs directly to integer cents without float drift', () {
      expect(CurrencyFormatter.parseToCents('10.50'), equals(1050));
      expect(CurrencyFormatter.parseToCents('\$10.50'), equals(1050));
      expect(CurrencyFormatter.parseToCents('10.5'), equals(1050));
      expect(CurrencyFormatter.parseToCents('10'), equals(1000));
      expect(CurrencyFormatter.parseToCents('0.99'), equals(99));
      expect(CurrencyFormatter.parseToCents('0.05'), equals(5));
      expect(CurrencyFormatter.parseToCents('1234567.89'), equals(123456789));
      expect(CurrencyFormatter.parseToCents(''), equals(0));
    });

    test('Eliminates standard IEEE-754 floating point rounding errors', () {
      // Classic floating point drift: 0.1 + 0.2 = 0.30000000000000004
      // In cents: 10 cents + 20 cents = 30 cents exactly!
      final int tenCents = CurrencyFormatter.parseToCents('0.10');
      final int twentyCents = CurrencyFormatter.parseToCents('0.20');
      final int sum = tenCents + twentyCents;

      expect(sum, equals(30));
      expect(CurrencyFormatter.formatCents(sum), equals('\$0.30'));

      // 10.50 + 20.75 = 31.25 exactly
      final int item1 = CurrencyFormatter.parseToCents('10.50');
      final int item2 = CurrencyFormatter.parseToCents('20.75');
      expect(item1 + item2, equals(3125));
      expect(CurrencyFormatter.formatCents(item1 + item2), equals('\$31.25'));
    });

    test('Formats negative and surplus balances properly', () {
      expect(CurrencyFormatter.formatCents(0), equals('\$0.00'));
      expect(CurrencyFormatter.formatCents(-1500), equals('-\$15.00'));
      expect(CurrencyFormatter.formatCents(2500, showSign: true), equals('+\$25.00'));
    });

    test('Formats compact currency notation for large numbers', () {
      expect(CurrencyFormatter.formatCompactCents(120000), equals('\$1.2K'));
      expect(CurrencyFormatter.formatCompactCents(350000000), equals('\$3.5M'));
    });
  });
}
