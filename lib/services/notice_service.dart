import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notice_model.dart';

class NoticeService {
  final supabase = Supabase.instance.client;

  Future<List<Notice>> fetchAllNotices() async {
    final response = await supabase
        .from('notices')
        .select('*')
        .order('priority', ascending: false)
        .order('created_at', ascending: false);
    return (response as List)
        .map((n) => Notice.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  Future<List<Notice>> fetchActiveNotices() async {
    final now = DateTime.now().toIso8601String();
    final response = await supabase
        .from('notices')
        .select('*')
        .eq('is_active', true)
        .or('expires_at.is.null,expires_at.gt.$now')
        .order('priority', ascending: false)
        .order('created_at', ascending: false);
    return (response as List)
        .map((n) => Notice.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  Future<Notice> createNotice({
    required String title,
    required String content,
    bool isActive = true,
    int priority = 0,
    DateTime? expiresAt,
  }) async {
    final userId = supabase.auth.currentUser?.id;

    final response = await supabase
        .from('notices')
        .insert({
          'title': title,
          'content': content,
          'is_active': isActive,
          'priority': priority,
          'created_by': userId,
          'expires_at': expiresAt?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return Notice.fromJson(response as Map<String, dynamic>);
  }

  Future<Notice> updateNotice({
    required int id,
    String? title,
    String? content,
    bool? isActive,
    int? priority,
    DateTime? expiresAt,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updateData['title'] = title;
    if (content != null) updateData['content'] = content;
    if (isActive != null) updateData['is_active'] = isActive;
    if (priority != null) updateData['priority'] = priority;
    if (expiresAt != null)
      updateData['expires_at'] = expiresAt.toIso8601String();

    final response = await supabase
        .from('notices')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    return Notice.fromJson(response as Map<String, dynamic>);
  }

  Future<void> toggleNoticeStatus(int id, bool isActive) async {
    await supabase
        .from('notices')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteNotice(int id) async {
    await supabase.from('notices').delete().eq('id', id);
  }
}
