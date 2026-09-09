import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/providers/tasks_providers.dart';
import 'finance_providers.dart';

enum SafeToSpendStatus {
  good,
  tight,
  over,
}

class SafeToSpendData {
  final int dailySafeToSpendCents;
  final int remainingBudgetCents;
  final int remainingDays;
  final int upcomingCommitmentsCents;
  final SafeToSpendStatus status;

  const SafeToSpendData({
    required this.dailySafeToSpendCents,
    required this.remainingBudgetCents,
    required this.remainingDays,
    required this.upcomingCommitmentsCents,
    required this.status,
  });
}

final safeToSpendProvider = Provider<SafeToSpendData>((ref) {
  final now = DateTime.now();
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
  final remainingDays = (lastDayOfMonth - now.day + 1).clamp(1, 31);

  final totalIncome = ref.watch(totalIncomeCentsProvider);
  final totalExpense = ref.watch(totalExpenseCentsProvider);
  final netBalance = totalIncome - totalExpense;

  // Watch tasks with due date in current month that have estimated costs
  final tasksAsync = ref.watch(tasksNotifierProvider);
  int upcomingCommitments = 0;
  tasksAsync.whenData((tasks) {
    for (final t in tasks) {
      if (!t.isDone && t.dueDate != null && t.dueDate!.month == now.month && t.dueDate!.year == now.year) {
        upcomingCommitments += t.estimatedCostCents;
      }
    }
  });

  // Effective available funds for the rest of the month
  final availableForMonth = netBalance > 0 ? (netBalance - upcomingCommitments) : 0;
  final dailyCents = availableForMonth > 0 ? (availableForMonth ~/ remainingDays) : 0;

  SafeToSpendStatus status;
  if (dailyCents >= 500000) {
    // Over Rp 50,000 / $50/day
    status = SafeToSpendStatus.good;
  } else if (dailyCents > 0) {
    status = SafeToSpendStatus.tight;
  } else {
    status = SafeToSpendStatus.over;
  }

  return SafeToSpendData(
    dailySafeToSpendCents: dailyCents,
    remainingBudgetCents: availableForMonth,
    remainingDays: remainingDays,
    upcomingCommitmentsCents: upcomingCommitments,
    status: status,
  );
});
