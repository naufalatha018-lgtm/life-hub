import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/currency_toggle_chip.dart';
import '../models/task_item.dart';
import '../providers/tasks_providers.dart';
import 'widgets/add_task_dialog.dart';
import 'widgets/task_kanban_view.dart';
import 'widgets/task_list_view.dart';

class TasksView extends ConsumerWidget {
  const TasksView({super.key});

  void _openAddTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(taskViewModeProvider);
    final activeCategory = ref.watch(taskCategoryFilterProvider);
    final activePriority = ref.watch(taskPriorityFilterProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final strings = ref.watch(appStringsProvider);

    final totalCount = filteredTasks.length;
    final doneCount = filteredTasks.where((t) => t.isDone).length;
    final pendingCount = totalCount - doneCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.task_alt_rounded, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                strings.tasksTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          const CurrencyToggleChip(),
          const SizedBox(width: 4),
          // View Mode Toggle (List vs Kanban)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: strings.listTab,
                  icon: Icon(
                    Icons.view_list_rounded,
                    size: 20,
                    color: viewMode == TaskViewMode.list ? AppColors.primaryLight : AppColors.textMuted,
                  ),
                  onPressed: () {
                    ref.read(taskViewModeProvider.notifier).state = TaskViewMode.list;
                  },
                ),
                IconButton(
                  tooltip: strings.kanbanTab,
                  icon: Icon(
                    Icons.view_kanban_rounded,
                    size: 20,
                    color: viewMode == TaskViewMode.kanban ? AppColors.primaryLight : AppColors.textMuted,
                  ),
                  onPressed: () {
                    ref.read(taskViewModeProvider.notifier).state = TaskViewMode.kanban;
                  },
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: strings.createTask,
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight),
            onPressed: () => _openAddTask(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTask(context),
        icon: const Icon(Icons.add_task_rounded),
        label: Text(strings.createTask, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Counters & Progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.checklist_rtl_rounded, color: AppColors.primaryLight, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$pendingCount Pending',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$doneCount Completed',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalCount > 0 ? (doneCount / totalCount) : 0,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.income),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Category Dropdown Filter Chip
                  PopupMenuButton<String?>(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: null, child: Text('All Categories')),
                      ...AppConstants.taskCategories.map(
                        (c) => PopupMenuItem(value: c, child: Text(c)),
                      ),
                    ],
                    onSelected: (val) {
                      ref.read(taskCategoryFilterProvider.notifier).state = val;
                    },
                    child: Chip(
                      label: Text(
                        activeCategory ?? 'Category: All',
                        style: TextStyle(
                          color: activeCategory != null ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor:
                          activeCategory != null ? AppColors.primary : AppColors.surfaceVariant,
                      side: BorderSide(
                        color: activeCategory != null ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority Dropdown Filter Chip
                  PopupMenuButton<TaskPriority?>(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: null, child: Text('All Priorities')),
                      ...TaskPriority.values.map(
                        (p) => PopupMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(p.label),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onSelected: (val) {
                      ref.read(taskPriorityFilterProvider.notifier).state = val;
                    },
                    child: Chip(
                      label: Text(
                        activePriority != null ? 'Priority: ${activePriority.label}' : 'Priority: All',
                        style: TextStyle(
                          color: activePriority != null ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor:
                          activePriority != null ? AppColors.primary : AppColors.surfaceVariant,
                      side: BorderSide(
                        color: activePriority != null ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic View: List View or Kanban Board
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: viewMode == TaskViewMode.list
                  ? const TaskListView()
                  : const TaskKanbanView(),
            ),
            const SizedBox(height: 80), // Fab space
          ],
        ),
      ),
    );
  }
}
