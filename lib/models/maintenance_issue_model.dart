class MaintenanceIssue {
  final String id;
  final int roomId;
  final String reportedBy;
  final String issueType;
  final String description;
  final String status; // pending, in_progress, resolved
  final String priority; // low, medium, high, urgent
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;

  MaintenanceIssue({
    required this.id,
    required this.roomId,
    required this.reportedBy,
    required this.issueType,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
  });

  factory MaintenanceIssue.fromJson(Map<String, dynamic> json) {
    return MaintenanceIssue(
      id: json['id'] as String,
      roomId: json['room_id'] as int,
      reportedBy: json['reported_by'] as String,
      issueType: json['issue_type'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'reported_by': reportedBy,
      'issue_type': issueType,
      'description': description,
      'status': status,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'resolution_notes': resolutionNotes,
    };
  }
}
