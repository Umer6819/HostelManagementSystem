import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/maintenance_issue_model.dart';
import '../../models/room_model.dart';
import '../../services/maintenance_issue_service.dart';
import '../../services/room_service.dart';

class MaintenanceManagementScreen extends StatefulWidget {
  const MaintenanceManagementScreen({super.key});

  @override
  State<MaintenanceManagementScreen> createState() =>
      _MaintenanceManagementScreenState();
}

class _MaintenanceManagementScreenState
    extends State<MaintenanceManagementScreen> {
  final MaintenanceIssueService _issueService = MaintenanceIssueService();
  final RoomService _roomService = RoomService();

  List<MaintenanceIssue> _issues = [];
  List<Room> _rooms = [];
  bool _isLoading = true;
  String _filterStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _issueService.fetchAllIssues(),
        _roomService.fetchRooms(),
      ]);
      setState(() {
        _issues = results[0] as List<MaintenanceIssue>;
        _rooms = results[1] as List<Room>;
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

  List<MaintenanceIssue> _getFilteredIssues() {
    if (_filterStatus == 'all') {
      return _issues;
    }
    return _issues.where((i) => i.status == _filterStatus).toList();
  }

  Room _getRoom(int roomId) {
    return _rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => Room(
        id: 0,
        roomNumber: 'Unknown',
        capacity: 0,
        occupied: 0,
        status: 'unlocked',
      ),
    );
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

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredIssues();

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('pending', 'Pending'),
                        _buildFilterChip('in_progress', 'In Progress'),
                        _buildFilterChip('resolved', 'Resolved'),
                        _buildFilterChip('all', 'All'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text('No $_filterStatus issues'))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final issue = filtered[index];
                              final room = _getRoom(issue.roomId);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.build,
                                    color: _priorityColor(issue.priority),
                                    size: 36,
                                  ),
                                  title: Text(
                                    issue.issueType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('Room: ${room.roomNumber}'),
                                      Text(
                                        issue.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Priority: ${issue.priority.toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _priorityColor(issue.priority),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Reported: ${issue.createdAt.toLocal().toString().split('.')[0]}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(issue.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      issue.status
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _showIssueDetails(issue, room),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterStatus == value,
        onSelected: (isSelected) {
          setState(() => _filterStatus = value);
        },
      ),
    );
  }

  void _showIssueDetails(MaintenanceIssue issue, Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${issue.issueType} - Room ${room.roomNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    issue.status == 'resolved'
                        ? Icons.check_circle
                        : issue.status == 'in_progress'
                        ? Icons.schedule
                        : Icons.pending,
                    color: _statusColor(issue.status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('Status: ${issue.status.replaceAll('_', ' ')}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 20,
                    color: _priorityColor(issue.priority),
                  ),
                  const SizedBox(width: 8),
                  Text('Priority: ${issue.priority.toUpperCase()}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reported: ${issue.createdAt.toLocal().toString().split('.')[0]}',
                    ),
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
                    Expanded(
                      child: Text(
                        'Resolved: ${issue.resolvedAt!.toLocal().toString().split('.')[0]}',
                      ),
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
          if (issue.status != 'in_progress')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateIssueStatus(issue, 'in_progress');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Start Work'),
            ),
          if (issue.status != 'resolved')
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showResolutionDialog(issue);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }

  Future<void> _updateIssueStatus(
    MaintenanceIssue issue,
    String newStatus,
  ) async {
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to update issues.'),
          ),
        );
        return;
      }

      await _issueService.updateIssueStatus(
        issueId: issue.id,
        status: newStatus,
        resolvedBy: newStatus == 'resolved' ? adminId : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue marked as ${newStatus.replaceAll('_', ' ')}'),
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

  void _showResolutionDialog(MaintenanceIssue issue) {
    final formKey = GlobalKey<FormState>();
    String resolutionNotes = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Issue'),
        content: Form(
          key: formKey,
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Resolution Notes',
              hintText: 'Describe how the issue was resolved',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (value) => resolutionNotes = value,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter resolution notes'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _updateIssueWithNotes(issue, resolutionNotes);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateIssueWithNotes(
    MaintenanceIssue issue,
    String notes,
  ) async {
    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      if (adminId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
        return;
      }

      await _issueService.updateIssueStatus(
        issueId: issue.id,
        status: 'resolved',
        resolvedBy: adminId,
        resolutionNotes: notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue resolved successfully')),
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
