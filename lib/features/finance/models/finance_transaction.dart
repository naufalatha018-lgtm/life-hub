import 'package:flutter/foundation.dart';
import '../../../core/location/location_data.dart';
import '../../../core/utils/currency_formatter.dart';

enum TransactionType {
  income,
  expense;

  String get displayName => this == TransactionType.income ? 'Income' : 'Expense';
}

@immutable
class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    this.userId,
    this.walletId,
    required this.title,
    required this.amountCents,
    required this.type,
    required this.category,
    required this.timestamp,
    this.note,
    this.linkedTaskId,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? userId;
  final String? walletId;
  final String title;
  final int amountCents; // Smallest integer unit (e.g., $10.50 -> 1050)
  final TransactionType type;
  final String category;
  final DateTime timestamp;
  final String? note;
  final String? linkedTaskId;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  String get formattedAmount => CurrencyFormatter.formatCents(amountCents);

  LocationData? get location => (latitude != null && longitude != null)
      ? LocationData(
          latitude: latitude!,
          longitude: longitude!,
          locationName: locationName,
        )
      : null;

  FinanceTransaction copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    int? amountCents,
    TransactionType? type,
    String? category,
    DateTime? timestamp,
    String? note,
    String? linkedTaskId,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      type: type ?? this.type,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
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
      if (userId != null) 'user_id': userId,
      if (walletId != null) 'wallet_id': walletId,
      'title': title,
      'amount_cents': amountCents,
      'type': type.name,
      'category': category,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'note': note,
      'linked_task_id': linkedTaskId,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      walletId: map['wallet_id'] as String?,
      title: map['title'] as String,
      amountCents: (map['amount_cents'] as num).toInt(),
      type: (map['type'] as String) == 'income' ? TransactionType.income : TransactionType.expense,
      category: map['category'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as num).toInt()),
      note: map['note'] as String?,
      linkedTaskId: map['linked_task_id'] as String?,
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
      other is FinanceTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amountCents == other.amountCents &&
          type == other.type &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => id.hashCode ^ amountCents.hashCode ^ type.hashCode;
}
