import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_model.dart';

class PaymentService {
  final supabase = Supabase.instance.client;

  Future<List<Payment>> fetchAllPayments() async {
    final response = await supabase
        .from('payments')
        .select('*')
        .order('created_at', ascending: false);
    return (response as List)
        .map((p) => Payment.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<List<Payment>> fetchPaymentsByStudent(String studentId) async {
    final response = await supabase
        .from('payments')
        .select('*')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((p) => Payment.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<List<Payment>> fetchPaymentsByStatus(bool isPaid) async {
    final response = await supabase
        .from('payments')
        .select('*')
        .eq('status', isPaid)
        .order('created_at', ascending: false);
    return (response as List)
        .map((p) => Payment.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsPaid(int paymentId) async {
    await supabase
        .from('payments')
        .update({'status': true, 'paid_at': DateTime.now().toIso8601String()})
        .eq('id', paymentId);
  }

  Future<void> updatePaymentStatus(int paymentId, bool isPaid) async {
    final updateData = <String, dynamic>{'status': isPaid};
    if (isPaid) {
      updateData['paid_at'] = DateTime.now().toIso8601String();
    }
    await supabase.from('payments').update(updateData).eq('id', paymentId);
  }
}
