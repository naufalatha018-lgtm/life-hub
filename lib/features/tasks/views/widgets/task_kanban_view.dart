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

class TaskKanbanView extends ConsumerWidget {
  const TaskKanbanView({super.key});

  void _onMoveStatus(
    BuildContext context,
    WidgetRef ref,
    TaskItem task,
    TaskStatus newStatus,
  ) async {
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
    final todoList = ref.watch(todoTasksProvider);
    final inProgressList = ref.watch(inProgressTasksProvider);
    final doneList = ref.watch(doneTasksProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final columns = [
          _buildKanbanColumn(
            context: context,
            ref: ref,
            title: 'To Do',
            status: TaskStatus.todo,
            statusColor: AppColors.textSecondary,
            tasks: todoList,
          ),
          _buildKanbanColumn(
            context: context,
            ref: ref,
            title: 'In Progress',
            status: TaskStatus.inProgress,
            statusColor: AppColors.primaryLight,
            tasks: inProgressList,
          ),
          _buildKanbanColumn(
            context: context,
            ref: ref,
            title: 'Done',
            status: TaskStatus.done,
            statusColor: AppColors.income,
            tasks: doneList,
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((col) => Expanded(child: col)).toList(),
          );
        }

        // On smaller screens, horizontally scrollable board
        return SizedBox(
          height: 600,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: columns.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: 280, child: columns[i]),
          ),
        );
      },
    );
  }

  Widget _buildKanbanColumn({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required TaskStatus status,
    required Color statusColor,
    required List<TaskItem> tasks,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textMuted, size: 18),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddTaskDialog(initialStatus: status),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards List
          if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              child: Text(
                'No tasks in $title',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildKanbanCard(context, ref, task);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(BuildContext context, WidgetRef ref, TaskItem task) {
    final activeCurrency = ref.watch(activeCurrencyProvider);

    return GlassContainer(
      blur: 8,
      backgroundColor: AppColors.surfaceVariant.withOpacity(0.4),
      borderColor: AppColors.cardBorderSubtle,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: task.priority.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.priority.label,
                  style: TextStyle(
                    color: task.priority.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<TaskStatus>(
                icon: const Icon(Icons.more_horiz_rounded, size: 16, color: AppColors.textMuted),
                color: AppColors.surface,
                itemBuilder: (_) => TaskStatus.values
                    .where((s) => s != task.status)
                    .map(
                      (s) => PopupMenuItem(
                        value: s,
                        child: Text(
                          'Move to ${s.label}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    )
                    .toList(),
                onSelected: (newStatus) => _onMoveStatus(context, ref, task, newStatus),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AddTaskDialog(existingTask: task),
              );
            },
            child: Text(
              task.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                task.category,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              if (task.hasEstimatedCost)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: task.isExpenseLogged ? AppColors.incomeBg : AppColors.expenseBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    CurrencyFormatter.formatCents(task.estimatedCostCents, currency: activeCurrency),
                    style: TextStyle(
                      color: task.isExpenseLogged ? AppColors.income : AppColors.expense,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (task.dueDate != null || task.location != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (task.dueDate != null) ...[
                  const Icon(Icons.schedule_rounded, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatShort(task.dueDate!),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
                if (task.dueDate != null && task.location != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ),
                if (task.location != null) ...[
                  const Icon(Icons.location_on_rounded, size: 11, color: AppColors.primaryLight),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      task.location!.displayName,
                      style: const TextStyle(color: AppColors.primaryLight, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
