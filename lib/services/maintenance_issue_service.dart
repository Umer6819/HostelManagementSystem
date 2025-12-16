import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_issue_model.dart';

class MaintenanceIssueService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MaintenanceIssue>> fetchAllIssues() async {
    try {
      final response = await _supabase
          .from('maintenance_issues')
          .select('*')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MaintenanceIssue.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch maintenance issues: $e');
    }
  }

  Future<List<MaintenanceIssue>> fetchIssuesByWarden(String wardenId) async {
    try {
      final response = await _supabase
          .from('maintenance_issues')
          .select('*')
          .eq('reported_by', wardenId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MaintenanceIssue.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch warden maintenance issues: $e');
    }
  }

  Future<List<MaintenanceIssue>> fetchIssuesByStatus(String status) async {
    try {
      final response = await _supabase
          .from('maintenance_issues')
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MaintenanceIssue.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch issues by status: $e');
    }
  }

  Future<MaintenanceIssue> createIssue({
    required int roomId,
    required String reportedBy,
    required String issueType,
    required String description,
    required String priority,
  }) async {
    try {
      final response = await _supabase
          .from('maintenance_issues')
          .insert({
            'room_id': roomId,
            'reported_by': reportedBy,
            'issue_type': issueType,
            'description': description,
            'status': 'pending',
            'priority': priority,
          })
          .select()
          .single();

      return MaintenanceIssue.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create maintenance issue: $e');
    }
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required String status,
    String? resolvedBy,
    String? resolutionNotes,
  }) async {
    try {
      final data = {
        'status': status,
        if (status == 'resolved')
          'resolved_at': DateTime.now().toIso8601String(),
        if (resolvedBy != null) 'resolved_by': resolvedBy,
        if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      };

      await _supabase.from('maintenance_issues').update(data).eq('id', issueId);
    } catch (e) {
      throw Exception('Failed to update issue status: $e');
    }
  }

  Future<void> deleteIssue(String issueId) async {
    try {
      await _supabase.from('maintenance_issues').delete().eq('id', issueId);
    } catch (e) {
      throw Exception('Failed to delete maintenance issue: $e');
    }
  }
}
