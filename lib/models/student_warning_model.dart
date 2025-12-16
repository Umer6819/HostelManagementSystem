class StudentWarning {
  final String id;
  final String studentId;
  final String issuedBy;
  final String reason;
  final String severity; // minor, moderate, severe
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;

  StudentWarning({
    required this.id,
    required this.studentId,
    required this.issuedBy,
    required this.reason,
    required this.severity,
    required this.createdAt,
    this.expiresAt,
    required this.isActive,
  });

  factory StudentWarning.fromJson(Map<String, dynamic> json) {
    return StudentWarning(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      issuedBy: json['issued_by'] as String,
      reason: json['reason'] as String,
      severity: json['severity'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'issued_by': issuedBy,
      'reason': reason,
      'severity': severity,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
