import 'package:flutter/foundation.dart';

@immutable
class VaultFileItem {
  final String id;
  final String encryptedFileName;
  final String encryptedMimeType;
  final String relativePath;
  final int fileSizeBytes;
  final String ivBase64;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Transient decrypted metadata in memory (zeroized on lock)
  final String? decryptedFileName;
  final String? decryptedMimeType;

  const VaultFileItem({
    required this.id,
    required this.encryptedFileName,
    required this.encryptedMimeType,
    required this.relativePath,
    required this.fileSizeBytes,
    required this.ivBase64,
    required this.createdAt,
    required this.updatedAt,
    this.decryptedFileName,
    this.decryptedMimeType,
  });

  String get displayName => decryptedFileName ?? 'Encrypted Document';
  String get mimeType => decryptedMimeType ?? 'application/octet-stream';

  String get formattedSize {
    if (fileSizeBytes >= 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (fileSizeBytes >= 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$fileSizeBytes B';
  }

  bool get isImage {
    final lower = displayName.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        mimeType.startsWith('image/');
  }

  bool get isTextDoc {
    final lower = displayName.toLowerCase();
    return lower.endsWith('.txt') ||
        lower.endsWith('.md') ||
        lower.endsWith('.json') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.log') ||
        mimeType.startsWith('text/');
  }

  bool get isPdf => displayName.toLowerCase().endsWith('.pdf') || mimeType.contains('pdf');

  VaultFileItem copyWith({
    String? id,
    String? encryptedFileName,
    String? encryptedMimeType,
    String? relativePath,
    int? fileSizeBytes,
    String? ivBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? decryptedFileName,
    String? decryptedMimeType,
  }) {
    return VaultFileItem(
      id: id ?? this.id,
      encryptedFileName: encryptedFileName ?? this.encryptedFileName,
      encryptedMimeType: encryptedMimeType ?? this.encryptedMimeType,
      relativePath: relativePath ?? this.relativePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      ivBase64: ivBase64 ?? this.ivBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      decryptedFileName: decryptedFileName ?? this.decryptedFileName,
      decryptedMimeType: decryptedMimeType ?? this.decryptedMimeType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'encrypted_file_name': encryptedFileName,
      'encrypted_mime_type': encryptedMimeType,
      'relative_path': relativePath,
      'file_size_bytes': fileSizeBytes,
      'iv_base64': ivBase64,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory VaultFileItem.fromMap(Map<String, dynamic> map) {
    return VaultFileItem(
      id: map['id'] as String,
      encryptedFileName: map['encrypted_file_name'] as String,
      encryptedMimeType: map['encrypted_mime_type'] as String,
      relativePath: map['relative_path'] as String,
      fileSizeBytes: (map['file_size_bytes'] as num).toInt(),
      ivBase64: map['iv_base64'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updated_at'] as num).toInt()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultFileItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fileSizeBytes == other.fileSizeBytes &&
          decryptedFileName == other.decryptedFileName;

  @override
  int get hashCode => id.hashCode ^ fileSizeBytes.hashCode;
}
