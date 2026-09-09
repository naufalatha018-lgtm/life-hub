import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../crypto/aes_gcm_helper.dart';
import '../database/app_database.dart';

class BackupRestoreSummary {
  final int transactionCount;
  final int taskCount;
  final int noteCount;
  final String exportedAt;

  const BackupRestoreSummary({
    required this.transactionCount,
    required this.taskCount,
    required this.noteCount,
    required this.exportedAt,
  });
}

class InvalidBackupPasswordException implements Exception {
  final String message;
  const InvalidBackupPasswordException([this.message = 'Invalid backup password or corrupted package']);

  @override
  String toString() => message;
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupService {
  static const String _magicHeader = 'LHPACK1';
  final Database? _dbOverride;

  BackupService({Database? db}) : _dbOverride = db;

  Future<Database> get _db async => _dbOverride ?? await AppDatabase.instance.database;

  /// Generates a password-protected, encrypted `.lhpack` backup file.
  Future<String> createEncryptedBackup({required String password}) async {
    final db = await _db;

    final txRows = await db.query('finance_transactions');
    final taskRows = await db.query('tasks');
    final noteRows = await db.query('secure_notes');

    final payloadMap = {
      'version': 1,
      'app': 'Life Hub',
      'exported_at': DateTime.now().toIso8601String(),
      'transactions': txRows,
      'tasks': taskRows,
      'notes': noteRows,
    };

    final rawJsonBytes = utf8.encode(jsonEncode(payloadMap));

    // 1. Derive 256-bit AES key using PBKDF2 with 100,000 iterations
    final salt = AesGcmHelper.generateRandomSalt(16);
    final derivedKey = await AesGcmHelper.deriveKeyFromPin(pin: password, salt: salt);

    // 2. Encrypt with AES-256-GCM
    final encryptedData = await AesGcmHelper.encryptBytes(
      clearBytes: rawJsonBytes,
      derivedKey: derivedKey,
    );

    // 3. Pack into binary format:
    // [Header 7B: 'LHPACK1'][Salt len 1B][Salt 16B][EncryptedData (Nonce 12B + MAC 16B + Ciphertext)]
    final headerBytes = utf8.encode(_magicHeader);
    final buffer = BytesBuilder();
    buffer.add(headerBytes);
    buffer.addByte(salt.length);
    buffer.add(salt);
    buffer.add(encryptedData);

    final finalBytes = buffer.toBytes();
    final base64Output = base64Encode(finalBytes);

    // Write to documents directory for easy local device access
    if (!kIsWeb && _dbOverride == null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'life_hub_backup_${DateTime.now().millisecondsSinceEpoch}.lhpack';
        final file = File(p.join(dir.path, fileName));
        await file.writeAsBytes(finalBytes);
      } catch (_) {}
    }

    return base64Output;
  }

  /// Restores database records from an encrypted `.lhpack` package.
  Future<BackupRestoreSummary> restoreEncryptedBackup({
    required String packageData,
    required String password,
  }) async {
    Uint8List rawBytes;
    try {
      rawBytes = base64Decode(packageData.trim());
    } catch (_) {
      throw const InvalidBackupPasswordException('Invalid backup package format.');
    }

    final headerBytes = utf8.encode(_magicHeader);
    if (rawBytes.length < headerBytes.length + 45) {
      throw const InvalidBackupPasswordException('Corrupted or invalid backup package.');
    }

    // Verify magic header
    for (int i = 0; i < headerBytes.length; i++) {
      if (rawBytes[i] != headerBytes[i]) {
        throw const InvalidBackupPasswordException('Invalid Life Hub backup file header.');
      }
    }

    int offset = headerBytes.length;
    final saltLen = rawBytes[offset++];
    final salt = rawBytes.sublist(offset, offset + saltLen);
    offset += saltLen;

    final packedBytes = rawBytes.sublist(offset);

    // Derive key
    final derivedKey = await AesGcmHelper.deriveKeyFromPin(pin: password, salt: salt);

    Uint8List decryptedBytes;
    try {
      decryptedBytes = await AesGcmHelper.decryptBytes(
        packedBytes: packedBytes,
        derivedKey: derivedKey,
      );
    } catch (e) {
      throw const InvalidBackupPasswordException('Incorrect password or corrupted backup package.');
    }

    final jsonString = utf8.decode(decryptedBytes);
    final map = jsonDecode(jsonString) as Map<String, dynamic>;

    final txList = (map['transactions'] as List?) ?? [];
    final taskList = (map['tasks'] as List?) ?? [];
    final noteList = (map['notes'] as List?) ?? [];

    final db = await _db;
    await db.transaction((txn) async {
      for (final tx in txList) {
        if (tx is Map<String, dynamic>) {
          await txn.insert('finance_transactions', tx, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      for (final task in taskList) {
        if (task is Map<String, dynamic>) {
          await txn.insert('tasks', task, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      for (final note in noteList) {
        if (note is Map<String, dynamic>) {
          await txn.insert('secure_notes', note, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });

    return BackupRestoreSummary(
      transactionCount: txList.length,
      taskCount: taskList.length,
      noteCount: noteList.length,
      exportedAt: (map['exported_at'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }
}
