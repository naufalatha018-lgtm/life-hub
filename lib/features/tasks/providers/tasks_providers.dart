import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/tasks_dao.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/task_item.dart';

enum TaskViewMode {
  list('List View'),
  kanban('Kanban Board');

  final String label;
  const TaskViewMode(this.label);
}

final tasksDaoProvider = Provider<TasksDao>((ref) {
  return TasksDao();
});

final taskViewModeProvider = StateProvider<TaskViewMode>((ref) {
  return TaskViewMode.list;
});

final taskCategoryFilterProvider = StateProvider<String?>((ref) {
  return null;
});

final taskPriorityFilterProvider = StateProvider<TaskPriority?>((ref) {
  return null;
});

final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskItem>>>((ref) {
  final dao = ref.watch(tasksDaoProvider);
  final userId = ref.watch(currentUserIdProvider);
  return TasksNotifier(dao, userId);
});

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskItem>>> {
  TasksNotifier(this._dao, [String? userId])
      : _userId = userId ?? 'guest_default',
        super(const AsyncValue.loading()) {
    loadTasks();
  }

  final TasksDao _dao;
  final String _userId;

  Future<void> loadTasks() async {
    try {
      final rows = await _dao.getAllTasks(_userId);
      final list = rows.map((r) => TaskItem.fromMap(r)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TaskItem> addTask({
    required String title,
    String? description,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    required String category,
    DateTime? dueDate,
    int estimatedCostCents = 0,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    final now = DateTime.now();
    final task = TaskItem(
      id: 'task_${now.microsecondsSinceEpoch}',
      userId: _userId,
      title: title.trim(),
      description: description?.trim(),
      status: status,
      priority: priority,
      category: category,
      dueDate: dueDate,
      estimatedCostCents: estimatedCostCents,
      isExpenseLogged: false,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      createdAt: now,
      updatedAt: now,
    );

    await _dao.insertTask(task.toMap());

    state.whenData((tasks) {
      state = AsyncValue.data([task, ...tasks]);
    });

    return task;
  }

  Future<void> updateTask(TaskItem task) async {
    final updated = task.copyWith(
      userId: _userId,
      updatedAt: DateTime.now(),
    );
    await _dao.updateTask(updated.toMap());

    state.whenData((tasks) {
      state = AsyncValue.data(
        tasks.map((t) => t.id == task.id ? updated : t).toList(),
      );
    });
  }

  Future<void> updateTaskStatus(String id, TaskStatus newStatus) async {
    final now = DateTime.now();
    await _dao.updateTaskStatus(
      id: id,
      status: newStatus.name,
      updatedAt: now.millisecondsSinceEpoch,
    );

    state.whenData((tasks) {
      state = AsyncValue.data(
        tasks.map((t) {
          if (t.id == id) {
            return t.copyWith(status: newStatus, updatedAt: now);
          }
          return t;
        }).toList(),
      );
    });
  }

  Future<void> markExpenseLogged(String taskId, bool isLogged) async {
    final now = DateTime.now();
    await _dao.markExpenseLogged(
      taskId: taskId,
      isLogged: isLogged,
      updatedAt: now.millisecondsSinceEpoch,
    );

    state.whenData((tasks) {
      state = AsyncValue.data(
        tasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(isExpenseLogged: isLogged, updatedAt: now);
          }
          return t;
        }).toList(),
      );
    });
  }

  Future<void> deleteTask(String id) async {
    await _dao.deleteTask(id);
    state.whenData((tasks) {
      state = AsyncValue.data(tasks.where((t) => t.id != id).toList());
    });
  }
}

/// Filtered tasks list based on Category and Priority filters
final filteredTasksProvider = Provider<List<TaskItem>>((ref) {
  final tasksAsync = ref.watch(tasksNotifierProvider);
  final category = ref.watch(taskCategoryFilterProvider);
  final priority = ref.watch(taskPriorityFilterProvider);

  return tasksAsync.maybeWhen(
    data: (tasks) {
      return tasks.where((t) {
        if (category != null && category.isNotEmpty && t.category != category) {
          return false;
        }
        if (priority != null && t.priority != priority) {
          return false;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

final todoTasksProvider = Provider<List<TaskItem>>((ref) {
  return ref.watch(filteredTasksProvider).where((t) => t.status == TaskStatus.todo).toList();
});

final inProgressTasksProvider = Provider<List<TaskItem>>((ref) {
  return ref.watch(filteredTasksProvider).where((t) => t.status == TaskStatus.inProgress).toList();
});

final doneTasksProvider = Provider<List<TaskItem>>((ref) {
  return ref.watch(filteredTasksProvider).where((t) => t.status == TaskStatus.done).toList();
});
