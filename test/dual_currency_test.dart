import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/utils/currency_formatter.dart';

void main() {
  group('Dual Currency Engine (USD & IDR) Test Suite', () {
    test('Fixed conversion rate constants are accurate', () {
      expect(CurrencyFormatter.idrPerUsd, equals(16000));
      expect(CurrencyFormatter.idrPerCent, equals(160));
    });

    test('Converts cents to IDR correctly', () {
      // 100 cents ($1.00) = 16,000 IDR
      expect(CurrencyFormatter.centsToIdr(100), equals(16000));
      // 50 cents ($0.50) = 8,000 IDR
      expect(CurrencyFormatter.centsToIdr(50), equals(8000));
      // 1050 cents ($10.50) = 168,000 IDR
      expect(CurrencyFormatter.centsToIdr(1050), equals(168000));
      // 0 cents = 0 IDR
      expect(CurrencyFormatter.centsToIdr(0), equals(0));
    });

    test('Converts IDR to USD cents correctly', () {
      // 16,000 IDR = 100 cents ($1.00)
      expect(CurrencyFormatter.idrToCents(16000), equals(100));
      // 160,000 IDR = 1000 cents ($10.00)
      expect(CurrencyFormatter.idrToCents(160000), equals(1000));
      // 80,000 IDR = 500 cents ($5.00)
      expect(CurrencyFormatter.idrToCents(80000), equals(500));
      // 0 IDR = 0 cents
      expect(CurrencyFormatter.idrToCents(0), equals(0));
    });

    test('Formats USD cents properly with symbol and decimals', () {
      expect(CurrencyFormatter.formatCents(1050, currency: AppCurrency.usd), equals(r'$10.50'));
      expect(CurrencyFormatter.formatCents(0, currency: AppCurrency.usd), equals(r'$0.00'));
      expect(CurrencyFormatter.formatCents(-2500, currency: AppCurrency.usd), equals(r'-$25.00'));
      expect(CurrencyFormatter.formatCents(5000, currency: AppCurrency.usd, showSign: true), equals(r'+$50.00'));
    });

    test('Formats IDR properly with Rp symbol and thousands separators', () {
      // 16.000 IDR -> Rp 16.000 (localized with dot separator)
      final formatted16k = CurrencyFormatter.formatCents(16000, currency: AppCurrency.idr);
      expect(formatted16k, contains('Rp'));
      expect(formatted16k, contains('16'));

      // Negative IDR
      final formattedNeg = CurrencyFormatter.formatCents(-16000, currency: AppCurrency.idr);
      expect(formattedNeg, contains('-'));
      expect(formattedNeg, contains('16'));
    });

    test('Parses USD input strings without IEEE-754 float drift', () {
      expect(CurrencyFormatter.parseToCents('10.50', currency: AppCurrency.usd), equals(1050));
      expect(CurrencyFormatter.parseToCents(r'$10.50', currency: AppCurrency.usd), equals(1050));
      expect(CurrencyFormatter.parseToCents('0.99', currency: AppCurrency.usd), equals(99));
      expect(CurrencyFormatter.parseToCents('0.01', currency: AppCurrency.usd), equals(1));
      expect(CurrencyFormatter.parseToCents('0', currency: AppCurrency.usd), equals(0));
      expect(CurrencyFormatter.parseToCents('', currency: AppCurrency.usd), equals(0));
    });

    test('Parses IDR input strings to raw exact integers accurately', () {
      expect(CurrencyFormatter.parseToCents('5000', currency: AppCurrency.idr), equals(5000));
      expect(CurrencyFormatter.parseToCents('Rp 5.000', currency: AppCurrency.idr), equals(5000));
      expect(CurrencyFormatter.parseToCents('16000', currency: AppCurrency.idr), equals(16000));
      expect(CurrencyFormatter.parseToCents('Rp 16.000', currency: AppCurrency.idr), equals(16000));
      expect(CurrencyFormatter.parseToCents('160.000', currency: AppCurrency.idr), equals(160000));
      expect(CurrencyFormatter.parseToCents('Rp 80.000', currency: AppCurrency.idr), equals(80000));
    });

    test('Compact format works for both currencies', () {
      final compactUsd = CurrencyFormatter.formatCompactCents(100000, currency: AppCurrency.usd);
      expect(compactUsd, equals(r'$1.0K'));

      final compactIdr = CurrencyFormatter.formatCompactCents(100000, currency: AppCurrency.idr);
      expect(compactIdr, contains('Rp'));
    });
  });
}
