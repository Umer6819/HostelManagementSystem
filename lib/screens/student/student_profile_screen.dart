import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_model.dart';
import '../../models/room_model.dart';
import '../../services/student_service.dart';
import '../../services/room_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final StudentService _studentService = StudentService();
  final RoomService _roomService = RoomService();

  Student? _student;
  Room? _room;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('Not authenticated');

      final student = await _studentService.fetchStudentById(uid);
      if (student == null) throw Exception('Student profile not found');

      Room? room;
      if (student.roomId != null) {
        final rooms = await _roomService.fetchRooms();
        try {
          room = rooms.firstWhere((r) => r.id == student.roomId);
        } catch (_) {
          room = null;
        }
      }

      setState(() {
        _student = student;
        _room = room;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _student == null
              ? const Center(child: Text('Profile not found'))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        _buildPersonalDetailsSection(),
                        const SizedBox(height: 24),
                        _buildRoomAssignmentSection(),
                        const SizedBox(height: 24),
                        _buildContactInfoSection(),
                        const SizedBox(height: 24),
                        _buildSecuritySection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Text(
                _student!.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _student!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _student!.regNo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Full Name', _student!.name),
            const SizedBox(height: 12),
            _buildDetailRow('Registration No', _student!.regNo),
            const SizedBox(height: 12),
            _buildDetailRow('Student ID', _student!.id),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomAssignmentSection() {
    final roomInfo = _student!.roomId == null
        ? 'Not assigned'
        : _room != null
            ? 'Room ${_room!.roomNumber} (Standard)'
            : 'Room ${_student!.roomId} (Loading...)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.meeting_room, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Room Assignment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Room Number', roomInfo),
            if (_room != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Room Type', 'Standard'),
              const SizedBox(height: 12),
              _buildDetailRow('Occupancy', '${_room!.occupied}/${_room!.capacity}'),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Status',
                _room!.status == 'locked' ? 'Locked 🔒' : 'Unlocked 🔓',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.phone, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                FilledButton.tonal(
                  onPressed: _showEditContactDialog,
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Phone Number',
              _student!.phone ?? 'Not provided',
              color: _student!.phone == null ? Colors.grey[400] : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _showChangePasswordDialog,
                child: const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _showEditContactDialog() async {
    final phoneController = TextEditingController(text: _student!.phone ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _studentService.updateStudent(
                  id: _student!.id,
                  phone: phoneController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  await _loadProfile();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact info updated')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool obscureCurrent = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => obscureNew = !obscureNew),
                    ),
                    helperText:
                        'At least 8 characters, uppercase, lowercase, number, special char',
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Password Requirements:\n• Minimum 8 characters\n• At least one uppercase letter\n• At least one lowercase letter\n• At least one number\n• At least one special character (!@#\$%^&*)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final current = currentPasswordController.text.trim();
                final newPass = newPasswordController.text.trim();
                final confirm = confirmPasswordController.text.trim();

                if (current.isEmpty ||
                    newPass.isEmpty ||
                    confirm.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All fields are required'),
                    ),
                  );
                  return;
                }

                if (newPass != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('New password and confirm password do not match'),
                    ),
                  );
                  return;
                }

                if (!_isPasswordStrong(newPass)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password must be at least 8 characters and contain uppercase, lowercase, number, and special character',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await Supabase.instance.client.auth
                      .updateUser(UserAttributes(password: newPass));

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return false;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return false;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return false;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:",./<>?\\|`~]'))) {
      return false;
    }
    return true;
  }
}
