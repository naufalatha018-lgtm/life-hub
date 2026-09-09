import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class TasksDao {
  TasksDao({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  Future<void> insertTask(Map<String, dynamic> row) async {
    final db = await _database;
    await db.insert(
      'tasks',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(Map<String, dynamic> row) async {
    final db = await _database;
    await db.update(
      'tasks',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await _database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await _database;
    return await db.query(
      'tasks',
      orderBy: 'created_at DESC',
    );
  }

  Future<void> updateTaskStatus({
    required String id,
    required String status,
    required int updatedAt,
  }) async {
    final db = await _database;
    await db.update(
      'tasks',
      {
        'status': status,
        'updated_at': updatedAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markExpenseLogged({
    required String taskId,
    required bool isLogged,
    required int updatedAt,
  }) async {
    final db = await _database;
    await db.update(
      'tasks',
      {
        'is_expense_logged': isLogged ? 1 : 0,
        'updated_at': updatedAt,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}
