// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IndividualKPI _$IndividualKPIFromJson(Map<String, dynamic> json) =>
    _IndividualKPI(
      userId: json['userId'] as String,
      efectivaCount: (json['efectivaCount'] as num).toInt(),
      abonoCount: (json['abonoCount'] as num).toInt(),
      efectivaPct: (json['efectivaPct'] as num).toDouble(),
      abonoPct: (json['abonoPct'] as num).toDouble(),
      totalAttendance: (json['totalAttendance'] as num).toInt(),
    );

Map<String, dynamic> _$IndividualKPIToJson(_IndividualKPI instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'efectivaCount': instance.efectivaCount,
      'abonoCount': instance.abonoCount,
      'efectivaPct': instance.efectivaPct,
      'abonoPct': instance.abonoPct,
      'totalAttendance': instance.totalAttendance,
    };

_MonthlyStats _$MonthlyStatsFromJson(Map<String, dynamic> json) =>
    _MonthlyStats(
      month: json['month'] as String,
      year: (json['year'] as num).toInt(),
      efectivaCount: (json['efectivaCount'] as num).toInt(),
      abonoCount: (json['abonoCount'] as num).toInt(),
    );

Map<String, dynamic> _$MonthlyStatsToJson(_MonthlyStats instance) =>
    <String, dynamic>{
      'month': instance.month,
      'year': instance.year,
      'efectivaCount': instance.efectivaCount,
      'abonoCount': instance.abonoCount,
    };

_AttendanceRanking _$AttendanceRankingFromJson(Map<String, dynamic> json) =>
    _AttendanceRanking(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      rank: json['rank'] as String,
      attendancePct: (json['attendancePct'] as num).toDouble(),
      totalEvents: (json['totalEvents'] as num).toInt(),
    );

Map<String, dynamic> _$AttendanceRankingToJson(_AttendanceRanking instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullName': instance.fullName,
      'rank': instance.rank,
      'attendancePct': instance.attendancePct,
      'totalEvents': instance.totalEvents,
    };

_LowAttendanceAlert _$LowAttendanceAlertFromJson(Map<String, dynamic> json) =>
    _LowAttendanceAlert(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      rank: json['rank'] as String,
      attendancePct: (json['attendancePct'] as num).toDouble(),
      severity: json['severity'] as String,
    );

Map<String, dynamic> _$LowAttendanceAlertToJson(_LowAttendanceAlert instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullName': instance.fullName,
      'rank': instance.rank,
      'attendancePct': instance.attendancePct,
      'severity': instance.severity,
    };

_ShiftCompliance _$ShiftComplianceFromJson(Map<String, dynamic> json) =>
    _ShiftCompliance(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      maritalStatus: json['maritalStatus'] as String,
      requiredShiftsPerWeek: (json['requiredShiftsPerWeek'] as num).toInt(),
      averageShiftsPerWeek: (json['averageShiftsPerWeek'] as num).toDouble(),
      meetsRequirement: json['meetsRequirement'] as bool,
    );

Map<String, dynamic> _$ShiftComplianceToJson(_ShiftCompliance instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullName': instance.fullName,
      'maritalStatus': instance.maritalStatus,
      'requiredShiftsPerWeek': instance.requiredShiftsPerWeek,
      'averageShiftsPerWeek': instance.averageShiftsPerWeek,
      'meetsRequirement': instance.meetsRequirement,
    };
