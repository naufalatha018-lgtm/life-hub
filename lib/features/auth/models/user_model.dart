import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String authProvider; // 'local', 'google', 'guest'
  final bool isVerified;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.authProvider,
    this.isVerified = true,
    required this.createdAt,
    required this.lastLoginAt,
  });

  bool get isGuest => authProvider == 'guest';
  bool get isGoogle => authProvider == 'google';
  bool get isLocal => authProvider == 'local';

  String get effectiveName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@').first;
    }
    return isGuest ? 'Executive Guest' : 'Life Hub Member';
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? authProvider,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider ?? this.authProvider,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'auth_provider': authProvider,
      'is_verified': isVerified ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_login_at': lastLoginAt.millisecondsSinceEpoch,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      photoUrl: map['photo_url'] as String?,
      authProvider: map['auth_provider'] as String,
      isVerified: ((map['is_verified'] as num?)?.toInt() ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch((map['last_login_at'] as num).toInt()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          authProvider == other.authProvider &&
          isVerified == other.isVerified;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ authProvider.hashCode ^ isVerified.hashCode;
}
