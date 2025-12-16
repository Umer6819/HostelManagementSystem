import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_lock_request_model.dart';

class RoomLockRequestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<RoomLockRequest>> fetchAllRequests() async {
    try {
      final response = await _supabase
          .from('room_lock_requests')
          .select('*')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RoomLockRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch room lock requests: $e');
    }
  }

  Future<List<RoomLockRequest>> fetchRequestsByWarden(String wardenId) async {
    try {
      final response = await _supabase
          .from('room_lock_requests')
          .select('*')
          .eq('requested_by', wardenId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RoomLockRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch warden room lock requests: $e');
    }
  }

  Future<List<RoomLockRequest>> fetchPendingRequests() async {
    try {
      final response = await _supabase
          .from('room_lock_requests')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RoomLockRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  Future<RoomLockRequest> createRequest({
    required int roomId,
    required String requestedBy,
    required String reason,
    DateTime? lockUntil,
  }) async {
    try {
      final response = await _supabase
          .from('room_lock_requests')
          .insert({
            'room_id': roomId,
            'requested_by': requestedBy,
            'reason': reason,
            'status': 'pending',
            if (lockUntil != null) 'lock_until': lockUntil.toIso8601String(),
          })
          .select()
          .single();

      return RoomLockRequest.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create room lock request: $e');
    }
  }

  Future<void> reviewRequest({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewNotes,
  }) async {
    try {
      await _supabase
          .from('room_lock_requests')
          .update({
            'status': status,
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': reviewedBy,
            if (reviewNotes != null) 'review_notes': reviewNotes,
          })
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to review room lock request: $e');
    }
  }

  Future<void> deleteRequest(String requestId) async {
    try {
      await _supabase.from('room_lock_requests').delete().eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to delete room lock request: $e');
    }
  }
}
