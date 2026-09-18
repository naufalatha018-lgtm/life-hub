/// Hybrid Logical Clock (HLC) implementation for deterministic causality tracking.
class HybridLogicalClock implements Comparable<HybridLogicalClock> {
  final int logicalTime; // Physical wall-clock ms
  final int counter; // Tie-breaker sequence within the same millisecond
  final String nodeId; // Deterministic device node identifier

  const HybridLogicalClock({
    required this.logicalTime,
    required this.counter,
    required this.nodeId,
  });

  /// Generates a new local tick based on current physical time and last known HLC.
  static HybridLogicalClock tick({
    required HybridLogicalClock? lastHlc,
    required String nodeId,
  }) {
    final physicalMs = DateTime.now().millisecondsSinceEpoch;

    if (lastHlc == null) {
      return HybridLogicalClock(
        logicalTime: physicalMs,
        counter: 0,
        nodeId: nodeId,
      );
    }

    if (physicalMs > lastHlc.logicalTime) {
      return HybridLogicalClock(
        logicalTime: physicalMs,
        counter: 0,
        nodeId: nodeId,
      );
    } else {
      return HybridLogicalClock(
        logicalTime: lastHlc.logicalTime,
        counter: lastHlc.counter + 1,
        nodeId: nodeId,
      );
    }
  }

  /// Parses an HLC string formatted as: `logicalTime:counter:nodeId`
  factory HybridLogicalClock.parse(String formatted) {
    final parts = formatted.split(':');
    if (parts.length < 3) {
      return HybridLogicalClock(
        logicalTime: DateTime.now().millisecondsSinceEpoch,
        counter: 0,
        nodeId: 'unknown',
      );
    }
    return HybridLogicalClock(
      logicalTime: int.tryParse(parts[0]) ?? 0,
      counter: int.tryParse(parts[1]) ?? 0,
      nodeId: parts.sublist(2).join(':'),
    );
  }

  @override
  String toString() => '$logicalTime:$counter:$nodeId';

  @override
  int compareTo(HybridLogicalClock other) {
    if (logicalTime != other.logicalTime) {
      return logicalTime.compareTo(other.logicalTime);
    }
    if (counter != other.counter) {
      return counter.compareTo(other.counter);
    }
    return nodeId.compareTo(other.nodeId);
  }
}

/// Outcome of conflict resolution between local mutation and remote state.
enum ConflictResolutionStrategy {
  lastWriteWins,
  mergeFields,
  clientAuthoritative,
  serverAuthoritative,
}

class ConflictResolutionResult {
  final ConflictResolutionStrategy strategy;
  final Map<String, dynamic> resolvedPayload;
  final String resolutionNote;

  const ConflictResolutionResult({
    required this.strategy,
    required this.resolvedPayload,
    required this.resolutionNote,
  });
}

/// Enterprise Conflict Resolution Engine.
class ConflictResolver {
  ConflictResolver._();

  /// Resolves a 409 Conflict between local mutation and server snapshot.
  static ConflictResolutionResult resolve({
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> serverPayload,
    String? localClockStr,
    String? serverClockStr,
    ConflictResolutionStrategy preferredStrategy =
        ConflictResolutionStrategy.lastWriteWins,
  }) {
    // Strategy 1: Last-Write-Wins via HLC comparison
    if (preferredStrategy == ConflictResolutionStrategy.lastWriteWins) {
      if (localClockStr != null && serverClockStr != null) {
        final localHlc = HybridLogicalClock.parse(localClockStr);
        final serverHlc = HybridLogicalClock.parse(serverClockStr);

        if (localHlc.compareTo(serverHlc) >= 0) {
          return ConflictResolutionResult(
            strategy: ConflictResolutionStrategy.lastWriteWins,
            resolvedPayload: Map<String, dynamic>.from(localPayload),
            resolutionNote:
                'Resolved via LWW: Local HLC ($localClockStr) >= Server ($serverClockStr). Local applied.',
          );
        } else {
          return ConflictResolutionResult(
            strategy: ConflictResolutionStrategy.lastWriteWins,
            resolvedPayload: Map<String, dynamic>.from(serverPayload),
            resolutionNote:
                'Resolved via LWW: Server HLC ($serverClockStr) > Local ($localClockStr). Server applied.',
          );
        }
      }

      // Fallback: compare updated_at timestamps
      final localTs = (localPayload['updated_at'] as num?)?.toInt() ?? 0;
      final serverTs = (serverPayload['updated_at'] as num?)?.toInt() ?? 0;

      if (localTs >= serverTs) {
        return ConflictResolutionResult(
          strategy: ConflictResolutionStrategy.lastWriteWins,
          resolvedPayload: Map<String, dynamic>.from(localPayload),
          resolutionNote: 'Resolved via timestamp LWW: Local timestamp >= Server.',
        );
      } else {
        return ConflictResolutionResult(
          strategy: ConflictResolutionStrategy.lastWriteWins,
          resolvedPayload: Map<String, dynamic>.from(serverPayload),
          resolutionNote: 'Resolved via timestamp LWW: Server timestamp > Local.',
        );
      }
    }

    // Strategy 2: 3-way Field Merge
    final merged = Map<String, dynamic>.from(serverPayload);
    for (final entry in localPayload.entries) {
      if (entry.value != null && entry.value != '') {
        merged[entry.key] = entry.value;
      }
    }

    return ConflictResolutionResult(
      strategy: ConflictResolutionStrategy.mergeFields,
      resolvedPayload: merged,
      resolutionNote: 'Resolved via field-level merge algorithm.',
    );
  }
}
