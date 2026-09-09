import 'app_database.dart';

/// Repository-style DAO for Water Logs and Mood Logs.
/// Handles daily intake tracking and mood journaling.
class WellnessDao {
  // ─────────────────────────────────────────────
  // WATER LOGS
  // ─────────────────────────────────────────────

  Future<void> addWaterLog(Map<String, dynamic> log) async {
    final db = await AppDatabase.instance.database;
    await db.insert('water_logs', log);
  }

  Future<List<Map<String, dynamic>>> getWaterLogsForDay(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dayStart = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final dayEnd = dayStart + 86400000;
    return db.query(
      'water_logs',
      where: 'logged_at >= ? AND logged_at < ?',
      whereArgs: [dayStart, dayEnd],
      orderBy: 'logged_at DESC',
    );
  }

  Future<int> getTodayTotalMl() async {
    final db = await AppDatabase.instance.database;
    final dayStart = DateTime.now();
    final start = DateTime(dayStart.year, dayStart.month, dayStart.day).millisecondsSinceEpoch;
    final end = start + 86400000;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_ml), 0) as total FROM water_logs WHERE logged_at >= ? AND logged_at < ?',
      [start, end],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteWaterLog(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('water_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────
  // MOOD LOGS
  // ─────────────────────────────────────────────

  Future<void> addMoodLog(Map<String, dynamic> log) async {
    final db = await AppDatabase.instance.database;
    await db.insert('mood_logs', log);
  }

  Future<Map<String, dynamic>?> getTodayMoodLog() async {
    final db = await AppDatabase.instance.database;
    final dayStart = DateTime.now();
    final start = DateTime(dayStart.year, dayStart.month, dayStart.day).millisecondsSinceEpoch;
    final end = start + 86400000;
    final result = await db.query(
      'mood_logs',
      where: 'logged_at >= ? AND logged_at < ?',
      whereArgs: [start, end],
      orderBy: 'logged_at DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getRecentMoodLogs({int days = 30}) async {
    final db = await AppDatabase.instance.database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    return db.query(
      'mood_logs',
      where: 'logged_at >= ?',
      whereArgs: [cutoff],
      orderBy: 'logged_at DESC',
    );
  }

  Future<void> deleteMoodLog(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('mood_logs', where: 'id = ?', whereArgs: [id]);
  }
}
