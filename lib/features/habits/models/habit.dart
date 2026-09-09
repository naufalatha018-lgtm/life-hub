import 'package:flutter/foundation.dart';

enum HabitFrequency {
  daily,
  weekdays,
  weekly;

  String get displayNameId {
    switch (this) {
      case HabitFrequency.daily: return 'Setiap Hari';
      case HabitFrequency.weekdays: return 'Hari Kerja (Sen–Jum)';
      case HabitFrequency.weekly: return 'Mingguan';
    }
  }

  String get displayNameEn {
    switch (this) {
      case HabitFrequency.daily: return 'Every Day';
      case HabitFrequency.weekdays: return 'Weekdays (Mon–Fri)';
      case HabitFrequency.weekly: return 'Weekly';
    }
  }
}

enum HabitCategory {
  health,
  productivity,
  mindfulness,
  finance;

  String get displayNameId {
    switch (this) {
      case HabitCategory.health: return 'Kesehatan';
      case HabitCategory.productivity: return 'Produktivitas';
      case HabitCategory.mindfulness: return 'Mindfulness';
      case HabitCategory.finance: return 'Finansial';
    }
  }

  String get displayNameEn {
    switch (this) {
      case HabitCategory.health: return 'Health';
      case HabitCategory.productivity: return 'Productivity';
      case HabitCategory.mindfulness: return 'Mindfulness';
      case HabitCategory.finance: return 'Finance';
    }
  }

  String get iconAsset {
    switch (this) {
      case HabitCategory.health: return '💪';
      case HabitCategory.productivity: return '⚡';
      case HabitCategory.mindfulness: return '🧘';
      case HabitCategory.finance: return '💰';
    }
  }
}

@immutable
class Habit {
  const Habit({
    required this.id,
    required this.title,
    this.description,
    required this.frequency,
    required this.category,
    this.targetDays = const [1, 2, 3, 4, 5, 6, 7],
    this.streakCurrent = 0,
    this.streakLongest = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final HabitFrequency frequency;
  final HabitCategory category;
  final List<int> targetDays; // 1=Monday ... 7=Sunday
  final int streakCurrent;
  final int streakLongest;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    HabitFrequency? frequency,
    HabitCategory? category,
    List<int>? targetDays,
    int? streakCurrent,
    int? streakLongest,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      targetDays: targetDays ?? this.targetDays,
      streakCurrent: streakCurrent ?? this.streakCurrent,
      streakLongest: streakLongest ?? this.streakLongest,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'frequency': frequency.name,
      'category': category.name,
      'target_days': targetDays.join(','),
      'streak_current': streakCurrent,
      'streak_longest': streakLongest,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == (map['frequency'] as String),
        orElse: () => HabitFrequency.daily,
      ),
      category: HabitCategory.values.firstWhere(
        (c) => c.name == (map['category'] as String),
        orElse: () => HabitCategory.productivity,
      ),
      targetDays: (map['target_days'] as String)
          .split(',')
          .map((s) => int.tryParse(s.trim()) ?? 1)
          .toList(),
      streakCurrent: (map['streak_current'] as num?)?.toInt() ?? 0,
      streakLongest: (map['streak_longest'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as num?)?.toInt() == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updated_at'] as num).toInt()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class HabitCompletion {
  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.completedDate,
    required this.createdAt,
  });

  final String id;
  final String habitId;
  final DateTime completedDate;
  final DateTime createdAt;

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      completedDate: DateTime.fromMillisecondsSinceEpoch((map['completed_date'] as num).toInt()),
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
    );
  }
}
