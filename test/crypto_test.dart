import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/crypto/aes_gcm_helper.dart';
import 'package:life_hub/core/crypto/session_key_holder.dart';

void main() {
  group('AES-256-GCM Cryptography & PBKDF2 Suite', () {
    const testPin = '849201';
    final testSalt = Uint8List.fromList([
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    ]);

    test('PBKDF2 derives deterministic 256-bit (32 bytes) key', () async {
      final key1 = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);
      final key2 = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);

      expect(key1.length, equals(32));
      expect(key1, equals(key2));

      // Different PIN produces completely different key
      final keyDiff = await AesGcmHelper.deriveKeyFromPin(pin: '000000', salt: testSalt);
      expect(key1, isNot(equals(keyDiff)));
    });

    test('Auth verifier is consistent for identical derived keys', () async {
      final key = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);
      final verifier1 = AesGcmHelper.computeAuthVerifier(key);
      final verifier2 = AesGcmHelper.computeAuthVerifier(key);

      expect(verifier1, equals(verifier2));
      expect(verifier1.isNotEmpty, isTrue);
    });

    test('AES-256-GCM encrypts and decrypts confidential text accurately', () async {
      final key = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);
      const secretDiary = 'Confidential: Bitcoin wallet seed words and personal diary.';

      final encryptedPayload = await AesGcmHelper.encrypt(
        plainText: secretDiary,
        derivedKey: key,
      );

      expect(encryptedPayload, isNotEmpty);
      expect(encryptedPayload, isNot(contains(secretDiary)));

      final decrypted = await AesGcmHelper.decrypt(
        packedPayload: encryptedPayload,
        derivedKey: key,
      );

      expect(decrypted, equals(secretDiary));
    });

    test('AES-256-GCM fails decryption with tampered ciphertext or wrong key', () async {
      final key = await AesGcmHelper.deriveKeyFromPin(pin: testPin, salt: testSalt);
      final wrongKey = await AesGcmHelper.deriveKeyFromPin(pin: '999999', salt: testSalt);

      final payload = await AesGcmHelper.encrypt(
        plainText: 'Highly secret payload',
        derivedKey: key,
      );

      // Decryption with wrong key must fail
      expect(
        () async => await AesGcmHelper.decrypt(
          packedPayload: payload,
          derivedKey: wrongKey,
        ),
        throwsA(anything),
      );

      // Decryption with tampered payload must fail
      final rawBytes = base64Decode(payload);
      rawBytes[rawBytes.length - 1] ^= 0xFF; // Flip bits
      final tamperedPayload = base64Encode(rawBytes);

      expect(
        () async => await AesGcmHelper.decrypt(
          packedPayload: tamperedPayload,
          derivedKey: key,
        ),
        throwsA(anything),
      );
    });

    test('SessionKeyHolder securely zeroes out key bytes on lock', () {
      final keyHolder = SessionKeyHolder();
      final sampleKey = Uint8List.fromList(List.generate(32, (i) => i + 1));

      keyHolder.setKey(sampleKey);
      expect(keyHolder.hasKey, isTrue);
      expect(keyHolder.key, isNotNull);

      keyHolder.zeroize();
      expect(keyHolder.hasKey, isFalse);
      expect(keyHolder.key, isNull);
    });
  });
}
