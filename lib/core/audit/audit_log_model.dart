import 'dart:convert';

/// Immutable Audit Log Record representing a tamper-evident audit block.
class AuditLogEntry {
  final String logId;
  final String actorId;
  final String actionType; // 'CREATE', 'UPDATE', 'DELETE'
  final String tableName;
  final Map<String, dynamic> diffPayload; // {"before": {...}, "after": {...}}
  final String deviceFingerprint;
  final int timestamp;
  final String previousHash;
  final String currentHash;

  const AuditLogEntry({
    required this.logId,
    required this.actorId,
    required this.actionType,
    required this.tableName,
    required this.diffPayload,
    required this.deviceFingerprint,
    required this.timestamp,
    required this.previousHash,
    required this.currentHash,
  });

  /// Canonical serialization string used for cryptographic HMAC-SHA256 hashing.
  String get canonicalSigningPayload {
    final sortedDiff = jsonEncode(diffPayload);
    return '$logId|$actorId|$actionType|$tableName|$sortedDiff|$deviceFingerprint|$timestamp|$previousHash';
  }

  Map<String, dynamic> toMap() {
    return {
      'log_id': logId,
      'actor_id': actorId,
      'action_type': actionType,
      'table_name': tableName,
      'diff_payload': jsonEncode(diffPayload),
      'device_fingerprint': deviceFingerprint,
      'timestamp': timestamp,
      'previous_hash': previousHash,
      'current_hash': currentHash,
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedDiff = {};
    try {
      final raw = map['diff_payload'];
      if (raw is String) {
        parsedDiff = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        parsedDiff = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    return AuditLogEntry(
      logId: map['log_id'] as String,
      actorId: map['actor_id'] as String,
      actionType: map['action_type'] as String,
      tableName: map['table_name'] as String,
      diffPayload: parsedDiff,
      deviceFingerprint: map['device_fingerprint'] as String,
      timestamp: map['timestamp'] as int,
      previousHash: map['previous_hash'] as String,
      currentHash: map['current_hash'] as String,
    );
  }
}

/// Verification result detailing cryptographic chain health.
class AuditVerificationResult {
  final bool isValid;
  final int verifiedCount;
  final String? corruptedLogId;
  final String? reason;
  final DateTime verifiedAt;

  const AuditVerificationResult({
    required this.isValid,
    required this.verifiedCount,
    this.corruptedLogId,
    this.reason,
    required this.verifiedAt,
  });

  factory AuditVerificationResult.success(int count) => AuditVerificationResult(
        isValid: true,
        verifiedCount: count,
        verifiedAt: DateTime.now(),
      );

  factory AuditVerificationResult.tampered({
    required int count,
    required String logId,
    required String reason,
  }) =>
      AuditVerificationResult(
        isValid: false,
        verifiedCount: count,
        corruptedLogId: logId,
        reason: reason,
        verifiedAt: DateTime.now(),
      );
}
