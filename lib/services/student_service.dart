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
    if (roomId != null) updateData['room_id'] = roomId;

    final response = await supabase
        .from('students')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    return Student.fromJson(response as Map<String, dynamic>);
  }

  Future<void> assignRoom(String studentId, int? roomId) async {
    await supabase
        .from('students')
        .update({'room_id': roomId})
        .eq('id', studentId);
  }

  Future<void> deleteStudent(String id) async {
    await supabase.from('students').delete().eq('id', id);
  }
}
