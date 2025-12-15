import 'package:flutter/material.dart';
import '../services/complaint_service.dart';
import '../services/student_service.dart';
import '../models/complaint_model.dart';
import '../models/student_model.dart';

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
  final TextEditingController _searchController = TextEditingController();

  List<Complaint> _assignedComplaints = [];
  List<Student> _students = [];
  bool _isLoading = true;
  String? _selectedStatus;
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      ]);
      final allComplaints = results[0] as List<Complaint>;
      // Filter complaints assigned to this warden (you'll need to get current user ID)
      setState(() {
        _assignedComplaints = allComplaints;
        _students = results[1] as List<Student>;
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
            Tab(text: 'Assigned Rooms'),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(student.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reg No: ${student.regNo}'),
                  Text(
                    'Room: ${student.roomId != null ? 'Room ${student.roomId}' : 'Not assigned'}',
                  ),
                  if (student.phone != null) Text('Phone: ${student.phone}'),
                ],
              ),
            ),
          );
        },
      ),
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
}
