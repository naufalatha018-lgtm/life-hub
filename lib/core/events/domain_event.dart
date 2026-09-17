import 'dart:convert';

/// Typed Sealed Domain Event Hierarchy (Laravel Echo Event Parity).
sealed class DomainEvent {
  final String eventId;
  final String channel;
  final int timestamp;

  const DomainEvent({
    required this.eventId,
    required this.channel,
    required this.timestamp,
  });

  Map<String, dynamic> toMap();

  /// Deserializes a raw push/socket payload into a typed DomainEvent instance.
  static DomainEvent fromPayload({
    required String eventName,
    required String channel,
    required Map<String, dynamic> data,
  }) {
    final eventId = data['event_id'] as String? ?? 'evt_${DateTime.now().microsecondsSinceEpoch}';
    final timestamp = data['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    switch (eventName) {
      case 'TransactionCreated':
      case 'App\\Events\\TransactionCreated':
        return TransactionCreatedEvent(
          eventId: eventId,
          channel: channel,
          timestamp: timestamp,
          transactionData: data['transaction'] as Map<String, dynamic>? ?? data,
        );

      case 'VaultItemLocked':
      case 'App\\Events\\VaultItemLocked':
        return VaultItemLockedEvent(
          eventId: eventId,
          channel: channel,
          timestamp: timestamp,
          vaultId: data['vault_id'] as String? ?? 'vault_root',
          reason: data['reason'] as String? ?? 'Auto-lock triggered',
        );

      case 'OutboxDrained':
      case 'App\\Events\\OutboxDrained':
        return OutboxDrainedEvent(
          eventId: eventId,
          channel: channel,
          timestamp: timestamp,
          itemsProcessed: (data['items_processed'] as num?)?.toInt() ?? 0,
        );

      case 'SystemAuditAlert':
      case 'App\\Events\\SystemAuditAlert':
        return SystemAuditAlertEvent(
          eventId: eventId,
          channel: channel,
          timestamp: timestamp,
          severity: data['severity'] as String? ?? 'WARNING',
          message: data['message'] as String? ?? 'System security notification',
        );

      default:
        return GenericDomainEvent(
          eventId: eventId,
          channel: channel,
          timestamp: timestamp,
          eventName: eventName,
          payload: data,
        );
    }
  }
}

/// Dispatched when a financial ledger transaction is created remotely.
class TransactionCreatedEvent extends DomainEvent {
  final Map<String, dynamic> transactionData;

  const TransactionCreatedEvent({
    required super.eventId,
    required super.channel,
    required super.timestamp,
    required this.transactionData,
  });

  @override
  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'channel': channel,
        'timestamp': timestamp,
        'transaction': transactionData,
      };
}

/// Dispatched when a secure vault entry is locked due to policy or inactivity.
class VaultItemLockedEvent extends DomainEvent {
  final String vaultId;
  final String reason;

  const VaultItemLockedEvent({
    required super.eventId,
    required super.channel,
    required super.timestamp,
    required this.vaultId,
    required this.reason,
  });

  @override
  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'channel': channel,
        'timestamp': timestamp,
        'vault_id': vaultId,
        'reason': reason,
      };
}

/// Dispatched when the background outbox worker successfully drains mutations.
class OutboxDrainedEvent extends DomainEvent {
  final int itemsProcessed;

  const OutboxDrainedEvent({
    required super.eventId,
    required super.channel,
    required super.timestamp,
    required this.itemsProcessed,
  });

  @override
  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'channel': channel,
        'timestamp': timestamp,
        'items_processed': itemsProcessed,
      };
}

/// Dispatched when an audit trail verification failure or anomaly occurs.
class SystemAuditAlertEvent extends DomainEvent {
  final String severity; // 'INFO', 'WARNING', 'CRITICAL'
  final String message;

  const SystemAuditAlertEvent({
    required super.eventId,
    required super.channel,
    required super.timestamp,
    required this.severity,
    required this.message,
  });

  @override
  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'channel': channel,
        'timestamp': timestamp,
        'severity': severity,
        'message': message,
      };
}

/// Catch-all generic domain event.
class GenericDomainEvent extends DomainEvent {
  final String eventName;
  final Map<String, dynamic> payload;

  const GenericDomainEvent({
    required super.eventId,
    required super.channel,
    required super.timestamp,
    required this.eventName,
    required this.payload,
  });

  @override
  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'channel': channel,
        'timestamp': timestamp,
        'event_name': eventName,
        'payload': payload,
      };
}
