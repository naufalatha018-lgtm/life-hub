import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/theme/app_colors.dart';
import 'package:life_hub/features/calendar/models/calendar_event.dart';
import 'package:life_hub/features/calendar/providers/calendar_providers.dart';
import 'package:life_hub/features/finance/models/finance_transaction.dart';
import 'package:life_hub/features/finance/providers/finance_providers.dart';
import 'package:life_hub/features/tasks/models/task_item.dart';
import 'package:life_hub/features/tasks/providers/tasks_providers.dart';

class FakeTasksNotifier extends StateNotifier<AsyncValue<List<TaskItem>>>
    implements TasksNotifier {
  FakeTasksNotifier(List<TaskItem> tasks) : super(AsyncValue.data(tasks));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFinanceNotifier
    extends StateNotifier<AsyncValue<List<FinanceTransaction>>>
    implements FinanceNotifier {
  FakeFinanceNotifier(List<FinanceTransaction> transactions)
      : super(AsyncValue.data(transactions));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Real-Time Calendar & Scheduler Sync Suite', () {
    test('CalendarEvent model identifies tasks and finance events accurately', () {
      final taskEvent = CalendarEvent(
        id: 'cal_01',
        title: 'Board Meeting Presentation',
        dateTime: DateTime(2026, 9, 15, 10, 0),
        type: CalendarEventType.task,
        color: AppColors.primaryLight,
      );

      expect(taskEvent.isTask, isTrue);
      expect(taskEvent.isFinance, isFalse);
      expect(taskEvent.type.label, equals('Task Deadline'));

      final incomeEvent = CalendarEvent(
        id: 'cal_02',
        title: 'Consulting Retainer',
        dateTime: DateTime(2026, 9, 15, 14, 0),
        type: CalendarEventType.financeIncome,
        color: AppColors.income,
      );

      expect(incomeEvent.isTask, isFalse);
      expect(incomeEvent.isFinance, isTrue);
      expect(incomeEvent.type.label, equals('Income'));

      final expenseEvent = CalendarEvent(
        id: 'cal_03',
        title: 'Cloud Infrastructure Bill',
        dateTime: DateTime(2026, 9, 16, 9, 0),
        type: CalendarEventType.financeExpense,
        color: AppColors.expense,
      );

      expect(expenseEvent.isTask, isFalse);
      expect(expenseEvent.isFinance, isTrue);
      expect(expenseEvent.type.label, equals('Expense'));
    });

    test('Calendar aggregators sync both tasks with deadlines and finance transactions', () {
      final now = DateTime(2026, 9, 10, 12, 0);

      final taskWithDueDate = TaskItem(
        id: 'task_01',
        title: 'Submit Q3 Tax Filings',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        category: 'Legal',
        dueDate: DateTime(2026, 9, 10, 17, 0),
        estimatedCostCents: 25000,
        createdAt: now,
        updatedAt: now,
      );

      final taskWithoutDueDate = TaskItem(
        id: 'task_02',
        title: 'Someday reading list',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        category: 'Personal',
        dueDate: null,
        createdAt: now,
        updatedAt: now,
      );

      final transaction = FinanceTransaction(
        id: 'tx_01',
        title: 'Client Wire Transfer',
        amountCents: 500000, // $5,000.00
        type: TransactionType.income,
        category: 'Salary',
        timestamp: DateTime(2026, 9, 10, 9, 30),
        createdAt: now,
        updatedAt: now,
      );

      final container = ProviderContainer(
        overrides: [
          tasksNotifierProvider.overrideWith(
            (ref) => FakeTasksNotifier([taskWithDueDate, taskWithoutDueDate]),
          ),
          financeNotifierProvider.overrideWith(
            (ref) => FakeFinanceNotifier([transaction]),
          ),
          selectedCalendarDateProvider.overrideWith((ref) => DateTime(2026, 9, 10)),
        ],
      );
      addTearDown(container.dispose);

      final allEvents = container.read(allCalendarEventsProvider);

      // taskWithoutDueDate must be excluded (no due date)
      expect(allEvents.length, equals(2));

      // Sorted chronologically: transaction at 9:30 AM before task at 5:00 PM
      expect(allEvents[0].id, equals('cal_tx_tx_01'));
      expect(allEvents[0].isFinance, isTrue);

      expect(allEvents[1].id, equals('cal_task_task_01'));
      expect(allEvents[1].isTask, isTrue);

      // Verify date filter provider returns both events for 2026-09-10
      final dateEvents = container.read(eventsForSelectedDateProvider);
      expect(dateEvents.length, equals(2));
    });
  });
}
