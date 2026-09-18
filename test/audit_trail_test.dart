import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/audit/audit_log_dao.dart';
import 'package:life_hub/core/audit/audit_trail_manager.dart';
import 'package:life_hub/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Immutable Audit Trail & HMAC-SHA256 Chaining Suite', () {
    late AppDatabase appDb;
    late AuditLogDao dao;
    late AuditTrailManager manager;

    setUp(() async {
      await AppDatabase.initInMemoryDatabase();
      appDb = AppDatabase.instance;
      dao = AuditLogDao(db: appDb);
      manager = AuditTrailManager(dao: dao);
    });

    tearDown(() async {
      await appDb.close();
    });

    test('Genesis block links to 64 zero-bytes and creates valid HMAC', () async {
      final entry = await manager.recordOperation(
        actorId: 'admin@lifehub.corp',
        actionType: 'CREATE',
        tableName: 'finance_transactions',
        after: {'id': 'tx_01', 'amount_cents': 50000},
      );

      expect(entry.previousHash, equals(AuditTrailManager.genesisHash));
      expect(entry.currentHash.length, equals(64)); // 256-bit hex string

      final verification = await manager.verifyChainIntegrity();
      expect(verification.isValid, isTrue);
      expect(verification.verifiedCount, equals(1));
    });

    test('Sequential chaining correctly links each block to previous block hash', () async {
      final block1 = await manager.recordOperation(
        actorId: 'user_01',
        actionType: 'CREATE',
        tableName: 'tasks',
        after: {'id': 'task_1', 'title': 'Audit Preparation'},
      );

      final block2 = await manager.recordOperation(
        actorId: 'user_02',
        actionType: 'UPDATE',
        tableName: 'tasks',
        before: {'id': 'task_1', 'status': 'pending'},
        after: {'id': 'task_1', 'status': 'completed'},
      );

      final block3 = await manager.recordOperation(
        actorId: 'user_01',
        actionType: 'DELETE',
        tableName: 'tasks',
        before: {'id': 'task_1'},
      );

      expect(block2.previousHash, equals(block1.currentHash));
      expect(block3.previousHash, equals(block2.currentHash));

      final verification = await manager.verifyChainIntegrity();
      expect(verification.isValid, isTrue);
      expect(verification.verifiedCount, equals(3));
    });

    test('Tamper detection triggers immediately when historical payload is modified', () async {
      await manager.recordOperation(
        actorId: 'user_01',
        actionType: 'CREATE',
        tableName: 'wallets',
        after: {'id': 'w_1', 'balance_cents': 1000000},
      );

      final block2 = await manager.recordOperation(
        actorId: 'user_02',
        actionType: 'UPDATE',
        tableName: 'wallets',
        after: {'id': 'w_1', 'balance_cents': 2000000},
      );

      // Verify chain is initially valid
      final initialVerif = await manager.verifyChainIntegrity();
      expect(initialVerif.isValid, isTrue);

      // Maliciously tamper with block 2 in database (simulating attacker altering balance)
      final db = await appDb.database;
      await db.rawUpdate('''
        UPDATE audit_logs 
        SET diff_payload = '{"before":{},"after":{"id":"w_1","balance_cents":999999999}}'
        WHERE log_id = ?
      ''', [block2.logId]);

      // Verification must catch the cryptographic mismatch
      final tamperedVerif = await manager.verifyChainIntegrity();
      expect(tamperedVerif.isValid, isFalse);
      expect(tamperedVerif.corruptedLogId, equals(block2.logId));
      expect(tamperedVerif.reason, contains('tampering detected'));
    });

    test('Auto-pruning removes records older than retention threshold', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fortyDaysAgo = now - Duration(days: 40).inMilliseconds;

      final db = await appDb.database;
      await db.insert('audit_logs', {
        'log_id': 'old_log_1',
        'actor_id': 'system',
        'action_type': 'CREATE',
        'table_name': 'test',
        'diff_payload': '{}',
        'device_fingerprint': 'test-host',
        'timestamp': fortyDaysAgo,
        'previous_hash': AuditTrailManager.genesisHash,
        'current_hash': 'abcdef123456',
      });

      expect(await dao.getTotalLogCount(), equals(1));

      final prunedCount = await manager.pruneOldLogs(retentionDays: 30);
      expect(prunedCount, equals(1));
      expect(await dao.getTotalLogCount(), equals(0));
    });
  });
}
