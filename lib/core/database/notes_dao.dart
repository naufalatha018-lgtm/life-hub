import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class NotesDao {
  NotesDao({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  Future<void> insertNote(Map<String, dynamic> row) async {
    final db = await _database;
    await db.insert(
      'secure_notes',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Map<String, dynamic> row) async {
    final db = await _database;
    await db.update(
      'secure_notes',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await _database;
    await db.delete(
      'secure_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllEncryptedNotes() async {
    final db = await _database;
    return await db.query(
      'secure_notes',
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
  }

  Future<void> togglePin({
    required String id,
    required bool isPinned,
    required int updatedAt,
  }) async {
    final db = await _database;
    await db.update(
      'secure_notes',
      {
        'is_pinned': isPinned ? 1 : 0,
        'updated_at': updatedAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
