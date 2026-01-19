/// Configuración de período de guardia
class ShiftConfigModel {
  final String id;
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationStart;
  final DateTime registrationEnd;
  final DateTime? createdAt;

  ShiftConfigModel({
    required this.id,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.registrationStart,
    required this.registrationEnd,
    this.createdAt,
  });

  factory ShiftConfigModel.fromJson(Map<String, dynamic> json) {
    return ShiftConfigModel(
      id: json['id'] as String,
      periodName: json['period_name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      registrationStart: DateTime.parse(json['registration_start'] as String),
      registrationEnd: DateTime.parse(json['registration_end'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_name': periodName,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'registration_start': registrationStart.toIso8601String().split('T')[0],
      'registration_end': registrationEnd.toIso8601String().split('T')[0],
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
