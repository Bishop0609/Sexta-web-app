import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_model.freezed.dart';
part 'permission_model.g.dart';

enum PermissionStatus {
  pending,
  approved,
  rejected,
}

@freezed
class PermissionModel with _$PermissionModel {
  const factory PermissionModel({
    required String id,
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    @Default(PermissionStatus.pending) PermissionStatus status,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) = _PermissionModel;

  factory PermissionModel.fromJson(Map<String, dynamic> json) =>
      _$PermissionModelFromJson(json);
}
