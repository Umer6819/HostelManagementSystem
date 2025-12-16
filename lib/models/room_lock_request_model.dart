class RoomLockRequest {
  final String id;
  final int roomId;
  final String requestedBy;
  final String reason;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final DateTime? lockUntil;

  RoomLockRequest({
    required this.id,
    required this.roomId,
    required this.requestedBy,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    this.lockUntil,
  });

  factory RoomLockRequest.fromJson(Map<String, dynamic> json) {
    return RoomLockRequest(
      id: json['id'] as String,
      roomId: json['room_id'] as int,
      requestedBy: json['requested_by'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewNotes: json['review_notes'] as String?,
      lockUntil: json['lock_until'] != null
          ? DateTime.parse(json['lock_until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'requested_by': requestedBy,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'review_notes': reviewNotes,
      'lock_until': lockUntil?.toIso8601String(),
    };
  }
}
