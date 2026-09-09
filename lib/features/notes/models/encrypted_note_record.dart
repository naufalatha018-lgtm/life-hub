import 'package:flutter/foundation.dart';

@immutable
class EncryptedNoteRecord {
  const EncryptedNoteRecord({
    required this.id,
    required this.encryptedTitle,
    required this.encryptedContent,
    required this.encryptedTags,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String encryptedTitle;
  final String encryptedContent;
  final String encryptedTags;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'encrypted_title': encryptedTitle,
      'encrypted_content': encryptedContent,
      'encrypted_tags': encryptedTags,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory EncryptedNoteRecord.fromMap(Map<String, dynamic> map) {
    return EncryptedNoteRecord(
      id: map['id'] as String,
      encryptedTitle: map['encrypted_title'] as String,
      encryptedContent: map['encrypted_content'] as String,
      encryptedTags: map['encrypted_tags'] as String,
      isPinned: (map['is_pinned'] as num?)?.toInt() == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updated_at'] as num).toInt()),
    );
  }
}
