import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/services/forex_service.dart';
import 'package:life_hub/core/utils/currency_formatter.dart';

void main() {
  group('Live Forex Engine & Model Test Suite', () {
    tearDown(() {
      // Always reset to baseline rate for test purity
      CurrencyFormatter.resetToDefaultExchangeRate();
    });

    test('ForexRateData serialization and deserialization works cleanly', () {
      final now = DateTime.now();
      final data = ForexRateData(
        rate: 16250.75,
        previousRate: 16000.0,
        lastUpdated: now,
        isLive: true,
      );

      final map = data.toMap();
      expect(map['rate'], equals(16250.75));
      expect(map['is_live'], isTrue);
      expect(map['previous_rate'], equals(16000.0));

      final restored = ForexRateData.fromMap(map);
      expect(restored.rate, equals(16250.75));
      expect(restored.previousRate, equals(16000.0));
      expect(restored.isLive, isTrue);
      expect(restored.deltaPercent, isNotNull);
      // (16250.75 - 16000) / 16000 * 100 = 1.567...
      expect(restored.deltaPercent, closeTo(1.567, 0.01));
    });

    test('CurrencyFormatter dynamically updates with live rates', () {
      expect(CurrencyFormatter.currentExchangeRate, equals(16000.0));

      // Update to 16,500 IDR per USD
      CurrencyFormatter.setLiveExchangeRate(16500.0);
      expect(CurrencyFormatter.currentExchangeRate, equals(16500.0));

      // 100 cents ($1.00) should now equal 16,500 IDR
      expect(CurrencyFormatter.centsToIdr(100), equals(16500));

      // 16,500 IDR should equal 100 cents ($1.00)
      expect(CurrencyFormatter.idrToCents(16500), equals(100));

      // 33,000 IDR should equal 200 cents ($2.00)
      expect(CurrencyFormatter.idrToCents(33000), equals(200));

      // Reset
      CurrencyFormatter.resetToDefaultExchangeRate();
      expect(CurrencyFormatter.currentExchangeRate, equals(16000.0));
      expect(CurrencyFormatter.centsToIdr(100), equals(16000));
    });
  });
}
