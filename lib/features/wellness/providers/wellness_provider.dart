import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/wellness_dao.dart';
import '../../auth/providers/auth_provider.dart';
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
  WaterNotifier(this._dao, [this._userId]) : super(const WaterState()) {
    loadToday();
  }

  final WellnessDao _dao;
  final String? _userId;

  Future<void> loadToday() async {
    final total = await _dao.getTodayTotalMl(_userId);
    final rows = await _dao.getWaterLogsForDay(DateTime.now(), _userId);
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
    await _dao.addWaterLog(log.toMap(), _userId);
    await loadToday();
  }

  Future<void> removeLog(String id) async {
    await _dao.deleteWaterLog(id, _userId);
    await loadToday();
  }

  void setDailyGoal(int ml) {
    state = state.copyWith(dailyGoalMl: ml);
  }
}

final waterNotifierProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return WaterNotifier(ref.watch(wellnessDaoProvider), userId);
});

// ─────────────────────────────────────────────
// MOOD TRACKER
// ─────────────────────────────────────────────

class MoodNotifier extends StateNotifier<AsyncValue<MoodLog?>> {
  MoodNotifier(this._dao, [this._userId]) : super(const AsyncValue.loading()) {
    loadTodayMood();
  }

  final WellnessDao _dao;
  final String? _userId;

  Future<void> loadTodayMood() async {
    try {
      final row = await _dao.getTodayMoodLog(_userId);
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
    await _dao.addMoodLog(log.toMap(), _userId);
    state = AsyncValue.data(log);
  }
}

final moodNotifierProvider = StateNotifierProvider<MoodNotifier, AsyncValue<MoodLog?>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return MoodNotifier(ref.watch(wellnessDaoProvider), userId);
});
