import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_model.dart';

class StudentService {
  final supabase = Supabase.instance.client;

  Future<List<Student>> fetchAllStudents() async {
    final response = await supabase
        .from('students')
        .select('*')
        .order('reg_no');
    return (response as List)
        .map((s) => Student.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<Student?> fetchStudentById(String userId) async {
    final response = await supabase
        .from('students')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Student.fromJson(response as Map<String, dynamic>);
  }

  Future<Student> createStudent({
    required String userId,
    required String regNo,
    required String name,
    String? phone,
    int? roomId,
  }) async {
    final response = await supabase
        .from('students')
        .insert({
          'id': userId,
          'reg_no': regNo,
          'name': name,
          'phone': phone,
          'room_id': roomId,
        })
        .select()
        .single();

    // Bump occupancy if a room was assigned at creation time.
    if (roomId != null) {
      await _incrementRoomOccupancy(roomId);
    }

    return Student.fromJson(response as Map<String, dynamic>);
  }

  Future<Student> updateStudent({
    required String id,
    String? regNo,
    String? name,
    String? phone,
    int? roomId,
  }) async {
    final updateData = <String, dynamic>{};
    if (regNo != null) updateData['reg_no'] = regNo;
    if (name != null) updateData['name'] = name;
    if (phone != null) updateData['phone'] = phone;
    // Handle room changes via assignRoom to keep occupancy in sync.
    if (roomId != null) {
      await assignRoom(id, roomId);
    }

    if (updateData.isNotEmpty) {
      await supabase.from('students').update(updateData).eq('id', id);
    }

    final refreshed = await supabase
        .from('students')
        .select('*')
        .eq('id', id)
        .single();

    return Student.fromJson(refreshed as Map<String, dynamic>);
  }

  Future<void> assignRoom(String studentId, int? roomId) async {
    // Get current assignment
    final current = await supabase
        .from('students')
        .select('room_id')
        .eq('id', studentId)
        .single();

    final int? previousRoomId = current['room_id'] as int?;

    // No change, nothing to do
    if (previousRoomId == roomId) return;

    // Update student assignment
    await supabase
        .from('students')
        .update({'room_id': roomId})
        .eq('id', studentId);

    // Decrement previous room occupancy
    if (previousRoomId != null) {
      await _decrementRoomOccupancy(previousRoomId);
    }

    // Increment new room occupancy
    if (roomId != null) {
      await _incrementRoomOccupancy(roomId);
    }
  }

  Future<void> deleteStudent(String id) async {
    await supabase.from('students').delete().eq('id', id);
  }

  Future<void> _incrementRoomOccupancy(int roomId) async {
    final room = await supabase
        .from('rooms')
        .select('occupied, capacity')
        .eq('id', roomId)
        .maybeSingle();

    if (room == null) return;
    final occupied = (room['occupied'] as int? ?? 0) + 1;
    final capacity = room['capacity'] as int?;
    final next = capacity != null && capacity > 0 && occupied > capacity
        ? capacity
        : occupied;

    await supabase.from('rooms').update({'occupied': next}).eq('id', roomId);
  }

  Future<void> _decrementRoomOccupancy(int roomId) async {
    final room = await supabase
        .from('rooms')
        .select('occupied')
        .eq('id', roomId)
        .maybeSingle();

    if (room == null) return;
    final occupied = (room['occupied'] as int? ?? 0) - 1;
    final next = occupied < 0 ? 0 : occupied;

    await supabase.from('rooms').update({'occupied': next}).eq('id', roomId);
  }
}
