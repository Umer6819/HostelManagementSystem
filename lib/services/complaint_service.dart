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

  // Student-specific operations
  Future<List<Complaint>> fetchComplaintsByStudent(String studentId) async {
    final response = await supabase
        .from('complaints')
        .select('*')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((c) => Complaint.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<Complaint> submitComplaint({required String title, required String description}) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('User not authenticated');

    final response = await supabase
        .from('complaints')
        .insert({
          'student_id': uid,
          'title': title,
          'description': description,
          'status': 'pending',
        })
        .select()
        .single();

    return Complaint.fromJson(response as Map<String, dynamic>);
  }

  Future<void> closeComplaint(int complaintId) async {
    await updateStatus(complaintId, 'resolved');
  }
}
