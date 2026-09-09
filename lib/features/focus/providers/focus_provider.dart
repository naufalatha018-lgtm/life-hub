import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/audio_notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/focus_session.dart';

enum FocusTimerState { idle, running, paused, breakTime }

@immutable
class FocusTimerData {
  const FocusTimerData({
    this.phase = FocusPhase.focus,
    this.timerState = FocusTimerState.idle,
    this.remainingSeconds = 25 * 60,
    this.totalSeconds = 25 * 60,
    this.sessionCount = 0,
    this.linkedTaskId,
    this.currentSessionId,
  });

  final FocusPhase phase;
  final FocusTimerState timerState;
  final int remainingSeconds;
  final int totalSeconds;
  final int sessionCount;
  final String? linkedTaskId;
  final String? currentSessionId;

  bool get isIdle => timerState == FocusTimerState.idle;
  bool get isRunning => timerState == FocusTimerState.running;
  bool get isPaused => timerState == FocusTimerState.paused;
  bool get isOnBreak => timerState == FocusTimerState.breakTime;

  double get progress => totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0;

  String get formattedTime {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get phaseLabel {
    switch (phase) {
      case FocusPhase.focus:
        return 'Waktu Fokus';
      case FocusPhase.shortBreak:
        return 'Istirahat Singkat';
      case FocusPhase.longBreak:
        return 'Istirahat Panjang';
    }
  }

  FocusTimerData copyWith({
    FocusPhase? phase,
    FocusTimerState? timerState,
    int? remainingSeconds,
    int? totalSeconds,
    int? sessionCount,
    String? linkedTaskId,
    String? currentSessionId,
  }) {
    return FocusTimerData(
      phase: phase ?? this.phase,
      timerState: timerState ?? this.timerState,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      sessionCount: sessionCount ?? this.sessionCount,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }

  // Pomodoro standard durations
  static const int focusDuration = 25 * 60; // 25 minutes
  static const int shortBreakDuration = 5 * 60; // 5 minutes
  static const int longBreakDuration = 15 * 60; // 15 minutes
  static const int sessionsBeforeLongBreak = 4;
}

class FocusTimerNotifier extends StateNotifier<FocusTimerData> {
  FocusTimerNotifier([this._userId]) : super(const FocusTimerData());

  final String? _userId;
  Timer? _timer;

  void start({String? taskId}) {
    if (state.isRunning) return;

    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final sessionId = 'fs_${now.microsecondsSinceEpoch}';

    state = state.copyWith(
      timerState: FocusTimerState.running,
      linkedTaskId: taskId,
      currentSessionId: sessionId,
    );

    _startTick();
  }

  void pause() {
    _timer?.cancel();
    HapticFeedback.lightImpact();
    state = state.copyWith(timerState: FocusTimerState.paused);
  }

  void resume() {
    HapticFeedback.lightImpact();
    state = state.copyWith(timerState: FocusTimerState.running);
    _startTick();
  }

  void reset() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    state = const FocusTimerData();
  }

  void linkTask(String? taskId) {
    state = state.copyWith(linkedTaskId: taskId);
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.remainingSeconds <= 0) {
      _onPhaseComplete();
      return;
    }
    state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    HapticFeedback.vibrate();

    if (state.phase == FocusPhase.focus) {
      // Play bell chime on focus timer completion
      AudioNotificationService.instance.playFocusCompleteChime();

      final newCount = state.sessionCount + 1;
      _saveSession(state.currentSessionId, FocusTimerData.focusDuration, true);

      final isLongBreak = newCount % FocusTimerData.sessionsBeforeLongBreak == 0;
      final breakDuration = isLongBreak
          ? FocusTimerData.longBreakDuration
          : FocusTimerData.shortBreakDuration;
      final breakPhase = isLongBreak ? FocusPhase.longBreak : FocusPhase.shortBreak;

      state = FocusTimerData(
        phase: breakPhase,
        timerState: FocusTimerState.breakTime,
        remainingSeconds: breakDuration,
        totalSeconds: breakDuration,
        sessionCount: newCount,
        linkedTaskId: state.linkedTaskId,
      );
      _startTick();
    } else {
      // Play alarm chime on break timer completion
      AudioNotificationService.instance.playBreakCompleteAlarm();

      // Break completed — return to idle focus state
      state = FocusTimerData(
        sessionCount: state.sessionCount,
        linkedTaskId: state.linkedTaskId,
      );
    }
  }

  Future<void> _saveSession(String? sessionId, int durationSeconds, bool isCompleted) async {
    if (sessionId == null) return;
    try {
      final db = await AppDatabase.instance.database;
      final now = DateTime.now();
      await db.insert('focus_sessions', {
        'id': sessionId,
        'user_id': ?_userId,
        'task_id': state.linkedTaskId,
        'duration_seconds': durationSeconds,
        'break_type': state.phase.name,
        'session_number': state.sessionCount + 1,
        'started_at': now.subtract(Duration(seconds: durationSeconds)).millisecondsSinceEpoch,
        'ended_at': now.millisecondsSinceEpoch,
        'is_completed': isCompleted ? 1 : 0,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusTimerProvider = StateNotifierProvider<FocusTimerNotifier, FocusTimerData>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return FocusTimerNotifier(userId);
});
