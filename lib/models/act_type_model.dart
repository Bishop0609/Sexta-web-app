import 'package:freezed_annotation/freezed_annotation.dart';

part 'act_type_model.freezed.dart';
part 'act_type_model.g.dart';

/// Categoría contable del tipo de acto
/// EFECTIVA: Suma para obligación legal de asistencia
/// ABONO: Suma como extra o compensación
enum ActCategory {
  @JsonValue('efectiva')
  efectiva,
  @JsonValue('abono')
  abono,
}

@freezed
class ActTypeModel with _$ActTypeModel {
  const factory ActTypeModel({
    required String id,
    required String name,
    required ActCategory category,
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _ActTypeModel;

  factory ActTypeModel.fromJson(Map<String, dynamic> json) =>
      _$ActTypeModelFromJson(json);
}
