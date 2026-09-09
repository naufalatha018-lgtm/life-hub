import 'package:flutter/foundation.dart';

enum FocusPhase { focus, shortBreak, longBreak }

@immutable
class FocusSession {
  const FocusSession({
    required this.id,
    this.taskId,
    required this.durationSeconds,
    required this.breakType,
    required this.sessionNumber,
    required this.startedAt,
    this.endedAt,
    this.isCompleted = false,
  });

  final String id;
  final String? taskId;
  final int durationSeconds;
  final String breakType; // 'focus', 'short', 'long'
  final int sessionNumber;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isCompleted;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'duration_seconds': durationSeconds,
      'break_type': breakType,
      'session_number': sessionNumber,
      'started_at': startedAt.millisecondsSinceEpoch,
      'ended_at': endedAt?.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as String,
      taskId: map['task_id'] as String?,
      durationSeconds: (map['duration_seconds'] as num).toInt(),
      breakType: map['break_type'] as String? ?? 'focus',
      sessionNumber: (map['session_number'] as num?)?.toInt() ?? 1,
      startedAt: DateTime.fromMillisecondsSinceEpoch((map['started_at'] as num).toInt()),
      endedAt: map['ended_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['ended_at'] as num).toInt())
          : null,
      isCompleted: (map['is_completed'] as num?)?.toInt() == 1,
    );
  }
}
