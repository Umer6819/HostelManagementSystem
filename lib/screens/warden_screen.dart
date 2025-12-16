import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/complaint_service.dart';
import '../services/student_service.dart';
import '../services/room_service.dart';
import '../services/maintenance_issue_service.dart';
import '../services/room_lock_request_service.dart';
import '../models/complaint_model.dart';
import '../models/student_model.dart';
import '../models/room_model.dart';
import '../models/maintenance_issue_model.dart';
import '../models/room_lock_request_model.dart';
import 'warden/discipline_view_screen.dart';

class WardenScreen extends StatefulWidget {
  const WardenScreen({super.key});

  @override
  State<WardenScreen> createState() => _WardenScreenState();
}

class _WardenScreenState extends State<WardenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ComplaintService _complaintService = ComplaintService();
  final StudentService _studentService = StudentService();
  final RoomService _roomService = RoomService();
  final MaintenanceIssueService _maintenanceService = MaintenanceIssueService();
  final RoomLockRequestService _lockRequestService = RoomLockRequestService();
  final TextEditingController _searchController = TextEditingController();

  List<Complaint> _assignedComplaints = [];
  List<Student> _students = [];
  List<Room> _rooms = [];
  List<MaintenanceIssue> _maintenanceIssues = [];
  List<RoomLockRequest> _lockRequests = [];
  bool _isLoading = true;
  String? _selectedStatus;
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _complaintService.fetchAllComplaints(),
        _studentService.fetchAllStudents(),
        _roomService.fetchRooms(),
        _maintenanceService.fetchAllIssues(),
        _lockRequestService.fetchAllRequests(),
      ]);
      final allComplaints = results[0] as List<Complaint>;
      // Filter complaints assigned to this warden (you'll need to get current user ID)
      setState(() {
        _assignedComplaints = allComplaints;
        _students = results[1] as List<Student>;
        _rooms = results[2] as List<Room>;
        _maintenanceIssues = results[3] as List<MaintenanceIssue>;
        _lockRequests = results[4] as List<RoomLockRequest>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  List<Student> _getFilteredStudents() {
    if (_studentSearchQuery.isEmpty) {
      return _students;
    }
    final query = _studentSearchQuery.toLowerCase();
    return _students
        .where(
          (student) =>
              student.name.toLowerCase().contains(query) ||
              student.regNo.toLowerCase().contains(query) ||
              (student.roomId?.toString().contains(query) ?? false),
        )
        .toList();
  }

  List<Complaint> _getFilteredComplaints() {
    if (_selectedStatus == null || _selectedStatus == 'all') {
      return _assignedComplaints;
    }
    return _assignedComplaints
        .where((c) => c.status == _selectedStatus)
        .toList();
  }

  String _studentName(String studentId) {
    try {
      return _students.firstWhere((s) => s.id == studentId).name;
    } catch (_) {
      return 'Unknown student';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Pending';
    }
  }

  Future<void> _updateComplaintStatus(
    Complaint complaint,
    String newStatus,
  ) async {
    try {
      await _complaintService.updateStatus(complaint.id, newStatus);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint marked as ${_statusLabel(newStatus)}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating complaint: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warden Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Complaints'),
            Tab(text: 'Student Monitoring'),
            Tab(text: 'Room Monitoring'),
            Tab(text: 'Discipline'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildComplaintsTab(),
                _buildStudentMonitoringTab(),
                const DisciplineViewScreen(),
                _buildRoomsTab(),
              ],
            ),
    );
  }

  Widget _buildComplaintsTab() {
    final filtered = _getFilteredComplaints();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, 'All', _selectedStatus == null),
                  _buildFilterChip(
                    'pending',
                    'Pending',
                    _selectedStatus == 'pending',
                  ),
                  _buildFilterChip(
                    'in_progress',
                    'In Progress',
                    _selectedStatus == 'in_progress',
                  ),
                  _buildFilterChip(
                    'resolved',
                    'Resolved',
                    _selectedStatus == 'resolved',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No complaints assigned'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final complaint = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(complaint.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Student: ${_studentName(complaint.studentId)}',
                              ),
                              Text('Status: ${_statusLabel(complaint.status)}'),
                              Text(
                                'Created: ${complaint.createdAt.toLocal().toString().split('.')[0]}',
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(complaint.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(complaint.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _showComplaintDetails(complaint),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentMonitoringTab() {
    final filtered = _getFilteredStudents();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, reg no, or room',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _studentSearchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() => _studentSearchQuery = value);
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _studentSearchQuery.isEmpty
                          ? 'No students assigned'
                          : 'No students found',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Reg No: ${student.regNo}'),
                              Text(
                                'Room: ${student.roomId != null ? 'Room ${student.roomId}' : 'Not assigned'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showStudentDetails(student),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? value, String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (isSelected) {
          setState(() => _selectedStatus = isSelected ? value : null);
        },
      ),
    );
  }

  Widget _buildRoomsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Occupancy Section
              _buildSectionHeader('Room Occupancy', Icons.meeting_room),
              const SizedBox(height: 12),
              _buildRoomOccupancyCards(),
              const SizedBox(height: 24),

              // Maintenance Issues Section
              _buildSectionHeader('Maintenance Issues', Icons.build),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showReportMaintenanceDialog,
                icon: const Icon(Icons.add),
                label: const Text('Report New Issue'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              _buildMaintenanceIssuesList(),
              const SizedBox(height: 24),

              // Room Lock Requests Section
              _buildSectionHeader('Room Lock Requests', Icons.lock),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showRoomLockRequestDialog,
                icon: const Icon(Icons.add),
                label: const Text('Request Room Lock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              _buildLockRequestsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRoomOccupancyCards() {
    if (_rooms.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No rooms available'),
        ),
      );
    }

    return Column(
      children: _rooms.map((room) {
        final occupancyRate = room.capacity > 0
            ? (room.occupied / room.capacity * 100).toInt()
            : 0;
        final Color statusColor = occupancyRate >= 100
            ? Colors.red
            : occupancyRate >= 80
            ? Colors.orange
            : Colors.green;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${room.occupied}/${room.capacity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: room.capacity > 0 ? room.occupied / room.capacity : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text(
                  '$occupancyRate% occupied',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaintenanceIssuesList() {
    if (_maintenanceIssues.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No maintenance issues reported')),
        ),
      );
    }

    return Column(
      children: _maintenanceIssues.take(5).map((issue) {
        final room = _rooms.firstWhere(
          (r) => r.id == issue.roomId,
          orElse: () => Room(
            id: 0,
            roomNumber: 'Unknown',
            capacity: 0,
            occupied: 0,
            status: 'unlocked',
          ),
        );

        Color statusColor;
        switch (issue.status) {
          case 'resolved':
            statusColor = Colors.green;
            break;
          case 'in_progress':
            statusColor = Colors.blue;
            break;
          default:
            statusColor = Colors.orange;
        }

        Color priorityColor;
        switch (issue.priority) {
          case 'urgent':
            priorityColor = Colors.red;
            break;
          case 'high':
            priorityColor = Colors.orange;
            break;
          case 'medium':
            priorityColor = Colors.yellow[700]!;
            break;
          default:
            priorityColor = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.build, color: priorityColor),
            title: Text(issue.issueType),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Room: ${room.roomNumber}'),
                Text('Priority: ${issue.priority.toUpperCase()}'),
                Text(
                  issue.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                issue.status.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showMaintenanceIssueDetails(issue, room),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLockRequestsList() {
    if (_lockRequests.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No room lock requests')),
        ),
      );
    }

    return Column(
      children: _lockRequests.take(5).map((request) {
        final room = _rooms.firstWhere(
          (r) => r.id == request.roomId,
          orElse: () => Room(
            id: 0,
            roomNumber: 'Unknown',
            capacity: 0,
            occupied: 0,
            status: 'unlocked',
          ),
        );

        Color statusColor;
        switch (request.status) {
          case 'approved':
            statusColor = Colors.green;
            break;
          case 'rejected':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              request.status == 'approved'
                  ? Icons.lock
                  : request.status == 'rejected'
                  ? Icons.lock_open
                  : Icons.lock_clock,
              color: statusColor,
            ),
            title: Text('Room ${room.roomNumber}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  request.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Requested: ${request.createdAt.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showLockRequestDetails(request, room),
          ),
        );
      }).toList(),
    );
  }

  void _showStudentDetails(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Registration Number',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(student.regNo),
              const SizedBox(height: 12),
              const Text(
                'Room Assignment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                student.roomId != null
                    ? 'Room ${student.roomId}'
                    : 'Not assigned',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: student.roomId != null ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Contact Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              if (student.phone != null && student.phone!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16),
                    const SizedBox(width: 8),
                    Text(student.phone!),
                  ],
                )
              else
                const Text(
                  'No phone number provided',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComplaintDetails(Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(complaint.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Student: ${_studentName(complaint.studentId)}'),
              const SizedBox(height: 8),
              Text('Status: ${_statusLabel(complaint.status)}'),
              const SizedBox(height: 8),
              Text(
                'Created: ${complaint.createdAt.toLocal().toString().split('.')[0]}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description.isEmpty
                    ? 'No description provided'
                    : complaint.description,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (complaint.status != 'in_progress')
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _updateComplaintStatus(complaint, 'in_progress');
              },
              child: const Text('Start Work'),
            ),
          if (complaint.status != 'resolved')
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _updateComplaintStatus(complaint, 'resolved');
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Mark Resolved'),
            ),
        ],
      ),
    );
  }

  void _showReportMaintenanceDialog() {
    final formKey = GlobalKey<FormState>();
    int? selectedRoomId;
    String issueType = '';
    String description = '';
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Maintenance Issue'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Select Room',
                    border: OutlineInputBorder(),
                  ),
                  items: _rooms.map((room) {
                    return DropdownMenuItem(
                      value: room.id,
                      child: Text('Room ${room.roomNumber}'),
                    );
                  }).toList(),
                  onChanged: (value) => selectedRoomId = value,
                  validator: (value) =>
                      value == null ? 'Please select a room' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Issue Type',
                    hintText: 'e.g., Plumbing, Electrical, Furniture',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => issueType = value,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter issue type'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => description = value,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter description'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  value: priority,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) => priority = value ?? 'medium',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final uid = Supabase.instance.client.auth.currentUser?.id;
                  if (uid == null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You must be logged in to report an issue.',
                        ),
                      ),
                    );
                    return;
                  }
                  await _maintenanceService.createIssue(
                    roomId: selectedRoomId!,
                    reportedBy: uid,
                    issueType: issueType,
                    description: description,
                    priority: priority,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Maintenance issue reported successfully',
                        ),
                      ),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRoomLockRequestDialog() {
    final formKey = GlobalKey<FormState>();
    int? selectedRoomId;
    String reason = '';
    DateTime? lockUntil;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Room Lock'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Select Room',
                      border: OutlineInputBorder(),
                    ),
                    items: _rooms.map((room) {
                      return DropdownMenuItem(
                        value: room.id,
                        child: Text('Room ${room.roomNumber}'),
                      );
                    }).toList(),
                    onChanged: (value) => selectedRoomId = value,
                    validator: (value) =>
                        value == null ? 'Please select a room' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Why do you need to lock this room?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => reason = value,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter reason'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Lock Until (Optional)'),
                    subtitle: Text(
                      lockUntil != null
                          ? lockUntil.toString().split('.')[0]
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            lockUntil = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final uid = Supabase.instance.client.auth.currentUser?.id;
                    if (uid == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You must be logged in to request a lock.',
                          ),
                        ),
                      );
                      return;
                    }
                    await _lockRequestService.createRequest(
                      roomId: selectedRoomId!,
                      requestedBy: uid,
                      reason: reason,
                      lockUntil: lockUntil,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Room lock request submitted'),
                        ),
                      );
                      _loadData();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaintenanceIssueDetails(MaintenanceIssue issue, Room room) {
    Color priorityColor;
    switch (issue.priority) {
      case 'urgent':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'medium':
        priorityColor = Colors.yellow[700]!;
        break;
      default:
        priorityColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(issue.issueType),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.meeting_room, size: 20),
                  const SizedBox(width: 8),
                  Text('Room: ${room.roomNumber}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.priority_high, size: 20, color: priorityColor),
                  const SizedBox(width: 8),
                  Text('Priority: ${issue.priority.toUpperCase()}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Text('Status: ${issue.status.replaceAll('_', ' ')}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Reported: ${issue.createdAt.toLocal().toString().split('.')[0]}',
                  ),
                ],
              ),
              if (issue.resolvedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Resolved: ${issue.resolvedAt!.toLocal().toString().split('.')[0]}',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(issue.description),
              if (issue.resolutionNotes != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Resolution Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(issue.resolutionNotes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLockRequestDetails(RoomLockRequest request, Room room) {
    Color statusColor;
    switch (request.status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Room Lock Request - ${room.roomNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    request.status == 'approved'
                        ? Icons.check_circle
                        : request.status == 'rejected'
                        ? Icons.cancel
                        : Icons.pending,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('Status: ${request.status.toUpperCase()}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Requested: ${request.createdAt.toLocal().toString().split('.')[0]}',
                  ),
                ],
              ),
              if (request.lockUntil != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Lock Until: ${request.lockUntil!.toLocal().toString().split('.')[0]}',
                    ),
                  ],
                ),
              ],
              if (request.reviewedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.rate_review, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Reviewed: ${request.reviewedAt!.toLocal().toString().split('.')[0]}',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Reason',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(request.reason),
              if (request.reviewNotes != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Review Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(request.reviewNotes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (request.status == 'pending')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteLockRequest(request.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Request'),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteLockRequest(String requestId) async {
    try {
      await _lockRequestService.deleteRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request cancelled')));
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
