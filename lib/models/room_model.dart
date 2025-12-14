class Room {
  final int id;
  final String roomNumber;
  final int capacity;
  final int occupied;
  final String status; // locked | unlocked

  Room({
    required this.id,
    required this.roomNumber,
    required this.capacity,
    required this.occupied,
    required this.status,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      roomNumber: json['room_number'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      occupied: json['occupied'] as int? ?? 0,
      status: json['status'] as String? ?? 'unlocked',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_number': roomNumber,
      'capacity': capacity,
      'occupied': occupied,
      'status': status,
    };
  }

  Room copyWith({
    int? id,
    String? roomNumber,
    int? capacity,
    int? occupied,
    String? status,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      capacity: capacity ?? this.capacity,
      occupied: occupied ?? this.occupied,
      status: status ?? this.status,
    );
  }
}
