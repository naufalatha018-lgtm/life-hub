import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../crypto/aes_gcm_helper.dart';
import '../crypto/session_key_holder.dart';
import '../services/biometric_service.dart';
import '../../features/auth/providers/auth_provider.dart';

enum MasterAuthStatus {
  loading,
  unconfigured,
  locked,
  unlocked;

  bool get hasPin => this != MasterAuthStatus.unconfigured;
}

class MasterAuthState {
  final MasterAuthStatus status;
  final bool isDecoySession;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final bool hasDecoyPin;
  final bool biometricAvailable;
  final String? errorMessage;

  const MasterAuthState({
    required this.status,
    this.isDecoySession = false,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.hasDecoyPin = false,
    this.biometricAvailable = false,
    this.errorMessage,
  });

  bool get isLockedOut =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);

  int get remainingLockoutSeconds {
    if (lockedUntil == null) return 0;
    final diff = lockedUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  MasterAuthState copyWith({
    MasterAuthStatus? status,
    bool? isDecoySession,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLockout = false,
    bool? hasDecoyPin,
    bool? biometricAvailable,
    String? errorMessage,
  }) {
    return MasterAuthState(
      status: status ?? this.status,
      isDecoySession: isDecoySession ?? this.isDecoySession,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockout ? null : (lockedUntil ?? this.lockedUntil),
      hasDecoyPin: hasDecoyPin ?? this.hasDecoyPin,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      errorMessage: errorMessage,
    );
  }
}

final masterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final masterSessionKeyHolderProvider = Provider<SessionKeyHolder>((ref) {
  return SessionKeyHolder();
});

final masterAuthNotifierProvider =
    StateNotifierProvider<MasterAuthNotifier, MasterAuthState>((ref) {
  final storage = ref.watch(masterSecureStorageProvider);
  final keyHolder = ref.watch(masterSessionKeyHolderProvider);
  final userId = ref.watch(currentUserIdProvider);
  return MasterAuthNotifier(storage, keyHolder, userId: userId);
});

final isDecoySessionProvider = Provider<bool>((ref) {
  return ref.watch(masterAuthNotifierProvider).isDecoySession;
});

class MasterAuthNotifier extends StateNotifier<MasterAuthState> {
  MasterAuthNotifier(
    this._storage,
    this._keyHolder, {
    required this.userId,
  }) : super(const MasterAuthState(status: MasterAuthStatus.loading)) {
    checkMasterConfiguration();
  }

  final FlutterSecureStorage _storage;
  final SessionKeyHolder _keyHolder;
  final String userId;

  String get _keySalt => 'vault_master_pin_${userId}_salt_v1';
  String get _keyVerifier => 'vault_master_pin_${userId}_verifier_v1';
  String get _keyRecovery => 'vault_master_pin_${userId}_recovery_v1';
  String get _keyBiometricKey => 'vault_master_pin_${userId}_biometric_key_v1';
  String get _keyDecoySalt => 'vault_master_pin_${userId}_decoy_salt_v1';
  String get _keyDecoyVerifier => 'vault_master_pin_${userId}_decoy_verifier_v1';

  Future<void> checkMasterConfiguration() async {
    try {
      final salt = await _storage.read(key: _keySalt);
      final verifier = await _storage.read(key: _keyVerifier);
      final decoyVerifier = await _storage.read(key: _keyDecoyVerifier);
      final bioHardware = await BiometricService.instance.isBiometricAvailable();
      final bioKey = await _storage.read(key: _keyBiometricKey);

      final hasDecoy = decoyVerifier != null && decoyVerifier.isNotEmpty;
      final bioReady = bioHardware && bioKey != null && verifier != null;

      if (salt == null || verifier == null) {
        state = state.copyWith(
          status: MasterAuthStatus.unconfigured,
          hasDecoyPin: hasDecoy,
          biometricAvailable: bioReady,
        );
      } else {
        state = state.copyWith(
          status: MasterAuthStatus.locked,
          hasDecoyPin: hasDecoy,
          biometricAvailable: bioReady,
        );
      }
    } catch (e) {
      debugPrint('Error checking master auth config: $e');
      state = state.copyWith(status: MasterAuthStatus.unconfigured);
    }
  }

  /// Sets up a new 6-digit Master PIN and derives a 256-bit AES key via PBKDF2 (100k iterations).
  /// Optionally sets up a distinct Decoy PIN for anti-extortion duress protection.
  Future<String> setupMasterPin(String pin, {String? decoyPin}) async {
    final salt = AesGcmHelper.generateRandomSalt(16);
    final derivedKey = await AesGcmHelper.deriveKeyFromPin(pin: pin, salt: salt);
    final verifier = AesGcmHelper.computeAuthVerifier(derivedKey);
    final recoveryCode = AesGcmHelper.generateRecoveryCode(pin, salt);

    await _storage.write(key: _keySalt, value: base64Encode(salt));
    await _storage.write(key: _keyVerifier, value: verifier);
    await _storage.write(key: _keyRecovery, value: recoveryCode);
    await _storage.write(key: _keyBiometricKey, value: base64Encode(derivedKey));

    bool hasDecoy = false;
    if (decoyPin != null && decoyPin.trim().isNotEmpty && decoyPin != pin) {
      final decoySalt = AesGcmHelper.generateRandomSalt(16);
      final decoyDerivedKey = await AesGcmHelper.deriveKeyFromPin(pin: decoyPin, salt: decoySalt);
      final decoyVerifier = AesGcmHelper.computeAuthVerifier(decoyDerivedKey);
      await _storage.write(key: _keyDecoySalt, value: base64Encode(decoySalt));
      await _storage.write(key: _keyDecoyVerifier, value: decoyVerifier);
      hasDecoy = true;
    }

    _keyHolder.setKey(derivedKey, isDecoy: false);
    state = state.copyWith(
      status: MasterAuthStatus.unlocked,
      isDecoySession: false,
      failedAttempts: 0,
      clearLockout: true,
      hasDecoyPin: hasDecoy,
      biometricAvailable: await BiometricService.instance.isBiometricAvailable(),
      errorMessage: null,
    );

    return recoveryCode;
  }

  /// Configures or updates the secondary Decoy PIN.
  Future<void> setDecoyPin(String decoyPin) async {
    if (decoyPin.length != 6) {
      throw ArgumentError('Decoy PIN must be exactly 6 digits');
    }
    final decoySalt = AesGcmHelper.generateRandomSalt(16);
    final decoyDerivedKey = await AesGcmHelper.deriveKeyFromPin(pin: decoyPin, salt: decoySalt);
    final decoyVerifier = AesGcmHelper.computeAuthVerifier(decoyDerivedKey);

    await _storage.write(key: _keyDecoySalt, value: base64Encode(decoySalt));
    await _storage.write(key: _keyDecoyVerifier, value: decoyVerifier);

    state = state.copyWith(hasDecoyPin: true);
  }

  /// Removes the configured Decoy PIN.
  Future<void> removeDecoyPin() async {
    await _storage.delete(key: _keyDecoySalt);
    await _storage.delete(key: _keyDecoyVerifier);
    state = state.copyWith(hasDecoyPin: false);
  }

  /// Validates the entered PIN against the Master PIN or Duress/Decoy PIN.
  /// If master PIN matches: unlocks full session with derived AES key.
  /// If decoy PIN matches: unlocks isolated decoy session with zeroed state.
  /// If incorrect: increments failed attempts and enforces lockout at 5 failures.
  Future<bool> unlockWithPin(String pin) async {
    if (state.isLockedOut) {
      state = state.copyWith(
        errorMessage: 'Terlalu banyak percobaan. Tunggu ${state.remainingLockoutSeconds} detik.',
      );
      return false;
    }

    try {
      final saltB64 = await _storage.read(key: _keySalt);
      final storedVerifier = await _storage.read(key: _keyVerifier);

      if (saltB64 == null || storedVerifier == null) {
        state = state.copyWith(status: MasterAuthStatus.unconfigured);
        return false;
      }

      // Check Master PIN
      final salt = base64Decode(saltB64);
      final derivedKey = await AesGcmHelper.deriveKeyFromPin(pin: pin, salt: salt);
      final calculatedVerifier = AesGcmHelper.computeAuthVerifier(derivedKey);

      if (calculatedVerifier == storedVerifier) {
        // Cache biometric key
        await _storage.write(key: _keyBiometricKey, value: base64Encode(derivedKey));
        _keyHolder.setKey(derivedKey, isDecoy: false);

        state = state.copyWith(
          status: MasterAuthStatus.unlocked,
          isDecoySession: false,
          failedAttempts: 0,
          clearLockout: true,
          errorMessage: null,
        );
        return true;
      }

      // Check Decoy PIN (Duress Mode)
      final decoySaltB64 = await _storage.read(key: _keyDecoySalt);
      final storedDecoyVerifier = await _storage.read(key: _keyDecoyVerifier);

      if (decoySaltB64 != null && storedDecoyVerifier != null) {
        final decoySalt = base64Decode(decoySaltB64);
        final decoyDerivedKey = await AesGcmHelper.deriveKeyFromPin(pin: pin, salt: decoySalt);
        final calculatedDecoyVerifier = AesGcmHelper.computeAuthVerifier(decoyDerivedKey);

        if (calculatedDecoyVerifier == storedDecoyVerifier) {
          // Initialize clean pseudo/zeroed key for decoy session
          final pseudoKey = Uint8List(32);
          _keyHolder.setKey(pseudoKey, isDecoy: true);

          state = state.copyWith(
            status: MasterAuthStatus.unlocked,
            isDecoySession: true,
            failedAttempts: 0,
            clearLockout: true,
            errorMessage: null,
          );
          return true;
        }
      }

      // Authentication failed
      final newFailures = state.failedAttempts + 1;
      DateTime? lockoutTime;
      String? errorMsg = 'PIN salah. Percobaan $newFailures/5';

      if (newFailures >= 5) {
        lockoutTime = DateTime.now().add(const Duration(seconds: 60));
        errorMsg = 'Aplikasi terkunci selama 60 detik karena 5x kesalahan.';
      }

      state = state.copyWith(
        failedAttempts: newFailures,
        lockedUntil: lockoutTime,
        errorMessage: errorMsg,
      );
      return false;
    } catch (e) {
      debugPrint('PIN authentication error: $e');
      state = state.copyWith(errorMessage: 'Terjadi kesalahan otentikasi.');
      return false;
    }
  }

  /// Attempts fast hardware biometric authentication (Fingerprint / Face ID).
  Future<bool> unlockWithBiometrics() async {
    if (state.isLockedOut) return false;

    try {
      final bioHardware = await BiometricService.instance.isBiometricAvailable();
      if (!bioHardware) return false;

      final keyB64 = await _storage.read(key: _keyBiometricKey);
      final storedVerifier = await _storage.read(key: _keyVerifier);
      if (keyB64 == null || storedVerifier == null) return false;

      final success = await BiometricService.instance.authenticate(
        localizedReason: 'Buka Actividata dengan sidik jari atau biometrik',
      );
      if (!success) return false;

      final derivedKey = base64Decode(keyB64);
      final computedVerifier = AesGcmHelper.computeAuthVerifier(derivedKey);

      if (computedVerifier != storedVerifier) {
        return false;
      }

      _keyHolder.setKey(derivedKey, isDecoy: false);
      state = state.copyWith(
        status: MasterAuthStatus.unlocked,
        isDecoySession: false,
        failedAttempts: 0,
        clearLockout: true,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      debugPrint('Biometric unlock failed: $e');
      return false;
    }
  }

  /// Instant Panic Wipe Trigger:
  /// Clears derived AES keys from RAM immediately, invalidates transient memory, and locks the application.
  void panicWipe() {
    _keyHolder.zeroize();
    state = state.copyWith(
      status: MasterAuthStatus.locked,
      isDecoySession: false,
      errorMessage: null,
    );
  }

  /// Normal lock and purge
  void lock() => panicWipe();

  /// Changes the Master PIN after verifying the current PIN.
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

    final newSalt = AesGcmHelper.generateRandomSalt(16);
    final newKey = await AesGcmHelper.deriveKeyFromPin(pin: newPin, salt: newSalt);
    final newVerifier = AesGcmHelper.computeAuthVerifier(newKey);
    final newRecoveryCode = AesGcmHelper.generateRecoveryCode(newPin, newSalt);

    await _storage.write(key: _keySalt, value: base64Encode(newSalt));
    await _storage.write(key: _keyVerifier, value: newVerifier);
    await _storage.write(key: _keyRecovery, value: newRecoveryCode);
    await _storage.write(key: _keyBiometricKey, value: base64Encode(newKey));

    _keyHolder.setKey(newKey, isDecoy: false);
    state = state.copyWith(
      status: MasterAuthStatus.unlocked,
      isDecoySession: false,
      failedAttempts: 0,
      clearLockout: true,
    );

    return newRecoveryCode;
  }

  /// Resets PIN using recovery code.
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

  Future<String?> getRecoveryCode() async {
    return await _storage.read(key: _keyRecovery);
  }
}
