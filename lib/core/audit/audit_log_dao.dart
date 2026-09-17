import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import 'audit_log_model.dart';

/// SQLite Data Access Object for Immutable Audit Trail records.
class AuditLogDao {
  AuditLogDao({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  /// Inserts a new immutable audit record.
  Future<void> insertLog(AuditLogEntry entry, [Transaction? txn]) async {
    final executor = txn ?? (await _database);
    await executor.insert(
      'audit_logs',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail, // Immutable — strictly no overwrite
    );
  }

  /// Retrieves the latest record at the head of the cryptographic chain.
  Future<AuditLogEntry?> getLatestLog() async {
    final db = await _database;
    final results = await db.query(
      'audit_logs',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return AuditLogEntry.fromMap(results.first);
  }

  /// Retrieves all records in ascending chronological order for blockchain verification.
  Future<List<AuditLogEntry>> getAllLogsAscending() async {
    final db = await _database;
    final results = await db.query(
      'audit_logs',
      orderBy: 'timestamp ASC',
    );
    return results.map((m) => AuditLogEntry.fromMap(m)).toList();
  }

  /// Retrieves recent records in descending order for executive UI inspection.
  Future<List<AuditLogEntry>> getRecentLogs({int limit = 50, int offset = 0}) async {
    final db = await _database;
    final results = await db.query(
      'audit_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((m) => AuditLogEntry.fromMap(m)).toList();
  }

  /// Returns total count of audit records.
  Future<int> getTotalLogCount() async {
    final db = await _database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM audit_logs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Deletes logs older than [epochThreshold] (e.g. 30 days) to keep database compact.
  Future<int> pruneLogsOlderThan(int epochThreshold) async {
    final db = await _database;
    return await db.delete(
      'audit_logs',
      where: 'timestamp < ?',
      whereArgs: [epochThreshold],
    );
  }
}
