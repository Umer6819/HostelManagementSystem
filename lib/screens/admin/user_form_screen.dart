import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/room_model.dart';
import '../../services/user_service.dart';
import '../../services/student_service.dart';
import '../../services/room_service.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _studentService = StudentService();
  final _roomService = RoomService();
  bool _isLoading = false;
  List<Room> _availableRooms = [];
  int? _selectedRoomId;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _regNoController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _regNoController = TextEditingController();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _selectedRole = widget.user?.role ?? 'student';
    _loadAvailableRooms();
  }

  Future<void> _loadAvailableRooms() async {
    try {
      final rooms = await _roomService.fetchRooms();
      setState(() {
        _availableRooms = rooms
            .where(
              (room) =>
                  room.occupied < room.capacity && room.status == 'unlocked',
            )
            .toList();
      });
    } catch (e) {
      // Silently fail, room selection is optional
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regNoController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.user == null) {
        // Create new user
        final user = await _userService.createUser(
          _emailController.text.trim(),
          _passwordController.text,
          _selectedRole,
        );

        // If student role, create student record
        if (_selectedRole == 'student') {
          await _studentService.createStudent(
            userId: user.id,
            regNo: _regNoController.text.trim(),
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            roomId: _selectedRoomId,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User created successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update user role
        await _userService.updateUserRole(widget.user!.id, _selectedRole);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Create User' : 'Edit User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email Field
              TextFormField(
                controller: _emailController,
                enabled: widget.user == null,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field (only for new users)
              if (widget.user == null)
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              if (widget.user == null) const SizedBox(height: 16),

              // Role Selection
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['admin', 'warden', 'student']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Student-specific fields (only shown when creating new student)
              if (widget.user == null && _selectedRole == 'student') ...[
                const Divider(),
                const Text(
                  'Student Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regNoController,
                  decoration: InputDecoration(
                    labelText: 'Registration Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (_selectedRole == 'student' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter registration number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (_selectedRole == 'student' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _selectedRoomId,
                  decoration: InputDecoration(
                    labelText: 'Room (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No room assigned'),
                    ),
                    ..._availableRooms.map(
                      (room) => DropdownMenuItem(
                        value: room.id,
                        child: Text(
                          'Room ${room.roomNumber} (${room.occupied}/${room.capacity})',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRoomId = value);
                  },
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.user == null ? 'Create User' : 'Update User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
