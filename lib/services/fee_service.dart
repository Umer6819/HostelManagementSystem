import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fee_model.dart';

class FeeService {
  final supabase = Supabase.instance.client;

  Future<List<Fee>> fetchAllFees() async {
    final response = await supabase
        .from('fees')
        .select('*')
        .order('created_at', ascending: false);
    return (response as List)
        .map((f) => Fee.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  Future<Fee> createFee({required String month, required double amount}) async {
    try {
      // Create the fee
      final feeResponse = await supabase
          .from('fees')
          .insert({'month': month, 'amount': amount})
          .select()
          .single();

      final fee = Fee.fromJson(feeResponse as Map<String, dynamic>);

      // Get all students
      final studentsResponse = await supabase.from('students').select('id');

      if (studentsResponse is List && studentsResponse.isNotEmpty) {
        // Create payment records for all students
        final paymentInserts = <Map<String, dynamic>>[];

        for (var studentData in studentsResponse) {
          paymentInserts.add({
            'student_id': studentData['id'] as String,
            'fee_id': fee.id,
            'month': month,
            'amount': amount,
            'status': false, // false = pending, true = paid
          });
        }

        // Insert all payments at once
        await supabase.from('payments').insert(paymentInserts);
        print(
          'Created ${paymentInserts.length} payment records for fee ${fee.id}',
        );
      } else {
        print('No students found to create payments for');
      }

      return fee;
    } catch (e) {
      print('Error creating fee and payments: $e');
      rethrow;
    }
  }

  Future<void> deleteFee(int id) async {
    // This will cascade delete related payments if foreign key is set up
    await supabase.from('fees').delete().eq('id', id);
  }
}
