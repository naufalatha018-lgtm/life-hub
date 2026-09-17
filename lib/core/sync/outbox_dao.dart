import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import 'outbox_sync_item.dart';

/// Data Access Object for SQLite Outbox Sync Queue.
class OutboxDao {
  OutboxDao({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  /// Enqueues a sync item within an ongoing database transaction or independently.
  Future<void> enqueue(OutboxSyncItem item, [Transaction? txn]) async {
    final executor = txn ?? (await _database);
    await executor.insert(
      'outbox_sync_queue',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves the oldest pending items (FIFO) for synchronization.
  Future<List<OutboxSyncItem>> getPendingItems({int limit = 50}) async {
    final db = await _database;
    final results = await db.query(
      'outbox_sync_queue',
      where: "status = 'PENDING' OR status = 'FAILED'",
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return results.map((m) => OutboxSyncItem.fromMap(m)).toList();
  }

  /// Marks an item as actively being processed.
  Future<void> markProcessing(String id) async {
    final db = await _database;
    await db.update(
      'outbox_sync_queue',
      {
        'status': OutboxStatus.processing.name.toUpperCase(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marks an item as successfully completed and removes it or archives it.
  Future<void> markCompleted(String id) async {
    final db = await _database;
    // Remove completed item to keep outbox slim, or set to completed
    await db.delete(
      'outbox_sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Increments retry count and sets status to failed with error message.
  Future<void> markFailed(String id, String error) async {
    final db = await _database;
    await db.rawUpdate('''
      UPDATE outbox_sync_queue 
      SET status = 'FAILED', 
          retry_count = retry_count + 1, 
          last_error = ?, 
          updated_at = ?
      WHERE id = ?
    ''', [error, DateTime.now().millisecondsSinceEpoch, id]);
  }

  /// Returns count of items remaining in outbox queue.
  Future<int> getPendingCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM outbox_sync_queue WHERE status = 'PENDING' OR status = 'FAILED'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Clears all completed or failed outbox entries (manual purge).
  Future<int> clearAll() async {
    final db = await _database;
    return await db.delete('outbox_sync_queue');
  }
}
