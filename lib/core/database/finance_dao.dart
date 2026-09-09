import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class FinanceDao {
  FinanceDao({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  Future<Database> get _database => _db.database;

  Future<void> insertTransaction(Map<String, dynamic> row) async {
    final db = await _database;
    await db.insert(
      'finance_transactions',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(Map<String, dynamic> row) async {
    final db = await _database;
    await db.update(
      'finance_transactions',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _database;
    await db.delete(
      'finance_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await _database;
    return await db.query(
      'finance_transactions',
      orderBy: 'timestamp DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDateRange({
    required int startEpoch,
    required int endEpoch,
  }) async {
    final db = await _database;
    return await db.query(
      'finance_transactions',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startEpoch, endEpoch],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> getTotalIncomeCents({int? startEpoch, int? endEpoch}) async {
    final db = await _database;
    String query = 'SELECT COALESCE(SUM(amount_cents), 0) as total FROM finance_transactions WHERE type = "income"';
    List<dynamic> args = [];

    if (startEpoch != null && endEpoch != null) {
      query += ' AND timestamp >= ? AND timestamp <= ?';
      args = [startEpoch, endEpoch];
    }

    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> getTotalExpenseCents({int? startEpoch, int? endEpoch}) async {
    final db = await _database;
    String query = 'SELECT COALESCE(SUM(amount_cents), 0) as total FROM finance_transactions WHERE type = "expense"';
    List<dynamic> args = [];

    if (startEpoch != null && endEpoch != null) {
      query += ' AND timestamp >= ? AND timestamp <= ?';
      args = [startEpoch, endEpoch];
    }

    final result = await db.rawQuery(query, args);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, int>> getCategoryExpenseAggregations({
    int? startEpoch,
    int? endEpoch,
  }) async {
    final db = await _database;
    String query = '''
      SELECT category, COALESCE(SUM(amount_cents), 0) as total
      FROM finance_transactions
      WHERE type = "expense"
    ''';
    List<dynamic> args = [];

    if (startEpoch != null && endEpoch != null) {
      query += ' AND timestamp >= ? AND timestamp <= ?';
      args = [startEpoch, endEpoch];
    }

    query += ' GROUP BY category ORDER BY total DESC';

    final result = await db.rawQuery(query, args);
    final Map<String, int> breakdown = {};
    for (final row in result) {
      final category = row['category'] as String;
      final total = (row['total'] as num?)?.toInt() ?? 0;
      breakdown[category] = total;
    }
    return breakdown;
  }
}
