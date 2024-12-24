class AppUser {
  final String id;
  final String email;
  final String username;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.username,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      email: map['email'],
      username: map['username'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
} 