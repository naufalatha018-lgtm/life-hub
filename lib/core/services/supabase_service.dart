import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      return null;
    }
  }

  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (client == null) return null;
    try {
      return await client!.auth.signUp(email: email, password: password);
    } catch (e) {
      debugPrint('SupabaseService.signUpWithEmail error: $e');
      return null;
    }
  }

  /// Web Client ID for Google Sign-In (OAuth server client ID for backend token exchange).
  static const String googleServerClientId = 'PASTE_WEB_CLIENT_ID_KAMU_DI_SINI';

  /// Performs Google Sign-In with configured [serverClientId] and links with Supabase.
  Future<AuthResponse?> signInWithGoogle({String? serverClientId}) async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: serverClientId ?? googleServerClientId,
      );
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      if (client != null && idToken != null) {
        return await client!.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
      }
    } catch (e) {
      debugPrint('SupabaseService.signInWithGoogle error: $e');
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
