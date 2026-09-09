import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/habits_dao.dart';
import '../../auth/providers/auth_provider.dart';
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
  HabitsNotifier(this._dao, [String? userId])
      : _userId = userId ?? 'guest_default',
        super(const AsyncValue.loading()) {
    loadHabits();
  }

  final HabitsDao _dao;
  final String _userId;

  Future<void> loadHabits() async {
    try {
      final rows = await _dao.getActiveHabits(_userId);
      final habits = rows.map((r) => Habit.fromMap(r)).toList();

      // Load today's completions
      final completedToday = <String>{};
      for (final habit in habits) {
        if (await _dao.isCompletedToday(habit.id, _userId)) {
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
      userId: _userId,
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
    await _dao.updateHabit(habit.copyWith(
      userId: _userId,
      updatedAt: DateTime.now(),
    ).toMap());
    await loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _dao.deleteHabit(id);
    await loadHabits();
  }

  Future<void> toggleCompletion(String habitId) async {
    HapticFeedback.lightImpact();
    await _dao.toggleCompletion(habitId, DateTime.now(), _userId);

    // Recalculate streak
    final allCompletions = await _dao.getAllCompletionsForHabit(habitId, _userId);
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
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final mostRecent = DateTime(sortedDates.first.year, sortedDates.first.month, sortedDates.first.day);

    final diff = todayDate.difference(mostRecent).inDays;
    if (diff > 1) return 0; // Streak broken

    int streak = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      final prev = DateTime(sortedDates[i - 1].year, sortedDates[i - 1].month, sortedDates[i - 1].day);
      final curr = DateTime(sortedDates[i].year, sortedDates[i].month, sortedDates[i].day);
      if (prev.difference(curr).inDays == 1) {
        streak++;
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
    final rows = await _dao.getCompletionsForHabit(habitId, days: 7, userId: _userId);
    return rows.map((r) => HabitCompletion.fromMap(r)).toList();
  }
}

final habitsNotifierProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<HabitsState>>((ref) {
  final dao = ref.watch(habitsDaoProvider);
  final userId = ref.watch(currentUserIdProvider);
  return HabitsNotifier(dao, userId);
});
