import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class VaultFilesDao {
  VaultFilesDao({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  Future<void> insertVaultFile(Map<String, dynamic> row, [String? userId]) async {
    final db = await _database;
    final map = Map<String, dynamic>.from(row);
    if (userId != null && !map.containsKey('user_id')) {
      map['user_id'] = userId;
    }
    await db.insert(
      'vault_files',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateVaultFile(Map<String, dynamic> row, [String? userId]) async {
    final db = await _database;
    if (userId != null) {
      await db.update(
        'vault_files',
        row,
        where: 'id = ? AND user_id = ?',
        whereArgs: [row['id'], userId],
      );
    } else {
      await db.update(
        'vault_files',
        row,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> deleteVaultFile(String id, [String? userId]) async {
    final db = await _database;
    if (userId != null) {
      await db.delete(
        'vault_files',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    } else {
      await db.delete(
        'vault_files',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllVaultFiles([String? userId]) async {
    final db = await _database;
    if (userId != null) {
      return await db.query(
        'vault_files',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    }
    return await db.query(
      'vault_files',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getVaultFileById(String id, [String? userId]) async {
    final db = await _database;
    final where = userId != null ? 'id = ? AND user_id = ?' : 'id = ?';
    final whereArgs = userId != null ? [id, userId] : [id];
    final rows = await db.query(
      'vault_files',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }
}
