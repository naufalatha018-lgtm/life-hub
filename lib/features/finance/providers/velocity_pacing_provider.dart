import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'finance_providers.dart';

/// Velocity Pacing snapshot – safe-to-spend expressed as hourly burn rate.
class VelocityPacingSnapshot {
  /// Monthly net balance remaining after expenses (cents).
  final int netBalanceCents;

  /// Remaining hours in the current month.
  final int remainingHours;

  /// Maximum hourly spend to stay on budget (cents/hour).
  /// Negative or zero means budget is already exceeded.
  final int hourlyBurnRateCents;

  /// Spend committed in the last rolling hour (cents).
  final int lastHourSpentCents;

  /// Whether burn rate is critical (last hour > hourly allowance × 1.5).
  final bool isCritical;

  const VelocityPacingSnapshot({
    required this.netBalanceCents,
    required this.remainingHours,
    required this.hourlyBurnRateCents,
    required this.lastHourSpentCents,
    required this.isCritical,
  });

  /// Safe-to-spend in cents for the current hour.
  int get remainingThisHourCents =>
      (hourlyBurnRateCents - lastHourSpentCents).clamp(0, hourlyBurnRateCents > 0 ? hourlyBurnRateCents : 0);
}

/// Provider that computes a real-time [VelocityPacingSnapshot].
final velocityPacingProvider = Provider<VelocityPacingSnapshot>((ref) {
  final now = DateTime.now();

  // Hours remaining in the month
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
  final endOfMonth = DateTime(now.year, now.month, lastDayOfMonth.day, 23, 59, 59);
  final remainingHours = endOfMonth.difference(now).inHours.clamp(1, 31 * 24);

  final netBalance = ref.watch(netBalanceCentsProvider);
  final hourlyRate = netBalance > 0 ? netBalance ~/ remainingHours : 0;

  // Compute amount spent in the last rolling 60 minutes
  final transactionsAsync = ref.watch(filteredTransactionsProvider);
  final oneHourAgo = now.subtract(const Duration(hours: 1));
  int lastHourSpent = 0;
  for (final tx in transactionsAsync) {
    if (!tx.isIncome && tx.timestamp.isAfter(oneHourAgo)) {
      lastHourSpent += tx.amountCents;
    }
  }

  final isCritical = hourlyRate > 0 && lastHourSpent > (hourlyRate * 1.5).round();

  return VelocityPacingSnapshot(
    netBalanceCents: netBalance,
    remainingHours: remainingHours,
    hourlyBurnRateCents: hourlyRate,
    lastHourSpentCents: lastHourSpent,
    isCritical: isCritical,
  );
});
