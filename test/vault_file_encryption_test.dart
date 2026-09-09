import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/crypto/aes_gcm_helper.dart';

void main() {
  group('Vault File Encryption & Cryptographic Helper Suite', () {
    const testPin = '928374';
    final testSalt = Uint8List.fromList(List.generate(16, (i) => i + 10));

    test('Derives consistent 256-bit encryption key from 6-digit PIN', () async {
      final key1 = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);
      final key2 = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);

      expect(key1.length, equals(32));
      expect(key1, equals(key2));
    });

    test('Encrypts and decrypts raw binary bytes (document/file payload) via AES-256-GCM', () async {
      final key = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);

      // Create a sample binary payload (e.g. simulated PDF header and bytes)
      final originalBytes = Uint8List.fromList(
        utf8.encode('%PDF-1.4 Executive Confidential Financial Portfolio Data 2026') +
            List.generate(512, (i) => (i * 7) % 256),
      );

      final encryptedPacked = await AesGcmHelper.encryptBytes(
        clearBytes: originalBytes,
        derivedKey: key,
      );

      expect(encryptedPacked.isNotEmpty, isTrue);
      expect(encryptedPacked, isNot(equals(originalBytes)));

      // Decrypt and verify byte-for-byte fidelity
      final decryptedBytes = await AesGcmHelper.decryptBytes(
        packedBytes: encryptedPacked,
        derivedKey: key,
      );

      expect(decryptedBytes, equals(originalBytes));
    });

    test('Fails decryption if packed file ciphertext is tampered or corrupted', () async {
      final key = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);
      final originalBytes = Uint8List.fromList(utf8.encode('Secret Passphrase Seed'));

      final encrypted = await AesGcmHelper.encryptBytes(
        clearBytes: originalBytes,
        derivedKey: key,
      );

      // Tamper single bit at the payload
      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length - 1] ^= 0x01;

      expect(
        () async => await AesGcmHelper.decryptBytes(
          packedBytes: tampered,
          derivedKey: key,
        ),
        throwsA(anything),
      );
    });

    test('Fails decryption when attempted with incorrect encryption key', () async {
      final key = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);
      final wrongKey = await AesGcmHelper.deriveKeyFromPin(pin: '000000', salt: testSalt);

      final originalBytes = Uint8List.fromList(utf8.encode('Private Legal Contract'));
      final encrypted = await AesGcmHelper.encryptBytes(
        clearBytes: originalBytes,
        derivedKey: key,
      );

      expect(
        () async => await AesGcmHelper.decryptBytes(
          packedBytes: encrypted,
          derivedKey: wrongKey,
        ),
        throwsA(anything),
      );
    });

    test('Generates formatted emergency recovery code', () {
      final code = AesGcmHelper.generateRecoveryCode(testPin, testSalt);
      expect(code.isNotEmpty, isTrue);

      // Pattern: LH-XXXX-XXXX-XXXX-XXXX
      expect(code.startsWith('LH-'), isTrue);
      final parts = code.split('-');
      expect(parts.length, equals(5));
      for (int i = 1; i < parts.length; i++) {
        expect(parts[i].length, equals(4));
        expect(parts[i], matches(RegExp(r'^[A-Z0-9]{4}$')));
      }

      // Different PIN produces different recovery code
      final code2 = AesGcmHelper.generateRecoveryCode('112233', testSalt);
      expect(code, isNot(equals(code2)));
    });

    test('Hashes passwords and authenticates correctly using PBKDF2', () async {
      const password = 'ExecutivePassword#2026!';
      final salt = AesGcmHelper.generateRandomSalt(16);

      final hash1 = await AesGcmHelper.hashPassword(password: password, salt: salt);
      final hash2 = await AesGcmHelper.hashPassword(password: password, salt: salt);

      expect(hash1, equals(hash2));
      expect(hash1.length, greaterThan(30));

      final wrongHash = await AesGcmHelper.hashPassword(
        password: 'WrongPassword!',
        salt: salt,
      );
      expect(hash1, isNot(equals(wrongHash)));
    });
  });
}
