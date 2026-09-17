import 'dart:convert';

enum OutboxStatus {
  pending,
  processing,
  failed,
  completed,
}

enum OutboxEventType {
  create,
  update,
  delete,
}

/// Persistent Outbox Queue item representing an offline mutation to be synchronized.
class OutboxSyncItem {
  final String id;
  final String aggregateType; // 'FINANCE', 'TASK', 'VAULT', 'HABIT', etc.
  final String aggregateId;
  final Map<String, dynamic> payload;
  final OutboxEventType eventType;
  final int retryCount;
  final String? lastError;
  final OutboxStatus status;
  final int createdAt;
  final int updatedAt;
  final String? vectorClock; // Logical timestamp for conflict resolution

  const OutboxSyncItem({
    required this.id,
    required this.aggregateType,
    required this.aggregateId,
    required this.payload,
    required this.eventType,
    this.retryCount = 0,
    this.lastError,
    this.status = OutboxStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.vectorClock,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aggregate_type': aggregateType,
      'aggregate_id': aggregateId,
      'payload': jsonEncode(payload),
      'event_type': eventType.name.toUpperCase(),
      'retry_count': retryCount,
      'last_error': lastError,
      'status': status.name.toUpperCase(),
      'created_at': createdAt,
      'updated_at': updatedAt,
      'vector_clock': vectorClock,
    };
  }

  factory OutboxSyncItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedPayload = {};
    try {
      final raw = map['payload'];
      if (raw is String) {
        parsedPayload = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        parsedPayload = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    final eventStr = (map['event_type'] as String? ?? 'CREATE').toLowerCase();
    final eventType = OutboxEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == eventStr,
      orElse: () => OutboxEventType.create,
    );

    final statusStr = (map['status'] as String? ?? 'PENDING').toLowerCase();
    final status = OutboxStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == statusStr,
      orElse: () => OutboxStatus.pending,
    );

    return OutboxSyncItem(
      id: map['id'] as String,
      aggregateType: map['aggregate_type'] as String,
      aggregateId: map['aggregate_id'] as String,
      payload: parsedPayload,
      eventType: eventType,
      retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
      lastError: map['last_error'] as String?,
      status: status,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      vectorClock: map['vector_clock'] as String?,
    );
  }

  OutboxSyncItem copyWith({
    String? id,
    String? aggregateType,
    String? aggregateId,
    Map<String, dynamic>? payload,
    OutboxEventType? eventType,
    int? retryCount,
    String? lastError,
    OutboxStatus? status,
    int? createdAt,
    int? updatedAt,
    String? vectorClock,
  }) {
    return OutboxSyncItem(
      id: id ?? this.id,
      aggregateType: aggregateType ?? this.aggregateType,
      aggregateId: aggregateId ?? this.aggregateId,
      payload: payload ?? this.payload,
      eventType: eventType ?? this.eventType,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vectorClock: vectorClock ?? this.vectorClock,
    );
  }
}
