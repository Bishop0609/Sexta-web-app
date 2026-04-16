import 'package:sexta_app/models/user_model.dart';

/// Registro de cambio de estado de un bombero
class UserStatusHistory {
  final String id;
  final String userId;
  final UserStatus previousStatus;
  final UserStatus newStatus;
  final DateTime effectiveDate;
  final String reason;
  final String changedBy;
  final DateTime createdAt;
  final String? userName;
  final String? changedByName;

  UserStatusHistory({
    required this.id,
    required this.userId,
    required this.previousStatus,
    required this.newStatus,
    required this.effectiveDate,
    required this.reason,
    required this.changedBy,
    required this.createdAt,
    this.userName,
    this.changedByName,
  });

  factory UserStatusHistory.fromJson(Map<String, dynamic> json) {
    return UserStatusHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      previousStatus: UserModel.parseStatus(json['previous_status'] as String),
      newStatus: UserModel.parseStatus(json['new_status'] as String),
      effectiveDate: DateTime.parse(json['effective_date'] as String),
      reason: json['reason'] as String,
      changedBy: json['changed_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
      changedByName: json['changed_by_name'] as String?,
    );
  }
}
