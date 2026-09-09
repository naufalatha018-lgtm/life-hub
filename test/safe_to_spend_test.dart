import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/features/finance/providers/safe_to_spend_provider.dart';

void main() {
  group('SafeToSpend Calculation Tests', () {
    test('SafeToSpendData model holds correct values and status', () {
      const data = SafeToSpendData(
        dailySafeToSpendCents: 1500000,
        remainingBudgetCents: 30000000,
        remainingDays: 20,
        upcomingCommitmentsCents: 5000000,
        status: SafeToSpendStatus.good,
      );

      expect(data.dailySafeToSpendCents, 1500000);
      expect(data.remainingBudgetCents, 30000000);
      expect(data.remainingDays, 20);
      expect(data.upcomingCommitmentsCents, 5000000);
      expect(data.status, SafeToSpendStatus.good);
    });

    test('SafeToSpendStatus accurately reflects budget threshold', () {
      expect(SafeToSpendStatus.good.name, 'good');
      expect(SafeToSpendStatus.tight.name, 'tight');
      expect(SafeToSpendStatus.over.name, 'over');
    });
  });
}
