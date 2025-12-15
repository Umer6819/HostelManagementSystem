import 'package:flutter/material.dart';
import '../../models/complaint_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart' as models;
import '../../services/complaint_service.dart';
import '../../services/student_service.dart';
import '../../services/user_service.dart';

class ComplaintManagementScreen extends StatefulWidget {
  const ComplaintManagementScreen({super.key});

  @override
  State<ComplaintManagementScreen> createState() =>
      _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState extends State<ComplaintManagementScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final StudentService _studentService = StudentService();
  final UserService _userService = UserService();

  List<Complaint> _allComplaints = [];
  List<Complaint> _filteredComplaints = [];
  List<Student> _students = [];
  List<models.User> _wardens = [];
  String? _selectedStatus; // null = all
  bool _isLoading = true;
  bool _isAssigning = false;

  static const List<Map<String, String>> _statusOptions = [
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'in_progress', 'label': 'In progress'},
    {'value': 'resolved', 'label': 'Resolved'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _complaintService.fetchAllComplaints(),
        _studentService.fetchAllStudents(),
        _userService.fetchWardens(),
      ]);

      setState(() {
        _allComplaints = results[0] as List<Complaint>;
        _students = results[1] as List<Student>;
        _wardens = results[2] as List<models.User>;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading complaints: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredComplaints = _allComplaints.where((complaint) {
      if (_selectedStatus != null && complaint.status != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();

    _filteredComplaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _studentName(String studentId) {
    try {
      return _students.firstWhere((s) => s.id == studentId).name;
    } catch (_) {
      return 'Unknown student';
    }
  }

  String _wardenLabel(String? wardenId) {
    if (wardenId == null) return 'Unassigned';
    try {
      final user = _wardens.firstWhere((w) => w.id == wardenId);
      return user.email;
    } catch (_) {
      return 'Unknown warden';
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

  String _resolutionTime(Complaint complaint) {
    if (complaint.resolvedAt == null) return '-';
    final duration = complaint.resolvedAt!.difference(complaint.createdAt);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 48) {
      final hours = duration.inHours;
      final mins = duration.inMinutes.remainder(60);
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    } else {
      final days = duration.inDays;
      final hours = duration.inHours.remainder(24);
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
  }

  Future<void> _assignWarden(Complaint complaint) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.8,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Assign to warden',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.only(bottom: bottomInset + 12),
                    itemCount: (_wardens.isEmpty ? 2 : _wardens.length + 1),
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          leading: const Icon(Icons.person_off_outlined),
                          title: const Text('Unassigned'),
                          selected: complaint.assignedWardenId == null,
                          onTap: () => Navigator.pop(context, ''),
                        );
                      }
                      if (_wardens.isEmpty && index == 1) {
                        return const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('No wardens found'),
                          subtitle: Text(
                            'Ensure profiles.role contains "warden" and admin can read profiles.',
                          ),
                        );
                      }
                      final warden = _wardens[index - 1];
                      final isSelected =
                          complaint.assignedWardenId == warden.id;
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(warden.email),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, warden.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() => _isAssigning = true);
    try {
      final valueToStore = selected.isEmpty ? null : selected;
      await _complaintService.assignWarden(complaint.id, valueToStore);
      await _loadData();
      if (mounted) {
        final message = selected == ''
            ? 'Assignment cleared'
            : 'Assigned to warden';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error assigning warden: $e')));
      }
    } finally {
      setState(() => _isAssigning = false);
    }
  }

  Future<void> _updateStatus(Complaint complaint, String status) async {
    try {
      await _complaintService.updateStatus(complaint.id, status);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${_labelFor(status)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  String _labelFor(String status) {
    return _statusOptions.firstWhere(
          (opt) => opt['value'] == status,
          orElse: () => {},
        )['label'] ??
        status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            _buildFilters(),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredComplaints.isEmpty
                  ? const Center(child: Text('No complaints found'))
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredComplaints.length,
                      itemBuilder: (context, index) {
                        final complaint = _filteredComplaints[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(complaint.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Student: ${_studentName(complaint.studentId)}',
                                ),
                                Text(
                                  'Assigned: ${_wardenLabel(complaint.assignedWardenId)}',
                                ),
                                Text('Status: ${_labelFor(complaint.status)}'),
                                Text(
                                  'Created: ${complaint.createdAt.toLocal().toString().split('.')[0]}',
                                ),
                                Text(
                                  'Resolution time: ${_resolutionTime(complaint)}',
                                ),
                              ],
                            ),
                            trailing: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(complaint.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _labelFor(complaint.status),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onSelected: (value) {
                                      if (value == 'assign') {
                                        _assignWarden(complaint);
                                      } else {
                                        _updateStatus(complaint, value);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'assign',
                                        child: Text('Assign warden'),
                                      ),
                                      PopupMenuItem(
                                        value: 'pending',
                                        child: Text('Mark Pending'),
                                      ),
                                      PopupMenuItem(
                                        value: 'in_progress',
                                        child: Text('Mark In progress'),
                                      ),
                                      PopupMenuItem(
                                        value: 'resolved',
                                        child: Text('Mark Resolved'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            onTap: () => _showDetails(complaint),
                          ),
                        );
                      },
                    ),
            ),
            if (_isAssigning) const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String?>(
            segments: const [
              ButtonSegment<String?>(value: null, label: Text('All')),
              ButtonSegment<String?>(value: 'pending', label: Text('Pending')),
              ButtonSegment<String?>(
                value: 'in_progress',
                label: Text('In progress'),
              ),
              ButtonSegment<String?>(
                value: 'resolved',
                label: Text('Resolved'),
              ),
            ],
            selected: {_selectedStatus},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedStatus = selection.first;
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  void _showDetails(Complaint complaint) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(complaint.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Student: ${_studentName(complaint.studentId)}'),
                const SizedBox(height: 4),
                Text('Status: ${_labelFor(complaint.status)}'),
                const SizedBox(height: 4),
                Text('Assigned: ${_wardenLabel(complaint.assignedWardenId)}'),
                const SizedBox(height: 4),
                Text(
                  'Created: ${complaint.createdAt.toLocal().toString().split('.')[0]}',
                ),
                const SizedBox(height: 4),
                if (complaint.resolvedAt != null)
                  Text(
                    'Resolved: ${complaint.resolvedAt!.toLocal().toString().split('.')[0]}',
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  complaint.description.isEmpty
                      ? 'No description provided'
                      : complaint.description,
                ),
                const SizedBox(height: 12),
                Text('Resolution time: ${_resolutionTime(complaint)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _assignWarden(complaint);
              },
              child: const Text('Assign'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(complaint, 'resolved');
              },
              child: const Text('Mark Resolved'),
            ),
          ],
        );
      },
    );
  }
}
