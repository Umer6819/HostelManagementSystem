class Payment {
  final int id;
  final String studentId;
  final int feeId;
  final String month;
  final double amount;
  final bool status; // true = paid, false = pending
  final DateTime? paidAt;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.studentId,
    required this.feeId,
    required this.month,
    required this.amount,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      studentId: json['student_id'] as String? ?? '',
      feeId: json['fee_id'] as int,
      month: json['month'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as bool? ?? false,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'fee_id': feeId,
      'month': month,
      'amount': amount,
      'status': status,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
