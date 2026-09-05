class UserProfile {
  final String id;
  final String username;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.create(String username) {
    final now = DateTime.now();
    return UserProfile(
      id: 'profile-${now.microsecondsSinceEpoch}',
      username: username.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return UserProfile(
      id: json['id']?.toString() ?? 'profile',
      username: json['username']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? now,
    );
  }

  UserProfile copyWith({String? username}) {
    return UserProfile(
      id: id,
      username: username?.trim() ?? this.username,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
