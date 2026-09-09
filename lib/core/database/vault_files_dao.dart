import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class VaultFilesDao {
  VaultFilesDao({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  Future<void> insertVaultFile(Map<String, dynamic> row) async {
    final db = await _database;
    await db.insert(
      'vault_files',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateVaultFile(Map<String, dynamic> row) async {
    final db = await _database;
    await db.update(
      'vault_files',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<void> deleteVaultFile(String id) async {
    final db = await _database;
    await db.delete(
      'vault_files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllVaultFiles() async {
    final db = await _database;
    return await db.query(
      'vault_files',
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getVaultFileById(String id) async {
    final db = await _database;
    final rows = await db.query(
      'vault_files',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }
}
