import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../models/room_model.dart';
import '../../services/student_service.dart';
import '../../services/user_service.dart';
import '../../services/room_service.dart';
import 'student_profile_screen.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _studentService = StudentService();
  final _userService = UserService();
  final _roomService = RoomService();

  List<Student> _students = [];
  Map<int, User> _userProfiles = {};
  Map<int, Room> _rooms = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load students
      final students = await _studentService.fetchAllStudents();

      // Load user profiles
      final users = await _userService.fetchUsersByRole('student');
      final userMap = <int, User>{};
      for (var user in users) {
        userMap[int.tryParse(user.id) ?? 0] = user;
      }

      // Load rooms
      final rooms = await _roomService.fetchRooms();
      final roomMap = <int, Room>{};
      for (var room in rooms) {
        roomMap[room.id] = room;
      }

      if (mounted) {
        setState(() {
          _students = students;
          _userProfiles = userMap;
          _rooms = roomMap;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assignRoom(Student student) async {
    final availableRooms = _rooms.values
        .where(
          (room) => room.occupied < room.capacity && room.status == 'unlocked',
        )
        .toList();

    if (availableRooms.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No available rooms')));
      }
      return;
    }

    final selectedRoomId = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a room:'),
            const SizedBox(height: 12),
            ...availableRooms.map(
              (room) => ListTile(
                title: Text('Room ${room.roomNumber}'),
                subtitle: Text('Occupancy: ${room.occupied}/${room.capacity}'),
                onTap: () => Navigator.pop(context, room.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedRoomId != null) {
      try {
        await _studentService.assignRoom(student.id, selectedRoomId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room assigned successfully')),
          );
          _loadData();
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

  Future<void> _removeRoom(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Room'),
        content: const Text('Remove student from current room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _studentService.assignRoom(student.id, null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room removed successfully')),
          );
          _loadData();
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

  Future<void> _toggleAccountActive(Student student) async {
    final userId = int.tryParse(student.id);
    if (userId == null) return;

    final user = _userProfiles[userId];
    if (user == null) return;

    final newStatus = !user.accountActive;
    try {
      await _userService.toggleAccountActive(user.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Account activated' : 'Account deactivated',
            ),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _viewProfile(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudentProfileScreen(student: student)),
    ).then((_) => _loadData());
  }

  Widget _buildStudentCard(Student student) {
    final userId = int.tryParse(student.id);
    final user = userId != null ? _userProfiles[userId] : null;
    final room = student.roomId != null ? _rooms[student.roomId] : null;
    final isActive = user?.accountActive ?? true;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(student.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reg: ${student.regNo}'),
            Text('Room: ${room != null ? room.roomNumber : 'Not assigned'}'),
            if (!isActive)
              const Text(
                'INACTIVE',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'profile', child: Text('View Profile')),
            PopupMenuItem(
              value: 'room',
              child: Text(room != null ? 'Change Room' : 'Assign Room'),
            ),
            if (room != null)
              const PopupMenuItem(
                value: 'remove_room',
                child: Text('Remove Room'),
              ),
            PopupMenuItem(
              value: 'toggle_active',
              child: Text(isActive ? 'Deactivate' : 'Activate'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _viewProfile(student);
                break;
              case 'room':
                _assignRoom(student);
                break;
              case 'remove_room':
                _removeRoom(student);
                break;
              case 'toggle_active':
                _toggleAccountActive(student);
                break;
            }
          },
        ),
        onTap: () => _viewProfile(student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Management')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _students.isEmpty
            ? const Center(child: Text('No students found'))
            : ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  return _buildStudentCard(_students[index]);
                },
              ),
      ),
    );
  }
}
