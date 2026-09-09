import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/habits_dao.dart';
import '../models/habit.dart';

final habitsDaoProvider = Provider<HabitsDao>((ref) => HabitsDao());

@immutable
class HabitsState {
  const HabitsState({
    required this.habits,
    required this.todayCompletions,
  });

  final List<Habit> habits;
  final Set<String> todayCompletions; // habit IDs completed today

  HabitsState copyWith({List<Habit>? habits, Set<String>? todayCompletions}) {
    return HabitsState(
      habits: habits ?? this.habits,
      todayCompletions: todayCompletions ?? this.todayCompletions,
    );
  }

  bool isCompletedToday(String habitId) => todayCompletions.contains(habitId);
  int get todayCompletedCount => todayCompletions.length;
  int get activeCount => habits.where((h) => h.isActive).length;
}

class HabitsNotifier extends StateNotifier<AsyncValue<HabitsState>> {
  HabitsNotifier(this._dao) : super(const AsyncValue.loading()) {
    loadHabits();
  }

  final HabitsDao _dao;

  Future<void> loadHabits() async {
    try {
      final rows = await _dao.getActiveHabits();
      final habits = rows.map((r) => Habit.fromMap(r)).toList();

      // Load today's completions
      final completedToday = <String>{};
      for (final habit in habits) {
        if (await _dao.isCompletedToday(habit.id)) {
          completedToday.add(habit.id);
        }
      }

      state = AsyncValue.data(HabitsState(
        habits: habits,
        todayCompletions: completedToday,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addHabit({
    required String title,
    String? description,
    required HabitFrequency frequency,
    required HabitCategory category,
    List<int>? targetDays,
  }) async {
    final now = DateTime.now();
    final habit = Habit(
      id: 'habit_${now.microsecondsSinceEpoch}',
      title: title.trim(),
      description: description?.trim(),
      frequency: frequency,
      category: category,
      targetDays: targetDays ?? [1, 2, 3, 4, 5, 6, 7],
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insertHabit(habit.toMap());
    HapticFeedback.lightImpact();
    await loadHabits();
  }

  Future<void> updateHabit(Habit habit) async {
    await _dao.updateHabit(habit.copyWith(updatedAt: DateTime.now()).toMap());
    await loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _dao.deleteHabit(id);
    await loadHabits();
  }

  Future<void> toggleCompletion(String habitId) async {
    HapticFeedback.lightImpact();
    await _dao.toggleCompletion(habitId, DateTime.now());

    // Recalculate streak
    final allCompletions = await _dao.getAllCompletionsForHabit(habitId);
    final sorted = allCompletions
        .map((r) => HabitCompletion.fromMap(r))
        .toList()
      ..sort((a, b) => b.completedDate.compareTo(a.completedDate));

    int current = 0;
    int longest = 0;

    if (sorted.isNotEmpty) {
      current = _calculateCurrentStreak(sorted.map((c) => c.completedDate).toList());
      longest = _calculateLongestStreak(sorted.map((c) => c.completedDate).toList());
    }

    await _dao.updateStreaks(habitId, current, longest);
    await loadHabits();
  }

  int _calculateCurrentStreak(List<DateTime> sortedDates) {
    if (sortedDates.isEmpty) return 0;
    int streak = 0;
    DateTime check = DateTime.now();
    for (final date in sortedDates) {
      final d = DateTime(date.year, date.month, date.day);
      final c = DateTime(check.year, check.month, check.day);
      if (d == c || d == c.subtract(const Duration(days: 1))) {
        streak++;
        check = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateLongestStreak(List<DateTime> sortedDates) {
    if (sortedDates.isEmpty) return 0;
    int longest = 1;
    int current = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      final prev = DateTime(sortedDates[i - 1].year, sortedDates[i - 1].month, sortedDates[i - 1].day);
      final curr = DateTime(sortedDates[i].year, sortedDates[i].month, sortedDates[i].day);
      if (prev.difference(curr).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  Future<List<HabitCompletion>> getWeekCompletions(String habitId) async {
    final rows = await _dao.getCompletionsForHabit(habitId, days: 7);
    return rows.map((r) => HabitCompletion.fromMap(r)).toList();
  }
}

final habitsNotifierProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<HabitsState>>((ref) {
  return HabitsNotifier(ref.watch(habitsDaoProvider));
});
