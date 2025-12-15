import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hostel_rule_model.dart';

class HostelRuleService {
  final supabase = Supabase.instance.client;

  Future<List<HostelRule>> fetchAllRules() async {
    final response = await supabase
        .from('hostel_rules')
        .select('*')
        .order('priority', ascending: false)
        .order('created_at', ascending: false);
    return (response as List)
        .map((r) => HostelRule.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<HostelRule>> fetchActiveRules() async {
    final response = await supabase
        .from('hostel_rules')
        .select('*')
        .eq('is_active', true)
        .order('priority', ascending: false)
        .order('created_at', ascending: false);
    return (response as List)
        .map((r) => HostelRule.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<HostelRule> createRule({
    required String title,
    required String description,
    bool isActive = true,
    int priority = 0,
  }) async {
    final response = await supabase
        .from('hostel_rules')
        .insert({
          'title': title,
          'description': description,
          'is_active': isActive,
          'priority': priority,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return HostelRule.fromJson(response as Map<String, dynamic>);
  }

  Future<HostelRule> updateRule({
    required int id,
    String? title,
    String? description,
    bool? isActive,
    int? priority,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (isActive != null) updateData['is_active'] = isActive;
    if (priority != null) updateData['priority'] = priority;

    final response = await supabase
        .from('hostel_rules')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    return HostelRule.fromJson(response as Map<String, dynamic>);
  }

  Future<void> toggleRuleStatus(int id, bool isActive) async {
    await supabase
        .from('hostel_rules')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteRule(int id) async {
    await supabase.from('hostel_rules').delete().eq('id', id);
  }
}
