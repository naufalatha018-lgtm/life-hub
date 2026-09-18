import 'dart:typed_data';

/// In-memory transient holder for the derived AES-256-GCM encryption key.
/// Never persists the key to disk, flash, or SharedPreferences.
/// Provides zeroization to clear cryptographic secrets from RAM on lock/auto-lock.
class SessionKeyHolder {
  Uint8List? _keyBytes;
  bool _isDecoy = false;

  bool get hasKey => _keyBytes != null && _keyBytes!.isNotEmpty;
  bool get isDecoy => _isDecoy;

  Uint8List? get key => _keyBytes;
  Uint8List? get derivedKey => _keyBytes;

  /// Sets the derived key for the active unlocked session.
  void setKey(Uint8List key, {bool isDecoy = false}) {
    _keyBytes = Uint8List.fromList(key);
    _isDecoy = isDecoy;
  }

  /// Securely clears the session key from RAM by overwriting with zeroes.
  void zeroize() {
    if (_keyBytes != null) {
      _keyBytes!.fillRange(0, _keyBytes!.length, 0);
      _keyBytes = null;
    }
    _isDecoy = false;
  }

  /// Alias for zeroize() to support instant panic wipe and session invalidation.
  void clear() => zeroize();
}
