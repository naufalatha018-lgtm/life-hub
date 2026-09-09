import 'package:flutter/foundation.dart';
import 'finance_transaction.dart';

/// Recurrence interval for scheduled auto-entries.
enum RecurrenceInterval {
  daily,
  weekly,
  monthly,
  yearly;

  String label(String lang) {
    if (lang == 'id') {
      switch (this) {
        case RecurrenceInterval.daily: return 'Harian';
        case RecurrenceInterval.weekly: return 'Mingguan';
        case RecurrenceInterval.monthly: return 'Bulanan';
        case RecurrenceInterval.yearly: return 'Tahunan';
      }
    }
    switch (this) {
      case RecurrenceInterval.daily: return 'Daily';
      case RecurrenceInterval.weekly: return 'Weekly';
      case RecurrenceInterval.monthly: return 'Monthly';
      case RecurrenceInterval.yearly: return 'Yearly';
    }
  }

  /// Returns the next due date after [from] based on this interval.
  DateTime nextDate(DateTime from) {
    switch (this) {
      case RecurrenceInterval.daily: return from.add(const Duration(days: 1));
      case RecurrenceInterval.weekly: return from.add(const Duration(days: 7));
      case RecurrenceInterval.monthly:
        final m = from.month == 12 ? 1 : from.month + 1;
        final y = from.month == 12 ? from.year + 1 : from.year;
        final d = _clampDay(from.day, m, y);
        return DateTime(y, m, d);
      case RecurrenceInterval.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  static int _clampDay(int day, int month, int year) {
    final maxDay = DateTime(year, month + 1, 0).day;
    return day > maxDay ? maxDay : day;
  }
}

/// Represents a recurring transaction template. When [nextDue] is reached,
/// a new [FinanceTransaction] is auto-created from this template.
@immutable
class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.type,
    required this.category,
    required this.interval,
    required this.nextDue,
    required this.walletId,
    this.note,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String title;
  final int amountCents;
  final TransactionType type;
  final String category;
  final RecurrenceInterval interval;
  final DateTime nextDue;
  final String walletId;
  final String? note;
  final bool isActive;
  final DateTime createdAt;

  bool get isDue => isActive && !nextDue.isAfter(DateTime.now());

  RecurringTransaction copyWith({
    DateTime? nextDue,
    bool? isActive,
  }) {
    return RecurringTransaction(
      id: id,
      title: title,
      amountCents: amountCents,
      type: type,
      category: category,
      interval: interval,
      nextDue: nextDue ?? this.nextDue,
      walletId: walletId,
      note: note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount_cents': amountCents,
    'type': type.name,
    'category': category,
    'interval': interval.name,
    'next_due': nextDue.toIso8601String(),
    'wallet_id': walletId,
    'note': note,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amountCents: (map['amount_cents'] as num).toInt(),
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: map['category'] as String,
      interval: RecurrenceInterval.values.firstWhere(
        (e) => e.name == map['interval'],
        orElse: () => RecurrenceInterval.monthly,
      ),
      nextDue: DateTime.parse(map['next_due'] as String),
      walletId: map['wallet_id'] as String,
      note: map['note'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
