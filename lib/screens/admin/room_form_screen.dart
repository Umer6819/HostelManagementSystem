import 'package:flutter/material.dart';

import '../../models/room_model.dart';
import '../../services/room_service.dart';

class RoomFormScreen extends StatefulWidget {
  final Room? room;
  const RoomFormScreen({super.key, this.room});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomService = RoomService();
  final _roomNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _occupiedController = TextEditingController();
  String _status = 'unlocked';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _roomNumberController.text = widget.room!.roomNumber;
      _capacityController.text = widget.room!.capacity.toString();
      _occupiedController.text = widget.room!.occupied.toString();
      _status = widget.room!.status;
    }
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _capacityController.dispose();
    _occupiedController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (widget.room == null) {
        await _roomService.createRoom(
          roomNumber: _roomNumberController.text.trim(),
          capacity: int.parse(_capacityController.text),
          status: _status,
        );
      } else {
        await _roomService.updateRoom(
          id: widget.room!.id,
          roomNumber: _roomNumberController.text.trim(),
          capacity: int.parse(_capacityController.text),
          occupied: int.parse(_occupiedController.text),
          status: _status,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
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
    final isEdit = widget.room != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Room' : 'Add Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter room number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter capacity';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) return 'Enter a valid number > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (isEdit)
                TextFormField(
                  controller: _occupiedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Occupied',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter occupied';
                    }
                    final n = int.tryParse(value);
                    if (n == null || n < 0) return 'Enter a valid number >= 0';
                    final capacity = int.tryParse(_capacityController.text);
                    if (capacity != null && n > capacity) {
                      return 'Occupied cannot exceed capacity';
                    }
                    return null;
                  },
                ),
              if (isEdit) const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'unlocked', child: Text('Unlocked')),
                  DropdownMenuItem(value: 'locked', child: Text('Locked')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Update Room' : 'Create Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
