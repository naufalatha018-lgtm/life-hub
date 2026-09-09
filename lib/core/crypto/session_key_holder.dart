import 'dart:typed_data';

/// In-memory transient holder for the derived AES-256-GCM encryption key.
/// Never persists the key to disk, flash, or SharedPreferences.
/// Provides zeroization to clear cryptographic secrets from RAM on lock/auto-lock.
class SessionKeyHolder {
  Uint8List? _keyBytes;

  bool get hasKey => _keyBytes != null && _keyBytes!.isNotEmpty;

  Uint8List? get key => _keyBytes;
  Uint8List? get derivedKey => _keyBytes;

  /// Sets the derived key for the active unlocked session.
  void setKey(Uint8List key) {
    _keyBytes = Uint8List.fromList(key);
  }

  /// Securely clears the session key from RAM by overwriting with zeroes.
  void zeroize() {
    if (_keyBytes != null) {
      _keyBytes!.fillRange(0, _keyBytes!.length, 0);
      _keyBytes = null;
    }
  }
}
