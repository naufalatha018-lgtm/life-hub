import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/crypto/aes_gcm_helper.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/currency_provider.dart';
import '../models/user_model.dart';

class UnverifiedAccountException implements Exception {
  final String message;
  final String email;
  const UnverifiedAccountException(this.message, this.email);

  @override
  String toString() => message;
}

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AppDatabase _db;
  final FlutterSecureStorage _storage;
  static const _sessionKey = 'active_auth_user_id';

  String? _pendingVerificationEmail;
  String? _lastSentVerificationCode;

  AuthNotifier(this._db, this._storage) : super(const AsyncValue.loading()) {
    checkSession();
  }

  String? get pendingVerificationEmail => _pendingVerificationEmail;
  String? get lastSentVerificationCode => _lastSentVerificationCode;

  Future<void> checkSession() async {
    try {
      final userId = await _storage.read(key: _sessionKey);
      if (userId == null || userId.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }

      final db = await _db.database;
      final rows = await db.query(
        'app_users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final user = AppUser.fromMap(rows.first);
        if (!user.isVerified) {
          // Unverified account cannot maintain active session
          await _storage.delete(key: _sessionKey);
          _pendingVerificationEmail = user.email;
          _lastSentVerificationCode = rows.first['verification_code'] as String?;
          state = const AsyncValue.data(null);
          return;
        }
        state = AsyncValue.data(user);
      } else {
        await _storage.delete(key: _sessionKey);
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  static void validatePasswordStrength(String password) {
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long.');
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    if (!hasLetter || !hasDigit) {
      throw Exception('Password must contain both letters and numbers.');
    }
  }

  void _triggerCloudSync() {
    Future.microtask(() async {
      try {
        final db = await _db.database;
        final res = await SupabaseService.instance.syncAllLocalToCloud(db);
        debugPrint('Auto cloud sync: ${res.totalRecords} records synced (success: ${res.isSuccess})');
      } catch (e) {
        debugPrint('Auto cloud sync error: $e');
      }
    });
  }

  Future<String?> signUpLocal({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPass = password.trim();

      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        throw Exception('Please enter a valid email address.');
      }
      validatePasswordStrength(cleanPass);

      final db = await _db.database;
      final existing = await db.query(
        'app_users',
        where: 'email = ?',
        whereArgs: [cleanEmail],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw Exception('An account with this email already exists.');
      }

      final salt = AesGcmHelper.generateRandomSalt(16);
      final passwordHash = await AesGcmHelper.hashPassword(
        password: cleanPass,
        salt: salt,
      );

      final now = DateTime.now();
      String userId = 'usr_${now.microsecondsSinceEpoch}';
      bool needsOtp = false;

      // 1. Try Supabase signUp if online
      if (SupabaseService.instance.client != null) {
        try {
          final res = await SupabaseService.instance.signUpWithEmail(
            email: cleanEmail,
            password: cleanPass,
            displayName: displayName?.trim(),
          );
          if (res?.user != null) {
            userId = res!.user!.id;
            if (res.session != null) {
              // Auto-confirmed by Supabase (no OTP needed)
              await db.insert('app_users', {
                'id': userId,
                'email': cleanEmail,
                'display_name': displayName?.trim(),
                'photo_url': null,
                'auth_provider': 'supabase',
                'password_hash': passwordHash,
                'salt': base64Encode(salt),
                'is_verified': 1,
                'verification_code': null,
                'created_at': now.millisecondsSinceEpoch,
                'last_login_at': now.millisecondsSinceEpoch,
              }, conflictAlgorithm: ConflictAlgorithm.replace);

              final user = AppUser(
                id: userId,
                email: cleanEmail,
                displayName: displayName?.trim(),
                authProvider: 'supabase',
                isVerified: true,
                createdAt: now,
                lastLoginAt: now,
              );
              await _storage.write(key: _sessionKey, value: user.id);
              _pendingVerificationEmail = null;
              _lastSentVerificationCode = null;
              state = AsyncValue.data(user);
              _triggerCloudSync();
              return null;
            } else {
              // Requires real OTP email confirmation from Supabase
              needsOtp = true;
            }
          }
        } catch (e) {
          debugPrint('Supabase signUp error: $e');
          if (e is AuthException) {
            state = const AsyncValue.data(null);
            rethrow;
          }
        }
      }

      // Save local user record
      await db.insert('app_users', {
        'id': userId,
        'email': cleanEmail,
        'display_name': displayName?.trim(),
        'photo_url': null,
        'auth_provider': needsOtp ? 'supabase' : 'local',
        'password_hash': passwordHash,
        'salt': base64Encode(salt),
        'is_verified': needsOtp ? 0 : 1,
        'verification_code': null,
        'created_at': now.millisecondsSinceEpoch,
        'last_login_at': now.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      if (needsOtp) {
        _pendingVerificationEmail = cleanEmail;
        _lastSentVerificationCode = null;
        state = const AsyncValue.data(null);
        return 'otp_sent';
      } else {
        final user = AppUser(
          id: userId,
          email: cleanEmail,
          displayName: displayName?.trim(),
          authProvider: 'local',
          isVerified: true,
          createdAt: now,
          lastLoginAt: now,
        );
        await _storage.write(key: _sessionKey, value: user.id);
        _pendingVerificationEmail = null;
        _lastSentVerificationCode = null;
        state = AsyncValue.data(user);
        _triggerCloudSync();
        return null;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInLocal({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPass = password.trim();
      final now = DateTime.now();

      // 1. Try Supabase Auth first
      if (SupabaseService.instance.client != null) {
        try {
          final res = await SupabaseService.instance.signInWithEmail(
            email: cleanEmail,
            password: cleanPass,
          );
          if (res != null && res.user != null) {
            final uid = res.user!.id;
            final db = await _db.database;
            await db.insert('app_users', {
              'id': uid,
              'email': cleanEmail,
              'display_name': res.user!.userMetadata?['display_name'] as String?,
              'photo_url': null,
              'auth_provider': 'supabase',
              'is_verified': 1,
              'created_at': now.millisecondsSinceEpoch,
              'last_login_at': now.millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            final user = AppUser(
              id: uid,
              email: cleanEmail,
              displayName: res.user!.userMetadata?['display_name'] as String?,
              authProvider: 'supabase',
              isVerified: true,
              createdAt: now,
              lastLoginAt: now,
            );
            await _storage.write(key: _sessionKey, value: user.id);
            _pendingVerificationEmail = null;
            _lastSentVerificationCode = null;
            state = AsyncValue.data(user);
            _triggerCloudSync();
            return;
          }
        } catch (e) {
          debugPrint('Supabase signInWithEmail: $e');
          if (e is AuthException) {
            rethrow;
          }
        }
      }

      // 2. Offline / Local SQLite verification fallback
      final db = await _db.database;
      final rows = await db.query(
        'app_users',
        where: 'email = ?',
        whereArgs: [cleanEmail],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('No account found with this email. Please sign up.');
      }

      final row = rows.first;
      final storedHash = row['password_hash'] as String?;
      final storedSaltBase64 = row['salt'] as String?;

      if (storedHash == null || storedSaltBase64 == null) {
        throw Exception('This account was registered through an external provider.');
      }

      final salt = base64Decode(storedSaltBase64);
      final computedHash = await AesGcmHelper.hashPassword(
        password: cleanPass,
        salt: salt,
      );

      if (computedHash != storedHash) {
        throw Exception('Incorrect password. Please try again.');
      }

      await db.update(
        'app_users',
        {'last_login_at': now.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [row['id']],
      );

      final user = AppUser.fromMap(row).copyWith(lastLoginAt: now);
      await _storage.write(key: _sessionKey, value: user.id);
      _pendingVerificationEmail = null;
      _lastSentVerificationCode = null;
      state = AsyncValue.data(user);
      _triggerCloudSync();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanCode = code.trim();
      final now = DateTime.now();

      // 1. Try Supabase verifyOTP
      if (SupabaseService.instance.client != null) {
        try {
          final res = await SupabaseService.instance.verifyOtp(
            email: cleanEmail,
            token: cleanCode,
            type: OtpType.signup,
          );
          if (res != null && res.user != null) {
            final uid = res.user!.id;
            final db = await _db.database;
            await db.insert('app_users', {
              'id': uid,
              'email': cleanEmail,
              'display_name': res.user!.userMetadata?['display_name'] as String?,
              'photo_url': null,
              'auth_provider': 'supabase',
              'is_verified': 1,
              'created_at': now.millisecondsSinceEpoch,
              'last_login_at': now.millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            final user = AppUser(
              id: uid,
              email: cleanEmail,
              displayName: res.user!.userMetadata?['display_name'] as String?,
              authProvider: 'supabase',
              isVerified: true,
              createdAt: now,
              lastLoginAt: now,
            );
            await _storage.write(key: _sessionKey, value: user.id);
            _pendingVerificationEmail = null;
            _lastSentVerificationCode = null;
            state = AsyncValue.data(user);
            _triggerCloudSync();
            return;
          }
        } catch (e) {
          debugPrint('Supabase verifyOtp error: $e');
          if (e is AuthException) {
            rethrow;
          }
        }
      }

      // 2. Offline fallback (if any stored code matches)
      final db = await _db.database;
      final rows = await db.query(
        'app_users',
        where: 'email = ?',
        whereArgs: [cleanEmail],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('Account not found. Please sign up again.');
      }

      final row = rows.first;
      final storedCode = row['verification_code'] as String?;
      if (storedCode != null && storedCode == cleanCode) {
        await db.update(
          'app_users',
          {
            'is_verified': 1,
            'verification_code': null,
            'last_login_at': now.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        final user = AppUser.fromMap(row).copyWith(
          isVerified: true,
          lastLoginAt: now,
        );
        await _storage.write(key: _sessionKey, value: user.id);
        _pendingVerificationEmail = null;
        _lastSentVerificationCode = null;
        state = AsyncValue.data(user);
        _triggerCloudSync();
        return;
      }

      throw Exception('Kode verifikasi tidak valid. Silakan periksa kembali.');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resendVerificationOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (SupabaseService.instance.client != null) {
      try {
        await SupabaseService.instance.resendOtp(email: cleanEmail, type: OtpType.signup);
      } catch (e) {
        debugPrint('Supabase resendOtp error: $e');
      }
    }
    _pendingVerificationEmail = cleanEmail;
    _lastSentVerificationCode = null;
  }

  void cancelVerification() {
    _pendingVerificationEmail = null;
    _lastSentVerificationCode = null;
    state = const AsyncValue.data(null);
  }

  Future<void> signInGoogle() async {
    state = const AsyncValue.loading();
    try {
      // Platform check: On Windows Desktop, Google Sign-In SDK requires custom deep linking / web browser OAuth.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        state = const AsyncValue.data(null);
        throw Exception(
          'Google Sign-In is native to Android. On Windows Desktop, please use Email Sign-In or Continue as Guest.',
        );
      }

      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: SupabaseService.googleServerClientId,
      );
      final account = await googleSignIn.authenticate();

      // Retrieve both idToken and accessToken
      final idToken = account.authentication.idToken;
      String? accessToken;
      try {
        final authz = await account.authorizationClient.authorizationForScopes(['email', 'profile']);
        accessToken = authz?.accessToken;
      } catch (e) {
        debugPrint('Google accessToken retrieval error: $e');
      }

      String? supabaseUserId;
      // Synchronize with Supabase Cloud Authentication if online
      if (idToken != null && SupabaseService.instance.client != null) {
        try {
          final authRes = await SupabaseService.instance.client!.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          supabaseUserId = authRes.user?.id;
          debugPrint('Supabase Google Sign-In session established: $supabaseUserId');
        } catch (e) {
          debugPrint('Supabase Google Sign-In link error: $e');
        }
      }

      final db = await _db.database;
      final email = account.email.trim().toLowerCase();
      final existing = await db.query(
        'app_users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      final now = DateTime.now();
      AppUser user;

      if (existing.isNotEmpty) {
        final row = existing.first;
        final targetId = supabaseUserId ?? row['id'] as String;
        await db.update(
          'app_users',
          {
            'id': targetId,
            'display_name': account.displayName,
            'photo_url': account.photoUrl,
            'is_verified': 1,
            'last_login_at': now.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        user = AppUser.fromMap(row).copyWith(
          id: targetId,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          isVerified: true,
          lastLoginAt: now,
        );
      } else {
        final userId = supabaseUserId ?? 'usr_${now.microsecondsSinceEpoch}';
        user = AppUser(
          id: userId,
          email: email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
          authProvider: 'google',
          isVerified: true,
          createdAt: now,
          lastLoginAt: now,
        );
        await db.insert('app_users', {
          'id': user.id,
          'email': user.email,
          'display_name': user.displayName,
          'photo_url': user.photoUrl,
          'auth_provider': user.authProvider,
          'password_hash': null,
          'salt': null,
          'is_verified': 1,
          'verification_code': null,
          'created_at': user.createdAt.millisecondsSinceEpoch,
          'last_login_at': user.lastLoginAt.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await _storage.write(key: _sessionKey, value: user.id);
      _pendingVerificationEmail = null;
      _lastSentVerificationCode = null;
      state = AsyncValue.data(user);
      _triggerCloudSync();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInGuest() async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final guestId = 'guest_${now.microsecondsSinceEpoch}';
      final guestUser = AppUser(
        id: guestId,
        email: 'guest@lifehub.local',
        displayName: 'Executive Guest',
        photoUrl: null,
        authProvider: 'guest',
        isVerified: true,
        createdAt: now,
        lastLoginAt: now,
      );

      final db = await _db.database;
      await db.insert('app_users', {
        'id': guestUser.id,
        'email': guestUser.email,
        'display_name': guestUser.displayName,
        'photo_url': null,
        'auth_provider': guestUser.authProvider,
        'password_hash': null,
        'salt': null,
        'is_verified': 1,
        'verification_code': null,
        'created_at': guestUser.createdAt.millisecondsSinceEpoch,
        'last_login_at': guestUser.lastLoginAt.millisecondsSinceEpoch,
      });

      await _storage.write(key: _sessionKey, value: guestUser.id);
      _pendingVerificationEmail = null;
      _lastSentVerificationCode = null;
      state = AsyncValue.data(guestUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = state.value;
    if (currentUser == null || !currentUser.isLocal) {
      throw Exception('Password change is only available for local email accounts.');
    }

    validatePasswordStrength(newPassword);

    final db = await _db.database;
    final rows = await db.query(
      'app_users',
      where: 'id = ?',
      whereArgs: [currentUser.id],
      limit: 1,
    );

    if (rows.isEmpty) throw Exception('Account not found.');

    final row = rows.first;
    final storedHash = row['password_hash'] as String?;
    final storedSaltBase64 = row['salt'] as String?;

    if (storedHash == null || storedSaltBase64 == null) {
      throw Exception('Invalid account credentials configuration.');
    }

    final salt = base64Decode(storedSaltBase64);
    final computedHash = await AesGcmHelper.hashPassword(
      password: currentPassword.trim(),
      salt: salt,
    );

    if (computedHash != storedHash) {
      throw Exception('Current password does not match.');
    }

    final newSalt = AesGcmHelper.generateRandomSalt(16);
    final newPasswordHash = await AesGcmHelper.hashPassword(
      password: newPassword.trim(),
      salt: newSalt,
    );

    await db.update(
      'app_users',
      {
        'password_hash': newPasswordHash,
        'salt': base64Encode(newSalt),
      },
      where: 'id = ?',
      whereArgs: [currentUser.id],
    );
  }

  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    final updated = currentUser.copyWith(
      displayName: displayName ?? currentUser.displayName,
      phoneNumber: phoneNumber ?? currentUser.phoneNumber,
      photoUrl: photoUrl ?? currentUser.photoUrl,
    );

    final db = await _db.database;
    await db.update(
      'app_users',
      {
        'display_name': updated.displayName,
        'phone_number': updated.phoneNumber,
        'photo_url': updated.photoUrl,
      },
      where: 'id = ?',
      whereArgs: [currentUser.id],
    );

    // If Supabase is active and signed in, sync user metadata
    try {
      if (SupabaseService.instance.isInitialized && SupabaseService.instance.isSignedIn) {
        await SupabaseService.instance.client?.auth.updateUser(
          UserAttributes(
            data: {
              if (updated.displayName != null) 'display_name': updated.displayName,
              if (updated.phoneNumber != null) 'phone_number': updated.phoneNumber,
              if (updated.photoUrl != null) 'avatar_url': updated.photoUrl,
            },
          ),
        );
      }
    } catch (_) {}

    state = AsyncValue.data(updated);
  }

  Future<void> deleteAccount() async {
    final currentUser = state.value;
    if (currentUser == null) return;

    final db = await _db.database;
    await db.delete(
      'app_users',
      where: 'id = ?',
      whereArgs: [currentUser.id],
    );

    await _storage.delete(key: _sessionKey);
    _pendingVerificationEmail = null;
    _lastSentVerificationCode = null;
    state = const AsyncValue.data(null);
  }

  Future<void> signOut() async {
    try {
      await _storage.delete(key: _sessionKey);
      _pendingVerificationEmail = null;
      _lastSentVerificationCode = null;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  final storage = ref.watch(currencyStorageProvider);
  return AuthNotifier(AppDatabase.instance, storage);
});

