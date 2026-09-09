import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/crypto/aes_gcm_helper.dart';
import 'package:life_hub/features/auth/models/user_model.dart';
import 'package:life_hub/features/auth/providers/auth_provider.dart';

void main() {
  group('Auth Hardening & Validation Test Suite', () {
    test('Validates password strength rules strictly', () {
      // Too short (< 8 chars)
      expect(
        () => AuthNotifier.validatePasswordStrength('Short1'),
        throwsA(isA<Exception>()),
      );

      // Only letters, no digits
      expect(
        () => AuthNotifier.validatePasswordStrength('OnlyLettersHere'),
        throwsA(isA<Exception>()),
      );

      // Only digits, no letters
      expect(
        () => AuthNotifier.validatePasswordStrength('1234567890'),
        throwsA(isA<Exception>()),
      );

      // Valid: >= 8 characters with letters and numbers
      expect(
        () => AuthNotifier.validatePasswordStrength('SecurePass123'),
        returnsNormally,
      );

      expect(
        () => AuthNotifier.validatePasswordStrength('Alpha999!@#'),
        returnsNormally,
      );
    });

    test('AppUser model handles isVerified serialization and defaults', () {
      final now = DateTime.now();

      // Default isVerified is true
      final userDefault = AppUser(
        id: 'usr_1',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        authProvider: 'local',
        createdAt: now,
        lastLoginAt: now,
      );
      expect(userDefault.isVerified, isTrue);

      final map = userDefault.toMap();
      expect(map['is_verified'], equals(1));

      // Unverified user
      final userUnverified = userDefault.copyWith(isVerified: false);
      expect(userUnverified.isVerified, isFalse);

      final unverifiedMap = userUnverified.toMap();
      expect(unverifiedMap['is_verified'], equals(0));

      final restored = AppUser.fromMap(unverifiedMap);
      expect(restored.isVerified, isFalse);
      expect(restored.email, equals('test@example.com'));
    });

    test('PBKDF2/SHA-256 password hashing generates deterministic hashes for given salt', () async {
      final salt = AesGcmHelper.generateRandomSalt(16);
      const password = 'ExecutivePassword2026!';

      final hash1 = await AesGcmHelper.hashPassword(password: password, salt: salt);
      final hash2 = await AesGcmHelper.hashPassword(password: password, salt: salt);

      expect(hash1, equals(hash2));
      expect(hash1.length, greaterThan(20));

      // Mismatched password yields different hash
      final hashMismatch = await AesGcmHelper.hashPassword(password: 'DifferentPass123', salt: salt);
      expect(hash1, isNot(equals(hashMismatch)));
    });
  });
}
