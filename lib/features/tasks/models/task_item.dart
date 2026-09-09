import 'package:flutter/material.dart';
import '../../../../core/location/location_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  done('Done');

  final String label;
  const TaskStatus(this.label);
}

enum TaskPriority {
  low('Low', AppColors.priorityLow),
  medium('Medium', AppColors.priorityMedium),
  high('High', AppColors.priorityHigh),
  urgent('Urgent', AppColors.priorityUrgent);

  final String label;
  final Color color;
  const TaskPriority(this.label, this.color);
}

@immutable
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.category,
    this.dueDate,
    this.estimatedCostCents = 0,
    this.isExpenseLogged = false,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String category;
  final DateTime? dueDate;
  final int estimatedCostCents; // Smallest integer unit
  final bool isExpenseLogged;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDone => status == TaskStatus.done;
  bool get hasEstimatedCost => estimatedCostCents > 0;
  String get formattedCost => CurrencyFormatter.formatCents(estimatedCostCents);

  LocationData? get location => (latitude != null && longitude != null)
      ? LocationData(
          latitude: latitude!,
          longitude: longitude!,
          locationName: locationName,
        )
      : null;

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? category,
    DateTime? dueDate,
    int? estimatedCostCents,
    bool? isExpenseLogged,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      estimatedCostCents: estimatedCostCents ?? this.estimatedCostCents,
      isExpenseLogged: isExpenseLogged ?? this.isExpenseLogged,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'category': category,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'estimated_cost_cents': estimatedCostCents,
      'is_expense_logged': isExpenseLogged ? 1 : 0,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      category: map['category'] as String,
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['due_date'] as num).toInt())
          : null,
      estimatedCostCents: (map['estimated_cost_cents'] as num?)?.toInt() ?? 0,
      isExpenseLogged: (map['is_expense_logged'] as num?)?.toInt() == 1,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationName: map['location_name'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updated_at'] as num).toInt()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          priority == other.priority &&
          isExpenseLogged == other.isExpenseLogged &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => id.hashCode ^ status.hashCode ^ isExpenseLogged.hashCode;
}
