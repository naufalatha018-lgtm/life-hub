import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/health_sync_service.dart';

class HealthSyncNotifier extends StateNotifier<AsyncValue<HealthSnapshot>> {
  HealthSyncNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  final HealthSyncService _service;

  Future<void> refresh() async {
    try {
      final snapshot = await _service.fetchLatestMetrics();
      state = AsyncValue.data(snapshot);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sync() async {
    state = const AsyncValue.loading();
    try {
      HapticFeedback.mediumImpact();
      final snapshot = await _service.fetchLatestMetrics();
      state = AsyncValue.data(snapshot);
      HapticFeedback.lightImpact();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> requestPermissions() async {
    await _service.requestPermissions();
    await sync();
  }

  Future<void> installHealthConnect() async {
    await _service.installHealthConnect();
  }
}

final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService.instance;
});

final healthSyncProvider =
    StateNotifierProvider<HealthSyncNotifier, AsyncValue<HealthSnapshot>>((ref) {
  final service = ref.watch(healthSyncServiceProvider);
  return HealthSyncNotifier(service);
});
