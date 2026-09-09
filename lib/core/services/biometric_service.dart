import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Wraps `local_auth` for biometric authentication.
/// Gracefully falls back to PIN when biometrics unavailable.
/// Desktop platforms (Windows, macOS, Linux) are guarded.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Returns true if the device hardware supports biometrics.
  Future<bool> isBiometricAvailable() async {
    // Desktop platforms do not support biometrics via local_auth
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return false;
    }
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (!await isBiometricAvailable()) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Returns a human-readable label for the available biometric.
  Future<String> getBiometricLabel() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) return 'Face ID';
    if (biometrics.contains(BiometricType.fingerprint)) return 'Fingerprint';
    return 'Biometrics';
  }

  /// Attempts biometric authentication.
  /// Returns `true` on success, `false` on failure or cancellation.
  Future<bool> authenticate({
    String localizedReason = 'Unlock your Life Hub vault',
  }) async {
    if (!await isBiometricAvailable()) return false;
    try {
      HapticFeedback.lightImpact();
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device PIN fallback
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}

// ─────────────────────────────────────────────
// RIVERPOD PROVIDERS
// ─────────────────────────────────────────────

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService.instance;
});

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return BiometricService.instance.isBiometricAvailable();
});

/// Persisted preference — whether biometric unlock is enabled.
/// Defaults to false (user must explicitly enable in VaultSecurityPage).
final biometricEnabledProvider = StateProvider<bool>((ref) => false);
