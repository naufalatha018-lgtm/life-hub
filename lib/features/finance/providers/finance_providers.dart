import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/finance_dao.dart';
import '../../../core/localization/app_strings.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/finance_transaction.dart';

enum DateRangeFilter {
  all('All Time'),
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  custom('Custom');

  final String label;
  const DateRangeFilter(this.label);

  String getLocalizedLabel(AppStrings strings) {
    switch (this) {
      case DateRangeFilter.all:
        return strings.dateFilterAll;
      case DateRangeFilter.today:
        return strings.dateFilterToday;
      case DateRangeFilter.thisWeek:
        return strings.dateFilterThisWeek;
      case DateRangeFilter.thisMonth:
        return strings.dateFilterThisMonth;
      case DateRangeFilter.custom:
        return strings.dateFilterCustom;
    }
  }
}

final financeDaoProvider = Provider<FinanceDao>((ref) {
  return FinanceDao();
});

final financeDateRangeFilterProvider = StateProvider<DateRangeFilter>((ref) {
  return DateRangeFilter.thisMonth;
});

final financeCustomDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  return null;
});

final financeCategoryFilterProvider = StateProvider<String?>((ref) {
  return null;
});

final financeNotifierProvider =
    StateNotifierProvider<FinanceNotifier, AsyncValue<List<FinanceTransaction>>>((ref) {
  final dao = ref.watch(financeDaoProvider);
  final userId = ref.watch(currentUserIdProvider);
  return FinanceNotifier(dao, userId);
});

class FinanceNotifier extends StateNotifier<AsyncValue<List<FinanceTransaction>>> {
  FinanceNotifier(this._dao, [String? userId])
      : _userId = userId ?? 'guest_default',
        super(const AsyncValue.loading()) {
    loadTransactions();
  }

  final FinanceDao _dao;
  final String _userId;

  Future<void> loadTransactions() async {
    try {
      final rows = await _dao.getAllTransactions(_userId);
      final list = rows.map((r) => FinanceTransaction.fromMap(r)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction({
    required String title,
    required int amountCents,
    required TransactionType type,
    required String category,
    DateTime? timestamp,
    String? note,
    String? linkedTaskId,
    String? walletId,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    final now = DateTime.now();
    final tx = FinanceTransaction(
      id: 'tx_${now.microsecondsSinceEpoch}',
      userId: _userId,
      walletId: walletId,
      title: title.trim(),
      amountCents: amountCents,
      type: type,
      category: category,
      timestamp: timestamp ?? now,
      note: note?.trim(),
      linkedTaskId: linkedTaskId,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      createdAt: now,
      updatedAt: now,
    );

    await _dao.insertTransaction(tx.toMap());

    state.whenData((transactions) {
      final updated = [tx, ...transactions];
      updated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = AsyncValue.data(updated);
    });
  }

  Future<void> updateTransaction(FinanceTransaction tx) async {
    final updatedTx = tx.copyWith(
      userId: _userId,
      updatedAt: DateTime.now(),
    );
    await _dao.updateTransaction(updatedTx.toMap());

    state.whenData((transactions) {
      final updated = transactions
          .map((item) => item.id == tx.id ? updatedTx : item)
          .toList();
      updated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = AsyncValue.data(updated);
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _dao.deleteTransaction(id);
    state.whenData((transactions) {
      state = AsyncValue.data(transactions.where((tx) => tx.id != id).toList());
    });
  }
}

/// Filtered transactions based on active DateRangeFilter and CategoryFilter
final filteredTransactionsProvider = Provider<List<FinanceTransaction>>((ref) {
  final txAsync = ref.watch(financeNotifierProvider);
  final dateFilter = ref.watch(financeDateRangeFilterProvider);
  final customRange = ref.watch(financeCustomDateRangeProvider);
  final categoryFilter = ref.watch(financeCategoryFilterProvider);

  return txAsync.maybeWhen(
    data: (transactions) {
      final now = DateTime.now();
      return transactions.where((tx) {
        // 1. Date Range Check
        bool dateMatches = true;
        switch (dateFilter) {
          case DateRangeFilter.all:
            dateMatches = true;
            break;
          case DateRangeFilter.today:
            dateMatches = tx.timestamp.year == now.year &&
                tx.timestamp.month == now.month &&
                tx.timestamp.day == now.day;
            break;
          case DateRangeFilter.thisWeek:
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final startDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
            dateMatches = tx.timestamp.isAfter(startDay.subtract(const Duration(seconds: 1)));
            break;
          case DateRangeFilter.thisMonth:
            dateMatches = tx.timestamp.year == now.year && tx.timestamp.month == now.month;
            break;
          case DateRangeFilter.custom:
            if (customRange != null) {
              final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
              final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
              dateMatches = (tx.timestamp.isAfter(start) || tx.timestamp.isAtSameMomentAs(start)) &&
                  (tx.timestamp.isBefore(end) || tx.timestamp.isAtSameMomentAs(end));
            }
            break;
        }

        if (!dateMatches) return false;

        // 2. Category Check
        if (categoryFilter != null && categoryFilter.isNotEmpty) {
          if (tx.category != categoryFilter) return false;
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

final totalIncomeCentsProvider = Provider<int>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  return transactions
      .where((tx) => tx.isIncome)
      .fold<int>(0, (sum, tx) => sum + tx.amountCents);
});

final totalExpenseCentsProvider = Provider<int>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  return transactions
      .where((tx) => tx.isExpense)
      .fold<int>(0, (sum, tx) => sum + tx.amountCents);
});

final netBalanceCentsProvider = Provider<int>((ref) {
  final income = ref.watch(totalIncomeCentsProvider);
  final expense = ref.watch(totalExpenseCentsProvider);
  return income - expense;
});

/// Category breakdown map: Category -> Total Expense Cents
final categoryExpenseBreakdownProvider = Provider<Map<String, int>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  final Map<String, int> map = {};

  for (final tx in transactions.where((t) => t.isExpense)) {
    map[tx.category] = (map[tx.category] ?? 0) + tx.amountCents;
  }

  return map;
});

/// Daily expenses for the last 7 active days (for bar chart)
final recentDailyExpenseProvider = Provider<Map<String, int>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  final Map<String, int> daily = {};

  final sorted = transactions.where((t) => t.isExpense).toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  for (final tx in sorted) {
    final key = '${tx.timestamp.month}/${tx.timestamp.day}';
    daily[key] = (daily[key] ?? 0) + tx.amountCents;
  }

  return daily;
});
