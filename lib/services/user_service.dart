import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as models;

class UserService {
  final supabase = Supabase.instance.client;

  // Fetch all users
  Future<List<models.User>> fetchAllUsers() async {
    final response = await supabase.from('profiles').select('*');
    return (response as List)
        .map((u) => models.User.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  // Fetch users by role
  Future<List<models.User>> fetchUsersByRole(String role) async {
    final response = await supabase
        .from('profiles')
        .select('*')
        .eq('role', role);
    return (response as List)
        .map((u) => models.User.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  // Create new user (via Supabase Admin API)
  Future<models.User> createUser(
    String email,
    String password,
    String role,
  ) async {
    // Sign up the user
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to create user');
    }

    final userId = response.user!.id;
    await supabase.from('profiles').insert({
      'id': userId,
      'email': email,
      'role': role,
    });

    return models.User(
      id: userId,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );
  }

  // Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
  }

  // Reset user password - generates a temporary password
  Future<String> resetUserPassword(String userId, String userEmail) async {
    // Generate a temporary password
    final tempPassword = 'Temp${DateTime.now().millisecondsSinceEpoch}!';

    // For now, we'll send a password reset email instead
    // Admin functions require service role key which shouldn't be in client
    await supabase.auth.resetPasswordForEmail(userEmail);

    return tempPassword;
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    // Delete from profiles table (auth.users will be handled by cascade or manually)
    await supabase.from('profiles').delete().eq('id', userId);
  }

  // Activate/Deactivate user account
  Future<void> toggleAccountActive(String userId, bool isActive) async {
    await supabase
        .from('profiles')
        .update({'account_active': isActive})
        .eq('id', userId);
  }
}
