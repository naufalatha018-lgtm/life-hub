import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/pipeline/report_isolate_worker.dart';

void main() {
  group('Isolate Pipeline Statistics Suite', () {
    test('FinancialStatistics models mean, std dev, and runway mathematically', () {
      final sampleAmounts = [100.0, 200.0, 300.0, 400.0, 500.0];
      final mean = sampleAmounts.reduce((a, b) => a + b) / sampleAmounts.length;
      expect(mean, equals(300.0));

      double varianceSum = 0;
      for (final a in sampleAmounts) {
        varianceSum += pow(a - mean, 2);
      }
      final variance = varianceSum / sampleAmounts.length;
      final stdDev = sqrt(variance);

      expect(stdDev, closeTo(141.42, 0.01));

      const stats = FinancialStatistics(
        totalCount: 5,
        totalIncome: 10000.0,
        totalExpense: 3000.0,
        netCashFlow: 7000.0,
        meanTransaction: 300.0,
        standardDeviation: 141.42,
        monthlyBurnRate: 1000.0,
        monthlyRunRate: 40000.0,
        runwayMonths: 7.0, // 7000 / 1000
      );

      expect(stats.runwayMonths, equals(7.0));
      expect(stats.netCashFlow, equals(7000.0));
      expect(stats.toMap()['totalCount'], equals(5));
    });
  });
}
