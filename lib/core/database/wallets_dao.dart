import 'app_database.dart';

/// Repository-style DAO for Multi-Wallet management.
class WalletsDao {
  Future<List<Map<String, dynamic>>> getAllWallets() async {
    final db = await AppDatabase.instance.database;
    return db.query('wallets', orderBy: 'sort_order ASC, created_at ASC');
  }

  Future<Map<String, dynamic>?> getDefaultWallet() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('wallets', where: 'is_default = 1', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getWalletById(String id) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('wallets', where: 'id = ?', whereArgs: [id], limit: 1);
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

  Future<void> deleteWallet(String id) async {
    final db = await AppDatabase.instance.database;
    // Move transactions to default wallet before deletion
    final defaultWallet = await getDefaultWallet();
    if (defaultWallet != null && defaultWallet['id'] != id) {
      await db.update(
        'finance_transactions',
        {'wallet_id': defaultWallet['id']},
        where: 'wallet_id = ?',
        whereArgs: [id],
      );
    }
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setDefaultWallet(String id) async {
    final db = await AppDatabase.instance.database;
    await db.update('wallets', {'is_default': 0}, where: 'is_default = 1');
    await db.update('wallets', {'is_default': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Recalculate wallet balance from transactions.
  Future<void> recalculateBalance(String walletId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0)
        AS balance
      FROM finance_transactions
      WHERE wallet_id = ?
      ''',
      [walletId],
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
