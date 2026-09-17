import 'policy_models.dart';

/// Declarative Policy interface (Laravel Policy Parity).
abstract class Policy<T> {
  bool can(UserPermissionProfile user, String ability, T? target);
}

/// Finance Policy controlling transaction operations and high-value exports.
class FinancePolicy implements Policy<Map<String, dynamic>> {
  @override
  bool can(UserPermissionProfile user, String ability, Map<String, dynamic>? target) {
    return switch (ability) {
      'view-transactions' => true, // Everyone can view their transactions
      'create-transaction' => user.role != UserRole.guest,
      'delete-transaction' => user.isAdmin || (target?['user_id'] == user.userId),
      'export-high-value-report' => () {
          // If transaction amount > 10,000,000 cents ($100,000 or Rp 100jt), requires Executive role
          final amountCents = (target?['amount_cents'] as num?)?.toInt() ?? 0;
          if (amountCents > 10000000) {
            return user.isExecutive;
          }
          return user.isAdmin || user.hasPermission('export-reports');
        }(),
      _ => false,
    };
  }
}

/// Audit Policy governing access to immutable blockchain-style logs.
class AuditPolicy implements Policy<dynamic> {
  @override
  bool can(UserPermissionProfile user, String ability, dynamic target) {
    return switch (ability) {
      'view-audit-trail' => user.isAuditor || user.isAdmin,
      'verify-audit-chain' => user.isAuditor || user.isAdmin,
      'export-audit-telemetry' => user.isAuditor || user.isExecutive,
      'purge-audit-trail' => user.isExecutive, // Strictly executive with biometric challenge
      _ => false,
    };
  }
}

/// Vault Policy governing access to encrypted files and secrets.
class VaultPolicy implements Policy<Map<String, dynamic>> {
  @override
  bool can(UserPermissionProfile user, String ability, Map<String, dynamic>? target) {
    return switch (ability) {
      'access-vault' => user.role != UserRole.guest,
      'export-vault' => user.isExecutive || user.isAdmin,
      'access-classified' => user.isExecutive,
      _ => false,
    };
  }
}
