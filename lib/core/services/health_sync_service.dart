import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Telemetry snapshot from Health Connect / wearable devices
/// (such as Redmi Watch 5 Lite synced via Mi Fitness).
@immutable
class HealthSnapshot {
  const HealthSnapshot({
    required this.steps,
    this.heartRate,
    this.sleepDuration = Duration.zero,
    this.activeCalories = 0,
    required this.lastSyncedAt,
    this.isConnected = false,
    this.isAvailable = false,
    this.errorMessage,
    this.isDemo = false,
  });

  final int steps;
  final int? heartRate;
  final Duration sleepDuration;
  final double activeCalories;
  final DateTime lastSyncedAt;
  final bool isConnected;
  final bool isAvailable;
  final String? errorMessage;
  final bool isDemo;

  String get formattedSleep {
    final hours = sleepDuration.inHours;
    final minutes = sleepDuration.inMinutes.remainder(60);
    if (hours == 0 && minutes == 0) return '--';
    return '${hours}j ${minutes}m';
  }

  HealthSnapshot copyWith({
    int? steps,
    int? heartRate,
    Duration? sleepDuration,
    double? activeCalories,
    DateTime? lastSyncedAt,
    bool? isConnected,
    bool? isAvailable,
    String? errorMessage,
    bool? isDemo,
  }) {
    return HealthSnapshot(
      steps: steps ?? this.steps,
      heartRate: heartRate ?? this.heartRate,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      activeCalories: activeCalories ?? this.activeCalories,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isConnected: isConnected ?? this.isConnected,
      isAvailable: isAvailable ?? this.isAvailable,
      errorMessage: errorMessage ?? this.errorMessage,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  static HealthSnapshot demo() {
    return HealthSnapshot(
      steps: 7420,
      heartRate: 72,
      sleepDuration: const Duration(hours: 7, minutes: 24),
      activeCalories: 385,
      lastSyncedAt: DateTime.now(),
      isConnected: true,
      isAvailable: true,
      isDemo: true,
    );
  }

  static HealthSnapshot empty() {
    return HealthSnapshot(
      steps: 0,
      lastSyncedAt: DateTime.now(),
      isConnected: false,
      isAvailable: false,
    );
  }
}

/// Service that interfaces with Google Health Connect on Android
/// to pull steps, heart rate, sleep, and calories synced from
/// smartwatches (including Redmi Watch 5 Lite via Mi Fitness).
class HealthSyncService {
  HealthSyncService._();
  static final HealthSyncService instance = HealthSyncService._();

  final Health _health = Health();
  bool _isConfigured = false;

  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<void> _ensureConfigured() async {
    if (_isConfigured) return;
    try {
      await _health.configure();
      _isConfigured = true;
    } catch (e) {
      debugPrint('[HealthSyncService] configure error: $e');
    }
  }

  /// Checks if Health Connect is supported and installed on this device.
  Future<bool> isHealthConnectAvailable() async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    try {
      if (Platform.isAndroid) {
        return await _health.isHealthConnectAvailable();
      } else if (Platform.isIOS) {
        return true; // Apple Health
      }
    } catch (_) {}
    return false;
  }

  /// Prompts user to install Google Health Connect from Google Play Store if missing.
  Future<void> installHealthConnect() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _health.installHealthConnect();
      }
    } catch (e) {
      debugPrint('[HealthSyncService] installHealthConnect error: $e');
    }
  }

  /// Checks whether read permissions are already granted.
  Future<bool> hasPermissions() async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    try {
      final granted = await _health.hasPermissions(_dataTypes, permissions: _permissions);
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests authorization from the user via the Health Connect system prompt.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    try {
      final granted = await _health.requestAuthorization(
        _dataTypes,
        permissions: _permissions,
      );
      return granted;
    } catch (e) {
      debugPrint('[HealthSyncService] requestAuthorization error: $e');
      return false;
    }
  }

  /// Queries Health Connect for today's steps, latest heart rate,
  /// last night's sleep duration, and active calories.
  Future<HealthSnapshot> fetchLatestMetrics({bool allowDemoFallback = true}) async {
    if (kIsWeb) {
      return allowDemoFallback ? HealthSnapshot.demo() : HealthSnapshot.empty();
    }

    await _ensureConfigured();

    final isAvailable = await isHealthConnectAvailable();
    if (!isAvailable) {
      if (allowDemoFallback) {
        return HealthSnapshot.demo().copyWith(isAvailable: false);
      }
      return HealthSnapshot.empty().copyWith(
        errorMessage: 'Health Connect belum terpasang di perangkat',
      );
    }

    final hasPerms = await hasPermissions();
    if (!hasPerms) {
      final granted = await requestPermissions();
      if (!granted) {
        if (allowDemoFallback) {
          return HealthSnapshot.demo().copyWith(
            isConnected: false,
            errorMessage: 'Izin Health Connect belum diberikan',
          );
        }
        return HealthSnapshot.empty().copyWith(
          errorMessage: 'Izin Health Connect belum diberikan',
        );
      }
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final yesterdayEvening = startOfDay.subtract(const Duration(hours: 8));

      // 1. Total Steps today
      int steps = 0;
      try {
        final stepCount = await _health.getTotalStepsInInterval(startOfDay, now);
        steps = stepCount ?? 0;
      } catch (e) {
        debugPrint('[HealthSyncService] steps fetch error: $e');
      }

      // 2. Query other types
      final dataPoints = await _health.getHealthDataFromTypes(
        startTime: yesterdayEvening,
        endTime: now,
        types: [
          HealthDataType.HEART_RATE,
          HealthDataType.SLEEP_SESSION,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
      );

      int? latestHeartRate;
      DateTime? latestHeartRateTime;
      Duration sleepDuration = Duration.zero;
      double activeCalories = 0;

      for (final p in dataPoints) {
        if (p.type == HealthDataType.HEART_RATE) {
          if (latestHeartRateTime == null || p.dateTo.isAfter(latestHeartRateTime)) {
            final val = p.value;
            if (val is NumericHealthValue) {
              latestHeartRate = val.numericValue.toInt();
              latestHeartRateTime = p.dateTo;
            }
          }
        } else if (p.type == HealthDataType.SLEEP_SESSION) {
          final session = p.dateTo.difference(p.dateFrom);
          if (session > Duration.zero) {
            sleepDuration += session;
          }
        } else if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          if (p.dateFrom.isAfter(startOfDay)) {
            final val = p.value;
            if (val is NumericHealthValue) {
              activeCalories += val.numericValue.toDouble();
            }
          }
        }
      }

      return HealthSnapshot(
        steps: steps,
        heartRate: latestHeartRate,
        sleepDuration: sleepDuration,
        activeCalories: activeCalories,
        lastSyncedAt: now,
        isConnected: true,
        isAvailable: true,
      );
    } catch (e) {
      debugPrint('[HealthSyncService] fetch error: $e');
      if (allowDemoFallback) {
        return HealthSnapshot.demo().copyWith(errorMessage: e.toString());
      }
      return HealthSnapshot.empty().copyWith(errorMessage: e.toString());
    }
  }
}
