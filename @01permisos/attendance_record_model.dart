/// Estado de asistencia
enum AttendanceStatus {
  present,
  absent,
  licencia, // Auto-set cuando hay permiso aprobado
}

/// Registro individual de asistencia
class AttendanceRecordModel {
  final String id;
  final String eventId;
  final String userId;
  final AttendanceStatus status;
  final bool isLocked; // True si auto-set desde permiso
  final DateTime? createdAt;

  AttendanceRecordModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    this.isLocked = false,
    this.createdAt,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      isLocked: json['is_locked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'status': status.name,
      'is_locked': isLocked,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
