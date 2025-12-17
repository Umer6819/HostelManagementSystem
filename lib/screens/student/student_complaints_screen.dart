import 'package:flutter/material.dart';

import '../../models/complaint_model.dart';
import '../../models/complaint_response_model.dart';
import '../../services/complaint_service.dart';
import '../../services/complaint_response_service.dart';

class StudentComplaintsScreen extends StatefulWidget {
  const StudentComplaintsScreen({super.key});

  @override
  State<StudentComplaintsScreen> createState() => _StudentComplaintsScreenState();
}

class _StudentComplaintsScreenState extends State<StudentComplaintsScreen> {
  final _complaintService = ComplaintService();
  final _responseService = ComplaintResponseService();

  List<Complaint> _complaints = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final uid = _complaintService.supabase.auth.currentUser?.id;
      if (uid == null) {
        setState(() {
          _error = 'User not authenticated';
          _loading = false;
        });
        return;
      }

      final items = await _complaintService.fetchComplaintsByStudent(uid);
      if (!mounted) return;
      setState(() {
        _complaints = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load complaints: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints & Requests'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadComplaints),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitComplaintDialog,
        icon: const Icon(Icons.add_comment),
        label: const Text('New Complaint'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadComplaints,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _complaints.isEmpty
                  ? const Center(child: Text('No complaints yet'))
                  : RefreshIndicator(
                      onRefresh: _loadComplaints,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          return _buildComplaintCard(_complaints[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final statusColor = _statusColor(complaint.status);
    final statusLabel = _statusLabel(complaint.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(complaint.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (complaint.assignedWardenId != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showResponses(complaint),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Responses'),
                ),
                const SizedBox(width: 8),
                if (complaint.status != 'resolved')
                  TextButton.icon(
                    onPressed: () => _closeComplaint(complaint),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Close'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showSubmitComplaintDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Complaint'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descController.text.trim();
              if (title.isEmpty || desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              try {
                await _complaintService.submitComplaint(title: title, description: desc);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complaint submitted')),
                );
                _loadComplaints();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResponses(Complaint complaint) async {
    try {
      final responses = await _responseService.fetchResponsesForComplaint(complaint.id);
      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.chat_bubble_outline),
                  SizedBox(width: 8),
                  Text(
                    'Responses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (responses.isEmpty)
                const Center(child: Text('No responses yet'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: responses.length,
                  itemBuilder: (context, index) => _buildResponseTile(responses[index]),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load responses: $e')),
      );
    }
  }

  Widget _buildResponseTile(ComplaintResponse r) {
    final roleColor = r.responderRole == 'warden' ? Colors.blue : Colors.purple;
    return ListTile(
      leading: Icon(Icons.person, color: roleColor),
      title: Text(r.content),
      subtitle: Text(_formatDate(r.createdAt)),
    );
  }

  Future<void> _closeComplaint(Complaint c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Complaint?'),
        content: const Text('Are you sure you want to mark this complaint as resolved?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Close')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _complaintService.closeComplaint(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint closed')),
      );
      _loadComplaints();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Pending';
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
