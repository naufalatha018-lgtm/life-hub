import 'app_database.dart';

/// Repository-style DAO for Habits and HabitCompletions.
/// Handles CRUD, streak calculation, and daily completion state.
class HabitsDao {
  Future<List<Map<String, dynamic>>> getActiveHabits() async {
    final db = await AppDatabase.instance.database;
    return db.query('habits', where: 'is_active = 1', orderBy: 'created_at ASC');
  }

  Future<List<Map<String, dynamic>>> getAllHabits() async {
    final db = await AppDatabase.instance.database;
    return db.query('habits', orderBy: 'created_at ASC');
  }

  Future<void> insertHabit(Map<String, dynamic> habit) async {
    final db = await AppDatabase.instance.database;
    await db.insert('habits', habit);
  }

  Future<void> updateHabit(Map<String, dynamic> habit) async {
    final db = await AppDatabase.instance.database;
    await db.update('habits', habit, where: 'id = ?', whereArgs: [habit['id']]);
  }

  Future<void> deleteHabit(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('habit_completions', where: 'habit_id = ?', whereArgs: [id]);
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> archiveHabit(String id) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'habits',
      {'is_active': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Record a completion for today. Returns true if inserted, false if already done.
  Future<bool> toggleCompletion(String habitId, DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dayStart = _dayStart(date);
    final existing = await db.query(
      'habit_completions',
      where: 'habit_id = ? AND completed_date >= ? AND completed_date < ?',
      whereArgs: [habitId, dayStart, dayStart + 86400000],
    );

    if (existing.isNotEmpty) {
      // Remove completion (toggle off)
      await db.delete(
        'habit_completions',
        where: 'habit_id = ? AND completed_date >= ? AND completed_date < ?',
        whereArgs: [habitId, dayStart, dayStart + 86400000],
      );
      return false;
    } else {
      // Add completion
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('habit_completions', {
        'id': 'hc_${now}_$habitId',
        'habit_id': habitId,
        'completed_date': dayStart,
        'created_at': now,
      });
      return true;
    }
  }

  /// Get completions for the last [days] days for a specific habit.
  Future<List<Map<String, dynamic>>> getCompletionsForHabit(String habitId, {int days = 7}) async {
    final db = await AppDatabase.instance.database;
    final cutoff = _dayStart(DateTime.now().subtract(Duration(days: days)));
    return db.query(
      'habit_completions',
      where: 'habit_id = ? AND completed_date >= ?',
      whereArgs: [habitId, cutoff],
      orderBy: 'completed_date DESC',
    );
  }

  /// Check if a habit was completed today.
  Future<bool> isCompletedToday(String habitId) async {
    final db = await AppDatabase.instance.database;
    final dayStart = _dayStart(DateTime.now());
    final result = await db.query(
      'habit_completions',
      where: 'habit_id = ? AND completed_date >= ? AND completed_date < ?',
      whereArgs: [habitId, dayStart, dayStart + 86400000],
    );
    return result.isNotEmpty;
  }

  /// Update streak values for a habit.
  Future<void> updateStreaks(String habitId, int current, int longest) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'habits',
      {
        'streak_current': current,
        'streak_longest': longest,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  /// Get all completions (for streak recalculation).
  Future<List<Map<String, dynamic>>> getAllCompletionsForHabit(String habitId) async {
    final db = await AppDatabase.instance.database;
    return db.query(
      'habit_completions',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'completed_date DESC',
    );
  }

  int _dayStart(DateTime date) {
    return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  }
}
