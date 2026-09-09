import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// Cryptographic helper implementing:
/// 1. PBKDF2-HMAC-SHA256 key derivation with 100,000 iterations & 16-byte random salt.
/// 2. Authenticated AES-256-GCM encryption & decryption for strings and binary files.
/// 3. Auth verifier generation for zero-knowledge PIN validation.
/// 4. Salted password hashing for local user accounts.
class AesGcmHelper {
  AesGcmHelper._();

  static final AesGcm _aesGcm = AesGcm.with256bits();
  static final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  static const String _verifierSentinel = 'LIFE_HUB_AUTH_VERIFIER_V1';

  /// Generates a cryptographically secure 16-byte random salt.
  static Uint8List generateRandomSalt([int length = 16]) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Derives a 256-bit (32-byte) key from the PIN/passphrase and salt
  /// using PBKDF2 with HMAC-SHA256 and 100,000 iterations.
  static Future<Uint8List> deriveKeyFromPin({
    required String pin,
    required List<int> salt,
  }) async {
    final pinBytes = utf8.encode(pin);
    final secretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(pinBytes),
      nonce: salt,
    );
    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }

  /// Computes a salted PBKDF2 password hash for local user accounts.
  static Future<String> hashPassword({
    required String password,
    required List<int> salt,
  }) async {
    final key = await deriveKeyFromPin(pin: password, salt: salt);
    return base64Encode(key);
  }

  /// Computes an HMAC-SHA256 authentication verifier string from the derived key.
  /// Used to verify PIN correctness without persisting the PIN or key.
  static String computeAuthVerifier(List<int> derivedKey) {
    final hmac = crypto.Hmac(crypto.sha256, derivedKey);
    final digest = hmac.convert(utf8.encode(_verifierSentinel));
    return digest.toString();
  }

  /// Generates a human-readable recovery code from PIN and salt (e.g. "LH-84F1-92A3-E7B0-48C2").
  static String generateRecoveryCode(String pin, List<int> salt) {
    final combined = utf8.encode('$pin:${base64Encode(salt)}:LIFE_HUB_RECOVERY');
    final digest = crypto.sha256.convert(combined).bytes;
    final hex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    return 'LH-${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}';
  }

  /// Encrypts plaintext string using AES-256-GCM with a fresh 12-byte random nonce.
  /// Returns a packed Base64 payload: [12-byte Nonce | 16-byte MAC | CipherText].
  static Future<String> encrypt({
    required String plainText,
    required List<int> derivedKey,
  }) async {
    final clearBytes = utf8.encode(plainText);
    final packed = await encryptBytes(clearBytes: clearBytes, derivedKey: derivedKey);
    return base64Encode(packed);
  }

  /// Decrypts a packed Base64 payload using AES-256-GCM with the derived key.
  static Future<String> decrypt({
    required String packedPayload,
    required List<int> derivedKey,
  }) async {
    if (packedPayload.isEmpty) return '';
    final rawBytes = base64Decode(packedPayload);
    final clearBytes = await decryptBytes(packedBytes: rawBytes, derivedKey: derivedKey);
    return utf8.decode(clearBytes);
  }

  /// Encrypts raw binary bytes using AES-256-GCM with fresh 12-byte nonce.
  /// Returns [12-byte Nonce | 16-byte MAC | CipherText].
  static Future<Uint8List> encryptBytes({
    required List<int> clearBytes,
    required List<int> derivedKey,
  }) async {
    final nonce = _aesGcm.newNonce();
    final secretKey = SecretKey(derivedKey);

    final secretBox = await _aesGcm.encrypt(
      clearBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    final nonceBytes = secretBox.nonce;
    final macBytes = secretBox.mac.bytes;
    final cipherBytes = secretBox.cipherText;

    final builder = BytesBuilder(copy: false)
      ..add(nonceBytes)
      ..add(macBytes)
      ..add(cipherBytes);

    return builder.toBytes();
  }

  /// Decrypts packed raw binary bytes: [12-byte Nonce | 16-byte MAC | CipherText].
  static Future<Uint8List> decryptBytes({
    required List<int> packedBytes,
    required List<int> derivedKey,
  }) async {
    if (packedBytes.length < 28) {
      throw const FormatException('Payload too short for AES-GCM nonce and MAC');
    }

    final nonce = packedBytes.sublist(0, 12);
    final macBytes = packedBytes.sublist(12, 28);
    final cipherText = packedBytes.sublist(28);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final clearBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: SecretKey(derivedKey),
    );

    return Uint8List.fromList(clearBytes);
  }
}
