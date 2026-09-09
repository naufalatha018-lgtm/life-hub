import 'package:flutter/foundation.dart';

@immutable
class WaterLog {
  const WaterLog({
    required this.id,
    required this.amountMl,
    required this.dailyGoalMl,
    required this.loggedAt,
    required this.createdAt,
  });

  final String id;
  final int amountMl;
  final int dailyGoalMl;
  final DateTime loggedAt;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount_ml': amountMl,
      'daily_goal_ml': dailyGoalMl,
      'logged_at': loggedAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      id: map['id'] as String,
      amountMl: (map['amount_ml'] as num).toInt(),
      dailyGoalMl: (map['daily_goal_ml'] as num?)?.toInt() ?? 2000,
      loggedAt: DateTime.fromMillisecondsSinceEpoch((map['logged_at'] as num).toInt()),
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
    );
  }
}

enum MoodLevel { awful, bad, neutral, good, great }

@immutable
class MoodLog {
  const MoodLog({
    required this.id,
    required this.moodLevel,
    this.note,
    required this.loggedAt,
    required this.createdAt,
  });

  final String id;
  final MoodLevel moodLevel;
  final String? note;
  final DateTime loggedAt;
  final DateTime createdAt;

  int get moodValue => moodLevel.index + 1; // 1–5

  String get emojiForMood {
    switch (moodLevel) {
      case MoodLevel.awful: return '😞';
      case MoodLevel.bad: return '😕';
      case MoodLevel.neutral: return '😐';
      case MoodLevel.good: return '🙂';
      case MoodLevel.great: return '😄';
    }
  }

  String get labelId {
    switch (moodLevel) {
      case MoodLevel.awful: return 'Sangat Buruk';
      case MoodLevel.bad: return 'Buruk';
      case MoodLevel.neutral: return 'Biasa';
      case MoodLevel.good: return 'Baik';
      case MoodLevel.great: return 'Luar Biasa';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood_level': moodValue,
      'note': note,
      'logged_at': loggedAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory MoodLog.fromMap(Map<String, dynamic> map) {
    final level = (map['mood_level'] as num?)?.toInt() ?? 3;
    return MoodLog(
      id: map['id'] as String,
      moodLevel: MoodLevel.values[((level - 1).clamp(0, 4))],
      note: map['note'] as String?,
      loggedAt: DateTime.fromMillisecondsSinceEpoch((map['logged_at'] as num).toInt()),
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
    );
  }
}
