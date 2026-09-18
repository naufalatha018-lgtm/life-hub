import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/policy/gate.dart';
import 'package:life_hub/core/policy/policy_models.dart';

void main() {
  group('Policy Engine & RBAC Gates Suite (Laravel Gate Parity)', () {
    const executiveUser = UserPermissionProfile.defaultExecutive;

    const auditorUser = UserPermissionProfile(
      userId: 'usr_auditor',
      email: 'auditor@lifehub.corp',
      role: UserRole.auditor,
      directPermissions: {'view-audit-trail', 'verify-audit-chain'},
    );

    const memberUser = UserPermissionProfile(
      userId: 'usr_member',
      email: 'member@lifehub.local',
      role: UserRole.member,
      directPermissions: {'view-ledger', 'create-transaction'},
    );

    const guestUser = UserPermissionProfile(
      userId: 'usr_guest',
      email: 'guest@lifehub.local',
      role: UserRole.guest,
    );

    test('Executive role possesses root override across all policy gates', () {
      expect(Gate.allows(user: executiveUser, ability: 'purge-audit-trail'), isTrue);
      expect(Gate.allows(user: executiveUser, ability: 'export-high-value-report'), isTrue);
      expect(Gate.allows(user: executiveUser, ability: 'access-classified'), isTrue);
      expect(Gate.allows(user: executiveUser, ability: 'non-existent-ability'), isTrue);
    });

    test('Auditor role can verify audit chain but cannot purge audit trail', () {
      expect(Gate.allows(user: auditorUser, ability: 'view-audit-trail'), isTrue);
      expect(Gate.allows(user: auditorUser, ability: 'verify-audit-chain'), isTrue);
      expect(Gate.denies(user: auditorUser, ability: 'purge-audit-trail'), isTrue);
    });

    test('Standard member cannot export high-value transactions (> 100,000)', () {
      final highValueTransaction = {
        'id': 'tx_999',
        'amount_cents': 50000000, // $500,000 / Rp 500.000.000
      };

      final lowValueTransaction = {
        'id': 'tx_111',
        'amount_cents': 2000, // $20
      };

      expect(
        Gate.allows(
          user: memberUser,
          ability: 'export-high-value-report',
          target: highValueTransaction,
        ),
        isFalse,
      );

      const exportUser = UserPermissionProfile(
        userId: 'usr_export',
        email: 'export@lifehub.corp',
        role: UserRole.member,
        directPermissions: {'export-reports'},
      );

      expect(
        Gate.allows(
          user: exportUser,
          ability: 'export-high-value-report',
          target: lowValueTransaction,
        ),
        isTrue,
      );

      // Executive is allowed
      expect(
        Gate.allows(
          user: executiveUser,
          ability: 'export-high-value-report',
          target: highValueTransaction,
        ),
        isTrue,
      );
    });

    test('Guest cannot create transactions', () {
      expect(Gate.allows(user: guestUser, ability: 'create-transaction'), isFalse);
      expect(Gate.allows(user: memberUser, ability: 'create-transaction'), isTrue);
    });
  });
}
