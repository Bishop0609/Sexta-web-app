// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'act_type_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActTypeModel _$ActTypeModelFromJson(Map<String, dynamic> json) =>
    _ActTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: $enumDecode(_$ActCategoryEnumMap, json['category']),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ActTypeModelToJson(_ActTypeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': _$ActCategoryEnumMap[instance.category]!,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$ActCategoryEnumMap = {
  ActCategory.efectiva: 'efectiva',
  ActCategory.abono: 'abono',
};
