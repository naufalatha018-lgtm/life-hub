import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class NotesDao {
  NotesDao({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  Future<void> insertNote(Map<String, dynamic> row, [String? userId]) async {
    final db = await _database;
    final map = Map<String, dynamic>.from(row);
    if (userId != null && !map.containsKey('user_id')) {
      map['user_id'] = userId;
    }
    await db.insert(
      'secure_notes',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Map<String, dynamic> row, [String? userId]) async {
    final db = await _database;
    if (userId != null) {
      await db.update(
        'secure_notes',
        row,
        where: 'id = ? AND user_id = ?',
        whereArgs: [row['id'], userId],
      );
    } else {
      await db.update(
        'secure_notes',
        row,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> deleteNote(String id, [String? userId]) async {
    final db = await _database;
    if (userId != null) {
      await db.delete(
        'secure_notes',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    } else {
      await db.delete(
        'secure_notes',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllEncryptedNotes([String? userId]) async {
    final db = await _database;
    if (userId != null) {
      return await db.query(
        'secure_notes',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'is_pinned DESC, updated_at DESC',
      );
    }
    return await db.query(
      'secure_notes',
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
  }

  Future<void> togglePin({
    required String id,
    required bool isPinned,
    required int updatedAt,
    String? userId,
  }) async {
    final db = await _database;
    final where = userId != null ? 'id = ? AND user_id = ?' : 'id = ?';
    final whereArgs = userId != null ? [id, userId] : [id];
    await db.update(
      'secure_notes',
      {
        'is_pinned': isPinned ? 1 : 0,
        'updated_at': updatedAt,
      },
      where: where,
      whereArgs: whereArgs,
    );
  }
}
