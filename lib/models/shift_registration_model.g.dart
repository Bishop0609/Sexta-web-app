// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_registration_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShiftRegistrationModel _$ShiftRegistrationModelFromJson(
  Map<String, dynamic> json,
) => _ShiftRegistrationModel(
  id: json['id'] as String,
  configId: json['configId'] as String,
  userId: json['userId'] as String,
  shiftDate: DateTime.parse(json['shiftDate'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ShiftRegistrationModelToJson(
  _ShiftRegistrationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'configId': instance.configId,
  'userId': instance.userId,
  'shiftDate': instance.shiftDate.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
};
