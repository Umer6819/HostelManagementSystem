import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/room_model.dart';

class RoomService {
  final supabase = Supabase.instance.client;

  Future<List<Room>> fetchRooms({String? status}) async {
    var query = supabase.from('rooms').select('*');
    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.eq('status', status);
    }

    final response = await query.order('room_number');
    return (response as List)
        .map((r) => Room.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Room> createRoom({
    required String roomNumber,
    required int capacity,
    String status = 'unlocked',
  }) async {
    final response = await supabase.from('rooms').insert({
      'room_number': roomNumber,
      'capacity': capacity,
      'status': status,
    }).select().single();

    return Room.fromJson(response as Map<String, dynamic>);
  }

  Future<Room> updateRoom({
    required int id,
    required String roomNumber,
    required int capacity,
    required int occupied,
    String status = 'unlocked',
  }) async {
    final response = await supabase
        .from('rooms')
        .update({
          'room_number': roomNumber,
          'capacity': capacity,
          'occupied': occupied,
          'status': status,
        })
        .eq('id', id)
        .select()
        .single();

    return Room.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteRoom(int id) async {
    await supabase.from('rooms').delete().eq('id', id);
  }

  Future<void> toggleLock({required int id, required bool lock}) async {
    await supabase
        .from('rooms')
        .update({'status': lock ? 'locked' : 'unlocked'})
        .eq('id', id);
  }
}
