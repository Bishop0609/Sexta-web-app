import 'package:sexta_app/models/user_model.dart';

/// Model for guard availability registration
class GuardAvailability {
  final String id;
  final String userId;
  final DateTime availableDate;
  final bool isDriver; // Register as maquinista
  final String guardType; // 'nocturna', 'fds', 'diurna'
  final String? shiftPeriod; // 'AM', 'PM'
  final DateTime createdAt;
  final UserModel? user; // Populated from join

  GuardAvailability({
    required this.id,
    required this.userId,
    required this.availableDate,
    required this.isDriver,
    this.guardType = 'nocturna',
    this.shiftPeriod,
    required this.createdAt,
    this.user,
  });

  factory GuardAvailability.fromJson(Map<String, dynamic> json) {
    return GuardAvailability(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      availableDate: DateTime.parse(json['available_date'] as String),
      isDriver: json['is_driver'] as bool? ?? false,
      guardType: json['guard_type'] as String? ?? 'nocturna',
      shiftPeriod: json['shift_period'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null 
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'available_date': availableDate.toIso8601String().split('T')[0],
      'is_driver': isDriver,
      'guard_type': guardType,
      'shift_period': shiftPeriod,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a new availability registration (without id and createdAt)
  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'available_date': availableDate.toIso8601String().split('T')[0],
      'is_driver': isDriver,
      'guard_type': guardType,
      'shift_period': shiftPeriod,
    };
  }
}
