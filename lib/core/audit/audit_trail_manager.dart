import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'audit_log_dao.dart';
import 'audit_log_model.dart';

/// Enterprise Immutable Tamper-Evident Audit Trail Manager (Laravel Spatie Parity).
///
/// Every state-mutating operation (CUD) across financial ledgers, vault secrets,
/// and core tasks is cryptographically signed and chained with HMAC-SHA256
/// (Blockchain-style sequential chaining).
class AuditTrailManager {
  AuditTrailManager({
    AuditLogDao? dao,
    String? secretKey,
  })  : _dao = dao ?? AuditLogDao(),
        _secretKey = secretKey ?? _defaultHmacKey;

  final AuditLogDao _dao;
  final String _secretKey;

  static const String _defaultHmacKey =
      'lifeos_enterprise_hmac_sha256_immutable_audit_root_key_2026';
  static const String genesisHash =
      '0000000000000000000000000000000000000000000000000000000000000000';
  static const _uuid = Uuid();

  /// Computes HMAC-SHA256 signature for a given payload string.
  String computeHmac(String payload) {
    final keyBytes = utf8.encode(_secretKey);
    final payloadBytes = utf8.encode(payload);
    final hmacSha256 = Hmac(sha256, keyBytes);
    return hmacSha256.convert(payloadBytes).toString();
  }

  /// Device / Hardware runtime fingerprint.
  String get deviceFingerprint {
    try {
      final host = Platform.localHostname;
      final os = Platform.operatingSystem;
      return '$os-$host';
    } catch (_) {
      return 'generic-secure-node';
    }
  }

  /// Records an immutable audit log entry into SQLite.
  Future<AuditLogEntry> recordOperation({
    required String actorId,
    required String actionType,
    required String tableName,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    Transaction? txn,
  }) async {
    final latest = await _dao.getLatestLog();
    final previousHash = latest?.currentHash ?? genesisHash;

    final logId = _uuid.v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final diff = <String, dynamic>{
      'before': before ?? {},
      'after': after ?? {},
    };

    final entryCandidate = AuditLogEntry(
      logId: logId,
      actorId: actorId,
      actionType: actionType.toUpperCase(),
      tableName: tableName,
      diffPayload: diff,
      deviceFingerprint: deviceFingerprint,
      timestamp: timestamp,
      previousHash: previousHash,
      currentHash: '', // computed next
    );

    final currentHash = computeHmac(entryCandidate.canonicalSigningPayload);

    final finalEntry = AuditLogEntry(
      logId: logId,
      actorId: actorId,
      actionType: actionType.toUpperCase(),
      tableName: tableName,
      diffPayload: diff,
      deviceFingerprint: deviceFingerprint,
      timestamp: timestamp,
      previousHash: previousHash,
      currentHash: currentHash,
    );

    await _dao.insertLog(finalEntry, txn);
    return finalEntry;
  }

  /// Rigorously verifies the entire cryptographic chain from genesis to head.
  /// Detects broken links, altered payloads, forged hashes, or timestamp tampering.
  Future<AuditVerificationResult> verifyChainIntegrity() async {
    final logs = await _dao.getAllLogsAscending();
    if (logs.isEmpty) {
      return AuditVerificationResult.success(0);
    }

    String expectedPreviousHash = genesisHash;

    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];

      // Check 1: Previous hash link integrity
      if (log.previousHash != expectedPreviousHash) {
        return AuditVerificationResult.tampered(
          count: i,
          logId: log.logId,
          reason: 'Chain link broken: expected previous hash $expectedPreviousHash '
              'but found ${log.previousHash}',
        );
      }

      // Check 2: Recompute current node's HMAC-SHA256 signature
      final recomputedHash = computeHmac(log.canonicalSigningPayload);
      if (recomputedHash != log.currentHash) {
        return AuditVerificationResult.tampered(
          count: i,
          logId: log.logId,
          reason: 'Cryptographic payload tampering detected! '
              'Stored hash ${log.currentHash} != computed $recomputedHash',
        );
      }

      expectedPreviousHash = log.currentHash;
    }

    return AuditVerificationResult.success(logs.length);
  }

  /// Automatically prunes records older than [retentionDays] (default: 30 days).
  Future<int> pruneOldLogs({int retentionDays = 30}) async {
    final threshold = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    return await _dao.pruneLogsOlderThan(threshold);
  }

  /// Compresses the recent audit logs into a gzip binary telemetry payload.
  Future<List<int>> exportGzipTelemetryBundle({int limit = 500}) async {
    final recentLogs = await _dao.getRecentLogs(limit: limit);
    final jsonList = recentLogs.map((l) => l.toMap()).toList();
    final jsonString = jsonEncode(jsonList);
    final utf8Bytes = utf8.encode(jsonString);
    return gzip.encode(utf8Bytes);
  }

  /// Gets recent logs for visual UI inspection.
  Future<List<AuditLogEntry>> getRecentLogs({int limit = 50}) {
    return _dao.getRecentLogs(limit: limit);
  }
}

// ─────────────────────────────────────────────
// RIVERPOD PROVIDERS
// ─────────────────────────────────────────────

final auditDaoProvider = Provider<AuditLogDao>((ref) {
  return AuditLogDao();
});

final auditTrailManagerProvider = Provider<AuditTrailManager>((ref) {
  final dao = ref.watch(auditDaoProvider);
  return AuditTrailManager(dao: dao);
});

final recentAuditLogsProvider =
    FutureProvider.autoDispose<List<AuditLogEntry>>((ref) async {
  final manager = ref.watch(auditTrailManagerProvider);
  return manager.getRecentLogs(limit: 50);
});

final auditChainVerificationProvider =
    FutureProvider.autoDispose<AuditVerificationResult>((ref) async {
  final manager = ref.watch(auditTrailManagerProvider);
  return manager.verifyChainIntegrity();
});
