import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/utils/currency_formatter.dart';

void main() {
  group('Finance Integer Precision & Currency Formatter Suite', () {
    test('Default formatting uses Indonesian Rupiah (IDR / Rp)', () {
      expect(CurrencyFormatter.formatCents(100), equals('Rp 16.000'));
      expect(CurrencyFormatter.formatCents(0), equals('Rp 0'));
      expect(CurrencyFormatter.formatCents(-100), equals('-Rp 16.000'));
      expect(CurrencyFormatter.formatCompactCents(100000), equals('Rp 16.0M'));
      expect(CurrencyFormatter.parseToCents('16000'), equals(100));
      expect(CurrencyFormatter.parseToCents('Rp 16.000'), equals(100));
    });

    test('Converts user string inputs directly to integer cents without float drift (USD)', () {
      expect(CurrencyFormatter.parseToCents('10.50', currency: AppCurrency.usd), equals(1050));
      expect(CurrencyFormatter.parseToCents('\$10.50', currency: AppCurrency.usd), equals(1050));
      expect(CurrencyFormatter.parseToCents('10.5', currency: AppCurrency.usd), equals(1050));
      expect(CurrencyFormatter.parseToCents('10', currency: AppCurrency.usd), equals(1000));
      expect(CurrencyFormatter.parseToCents('0.99', currency: AppCurrency.usd), equals(99));
      expect(CurrencyFormatter.parseToCents('0.05', currency: AppCurrency.usd), equals(5));
      expect(CurrencyFormatter.parseToCents('1234567.89', currency: AppCurrency.usd), equals(123456789));
      expect(CurrencyFormatter.parseToCents('', currency: AppCurrency.usd), equals(0));
    });

    test('Eliminates standard IEEE-754 floating point rounding errors', () {
      // Classic floating point drift: 0.1 + 0.2 = 0.30000000000000004
      // In cents: 10 cents + 20 cents = 30 cents exactly!
      final int tenCents = CurrencyFormatter.parseToCents('0.10', currency: AppCurrency.usd);
      final int twentyCents = CurrencyFormatter.parseToCents('0.20', currency: AppCurrency.usd);
      final int sum = tenCents + twentyCents;

      expect(sum, equals(30));
      expect(CurrencyFormatter.formatCents(sum, currency: AppCurrency.usd), equals('\$0.30'));

      // 10.50 + 20.75 = 31.25 exactly
      final int item1 = CurrencyFormatter.parseToCents('10.50', currency: AppCurrency.usd);
      final int item2 = CurrencyFormatter.parseToCents('20.75', currency: AppCurrency.usd);
      expect(item1 + item2, equals(3125));
      expect(CurrencyFormatter.formatCents(item1 + item2, currency: AppCurrency.usd), equals('\$31.25'));
    });

    test('Formats negative and surplus balances properly (USD)', () {
      expect(CurrencyFormatter.formatCents(0, currency: AppCurrency.usd), equals('\$0.00'));
      expect(CurrencyFormatter.formatCents(-1500, currency: AppCurrency.usd), equals('-\$15.00'));
      expect(CurrencyFormatter.formatCents(2500, showSign: true, currency: AppCurrency.usd), equals('+\$25.00'));
    });

    test('Formats compact currency notation for large numbers (USD)', () {
      expect(CurrencyFormatter.formatCompactCents(120000, currency: AppCurrency.usd), equals('\$1.2K'));
      expect(CurrencyFormatter.formatCompactCents(350000000, currency: AppCurrency.usd), equals('\$3.5M'));
    });
  });
}
