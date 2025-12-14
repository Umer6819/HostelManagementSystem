import 'package:flutter/material.dart';

import '../../models/room_model.dart';
import '../../services/room_service.dart';
import 'room_form_screen.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _roomService = RoomService();
  List<Room> _rooms = [];
  bool _loading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);
    try {
      final rooms = await _roomService.fetchRooms(
        status: _statusFilter,
      );
      if (mounted) setState(() => _rooms = rooms);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rooms: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onAddOrEdit(Room? room) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RoomFormScreen(room: room)),
    );
    if (changed == true) _loadRooms();
  }

  Future<void> _deleteRoom(Room room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Delete room ${room.roomNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _roomService.deleteRoom(room.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room deleted')),
        );
        _loadRooms();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting room: $e')),
        );
      }
    }
  }

  Future<void> _toggleLock(Room room) async {
    try {
      final isLocked = room.status == 'locked';
      await _roomService.toggleLock(id: room.id, lock: !isLocked);
      if (mounted) {
        final newStatus = isLocked ? 'unlocked' : 'locked';
        setState(() {
          _rooms = _rooms
              .map((r) => r.id == room.id ? r.copyWith(status: newStatus) : r)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating lock: $e')),
        );
      }
    }
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<String?>(
          value: _statusFilter,
          hint: const Text('Status'),
          items: const [
            DropdownMenuItem(value: null, child: Text('All')),
            DropdownMenuItem(value: 'unlocked', child: Text('Unlocked')),
            DropdownMenuItem(value: 'locked', child: Text('Locked')),
          ],
          onChanged: (val) => setState(() => _statusFilter = val),
        ),
        ElevatedButton(
          onPressed: _loadRooms,
          child: const Text('Apply'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _statusFilter = null;
            });
            _loadRooms();
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildRoomCard(Room room) {
    final occupancy = '${room.occupied}/${room.capacity}';
    final isLocked = room.status == 'locked';
    return Card(
      child: ListTile(
        title: Text('Room ${room.roomNumber}'),
        subtitle: Text('Occupancy: $occupancy'),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              tooltip: isLocked ? 'Unlock' : 'Lock',
              icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
              onPressed: () => _toggleLock(room),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _onAddOrEdit(room),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteRoom(room),
            ),
          ],
        ),
        onTap: () => _onAddOrEdit(room),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildFilters(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRooms,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rooms.isEmpty
                      ? const Center(child: Text('No rooms'))
                      : ListView.builder(
                          itemCount: _rooms.length,
                          itemBuilder: (context, index) {
                            final room = _rooms[index];
                            return _buildRoomCard(room);
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddOrEdit(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
