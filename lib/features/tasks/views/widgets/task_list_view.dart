import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/task_item.dart';
import '../../providers/tasks_providers.dart';
import 'add_task_dialog.dart';
import 'cross_module_expense_dialog.dart';

class TaskListView extends ConsumerWidget {
  const TaskListView({super.key});

  void _onToggleDone(BuildContext context, WidgetRef ref, TaskItem task) async {
    final newStatus = task.isDone ? TaskStatus.todo : TaskStatus.done;
    await ref.read(tasksNotifierProvider.notifier).updateTaskStatus(task.id, newStatus);

    if (newStatus == TaskStatus.done && context.mounted) {
      await CrossModuleExpenseDialog.checkAndPrompt(
        context: context,
        ref: ref,
        task: task,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(filteredTasksProvider);
    final activeCurrency = ref.watch(activeCurrencyProvider);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.checklist_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'No tasks found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap "+ New Task" to organize your productivity goals.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isDone = task.isDone;

        return Dismissible(
          key: Key(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.expense,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(tasksNotifierProvider.notifier).deleteTask(task.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted task "${task.title}"')),
            );
          },
          child: GlassContainer(
            blur: 8,
            backgroundColor: AppColors.surfaceVariant.withOpacity(0.4),
            borderColor: AppColors.cardBorderSubtle,
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Priority indicator left strip
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: task.priority.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),

                  // Checkbox
                  IconButton(
                    icon: Icon(
                      isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isDone ? AppColors.income : AppColors.textMuted,
                      size: 22,
                    ),
                    onPressed: () => _onToggleDone(context, ref, task),
                  ),

                  // Main Details
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddTaskDialog(existingTask: task),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (task.description != null && task.description!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                task.description!,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                // Category chip
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    task.category,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                  ),
                                ),

                                // Due date chip
                                if (task.dueDate != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textMuted),
                                      const SizedBox(width: 3),
                                      Text(
                                        DateFormatter.formatShort(task.dueDate!),
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),

                                // Location tag
                                if (task.location != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primaryLight),
                                      const SizedBox(width: 3),
                                      Text(
                                        task.location!.displayName,
                                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 10),
                                      ),
                                    ],
                                  ),

                                // Estimated cost badge with cross-module status
                                if (task.hasEstimatedCost)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: task.isExpenseLogged
                                          ? AppColors.incomeBg
                                          : AppColors.expenseBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: task.isExpenseLogged
                                            ? AppColors.income.withOpacity(0.3)
                                            : AppColors.expense.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          task.isExpenseLogged
                                              ? Icons.check_rounded
                                              : Icons.monetization_on_outlined,
                                          size: 11,
                                          color: task.isExpenseLogged
                                              ? AppColors.income
                                              : AppColors.expense,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          CurrencyFormatter.formatCents(task.estimatedCostCents, currency: activeCurrency),
                                          style: TextStyle(
                                            color: task.isExpenseLogged
                                                ? AppColors.income
                                                : AppColors.expense,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (task.isExpenseLogged) ...[
                                          const SizedBox(width: 3),
                                          const Text(
                                            '(Logged)',
                                            style: TextStyle(
                                              color: AppColors.income,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Priority badge & more
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: task.priority.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.priority.label,
                        style: TextStyle(
                          color: task.priority.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
