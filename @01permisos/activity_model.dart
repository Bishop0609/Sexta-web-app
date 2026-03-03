/// Tipos de actividades disponibles
enum ActivityType {
  academiaCompania,
  academiaCuerpo,
  reunionOrdinaria,
  reunionExtraordinaria,
  citacionCompania,
  citacionCuerpo,
  other,
}

/// Helper para convertir strings de JSON a enum
ActivityType activityTypeFromString(String value) {
  switch (value) {
    case 'academia_compania':
      return ActivityType.academiaCompania;
    case 'academia_cuerpo':
      return ActivityType.academiaCuerpo;
    case 'reunion_ordinaria':
      return ActivityType.reunionOrdinaria;
    case 'reunion_extraordinaria':
      return ActivityType.reunionExtraordinaria;
    case 'citacion_compania':
      return ActivityType.citacionCompania;
    case 'citacion_cuerpo':
      return ActivityType.citacionCuerpo;
    default:
      return ActivityType.other;
  }
}

/// Helper para convertir enum a string para JSON
String activityTypeToString(ActivityType type) {
  switch (type) {
    case ActivityType.academiaCompania:
      return 'academia_compania';
    case ActivityType.academiaCuerpo:
      return 'academia_cuerpo';
    case ActivityType.reunionOrdinaria:
      return 'reunion_ordinaria';
    case ActivityType.reunionExtraordinaria:
      return 'reunion_extraordinaria';
    case ActivityType.citacionCompania:
      return 'citacion_compania';
    case ActivityType.citacionCuerpo:
      return 'citacion_cuerpo';
    case ActivityType.other:
      return 'other';
  }
}

/// Modelo de actividad programada
class ActivityModel {
  final String id;
  final String title;
  final String? description;
  final ActivityType activityType;
  final DateTime activityDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? location;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? modifiedBy;  // Nuevo campo de auditoría
  final DateTime? modifiedAt;  // Nuevo campo de auditoría

  ActivityModel({
    required this.id,
    required this.title,
    this.description,
    required this.activityType,
    required this.activityDate,
    this.startTime,
    this.endTime,
    this.location,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.modifiedBy,
    this.modifiedAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      activityType: activityTypeFromString(json['activity_type'] as String),
      activityDate: DateTime.parse(json['activity_date'] as String),
      startTime: json['start_time'] != null
          ? _parseTime(json['start_time'] as String, json['activity_date'] as String)
          : null,
      endTime: json['end_time'] != null
          ? _parseTime(json['end_time'] as String, json['activity_date'] as String)
          : null,
      location: json['location'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      modifiedBy: json['modified_by'] as String?,
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'activity_type': activityTypeToString(activityType),
      'activity_date': activityDate.toIso8601String().split('T')[0],
      if (startTime != null)
        'start_time': '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}:00',
      if (endTime != null)
        'end_time': '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}:00',
      if (location != null) 'location': location,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (modifiedBy != null) 'modified_by': modifiedBy,
      if (modifiedAt != null) 'modified_at': modifiedAt!.toIso8601String(),
    };
  }

  static DateTime _parseTime(String time, String date) {
    final parts = time.split(':');
    final dateTime = DateTime.parse(date);
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  ActivityModel copyWith({
    String? id,
    String? title,
    String? description,
    ActivityType? activityType,
    DateTime? activityDate,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? modifiedBy,
    DateTime? modifiedAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      activityType: activityType ?? this.activityType,
      activityDate: activityDate ?? this.activityDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}

/// Extension para obtener nombre legible del tipo de actividad
extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.academiaCompania:
        return 'Academia de Compañía';
      case ActivityType.academiaCuerpo:
        return 'Academia de Cuerpo';
      case ActivityType.reunionOrdinaria:
        return 'Reunión Ordinaria';
      case ActivityType.reunionExtraordinaria:
        return 'Reunión Extraordinaria';
      case ActivityType.citacionCompania:
        return 'Citación de Compañía';
      case ActivityType.citacionCuerpo:
        return 'Citación de Cuerpo';
      case ActivityType.other:
        return 'Otra Actividad';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityType.academiaCompania:
      case ActivityType.academiaCuerpo:
        return '📚';
      case ActivityType.reunionOrdinaria:
      case ActivityType.reunionExtraordinaria:
        return '🤝';
      case ActivityType.citacionCompania:
      case ActivityType.citacionCuerpo:
        return '📢';
      case ActivityType.other:
        return '📅';
    }
  }
}
