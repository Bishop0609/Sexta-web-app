import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_attendance_model.freezed.dart';
part 'shift_attendance_model.g.dart';

@freezed
class ShiftAttendanceModel with _$ShiftAttendanceModel {
  const factory ShiftAttendanceModel({
    required String id,
    required DateTime shiftDate,
    required String userId,
    @Default(false) bool checkedIn,
    String? replacementUserId, // User who replaced this firefighter (Abono)
    @Default(false) bool isExtra, // Extra firefighter not in schedule
    DateTime? createdAt,
  }) = _ShiftAttendanceModel;

  factory ShiftAttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$ShiftAttendanceModelFromJson(json);
}
