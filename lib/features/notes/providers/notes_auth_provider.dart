import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/crypto/session_key_holder.dart';
import '../../../core/security/master_auth_provider.dart';
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
  return ref.watch(masterSessionKeyHolderProvider);
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return ref.watch(masterSecureStorageProvider);
});

final notesAuthNotifierProvider =
    StateNotifierProvider<NotesAuthNotifier, NotesAuthStatus>((ref) {
  return NotesAuthNotifier(ref);
});

class NotesAuthNotifier extends StateNotifier<NotesAuthStatus> {
  NotesAuthNotifier(this._ref) : super(NotesAuthStatus.loading) {
    // Synchronize with centralized Master Security state
    _ref.listen<MasterAuthState>(masterAuthNotifierProvider, (previous, next) {
      _syncStatus(next.status);
    }, fireImmediately: true);
  }

  final Ref _ref;

  void _syncStatus(MasterAuthStatus masterStatus) {
    switch (masterStatus) {
      case MasterAuthStatus.loading:
        state = NotesAuthStatus.loading;
        break;
      case MasterAuthStatus.unconfigured:
        state = NotesAuthStatus.unconfigured;
        break;
      case MasterAuthStatus.locked:
        state = NotesAuthStatus.locked;
        break;
      case MasterAuthStatus.unlocked:
        state = NotesAuthStatus.unlocked;
        // Trigger loading decrypted records upon unlocking
        _ref.read(decryptedNotesProvider.notifier).loadDecryptedNotes();
        _ref.read(decryptedVaultFilesProvider.notifier).loadDecryptedFiles();
        break;
    }
  }

  Future<void> checkPinConfiguration() async {
    await _ref.read(masterAuthNotifierProvider.notifier).checkMasterConfiguration();
  }

  Future<String> setupMasterPin(String pin, {String? decoyPin}) async {
    final code = await _ref
        .read(masterAuthNotifierProvider.notifier)
        .setupMasterPin(pin, decoyPin: decoyPin);
    await _ref.read(decryptedNotesProvider.notifier).loadDecryptedNotes();
    await _ref.read(decryptedVaultFilesProvider.notifier).loadDecryptedFiles();
    return code;
  }

  Future<bool> unlockWithPin(String pin) async {
    final success =
        await _ref.read(masterAuthNotifierProvider.notifier).unlockWithPin(pin);
    if (success) {
      await _ref.read(decryptedNotesProvider.notifier).loadDecryptedNotes();
      await _ref.read(decryptedVaultFilesProvider.notifier).loadDecryptedFiles();
    }
    return success;
  }

  Future<bool> unlockWithBiometrics() async {
    final success =
        await _ref.read(masterAuthNotifierProvider.notifier).unlockWithBiometrics();
    if (success) {
      await _ref.read(decryptedNotesProvider.notifier).loadDecryptedNotes();
      await _ref.read(decryptedVaultFilesProvider.notifier).loadDecryptedFiles();
    }
    return success;
  }

  Future<bool> canUseBiometrics() async {
    final authState = _ref.read(masterAuthNotifierProvider);
    return authState.biometricAvailable;
  }

  void lockAndPurge() {
    _ref.read(masterAuthNotifierProvider.notifier).panicWipe();
    _ref.read(decryptedNotesProvider.notifier).purgeMemory();
    _ref.read(decryptedVaultFilesProvider.notifier).purgeMemory();
  }

  Future<String> changeMasterPin({
    required String currentPin,
    required String newPin,
  }) async {
    final code = await _ref.read(masterAuthNotifierProvider.notifier).changeMasterPin(
          currentPin: currentPin,
          newPin: newPin,
        );
    await _ref.read(decryptedNotesProvider.notifier).loadDecryptedNotes();
    await _ref.read(decryptedVaultFilesProvider.notifier).loadDecryptedFiles();
    return code;
  }

  Future<bool> resetPinWithRecoveryCode(String inputCode, String newPin) async {
    return await _ref
        .read(masterAuthNotifierProvider.notifier)
        .resetPinWithRecoveryCode(inputCode, newPin);
  }

  Future<String?> getRecoveryCode() async {
    return await _ref.read(masterAuthNotifierProvider.notifier).getRecoveryCode();
  }
}

final vaultBiometricReadyProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(masterAuthNotifierProvider);
  return authState.biometricAvailable;
});
