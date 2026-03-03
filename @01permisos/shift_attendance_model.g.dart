// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShiftAttendanceModel _$ShiftAttendanceModelFromJson(
  Map<String, dynamic> json,
) => _ShiftAttendanceModel(
  id: json['id'] as String,
  shiftDate: DateTime.parse(json['shiftDate'] as String),
  userId: json['userId'] as String,
  checkedIn: json['checkedIn'] as bool? ?? false,
  replacementUserId: json['replacementUserId'] as String?,
  isExtra: json['isExtra'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ShiftAttendanceModelToJson(
  _ShiftAttendanceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'shiftDate': instance.shiftDate.toIso8601String(),
  'userId': instance.userId,
  'checkedIn': instance.checkedIn,
  'replacementUserId': instance.replacementUserId,
  'isExtra': instance.isExtra,
  'createdAt': instance.createdAt?.toIso8601String(),
};
