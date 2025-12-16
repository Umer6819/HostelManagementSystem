class MisconductReport {
  final String id;
  final String studentId;
  final String reportedBy;
  final String incidentType;
  final String description;
  final String severity; // minor, moderate, severe
  final String status; // pending, under_review, resolved, dismissed
  final DateTime createdAt;
  
  // Admin remarks
  final String? adminRemarks;
  final String? adminId;
  final DateTime? reviewedAt;
  final String? actionTaken;

  MisconductReport({
    required this.id,
    required this.studentId,
    required this.reportedBy,
    required this.incidentType,
    required this.description,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.adminRemarks,
    this.adminId,
    this.reviewedAt,
    this.actionTaken,
  });

  factory MisconductReport.fromJson(Map<String, dynamic> json) {
    return MisconductReport(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      reportedBy: json['reported_by'] as String,
      incidentType: json['incident_type'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      adminRemarks: json['admin_remarks'] as String?,
      adminId: json['admin_id'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      actionTaken: json['action_taken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'reported_by': reportedBy,
      'incident_type': incidentType,
      'description': description,
      'severity': severity,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'admin_remarks': adminRemarks,
      'admin_id': adminId,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'action_taken': actionTaken,
    };
  }
}
