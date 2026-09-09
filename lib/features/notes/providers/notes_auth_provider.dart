import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/crypto/aes_gcm_helper.dart';
import '../../../core/crypto/session_key_holder.dart';
import '../../auth/providers/auth_provider.dart';
import '../../vault/providers/vault_files_provider.dart';
import 'notes_crud_provider.dart';

enum NotesAuthStatus {
  loading,
  unconfigured,
  locked,
  unlocked;

  bool get hasPin => this != NotesAuthStatus.unconfigured;
}

final sessionKeyHolderProvider = Provider<SessionKeyHolder>((ref) {
  return SessionKeyHolder();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final notesAuthNotifierProvider =
    StateNotifierProvider<NotesAuthNotifier, NotesAuthStatus>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final keyHolder = ref.watch(sessionKeyHolderProvider);
  final userId = ref.watch(currentUserIdProvider);
  return NotesAuthNotifier(storage, keyHolder, ref, userId: userId);
});

class NotesAuthNotifier extends StateNotifier<NotesAuthStatus> {
  NotesAuthNotifier(this._storage, this._keyHolder, this._ref, {required this.userId})
      : super(NotesAuthStatus.loading) {
    checkPinConfiguration();
  }

  final FlutterSecureStorage _storage;
  final SessionKeyHolder _keyHolder;
  final Ref _ref;
  final String userId;

  String get _keySalt => 'vault_master_pin_${userId}_salt_v1';
  String get _keyVerifier => 'vault_master_pin_${userId}_verifier_v1';
  String get _keyRecovery => 'vault_master_pin_${userId}_recovery_v1';
  String get _keyPin => 'vault_master_pin_$userId';

  Future<void> checkPinConfiguration() async {
    try {
      final salt = await _storage.read(key: _keySalt);
      final verifier = await _storage.read(key: _keyVerifier);

      if (salt == null || verifier == null) {
        state = NotesAuthStatus.unconfigured;
      } else {
        state = NotesAuthStatus.locked;
      }
    } catch (_) {
      state = NotesAuthStatus.unconfigured;
    }
  }

  /// Sets up a new 6-digit Master PIN.
  /// Derives the 256-bit AES key via PBKDF2 with 100k iterations and stores the salt + auth verifier.
  /// Generates and returns a secure recovery code.
  Future<String> setupMasterPin(String pin) async {
    final salt = AesGcmHelper.generateRandomSalt(16);
    final derivedKey = await AesGcmHelper.deriveKeyFromPin(pin: pin, salt: salt);
    final verifier = AesGcmHelper.computeAuthVerifier(derivedKey);
    final recoveryCode = AesGcmHelper.generateRecoveryCode(pin, salt);

    await _storage.write(key: _keySalt, value: base64Encode(salt));
    await _storage.write(key: _keyVerifier, value: verifier);
    await _storage.write(key: _keyRecovery, value: recoveryCode);
    await _storage.write(key: _keyPin, value: verifier);

    _keyHolder.setKey(derivedKey);
    state = NotesAuthStatus.unlocked;

    // Trigger loading of notes and encrypted files
    await _ref.read(decryptedNotesProvider.notifier).loadDecryptedNotes();
    await _ref.read(decryptedVaultFilesProvider.notifier).loadDecryptedFiles();

    return recoveryCode;
  }

  /// Validates the entered 6-digit PIN against the stored HMAC verifier.
  /// Returns true if correct, unlocks session, and loads decrypted items into RAM.
  Future<bool> unlockWithPin(String pin) async {
    try {
      final saltB64 = await _storage.read(key: _keySalt);
      final storedVerifier = await _storage.read(key: _keyVerifier);

      if (saltB64 == null || storedVerifier == null) {
        state = NotesAuthStatus.unconfigured;
        return false;
      }

      final salt = base64Decode(saltB64);
      final derivedKey = await AesGcmHelper.deriveKeyFromPin(pin: pin, salt: salt);
      final calculatedVerifier = AesGcmHelper.computeAuthVerifier(derivedKey);

      if (calculatedVerifier == storedVerifier) {
        _keyHolder.setKey(derivedKey);
        state = NotesAuthStatus.unlocked;
        await _ref.read(decryptedNotesProvider.notifier).loadDecryptedNotes();
        await _ref.read(decryptedVaultFilesProvider.notifier).loadDecryptedFiles();
        return true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// Resets the Master PIN using the emergency recovery code.
  Future<bool> resetPinWithRecoveryCode(String inputCode, String newPin) async {
    try {
      final storedCode = await _storage.read(key: _keyRecovery);
      if (storedCode == null || storedCode.trim() != inputCode.trim()) {
        return false;
      }

      await setupMasterPin(newPin);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Changes the Master PIN after verifying the current PIN.
  /// Seamlessly re-encrypts all existing notes with the newly derived 256-bit key.
  Future<String> changeMasterPin({
    required String currentPin,
    required String newPin,
  }) async {
    final saltB64 = await _storage.read(key: _keySalt);
    final storedVerifier = await _storage.read(key: _keyVerifier);

    if (saltB64 == null || storedVerifier == null) {
      throw Exception('Master PIN is not configured.');
    }

    final oldSalt = base64Decode(saltB64);
    final oldKey = await AesGcmHelper.deriveKeyFromPin(pin: currentPin, salt: oldSalt);
    final computedVerifier = AesGcmHelper.computeAuthVerifier(oldKey);

    if (computedVerifier != storedVerifier) {
      throw Exception('Current Master PIN is incorrect.');
    }

    // Derive new key and recovery code
    final newSalt = AesGcmHelper.generateRandomSalt(16);
    final newKey = await AesGcmHelper.deriveKeyFromPin(pin: newPin, salt: newSalt);
    final newVerifier = AesGcmHelper.computeAuthVerifier(newKey);
    final newRecoveryCode = AesGcmHelper.generateRecoveryCode(newPin, newSalt);

    // Re-encrypt all existing secure notes
    final notesDao = _ref.read(notesDaoProvider);
    final existingRows = await notesDao.getAllEncryptedNotes();

    for (final row in existingRows) {
      try {
        final title = await AesGcmHelper.decrypt(
          packedPayload: row['encrypted_title'] as String,
          derivedKey: oldKey,
        );
        final content = await AesGcmHelper.decrypt(
          packedPayload: row['encrypted_content'] as String,
          derivedKey: oldKey,
        );
        final tags = await AesGcmHelper.decrypt(
          packedPayload: row['encrypted_tags'] as String,
          derivedKey: oldKey,
        );

        final newEncryptedTitle = await AesGcmHelper.encrypt(
          plainText: title,
          derivedKey: newKey,
        );
        final newEncryptedContent = await AesGcmHelper.encrypt(
          plainText: content,
          derivedKey: newKey,
        );
        final newEncryptedTags = await AesGcmHelper.encrypt(
          plainText: tags,
          derivedKey: newKey,
        );

        await notesDao.updateNote({
          'id': row['id'],
          'encrypted_title': newEncryptedTitle,
          'encrypted_content': newEncryptedContent,
          'encrypted_tags': newEncryptedTags,
          'is_pinned': row['is_pinned'],
          'created_at': row['created_at'],
          'updated_at': row['updated_at'],
        });
      } catch (_) {
        // Continue re-encrypting others if one note fails
      }
    }

    // Persist new crypto credentials
    await _storage.write(key: _keySalt, value: base64Encode(newSalt));
    await _storage.write(key: _keyVerifier, value: newVerifier);
    await _storage.write(key: _keyRecovery, value: newRecoveryCode);

    _keyHolder.setKey(newKey);
    state = NotesAuthStatus.unlocked;

    await _ref.read(decryptedNotesProvider.notifier).loadDecryptedNotes();
    await _ref.read(decryptedVaultFilesProvider.notifier).loadDecryptedFiles();

    return newRecoveryCode;
  }

  /// Generates and stores a new emergency recovery code verified by current PIN.
  Future<String> regenerateRecoveryCode(String currentPin) async {
    final saltB64 = await _storage.read(key: _keySalt);
    final storedVerifier = await _storage.read(key: _keyVerifier);

    if (saltB64 == null || storedVerifier == null) {
      throw Exception('Master PIN is not configured.');
    }

    final salt = base64Decode(saltB64);
    final key = await AesGcmHelper.deriveKeyFromPin(pin: currentPin, salt: salt);
    final computedVerifier = AesGcmHelper.computeAuthVerifier(key);

    if (computedVerifier != storedVerifier) {
      throw Exception('Current Master PIN is incorrect.');
    }

    final newRecoveryCode = AesGcmHelper.generateRecoveryCode(currentPin, salt);
    await _storage.write(key: _keyRecovery, value: newRecoveryCode);
    return newRecoveryCode;
  }

  Future<String?> getRecoveryCode() async {
    return await _storage.read(key: _keyRecovery);
  }

  /// Locks the vault and zeroes out all decrypted data and encryption keys from memory.
  void lockAndPurge() {
    _keyHolder.zeroize();
    _ref.read(decryptedNotesProvider.notifier).purgeMemory();
    _ref.read(decryptedVaultFilesProvider.notifier).purgeMemory();
    state = NotesAuthStatus.locked;
  }
}
