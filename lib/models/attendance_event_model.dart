/// Modelo de evento de asistencia
/// Este modelo representa un evento donde se toma asistencia
class AttendanceEventModel {
  final String id;
  final String actTypeId;
  final DateTime eventDate;
  final String createdBy;
  final String? modifiedBy;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  AttendanceEventModel({
    required this.id,
    required this.actTypeId,
    required this.eventDate,
    required this.createdBy,
    this.modifiedBy,
    this.createdAt,
    this.modifiedAt,
  });

  factory AttendanceEventModel.fromJson(Map<String, dynamic> json) {
    return AttendanceEventModel(
      id: json['id'] as String,
      actTypeId: json['act_type_id'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      createdBy: json['created_by'] as String,
      modifiedBy: json['modified_by'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'act_type_id': actTypeId,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'created_by': createdBy,
      if (modifiedBy != null) 'modified_by': modifiedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (modifiedAt != null) 'modified_at': modifiedAt!.toIso8601String(),
    };
  }

  AttendanceEventModel copyWith({
    String? id,
    String? actTypeId,
    DateTime? eventDate,
    String? createdBy,
    String? modifiedBy,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return AttendanceEventModel(
      id: id ?? this.id,
      actTypeId: actTypeId ?? this.actTypeId,
      eventDate: eventDate ?? this.eventDate,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}
