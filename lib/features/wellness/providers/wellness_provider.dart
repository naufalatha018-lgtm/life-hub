import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/wellness_dao.dart';
import '../models/wellness_log.dart';

final wellnessDaoProvider = Provider<WellnessDao>((ref) => WellnessDao());

// ─────────────────────────────────────────────
// WATER TRACKER
// ─────────────────────────────────────────────

@immutable
class WaterState {
  const WaterState({
    this.todayTotalMl = 0,
    this.dailyGoalMl = 2000,
    this.todayLogs = const [],
  });

  final int todayTotalMl;
  final int dailyGoalMl;
  final List<WaterLog> todayLogs;

  double get progressFraction => (todayTotalMl / dailyGoalMl).clamp(0.0, 1.0);
  bool get goalReached => todayTotalMl >= dailyGoalMl;
  int get remainingMl => (dailyGoalMl - todayTotalMl).clamp(0, dailyGoalMl);

  WaterState copyWith({int? todayTotalMl, int? dailyGoalMl, List<WaterLog>? todayLogs}) {
    return WaterState(
      todayTotalMl: todayTotalMl ?? this.todayTotalMl,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      todayLogs: todayLogs ?? this.todayLogs,
    );
  }
}

class WaterNotifier extends StateNotifier<WaterState> {
  WaterNotifier(this._dao) : super(const WaterState()) {
    loadToday();
  }

  final WellnessDao _dao;

  Future<void> loadToday() async {
    final total = await _dao.getTodayTotalMl();
    final rows = await _dao.getWaterLogsForDay(DateTime.now());
    final logs = rows.map((r) => WaterLog.fromMap(r)).toList();
    state = state.copyWith(todayTotalMl: total, todayLogs: logs);
  }

  Future<void> addWater(int amountMl) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final log = WaterLog(
      id: 'wl_${now.microsecondsSinceEpoch}',
      amountMl: amountMl,
      dailyGoalMl: state.dailyGoalMl,
      loggedAt: now,
      createdAt: now,
    );
    await _dao.addWaterLog(log.toMap());
    await loadToday();
  }

  Future<void> removeLog(String id) async {
    await _dao.deleteWaterLog(id);
    await loadToday();
  }

  void setDailyGoal(int ml) {
    state = state.copyWith(dailyGoalMl: ml);
  }
}

final waterNotifierProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier(ref.watch(wellnessDaoProvider));
});

// ─────────────────────────────────────────────
// MOOD TRACKER
// ─────────────────────────────────────────────

class MoodNotifier extends StateNotifier<AsyncValue<MoodLog?>> {
  MoodNotifier(this._dao) : super(const AsyncValue.loading()) {
    loadTodayMood();
  }

  final WellnessDao _dao;

  Future<void> loadTodayMood() async {
    try {
      final row = await _dao.getTodayMoodLog();
      state = AsyncValue.data(row != null ? MoodLog.fromMap(row) : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logMood(MoodLevel level, {String? note}) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final log = MoodLog(
      id: 'ml_${now.microsecondsSinceEpoch}',
      moodLevel: level,
      note: note,
      loggedAt: now,
      createdAt: now,
    );
    await _dao.addMoodLog(log.toMap());
    state = AsyncValue.data(log);
  }
}

final moodNotifierProvider = StateNotifierProvider<MoodNotifier, AsyncValue<MoodLog?>>((ref) {
  return MoodNotifier(ref.watch(wellnessDaoProvider));
});
