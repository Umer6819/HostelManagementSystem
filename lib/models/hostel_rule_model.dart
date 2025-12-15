class HostelRule {
  final int id;
  final String title;
  final String description;
  final bool isActive;
  final int priority;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const HostelRule({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
  });

  factory HostelRule.fromJson(Map<String, dynamic> json) {
    return HostelRule(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_active': isActive,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
