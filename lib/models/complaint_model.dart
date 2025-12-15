class Complaint {
  final int id;
  final String studentId;
  final String title;
  final String description;
  final String status; // pending, in_progress, resolved
  final String? assignedWardenId;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime? updatedAt;

  const Complaint({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.status,
    this.assignedWardenId,
    required this.createdAt,
    this.resolvedAt,
    this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as int,
      studentId: json['student_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      assignedWardenId: json['assigned_warden'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'title': title,
      'description': description,
      'status': status,
      'assigned_warden': assignedWardenId,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
