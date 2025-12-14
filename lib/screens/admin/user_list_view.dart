import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import 'user_form_screen.dart';

class UserListView extends StatefulWidget {
  const UserListView({super.key});

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  final _userService = UserService();
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.fetchAllUsers();
      setState(() {
        _allUsers = users;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredUsers = _allUsers.where((user) {
      final roleMatch = _roleFilter == 'all' || user.role == _roleFilter;
      return roleMatch;
    }).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButton<String>(
            value: _roleFilter,
            isExpanded: true,
            items: ['all', 'admin', 'warden', 'student']
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(role == 'all' ? 'All Roles' : role),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _roleFilter = value);
                _applyFilters();
              }
            },
          ),
        ),
        // User List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.email[0].toUpperCase()),
                      ),
                      title: Text(user.email),
                      subtitle: Text(user.role),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'reset',
                            child: const Text('Reset Password'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Text('Delete'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserFormScreen(user: user),
                              ),
                            ).then((_) => _loadUsers());
                          } else if (value == 'reset') {
                            _resetPassword(user);
                          } else if (value == 'delete') {
                            _deleteUser(user);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _resetPassword(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Send password reset email to ${user.email}?\n\n'
          'The user will receive an email with a link to reset their password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.resetUserPassword(user.id, user.email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.email}?\n\n'
          'Note: This removes the user from the app but the authentication record remains in Supabase. '
          'The user will not be able to login as they won\'t have a profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.deleteUser(user.id);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
