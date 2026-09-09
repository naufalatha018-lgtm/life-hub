import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum CalendarEventType {
  task,
  financeIncome,
  financeExpense;

  String get label {
    switch (this) {
      case CalendarEventType.task:
        return 'Task Deadline';
      case CalendarEventType.financeIncome:
        return 'Income';
      case CalendarEventType.financeExpense:
        return 'Expense';
    }
  }

  Color get defaultColor {
    switch (this) {
      case CalendarEventType.task:
        return AppColors.primaryLight;
      case CalendarEventType.financeIncome:
        return AppColors.income;
      case CalendarEventType.financeExpense:
        return AppColors.expense;
    }
  }

  IconData get icon {
    switch (this) {
      case CalendarEventType.task:
        return Icons.task_alt_rounded;
      case CalendarEventType.financeIncome:
        return Icons.arrow_downward_rounded;
      case CalendarEventType.financeExpense:
        return Icons.arrow_upward_rounded;
    }
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final CalendarEventType type;
  final Color color;
  final String? subtitle;
  final dynamic originalItem; // TaskItem or FinanceTransaction

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.type,
    required this.color,
    this.subtitle,
    this.originalItem,
  });

  bool get isTask => type == CalendarEventType.task;
  bool get isFinance =>
      type == CalendarEventType.financeIncome || type == CalendarEventType.financeExpense;
}
