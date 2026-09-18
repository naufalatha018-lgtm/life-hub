import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';
import 'policies.dart';
import 'policy_models.dart';

/// Laravel Gate Parity: Central Authorization Engine for granular RBAC & security checks.
class Gate {
  Gate._();

  static final FinancePolicy _financePolicy = FinancePolicy();
  static final AuditPolicy _auditPolicy = AuditPolicy();
  static final VaultPolicy _vaultPolicy = VaultPolicy();

  /// Checks if current [user] has permission for [ability] on [target].
  static bool allows({
    required UserPermissionProfile user,
    required String ability,
    dynamic target,
  }) {
    // 1. Direct permission override check
    if (user.isExecutive) return true;

    // 2. Ability routing to specialized policies
    if (ability.startsWith('view-transaction') ||
        ability.startsWith('create-transaction') ||
        ability.startsWith('delete-transaction') ||
        ability.startsWith('export-high-value')) {
      return _financePolicy.can(
        user,
        ability,
        target is Map<String, dynamic> ? target : null,
      );
    }

    if (ability.startsWith('view-audit') ||
        ability.startsWith('verify-audit') ||
        ability.startsWith('export-audit') ||
        ability.startsWith('purge-audit')) {
      return _auditPolicy.can(user, ability, target);
    }

    if (ability.startsWith('access-vault') ||
        ability.startsWith('export-vault') ||
        ability.startsWith('access-classified')) {
      return _vaultPolicy.can(
        user,
        ability,
        target is Map<String, dynamic> ? target : null,
      );
    }

    return user.hasPermission(ability);
  }

  /// Inverted allows check.
  static bool denies({
    required UserPermissionProfile user,
    required String ability,
    dynamic target,
  }) {
    return !allows(user: user, ability: ability, target: target);
  }

  /// Authorizes an action, optionally executing a hardware biometric challenge
  /// (Fingerprint / Face ID) for sensitive operations.
  static Future<bool> authorize({
    required BuildContext context,
    required UserPermissionProfile user,
    required String ability,
    dynamic target,
    bool requireBiometric = false,
    String biometricReason = 'Konfirmasi otorisasi eksekutif untuk operasi sensitif',
  }) async {
    final hasGatePermission = allows(
      user: user,
      ability: ability,
      target: target,
    );

    if (!hasGatePermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akses Ditolak: Peran "${user.role.name}" tidak memiliki izin "$ability".'),
          backgroundColor: const Color(0xFFFF3366),
        ),
      );
      return false;
    }

    // If biometric challenge is required for high-tier policy
    if (requireBiometric) {
      final bioSuccess = await BiometricService.instance.authenticate(
        localizedReason: biometricReason,
      );
      if (!bioSuccess) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Otentikasi biometrik gagal atau dibatalkan.'),
              backgroundColor: Color(0xFFFFB020),
            ),
          );
        }
        return false;
      }
    }

    return true;
  }
}

// ─────────────────────────────────────────────
// RIVERPOD PROVIDERS
// ─────────────────────────────────────────────

/// Persisted user permission profile in Riverpod.
/// Defaults to Executive so all enterprise features can be demonstrated immediately.
final userPermissionProfileProvider =
    StateProvider<UserPermissionProfile>((ref) {
  return UserPermissionProfile.defaultExecutive;
});
