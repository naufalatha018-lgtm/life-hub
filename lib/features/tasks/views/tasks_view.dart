import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_executive_theme.dart';
import '../../../../core/theme/premium_glass_card.dart';
import '../../../../core/widgets/currency_toggle_chip.dart';
import '../../../../core/widgets/executive_badge.dart';
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
      backgroundColor: AppColorPalette.surfaceDeepDark,
      appBar: AppBar(
        backgroundColor: AppColorPalette.surfaceDeepDark,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                style: AppExecutiveTheme.subsectionHeader.copyWith(fontSize: 18),
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
            PremiumGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: BorderRadius.circular(16),
              backgroundColor: AppColorPalette.surfaceSecondary.withOpacity(0.60),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColorPalette.azureGlow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.checklist_rtl_rounded,
                            color: AppColorPalette.azureLight,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$pendingCount',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColorPalette.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const ExecutiveBadge(
                                  label: 'PENDING',
                                  style: ExecutiveBadgeStyle.azure,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '$doneCount',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColorPalette.electricEmerald,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const ExecutiveBadge(
                                  label: 'DONE',
                                  style: ExecutiveBadgeStyle.emerald,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Radial-style progress ring placeholder using a Stack
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: totalCount > 0 ? (doneCount / totalCount) : 0,
                          backgroundColor: AppColorPalette.borderSubtle,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColorPalette.electricEmerald,
                          ),
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                        ),
                        Text(
                          totalCount > 0
                              ? '${((doneCount / totalCount) * 100).round()}%'
                              : '0%',
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColorPalette.electricEmerald,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
