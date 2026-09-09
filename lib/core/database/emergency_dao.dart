import 'app_database.dart';

/// DAO for the Emergency SOS Card.
/// Uses a single-row upsert pattern (id = 'singleton').
/// No encryption — accessible without Vault PIN.
class EmergencyDao {
  static const String _singletonId = 'singleton';

  Future<Map<String, dynamic>?> getCard() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'emergency_card',
      where: 'id = ?',
      whereArgs: [_singletonId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> upsertCard(Map<String, dynamic> card) async {
    final db = await AppDatabase.instance.database;
    final existing = await getCard();
    if (existing == null) {
      await db.insert('emergency_card', {
        ...card,
        'id': _singletonId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await db.update(
        'emergency_card',
        {
          ...card,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [_singletonId],
      );
    }
  }

  Future<void> clearCard() async {
    final db = await AppDatabase.instance.database;
    await db.delete('emergency_card', where: 'id = ?', whereArgs: [_singletonId]);
  }
}
