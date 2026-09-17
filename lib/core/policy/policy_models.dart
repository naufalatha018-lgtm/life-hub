/// Enterprise RBAC User Roles.
enum UserRole {
  executive, // Full root access, biometric challenge capability, financial audit
  admin, // Operation admin, transaction manager
  auditor, // Read-only audit log inspection, verification
  member, // Standard read/write on own data
  guest, // Read-only or restricted sandbox
}

/// User Permission Profile representing the authenticated user's authority matrix.
class UserPermissionProfile {
  final String userId;
  final String email;
  final UserRole role;
  final Set<String> directPermissions;

  const UserPermissionProfile({
    required this.userId,
    required this.email,
    required this.role,
    this.directPermissions = const {},
  });

  bool get isExecutive => role == UserRole.executive;
  bool get isAdmin => role == UserRole.admin || isExecutive;
  bool get isAuditor => role == UserRole.auditor || isExecutive;

  /// Returns true if user has the given capability or role bypass.
  bool hasPermission(String permission) {
    if (isExecutive) return true; // Executive root override
    return directPermissions.contains(permission);
  }

  static const UserPermissionProfile defaultExecutive = UserPermissionProfile(
    userId: 'usr_executive_root',
    email: 'executive@lifehub.enterprise',
    role: UserRole.executive,
    directPermissions: {
      'view-ledger',
      'create-transaction',
      'export-high-value-report',
      'view-audit-trail',
      'verify-audit-chain',
      'purge-audit-trail',
      'access-classified-vault',
      'flush-outbox-queue',
    },
  );

  static const UserPermissionProfile defaultStandard = UserPermissionProfile(
    userId: 'usr_standard_member',
    email: 'member@lifehub.local',
    role: UserRole.member,
    directPermissions: {
      'view-ledger',
      'create-transaction',
      'view-audit-trail',
    },
  );
}
