import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/complaint_response_model.dart';

class ComplaintResponseService {
  final supabase = Supabase.instance.client;

  Future<List<ComplaintResponse>> fetchResponsesForComplaint(
    int complaintId,
  ) async {
    final response = await supabase
        .from('complaint_responses')
        .select('*')
        .eq('complaint_id', complaintId)
        .order('created_at', ascending: true);
    return (response as List)
        .map((r) => ComplaintResponse.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
