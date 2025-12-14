class Student {
  final String id; // user id
  final String name;
  final String regNo;
  final int? roomId;
  final String? phone;

  Student({
    required this.id,
    required this.name,
    required this.regNo,
    this.roomId,
    this.phone,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      regNo: json['reg_no'] as String? ?? '',
      roomId: json['room_id'] as int?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'reg_no': regNo,
      'room_id': roomId,
      'phone': phone,
    };
  }

  Student copyWith({
    String? id,
    String? name,
    String? regNo,
    int? roomId,
    String? phone,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      regNo: regNo ?? this.regNo,
      roomId: roomId ?? this.roomId,
      phone: phone ?? this.phone,
    );
  }
}
