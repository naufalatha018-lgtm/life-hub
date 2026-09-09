import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/db_platform/db_platform.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/providers/notes_auth_provider.dart';

@immutable
class StorageStats {
  final int dbSizeBytes;
  final int vaultSizeBytes;
  final int cacheSizeBytes;
  final int transactionCount;
  final int taskCount;
  final int noteCount;
  final int vaultFileCount;

  const StorageStats({
    required this.dbSizeBytes,
    required this.vaultSizeBytes,
    required this.cacheSizeBytes,
    required this.transactionCount,
    required this.taskCount,
    required this.noteCount,
    required this.vaultFileCount,
  });

  int get totalSizeBytes => dbSizeBytes + vaultSizeBytes + cacheSizeBytes;

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedDbSize => formatBytes(dbSizeBytes);
  String get formattedVaultSize => formatBytes(vaultSizeBytes);
  String get formattedCacheSize => formatBytes(cacheSizeBytes);
  String get formattedTotalSize => formatBytes(totalSizeBytes);
}

final appThemeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final appThemeVariantProvider = StateProvider<AppThemeVariant>((ref) => AppThemeVariant.lightExecutive);

final autoLockTimeoutProvider = StateProvider<int>((ref) => 300); // 5 minutes default

class StorageManagerNotifier extends StateNotifier<AsyncValue<StorageStats>> {
  final Ref _ref;

  StorageManagerNotifier(this._ref) : super(const AsyncValue.loading()) {
    refreshStats();
  }

  Future<void> refreshStats() async {
    state = const AsyncValue.loading();
    try {
      final db = await AppDatabase.instance.database;

      // Calculate Database size
      int dbSize = 0;
      try {
        final dbPath = await getPlatformDatabasePath('life_hub_v2.db');
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          dbSize = await dbFile.length();
        }
      } catch (_) {}

      // Calculate Vault Storage size
      int vaultSize = 0;
      try {
        if (!kIsWeb) {
          final appDocDir = await getApplicationDocumentsDirectory();
          final vaultDir = Directory(p.join(appDocDir.path, 'vault_storage'));
          if (await vaultDir.exists()) {
            await for (final entity in vaultDir.list(recursive: true, followLinks: false)) {
              if (entity is File) {
                vaultSize += await entity.length();
              }
            }
          }
        }
      } catch (_) {}

      // Calculate Temporary Cache size
      int cacheSize = 0;
      try {
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          if (await tempDir.exists()) {
            await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
              if (entity is File) {
                cacheSize += await entity.length();
              }
            }
          }
        }
      } catch (_) {}

      // Query database record counts
      int txCount = 0;
      int taskCount = 0;
      int noteCount = 0;
      int fileCount = 0;

      try {
        final txRes = await db.rawQuery('SELECT COUNT(*) as count FROM finance_transactions');
        txCount = (txRes.first['count'] as num?)?.toInt() ?? 0;

        final taskRes = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
        taskCount = (taskRes.first['count'] as num?)?.toInt() ?? 0;

        final noteRes = await db.rawQuery('SELECT COUNT(*) as count FROM secure_notes');
        noteCount = (noteRes.first['count'] as num?)?.toInt() ?? 0;

        final fileRes = await db.rawQuery('SELECT COUNT(*) as count FROM vault_files');
        fileCount = (fileRes.first['count'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      state = AsyncValue.data(
        StorageStats(
          dbSizeBytes: dbSize,
          vaultSizeBytes: vaultSize,
          cacheSizeBytes: cacheSize,
          transactionCount: txCount,
          taskCount: taskCount,
          noteCount: noteCount,
          vaultFileCount: fileCount,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> clearTemporaryCache() async {
    int bytesReclaimed = 0;
    try {
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          await for (final entity in tempDir.list(recursive: false)) {
            try {
              if (entity is File) {
                bytesReclaimed += await entity.length();
                await entity.delete();
              } else if (entity is Directory) {
                await for (final sub in entity.list(recursive: true)) {
                  if (sub is File) bytesReclaimed += await sub.length();
                }
                await entity.delete(recursive: true);
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    await refreshStats();
    return bytesReclaimed;
  }

  Future<void> wipeAllLocalData() async {
    try {
      final db = await AppDatabase.instance.database;
      await db.delete('finance_transactions');
      await db.delete('tasks');
      await db.delete('secure_notes');
      await db.delete('vault_files');
      await db.delete('app_users');

      // Wipe vault directory
      if (!kIsWeb) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final vaultDir = Directory(p.join(appDocDir.path, 'vault_storage'));
        if (await vaultDir.exists()) {
          await vaultDir.delete(recursive: true);
        }
      }

      // Purge vault keys and lock
      _ref.read(notesAuthNotifierProvider.notifier).lockAndPurge();

      // Wipe secure storage
      const storage = FlutterSecureStorage();
      await storage.deleteAll();

      // Sign out
      await _ref.read(authNotifierProvider.notifier).signOut();
    } catch (_) {
      rethrow;
    }
  }
}

final storageStatsProvider =
    StateNotifierProvider<StorageManagerNotifier, AsyncValue<StorageStats>>((ref) {
  return StorageManagerNotifier(ref);
});
