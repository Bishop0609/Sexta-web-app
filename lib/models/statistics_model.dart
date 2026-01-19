import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistics_model.freezed.dart';
part 'statistics_model.g.dart';

/// KPI individual de un bombero
@freezed
class IndividualKPI with _$IndividualKPI {
  const factory IndividualKPI({
    required String userId,
    required int efectivaCount,
    required int abonoCount,
    required double efectivaPct,
    required double abonoPct,
    required int totalAttendance,
  }) = _IndividualKPI;

  factory IndividualKPI.fromJson(Map<String, dynamic> json) =>
      _$IndividualKPIFromJson(json);
}

/// Datos mensuales para gráfico
@freezed
class MonthlyStats with _$MonthlyStats {
  const factory MonthlyStats({
    required String month,
    required int year,
    required int efectivaCount,
    required int abonoCount,
  }) = _MonthlyStats;

  factory MonthlyStats.fromJson(Map<String, dynamic> json) =>
      _$MonthlyStatsFromJson(json);
}

/// Ranking de asistencia
@freezed
class AttendanceRanking with _$AttendanceRanking {
  const factory AttendanceRanking({
    required String userId,
    required String fullName,
    required String rank,
    required double attendancePct,
    required int totalEvents,
  }) = _AttendanceRanking;

  factory AttendanceRanking.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRankingFromJson(json);
}

/// Alerta de baja asistencia (semáforo)
@freezed
class LowAttendanceAlert with _$LowAttendanceAlert {
  const factory LowAttendanceAlert({
    required String userId,
    required String fullName,
    required String rank,
    required double attendancePct,
    required String severity, // 'critical' | 'warning'
  }) = _LowAttendanceAlert;

  factory LowAttendanceAlert.fromJson(Map<String, dynamic> json) =>
      _$LowAttendanceAlertFromJson(json);
}

/// Cumplimiento de guardia
@freezed
class ShiftCompliance with _$ShiftCompliance {
  const factory ShiftCompliance({
    required String userId,
    required String fullName,
    required String maritalStatus,
    required int requiredShiftsPerWeek,
    required double averageShiftsPerWeek,
    required bool meetsRequirement,
  }) = _ShiftCompliance;

  factory ShiftCompliance.fromJson(Map<String, dynamic> json) =>
      _$ShiftComplianceFromJson(json);
}
