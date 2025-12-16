import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/misconduct_report_model.dart';

class MisconductReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MisconductReport>> fetchAllReports() async {
    try {
      final response = await _supabase
          .from('misconduct_reports')
          .select('*')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => MisconductReport.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch misconduct reports: $e');
    }
  }

  Future<List<MisconductReport>> fetchStudentReports(String studentId) async {
    try {
      final response = await _supabase
          .from('misconduct_reports')
          .select('*')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => MisconductReport.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch student reports: $e');
    }
  }

  Future<List<MisconductReport>> fetchReportsByStatus(String status) async {
    try {
      final response = await _supabase
          .from('misconduct_reports')
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => MisconductReport.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports by status: $e');
    }
  }

  Future<MisconductReport> createReport({
    required String studentId,
    required String reportedBy,
    required String incidentType,
    required String description,
    required String severity,
  }) async {
    try {
      final response = await _supabase
          .from('misconduct_reports')
          .insert({
            'student_id': studentId,
            'reported_by': reportedBy,
            'incident_type': incidentType,
            'description': description,
            'severity': severity,
            'status': 'pending',
          })
          .select()
          .single();
      
      return MisconductReport.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create misconduct report: $e');
    }
  }

  Future<void> reviewReport({
    required String reportId,
    required String status,
    required String adminId,
    String? adminRemarks,
    String? actionTaken,
  }) async {
    try {
      await _supabase
          .from('misconduct_reports')
          .update({
            'status': status,
            'admin_id': adminId,
            'admin_remarks': adminRemarks,
            'action_taken': actionTaken,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to review misconduct report: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _supabase
          .from('misconduct_reports')
          .delete()
          .eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to delete misconduct report: $e');
    }
  }
}
