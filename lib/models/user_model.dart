class User {
  final String id;
  final String email;
  final String role;
  final DateTime createdAt;
  final bool accountActive;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    this.accountActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      createdAt: DateTime.parse(json['created_at'] as String),
      accountActive: json['account_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'account_active': accountActive,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? role,
    DateTime? createdAt,
    bool? accountActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      accountActive: accountActive ?? this.accountActive,
    );
  }
}
