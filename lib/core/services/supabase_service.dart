import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Summary of records synced between SQLite and Supabase Cloud.
class CloudSyncResult {
  final int walletsSynced;
  final int transactionsSynced;
  final int tasksSynced;
  final int habitsSynced;
  final bool isSuccess;
  final String? errorMessage;

  const CloudSyncResult({
    this.walletsSynced = 0,
    this.transactionsSynced = 0,
    this.tasksSynced = 0,
    this.habitsSynced = 0,
    this.isSuccess = true,
    this.errorMessage,
  });

  int get totalRecords => walletsSynced + transactionsSynced + tasksSynced + habitsSynced;
}

/// Supabase URL and anon key (from environment / hardcoded for this project).
const _supabaseUrl = 'https://tvzfwfodzwykzscayglr.supabase.co';
const _supabaseAnonKey =
    'sb_publishable_uNIwK0QkOGxgLZ9_hDukgw_x25x4d5W';

/// Central service to interact with Supabase.
///
/// All methods are safe to call even when offline. Errors are caught and
/// logged, never propagated to the UI to keep the offline-first promise.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SupabaseClient? get client => _initialized ? Supabase.instance.client : null;

  /// Must be called once from [main()] before [runApp()].
  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
        debug: kDebugMode,
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      _initialized = true;
      debugPrint('SupabaseService: initialized successfully');
    } catch (e, st) {
      _initialized = false;
      debugPrint('SupabaseService: initialization failed (offline mode) — $e\n$st');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Auth helpers
  // ─────────────────────────────────────────────────────────────────────────

  User? get currentUser => client?.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  String? get userId => currentUser?.id;

  Stream<AuthState> get authStateChanges =>
      client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (client == null) return null;
    try {
      return await client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('SupabaseService.signInWithEmail error: $e');
      rethrow;
    }
  }

  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (client == null) return null;
    try {
      return await client!.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
    } catch (e) {
      debugPrint('SupabaseService.signUpWithEmail error: $e');
      rethrow;
    }
  }

  Future<AuthResponse?> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    if (client == null) return null;
    try {
      return await client!.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
    } catch (e) {
      debugPrint('SupabaseService.verifyOtp error: $e');
      rethrow;
    }
  }

  Future<void> resendOtp({
    required String email,
    OtpType type = OtpType.signup,
  }) async {
    if (client == null) return;
    try {
      await client!.auth.resend(
        email: email,
        type: type,
      );
    } catch (e) {
      debugPrint('SupabaseService.resendOtp error: $e');
      rethrow;
    }
  }

  Future<void> resetPasswordForEmail(String email) async {
    if (client == null) throw Exception('Supabase client is not initialized.');
    try {
      await client!.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      debugPrint('SupabaseService.resetPasswordForEmail error: $e');
      rethrow;
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    if (client == null) throw Exception('Supabase client is not initialized.');
    try {
      await client!.auth.signInWithOtp(email: email.trim(), shouldCreateUser: false);
    } catch (e) {
      debugPrint('SupabaseService.signInWithMagicLink error: $e');
      rethrow;
    }
  }

  /// Web Client ID for Google Sign-In (OAuth server client ID for backend token exchange).
  static const String googleServerClientId =
      '59392267191-audaq0flvedrmtumdbt4j089n8rmu320.apps.googleusercontent.com';

  /// Performs Google Sign-In with configured [serverClientId] and links with Supabase.
  Future<AuthResponse?> signInWithGoogle({String? serverClientId}) async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: serverClientId ?? googleServerClientId,
      );
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      String? accessToken;
      try {
        final authz = await account.authorizationClient.authorizationForScopes(['email', 'profile']);
        accessToken = authz?.accessToken;
      } catch (e) {
        debugPrint('Google accessToken retrieval error: $e');
      }

      if (client != null && idToken != null) {
        return await client!.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      }
    } catch (e) {
      debugPrint('SupabaseService.signInWithGoogle error: $e');
      rethrow;
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await client?.auth.signOut();
    } catch (e) {
      debugPrint('SupabaseService.signOut error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Generic CRUD helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Deterministically converts any local string ID into a valid UUID v4 format
  /// acceptable by Supabase PostgreSQL UUID primary keys.
  static String deterministicUuid(String input) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidRegex.hasMatch(input)) return input.toLowerCase();

    final hash = crypto.md5.convert(utf8.encode(input)).toString();
    return '${hash.substring(0, 8)}-${hash.substring(8, 12)}-4${hash.substring(13, 16)}-a${hash.substring(17, 20)}-${hash.substring(20, 32)}'
        .toLowerCase();
  }

  /// Synchronizes local SQLite tables (wallets, finance_transactions, tasks, habits)
  /// directly to Supabase cloud tables for the authenticated user, and pulls down
  /// cloud records for the current user.
  Future<CloudSyncResult> syncAllLocalToCloud(Database db, [String? explicitUserId]) async {
    final uid = explicitUserId ?? userId;
    if (client == null || uid == null) {
      return const CloudSyncResult(
        isSuccess: false,
        errorMessage: 'Koneksi Supabase belum aktif atau sesi belum masuk.',
      );
    }

    int walletsCount = 0;
    int txnCount = 0;
    int tasksCount = 0;
    int habitsCount = 0;

    try {
      // 1. Wallets Upload (strictly user-scoped)
      final localWallets = await db.query(
        'wallets',
        where: 'user_id = ?',
        whereArgs: [uid],
      );
      for (final w in localWallets) {
        final cloudWallet = {
          'id': deterministicUuid('${uid}_${w['id']}'),
          'user_id': uid,
          'name': w['name'],
          'balance_cents': w['balance_cents'] ?? 0,
          'is_default': (w['is_default'] == 1),
          'created_at': DateTime.fromMillisecondsSinceEpoch(
            (w['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
          ).toIso8601String(),
        };
        await client!.from('wallets').upsert(cloudWallet);
        walletsCount++;
      }

      // 2. Finance Transactions Upload (strictly user-scoped)
      final localTxns = await db.query(
        'finance_transactions',
        where: 'user_id = ?',
        whereArgs: [uid],
      );
      for (final t in localTxns) {
        final rawWalletId = t['wallet_id'] as String?;
        final cloudTxn = {
          'id': deterministicUuid('${uid}_${t['id']}'),
          'user_id': uid,
          'wallet_id': rawWalletId != null ? deterministicUuid('${uid}_$rawWalletId') : null,
          'amount_cents': t['amount_cents'] ?? 0,
          'type': t['type'],
          'category': t['category'] ?? 'Other',
          'description': (t['note'] as String?)?.isNotEmpty == true
              ? t['note']
              : (t['title'] as String? ?? ''),
          'date': DateTime.fromMillisecondsSinceEpoch(
            (t['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
          ).toIso8601String().split('T')[0],
          'created_at': DateTime.fromMillisecondsSinceEpoch(
            (t['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
          ).toIso8601String(),
        };
        await client!.from('finance_transactions').upsert(cloudTxn);
        txnCount++;
      }

      // 3. Tasks Upload (strictly user-scoped)
      final localTasks = await db.query(
        'tasks',
        where: 'user_id = ?',
        whereArgs: [uid],
      );
      for (final tk in localTasks) {
        final rawDueDate = tk['due_date'] as int?;
        final cloudTask = {
          'id': deterministicUuid('${uid}_${tk['id']}'),
          'user_id': uid,
          'title': tk['title'],
          'description': tk['description'],
          'is_completed': (tk['status'] == 'completed' || tk['status'] == 'done'),
          'priority': (tk['priority'] ?? 'medium').toString().toLowerCase(),
          'due_date': rawDueDate != null
              ? DateTime.fromMillisecondsSinceEpoch(rawDueDate).toIso8601String().split('T')[0]
              : null,
          'created_at': DateTime.fromMillisecondsSinceEpoch(
            (tk['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
          ).toIso8601String(),
        };
        await client!.from('tasks').upsert(cloudTask);
        tasksCount++;
      }

      // 4. Habits Upload (strictly user-scoped)
      final localHabits = await db.query(
        'habits',
        where: 'user_id = ?',
        whereArgs: [uid],
      );
      for (final h in localHabits) {
        final cloudHabit = {
          'id': deterministicUuid('${uid}_${h['id']}'),
          'user_id': uid,
          'title': h['title'],
          'frequency': (h['frequency'] ?? 'daily').toString().toLowerCase(),
          'category': h['category'] ?? 'General',
          'streak_current': h['streak_current'] ?? 0,
          'created_at': DateTime.fromMillisecondsSinceEpoch(
            (h['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
          ).toIso8601String(),
        };
        await client!.from('habits').upsert(cloudHabit);
        habitsCount++;
      }

      // ── PULL DOWN FROM SUPABASE INTO LOCAL SQLITE (user-scoped) ─────────────
      try {
        final remoteWallets = await client!.from('wallets').select().eq('user_id', uid);
        for (final rw in remoteWallets) {
          final rawCreated = rw['created_at'] != null ? DateTime.tryParse(rw['created_at'])?.millisecondsSinceEpoch : null;
          await db.insert('wallets', {
            'id': rw['id'],
            'user_id': uid,
            'name': rw['name'] ?? 'Rekening Utama',
            'balance_cents': rw['balance_cents'] ?? 0,
            'is_default': (rw['is_default'] == true) ? 1 : 0,
            'created_at': rawCreated ?? DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (e) {
        debugPrint('SupabaseService pull remote wallets: $e');
      }

      try {
        final remoteTxns = await client!.from('finance_transactions').select().eq('user_id', uid);
        for (final rt in remoteTxns) {
          final rawDate = rt['date'] != null ? DateTime.tryParse(rt['date'])?.millisecondsSinceEpoch : null;
          final rawCreated = rt['created_at'] != null ? DateTime.tryParse(rt['created_at'])?.millisecondsSinceEpoch : null;
          await db.insert('finance_transactions', {
            'id': rt['id'],
            'user_id': uid,
            'wallet_id': rt['wallet_id'],
            'title': rt['description'] ?? rt['category'] ?? 'Transaksi',
            'amount_cents': rt['amount_cents'] ?? 0,
            'type': rt['type'] ?? 'expense',
            'category': rt['category'] ?? 'Other',
            'timestamp': rawDate ?? rawCreated ?? DateTime.now().millisecondsSinceEpoch,
            'note': rt['description'],
            'created_at': rawCreated ?? DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (e) {
        debugPrint('SupabaseService pull remote txns: $e');
      }

      try {
        final remoteTasks = await client!.from('tasks').select().eq('user_id', uid);
        for (final rtk in remoteTasks) {
          final rawDue = rtk['due_date'] != null ? DateTime.tryParse(rtk['due_date'])?.millisecondsSinceEpoch : null;
          final rawCreated = rtk['created_at'] != null ? DateTime.tryParse(rtk['created_at'])?.millisecondsSinceEpoch : null;
          await db.insert('tasks', {
            'id': rtk['id'],
            'user_id': uid,
            'title': rtk['title'] ?? 'Tugas',
            'description': rtk['description'],
            'status': (rtk['is_completed'] == true) ? 'done' : 'todo',
            'priority': rtk['priority'] ?? 'medium',
            'category': 'General',
            'due_date': rawDue,
            'created_at': rawCreated ?? DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (e) {
        debugPrint('SupabaseService pull remote tasks: $e');
      }

      try {
        final remoteHabits = await client!.from('habits').select().eq('user_id', uid);
        for (final rh in remoteHabits) {
          final rawCreated = rh['created_at'] != null ? DateTime.tryParse(rh['created_at'])?.millisecondsSinceEpoch : null;
          await db.insert('habits', {
            'id': rh['id'],
            'user_id': uid,
            'title': rh['title'] ?? 'Kebiasaan',
            'frequency': rh['frequency'] ?? 'daily',
            'category': rh['category'] ?? 'productivity',
            'streak_current': rh['streak_current'] ?? 0,
            'created_at': rawCreated ?? DateTime.now().millisecondsSinceEpoch,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (e) {
        debugPrint('SupabaseService pull remote habits: $e');
      }

      return CloudSyncResult(
        walletsSynced: walletsCount,
        transactionsSynced: txnCount,
        tasksSynced: tasksCount,
        habitsSynced: habitsCount,
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('SupabaseService.syncAllLocalToCloud error: $e');
      return CloudSyncResult(
        walletsSynced: walletsCount,
        transactionsSynced: txnCount,
        tasksSynced: tasksCount,
        habitsSynced: habitsCount,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Upserts a row into [table]. Returns true on success.
  Future<bool> upsert(String table, Map<String, dynamic> data) async {
    if (client == null || userId == null) return false;
    try {
      await client!.from(table).upsert({...data, 'user_id': userId});
      return true;
    } catch (e) {
      debugPrint('SupabaseService.upsert($table) error: $e');
      return false;
    }
  }

  /// Soft-deletes a row by setting deleted_at.
  Future<bool> softDelete(String table, String id) async {
    if (client == null || userId == null) return false;
    try {
      await client!.from(table).update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).match({'id': id, 'user_id': userId!});
      return true;
    } catch (e) {
      debugPrint('SupabaseService.softDelete($table, $id) error: $e');
      return false;
    }
  }

  /// Fetches all non-deleted rows for the current user.
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    if (client == null || userId == null) return [];
    try {
      final response = await client!
          .from(table)
          .select()
          .eq('user_id', userId!)
          .isFilter('deleted_at', null);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('SupabaseService.fetchAll($table) error: $e');
      return [];
    }
  }
}
