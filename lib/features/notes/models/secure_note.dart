import 'package:flutter/foundation.dart';

@immutable
class SecureNote {
  const SecureNote({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  SecureNote copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SecureNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecureNote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          isPinned == other.isPinned;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isPinned.hashCode;
}
