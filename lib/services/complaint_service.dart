import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/complaint_model.dart';

class ComplaintService {
  final supabase = Supabase.instance.client;

  Future<List<Complaint>> fetchAllComplaints() async {
    final response = await supabase
        .from('complaints')
        .select('*')
        .order('created_at', ascending: false);
    return (response as List)
        .map((c) => Complaint.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<Complaint>> fetchComplaintsByStatus(String status) async {
    final response = await supabase
        .from('complaints')
        .select('*')
        .eq('status', status)
        .order('created_at', ascending: false);
    return (response as List)
        .map((c) => Complaint.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> assignWarden(int complaintId, String? wardenId) async {
    await supabase
        .from('complaints')
        .update({'assigned_warden': wardenId})
        .eq('id', complaintId);
  }

  Future<void> updateStatus(int complaintId, String status) async {
    final updateData = <String, dynamic>{'status': status};

    if (status == 'resolved') {
      updateData['resolved_at'] = DateTime.now().toIso8601String();
    }

    await supabase.from('complaints').update(updateData).eq('id', complaintId);
  }
}
