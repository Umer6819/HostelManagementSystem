class Fee {
  final int id;
  final String month;
  final double amount;
  final DateTime createdAt;

  Fee({
    required this.id,
    required this.month,
    required this.amount,
    required this.createdAt,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'] as int,
      month: json['month'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
