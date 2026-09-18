import 'package:flutter/foundation.dart';

import 'health_sync_service.dart';

/// Computes a holistic Daily Readiness Score (0–100) from Health Connect
/// telemetry data: sleep quality, resting heart rate, and task load.
///
/// Algorithm (additive weighted):
///   - Sleep (40 pts): ≥7h → 40, ≥6h → 30, ≥5h → 18, <5h → 6
///   - Heart Rate (30 pts): resting HR ≤60 → 30, ≤70 → 24, ≤80 → 16, >80 → 8
///     (skipped/bonus=20 if no data — assumes resting)
///   - Task Load (30 pts): placeholder from pending task count — 30 if ≤3,
///     20 if ≤6, 10 if ≤10, 5 otherwise. Injected externally.
class ReadinessTelemetryService {
  ReadinessTelemetryService._();
  static final ReadinessTelemetryService instance = ReadinessTelemetryService._();

  int _pendingTaskCount = 0;

  /// Call this once per session before computing — inject the current pending
  /// task count so the algorithm can weight task load appropriately.
  void setTaskLoad(int pendingCount) {
    _pendingTaskCount = pendingCount;
  }

  /// Asynchronously fetches the latest [HealthSnapshot] and computes the score.
  Future<int> computeScore() async {
    HealthSnapshot snapshot;
    try {
      snapshot = await HealthSyncService.instance.fetchLatestMetrics();
    } catch (_) {
      snapshot = HealthSnapshot.empty();
    }

    return _compute(snapshot);
  }

  int _compute(HealthSnapshot snapshot) {
    int score = 0;

    // ── Sleep score (40 pts) ──────────────────────────────────────────────
    final sleepHours = snapshot.sleepDuration.inMinutes / 60.0;
    if (sleepHours >= 7.0) {
      score += 40;
    } else if (sleepHours >= 6.0) {
      score += 30;
    } else if (sleepHours >= 5.0) {
      score += 18;
    } else if (sleepHours > 0) {
      score += 6;
    } else {
      // No sleep data — award neutral 20
      score += 20;
    }

    // ── Heart rate score (30 pts) ─────────────────────────────────────────
    final hr = snapshot.heartRate;
    if (hr == null) {
      score += 20; // neutral bonus
    } else if (hr <= 60) {
      score += 30;
    } else if (hr <= 70) {
      score += 24;
    } else if (hr <= 80) {
      score += 16;
    } else {
      score += 8;
    }

    // ── Task load score (30 pts) ──────────────────────────────────────────
    if (_pendingTaskCount <= 3) {
      score += 30;
    } else if (_pendingTaskCount <= 6) {
      score += 20;
    } else if (_pendingTaskCount <= 10) {
      score += 10;
    } else {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  @visibleForTesting
  int computeFromSnapshot(HealthSnapshot snapshot) => _compute(snapshot);
}
