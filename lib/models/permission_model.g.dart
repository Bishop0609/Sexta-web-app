// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PermissionModel _$PermissionModelFromJson(Map<String, dynamic> json) =>
    _PermissionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String,
      tipoPermiso: json['tipo_permiso'] as String? ?? 'fecha',
      actividadId: json['actividad_id'] as String?,
      aprobadorTipo: json['aprobador_tipo'] as String?,
      status:
          $enumDecodeNullable(_$PermissionStatusEnumMap, json['status']) ??
          PermissionStatus.pending,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PermissionModelToJson(_PermissionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'reason': instance.reason,
      'tipo_permiso': instance.tipoPermiso,
      'actividad_id': instance.actividadId,
      'aprobador_tipo': instance.aprobadorTipo,
      'status': _$PermissionStatusEnumMap[instance.status]!,
      'reviewedBy': instance.reviewedBy,
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$PermissionStatusEnumMap = {
  PermissionStatus.pending: 'pending',
  PermissionStatus.approved: 'approved',
  PermissionStatus.rejected: 'rejected',
};
