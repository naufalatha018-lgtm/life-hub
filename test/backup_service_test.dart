import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/backup/backup_service.dart';
import 'package:life_hub/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('BackupService Encrypted .lhpack Tests', () {
    test('Can export and restore encrypted package with matching password', () async {
      final db = await AppDatabase.initInMemoryDatabase();

      // Insert dummy data
      await db.insert('finance_transactions', {
        'id': 'tx_test_1',
        'title': 'Test Groceries',
        'amount_cents': 50000,
        'type': 'expense',
        'category': 'Groceries',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      final backupService = BackupService(db: db);
      const password = 'SuperSecretBackupPassword123!';

      // Export package
      final packageBase64 = await backupService.createEncryptedBackup(password: password);
      expect(packageBase64.isNotEmpty, true);

      // Verify header magic
      final rawBytes = base64Decode(packageBase64);
      final header = utf8.decode(rawBytes.sublist(0, 7));
      expect(header, 'LHPACK1');

      // Clear database to test restoration
      await db.delete('finance_transactions');
      final emptyCheck = await db.query('finance_transactions');
      expect(emptyCheck.isEmpty, true);

      // Restore package
      final summary = await backupService.restoreEncryptedBackup(
        packageData: packageBase64,
        password: password,
      );

      expect(summary.transactionCount, 1);

      // Verify database has restored data
      final restoredRows = await db.query('finance_transactions');
      expect(restoredRows.length, 1);
      expect(restoredRows.first['title'], 'Test Groceries');

      await db.close();
    });

    test('Fails cleanly when password is wrong', () async {
      final db = await AppDatabase.initInMemoryDatabase();
      final backupService = BackupService(db: db);

      final packageBase64 = await backupService.createEncryptedBackup(
        password: 'CorrectPassword123!',
      );

      expect(
        () async => await backupService.restoreEncryptedBackup(
          packageData: packageBase64,
          password: 'WrongPassword!',
        ),
        throwsA(isA<InvalidBackupPasswordException>()),
      );

      await db.close();
    });
  });
}
