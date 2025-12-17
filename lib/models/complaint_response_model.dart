class ComplaintResponse {
  final int id;
  final int complaintId;
  final String responderId;
  final String responderRole; // warden, admin, system
  final String content;
  final DateTime createdAt;

  const ComplaintResponse({
    required this.id,
    required this.complaintId,
    required this.responderId,
    required this.responderRole,
    required this.content,
    required this.createdAt,
  });

  factory ComplaintResponse.fromJson(Map<String, dynamic> json) {
    return ComplaintResponse(
      id: json['id'] as int,
      complaintId: json['complaint_id'] as int,
      responderId: json['responder_id'] as String? ?? '',
      responderRole: json['responder_role'] as String? ?? 'warden',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'responder_id': responderId,
      'responder_role': responderRole,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
