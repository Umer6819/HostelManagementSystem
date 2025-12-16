import 'package:flutter/material.dart';
import '../../models/room_lock_request_model.dart';
import '../../models/room_model.dart';
import '../../services/room_lock_request_service.dart';
import '../../services/room_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomLockRequestsScreen extends StatefulWidget {
  const RoomLockRequestsScreen({super.key});

  @override
  State<RoomLockRequestsScreen> createState() => _RoomLockRequestsScreenState();
}

class _RoomLockRequestsScreenState extends State<RoomLockRequestsScreen> {
  final RoomLockRequestService _lockRequestService = RoomLockRequestService();
  final RoomService _roomService = RoomService();

  List<RoomLockRequest> _requests = [];
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
        _lockRequestService.fetchAllRequests(),
        _roomService.fetchRooms(),
      ]);
      setState(() {
        _requests = results[0] as List<RoomLockRequest>;
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

  List<RoomLockRequest> _getFilteredRequests() {
    if (_filterStatus == 'all') {
      return _requests;
    }
    return _requests.where((r) => r.status == _filterStatus).toList();
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
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredRequests();

    return Scaffold(
      appBar: AppBar(title: const Text('Room Lock Requests')),
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
                        _buildFilterChip('approved', 'Approved'),
                        _buildFilterChip('rejected', 'Rejected'),
                        _buildFilterChip('all', 'All'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text('No $_filterStatus requests'))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final request = filtered[index];
                              final room = _getRoom(request.roomId);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Icon(
                                    request.status == 'approved'
                                        ? Icons.lock
                                        : request.status == 'rejected'
                                        ? Icons.lock_open
                                        : Icons.lock_clock,
                                    color: _statusColor(request.status),
                                    size: 36,
                                  ),
                                  title: Text(
                                    'Room ${room.roomNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        request.reason,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Requested: ${request.createdAt.toLocal().toString().split('.')[0]}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      if (request.lockUntil != null)
                                        Text(
                                          'Lock until: ${request.lockUntil!.toLocal().toString().split('.')[0]}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(request.status),
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
                                  onTap: () =>
                                      _showRequestDetails(request, room),
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

  void _showRequestDetails(RoomLockRequest request, Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Room ${room.roomNumber} - Lock Request'),
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
                    color: _statusColor(request.status),
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
                  Expanded(
                    child: Text(
                      'Requested: ${request.createdAt.toLocal().toString().split('.')[0]}',
                    ),
                  ),
                ],
              ),
              if (request.lockUntil != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lock Until: ${request.lockUntil!.toLocal().toString().split('.')[0]}',
                      ),
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
                    Expanded(
                      child: Text(
                        'Reviewed: ${request.reviewedAt!.toLocal().toString().split('.')[0]}',
                      ),
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
          if (request.status == 'pending') ...[
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showReviewDialog(request, 'rejected');
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showReviewDialog(request, 'approved');
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve'),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(RoomLockRequest request, String decision) {
    final formKey = GlobalKey<FormState>();
    String reviewNotes = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${decision == 'approved' ? 'Approve' : 'Reject'} Request'),
        content: Form(
          key: formKey,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Review Notes (Optional)',
              hintText: 'Add any notes about your decision',
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => reviewNotes = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final adminId = Supabase.instance.client.auth.currentUser?.id;
                if (adminId == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You must be logged in to review requests.',
                      ),
                    ),
                  );
                  return;
                }
                await _lockRequestService.reviewRequest(
                  requestId: request.id,
                  status: decision,
                  reviewedBy: adminId,
                  reviewNotes: reviewNotes.isNotEmpty ? reviewNotes : null,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Request ${decision == 'approved' ? 'approved' : 'rejected'}',
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
            },
            style: FilledButton.styleFrom(
              backgroundColor: decision == 'approved'
                  ? Colors.green
                  : Colors.red,
            ),
            child: Text(decision == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}
