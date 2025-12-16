class Notice {
  final int id;
  final String title;
  final String content;
  final bool isActive;
  final int priority;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.isActive,
    required this.priority,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool _toBool(dynamic v, [bool fallback = false]) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1' || s == 't';
    }
    return fallback;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: _toInt(json['id']),
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      isActive: _toBool(json['is_active'], true),
      priority: _toInt(json['priority'], 0),
      createdBy: json['created_by'] as String?,
      createdAt: _toDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _toDate(json['updated_at']),
      expiresAt: _toDate(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_active': isActive,
      'priority': priority,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
