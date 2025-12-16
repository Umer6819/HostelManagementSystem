import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_warning_model.dart';

class StudentWarningService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<StudentWarning>> fetchAllWarnings() async {
    try {
      final response = await _supabase
          .from('student_warnings')
          .select('*')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => StudentWarning.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch warnings: $e');
    }
  }

  Future<List<StudentWarning>> fetchStudentWarnings(String studentId) async {
    try {
      final response = await _supabase
          .from('student_warnings')
          .select('*')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => StudentWarning.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch student warnings: $e');
    }
  }

  Future<List<StudentWarning>> fetchActiveWarnings(String studentId) async {
    try {
      final response = await _supabase
          .from('student_warnings')
          .select('*')
          .eq('student_id', studentId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => StudentWarning.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active warnings: $e');
    }
  }

  Future<StudentWarning> issueWarning({
    required String studentId,
    required String issuedBy,
    required String reason,
    required String severity,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _supabase
          .from('student_warnings')
          .insert({
            'student_id': studentId,
            'issued_by': issuedBy,
            'reason': reason,
            'severity': severity,
            'is_active': true,
            if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();
      
      return StudentWarning.fromJson(response);
    } catch (e) {
      throw Exception('Failed to issue warning: $e');
    }
  }

  Future<void> deactivateWarning(String warningId) async {
    try {
      await _supabase
          .from('student_warnings')
          .update({'is_active': false})
          .eq('id', warningId);
    } catch (e) {
      throw Exception('Failed to deactivate warning: $e');
    }
  }

  Future<void> deleteWarning(String warningId) async {
    try {
      await _supabase
          .from('student_warnings')
          .delete()
          .eq('id', warningId);
    } catch (e) {
      throw Exception('Failed to delete warning: $e');
    }
  }
}
