import 'app_database.dart';

/// Repository-style DAO for Water Logs and Mood Logs.
/// Handles daily intake tracking and mood journaling.
class WellnessDao {
  // ─────────────────────────────────────────────
  // WATER LOGS
  // ─────────────────────────────────────────────

  Future<void> addWaterLog(Map<String, dynamic> log, [String? userId]) async {
    final db = await AppDatabase.instance.database;
    final map = Map<String, dynamic>.from(log);
    if (userId != null && !map.containsKey('user_id')) {
      map['user_id'] = userId;
    }
    await db.insert('water_logs', map);
  }

  Future<List<Map<String, dynamic>>> getWaterLogsForDay(DateTime date, [String? userId]) async {
    final db = await AppDatabase.instance.database;
    final dayStart = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final dayEnd = dayStart + 86400000;
    final where = userId != null
        ? 'user_id = ? AND logged_at >= ? AND logged_at < ?'
        : 'logged_at >= ? AND logged_at < ?';
    final whereArgs = userId != null ? [userId, dayStart, dayEnd] : [dayStart, dayEnd];
    return db.query(
      'water_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'logged_at DESC',
    );
  }

  Future<int> getTodayTotalMl([String? userId]) async {
    final db = await AppDatabase.instance.database;
    final dayStart = DateTime.now();
    final start = DateTime(dayStart.year, dayStart.month, dayStart.day).millisecondsSinceEpoch;
    final end = start + 86400000;
    final query = userId != null
        ? 'SELECT COALESCE(SUM(amount_ml), 0) as total FROM water_logs WHERE user_id = ? AND logged_at >= ? AND logged_at < ?'
        : 'SELECT COALESCE(SUM(amount_ml), 0) as total FROM water_logs WHERE logged_at >= ? AND logged_at < ?';
    final args = userId != null ? [userId, start, end] : [start, end];
    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteWaterLog(String id, [String? userId]) async {
    final db = await AppDatabase.instance.database;
    final where = userId != null ? 'id = ? AND user_id = ?' : 'id = ?';
    final whereArgs = userId != null ? [id, userId] : [id];
    await db.delete('water_logs', where: where, whereArgs: whereArgs);
  }

  // ─────────────────────────────────────────────
  // MOOD LOGS
  // ─────────────────────────────────────────────

  Future<void> addMoodLog(Map<String, dynamic> log, [String? userId]) async {
    final db = await AppDatabase.instance.database;
    final map = Map<String, dynamic>.from(log);
    if (userId != null && !map.containsKey('user_id')) {
      map['user_id'] = userId;
    }
    await db.insert('mood_logs', map);
  }

  Future<Map<String, dynamic>?> getTodayMoodLog([String? userId]) async {
    final db = await AppDatabase.instance.database;
    final dayStart = DateTime.now();
    final start = DateTime(dayStart.year, dayStart.month, dayStart.day).millisecondsSinceEpoch;
    final end = start + 86400000;
    final where = userId != null
        ? 'user_id = ? AND logged_at >= ? AND logged_at < ?'
        : 'logged_at >= ? AND logged_at < ?';
    final whereArgs = userId != null ? [userId, start, end] : [start, end];
    final result = await db.query(
      'mood_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'logged_at DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getRecentMoodLogs({int days = 30, String? userId}) async {
    final db = await AppDatabase.instance.database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final where = userId != null ? 'user_id = ? AND logged_at >= ?' : 'logged_at >= ?';
    final whereArgs = userId != null ? [userId, cutoff] : [cutoff];
    return db.query(
      'mood_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'logged_at DESC',
    );
  }

  Future<void> deleteMoodLog(String id, [String? userId]) async {
    final db = await AppDatabase.instance.database;
    final where = userId != null ? 'id = ? AND user_id = ?' : 'id = ?';
    final whereArgs = userId != null ? [id, userId] : [id];
    await db.delete('mood_logs', where: where, whereArgs: whereArgs);
  }
}
