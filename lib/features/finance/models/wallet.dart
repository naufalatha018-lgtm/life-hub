import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';

@immutable
class Wallet {
  const Wallet({
    required this.id,
    this.userId,
    required this.name,
    required this.iconCodePoint,
    required this.colorHex,
    required this.balanceCents,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? userId;
  final String name;
  final int iconCodePoint;
  final String colorHex;
  final int balanceCents;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF0284C7);
    }
  }

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  String get formattedBalance => CurrencyFormatter.formatCents(balanceCents.abs());
  bool get isNegative => balanceCents < 0;

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    int? iconCodePoint,
    String? colorHex,
    int? balanceCents,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      balanceCents: balanceCents ?? this.balanceCents,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'icon_code_point': iconCodePoint,
      'color_hex': colorHex,
      'balance_cents': balanceCents,
      'is_default': isDefault ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      iconCodePoint: (map['icon_code_point'] as num?)?.toInt() ?? 57534,
      colorHex: map['color_hex'] as String? ?? '#0284C7',
      balanceCents: (map['balance_cents'] as num?)?.toInt() ?? 0,
      isDefault: (map['is_default'] as num?)?.toInt() == 1,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updated_at'] as num).toInt()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Wallet && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
