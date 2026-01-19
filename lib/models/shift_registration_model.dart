import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_registration_model.freezed.dart';
part 'shift_registration_model.g.dart';

@freezed
class ShiftRegistrationModel with _$ShiftRegistrationModel {
  const factory ShiftRegistrationModel({
    required String id,
    required String configId,
    required String userId,
    required DateTime shiftDate,
    DateTime? createdAt,
  }) = _ShiftRegistrationModel;

  factory ShiftRegistrationModel.fromJson(Map<String, dynamic> json) =>
      _$ShiftRegistrationModelFromJson(json);
}
