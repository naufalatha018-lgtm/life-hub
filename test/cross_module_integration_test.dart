import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/features/finance/models/finance_transaction.dart';
import 'package:life_hub/features/tasks/models/task_item.dart';

void main() {
  group('Cross-Module Integration: Tasks to Finance Suite', () {
    test('TaskItem with estimated cost translates directly into FinanceTransaction', () {
      final task = TaskItem(
        id: 'task_grocery_01',
        title: 'Weekly Supermarket Shopping',
        description: 'Milk, eggs, fruits, oats',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        category: 'Shopping',
        dueDate: DateTime.now(),
        estimatedCostCents: 4575, // $45.75
        isExpenseLogged: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(task.hasEstimatedCost, isTrue);
      expect(task.formattedCost, equals('\$45.75'));
      expect(task.isExpenseLogged, isFalse);

      // Simulate the cross-module automated action
      final expenseTx = FinanceTransaction(
        id: 'tx_auto_01',
        title: task.title,
        amountCents: task.estimatedCostCents,
        type: TransactionType.expense,
        category: task.category,
        timestamp: DateTime.now(),
        note: 'Logged from completed task: ${task.title}',
        linkedTaskId: task.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expenseTx.amountCents, equals(4575));
      expect(expenseTx.isExpense, isTrue);
      expect(expenseTx.linkedTaskId, equals('task_grocery_01'));
      expect(expenseTx.formattedAmount, equals('\$45.75'));

      // Mark task as logged
      final updatedTask = task.copyWith(isExpenseLogged: true);
      expect(updatedTask.isExpenseLogged, isTrue);
    });
  });
}
