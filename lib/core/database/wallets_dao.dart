import 'app_database.dart';

/// Repository-style DAO for Multi-Wallet management.
class WalletsDao {
  Future<List<Map<String, dynamic>>> getAllWallets(String userId) async {
    final db = await AppDatabase.instance.database;
    return db.query(
      'wallets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'sort_order ASC, created_at ASC',
    );
  }

  Future<Map<String, dynamic>?> getDefaultWallet(String userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'wallets',
      where: 'user_id = ? AND is_default = 1',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getWalletById(String id, [String? userId]) async {
    final db = await AppDatabase.instance.database;
    final where = userId != null ? 'id = ? AND user_id = ?' : 'id = ?';
    final whereArgs = userId != null ? [id, userId] : [id];
    final result = await db.query('wallets', where: where, whereArgs: whereArgs, limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> insertWallet(Map<String, dynamic> wallet) async {
    final db = await AppDatabase.instance.database;
    await db.insert('wallets', wallet);
  }

  Future<void> updateWallet(Map<String, dynamic> wallet) async {
    final db = await AppDatabase.instance.database;
    await db.update('wallets', wallet, where: 'id = ?', whereArgs: [wallet['id']]);
  }

  Future<void> deleteWallet(String id, String userId) async {
    final db = await AppDatabase.instance.database;
    // Move transactions to default wallet before deletion
    final defaultWallet = await getDefaultWallet(userId);
    if (defaultWallet != null && defaultWallet['id'] != id) {
      await db.update(
        'finance_transactions',
        {'wallet_id': defaultWallet['id']},
        where: 'wallet_id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    }
    await db.delete('wallets', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
  }

  Future<void> setDefaultWallet(String id, String userId) async {
    final db = await AppDatabase.instance.database;
    await db.update('wallets', {'is_default': 0}, where: 'user_id = ? AND is_default = 1', whereArgs: [userId]);
    await db.update(
      'wallets',
      {'is_default': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Recalculate wallet balance from transactions.
  Future<void> recalculateBalance(String walletId, [String? userId]) async {
    final db = await AppDatabase.instance.database;
    final whereClause = userId != null
        ? 'WHERE wallet_id = ? AND user_id = ?'
        : 'WHERE wallet_id = ?';
    final args = userId != null ? [walletId, userId] : [walletId];

    final result = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0)
        AS balance
      FROM finance_transactions
      $whereClause
      ''',
      args,
    );
    final balance = (result.first['balance'] as num?)?.toInt() ?? 0;
    await db.update(
      'wallets',
      {'balance_cents': balance, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }
}
