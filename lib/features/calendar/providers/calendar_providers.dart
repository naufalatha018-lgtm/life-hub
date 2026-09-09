import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/currency_provider.dart';
import '../../finance/providers/finance_providers.dart';
import '../../tasks/providers/tasks_providers.dart';
import '../models/calendar_event.dart';

enum CalendarViewMode {
  month('Month'),
  week('Week'),
  day('Day');

  final String label;
  const CalendarViewMode(this.label);
}

final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) {
  return CalendarViewMode.month;
});

final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final allCalendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  final financeAsync = ref.watch(financeNotifierProvider);
  final activeCurrency = ref.watch(activeCurrencyProvider);

  final List<CalendarEvent> events = [];

  tasksAsync.whenData((tasks) {
    for (final task in tasks) {
      if (task.dueDate != null) {
        events.add(
          CalendarEvent(
            id: 'cal_task_${task.id}',
            title: task.title,
            dateTime: task.dueDate!,
            type: CalendarEventType.task,
            color: task.priority.color,
            subtitle: task.hasEstimatedCost
                ? 'Due • Cost: ${CurrencyFormatter.formatCents(task.estimatedCostCents, currency: activeCurrency)}'
                : 'Due: ${task.priority.label} priority',
            originalItem: task,
          ),
        );
      }
    }
  });

  financeAsync.whenData((transactions) {
    for (final tx in transactions) {
      final isIncome = tx.isIncome;
      final formatted = isIncome
          ? '+${CurrencyFormatter.formatCents(tx.amountCents, currency: activeCurrency)}'
          : '-${CurrencyFormatter.formatCents(tx.amountCents, currency: activeCurrency)}';

      events.add(
        CalendarEvent(
          id: 'cal_tx_${tx.id}',
          title: tx.title,
          dateTime: tx.timestamp,
          type: isIncome ? CalendarEventType.financeIncome : CalendarEventType.financeExpense,
          color: isIncome ? AppColors.income : AppColors.expense,
          subtitle: '$formatted • ${tx.category}',
          originalItem: tx,
        ),
      );
    }
  });

  events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return events;
});

final eventsForSelectedDateProvider = Provider<List<CalendarEvent>>((ref) {
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final allEvents = ref.watch(allCalendarEventsProvider);

  return allEvents.where((e) {
    return e.dateTime.year == selectedDate.year &&
        e.dateTime.month == selectedDate.month &&
        e.dateTime.day == selectedDate.day;
  }).toList();
});
