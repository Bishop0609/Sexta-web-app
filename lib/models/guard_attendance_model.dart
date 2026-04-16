import 'package:sexta_app/models/user_model.dart';

/// Model for FDS (Weekend/Holiday) Guard Attendance
/// Composition: Maq1 + Maq2 + OBAC + 10 Bomberos = 13 people total
class GuardAttendanceFds {
  final String id;
  final DateTime guardDate;
  final String shiftPeriod; // 'AM' | 'PM'
  
  // Personnel IDs
  final String? maquinista1Id;
  final String? maquinista2Id;
  final String? obacId;
  final List<String?> bomberoIds; // 10 elements
  
  final String? observations;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? modifiedBy;
  
  // Populated user objects
  UserModel? maquinista1;
  UserModel? maquinista2;
  UserModel? obac;
  List<UserModel?> bomberos;

  GuardAttendanceFds({
    required this.id,
    required this.guardDate,
    required this.shiftPeriod,
    this.maquinista1Id,
    this.maquinista2Id,
    this.obacId,
    required this.bomberoIds,
    this.observations,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.modifiedBy,
    this.maquinista1,
    this.maquinista2,
    this.obac,
    List<UserModel?>? bomberos,
  }) : bomberos = bomberos ?? List.filled(10, null);

  factory GuardAttendanceFds.fromJson(Map<String, dynamic> json) {
    return GuardAttendanceFds(
      id: json['id'] as String,
      guardDate: DateTime.parse(json['guard_date'] as String),
      shiftPeriod: json['shift_period'] as String,
      maquinista1Id: json['maquinista_1_id'] as String?,
      maquinista2Id: json['maquinista_2_id'] as String?,
      obacId: json['obac_id'] as String?,
      bomberoIds: [
        json['bombero_1_id'] as String?,
        json['bombero_2_id'] as String?,
        json['bombero_3_id'] as String?,
        json['bombero_4_id'] as String?,
        json['bombero_5_id'] as String?,
        json['bombero_6_id'] as String?,
        json['bombero_7_id'] as String?,
        json['bombero_8_id'] as String?,
        json['bombero_9_id'] as String?,
        json['bombero_10_id'] as String?,
      ],
      observations: json['observations'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      modifiedBy: json['modified_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guard_date': guardDate.toIso8601String().split('T')[0],
      'shift_period': shiftPeriod,
      'maquinista_1_id': maquinista1Id,
      'maquinista_2_id': maquinista2Id,
      'obac_id': obacId,
      'bombero_1_id': bomberoIds.length > 0 ? bomberoIds[0] : null,
      'bombero_2_id': bomberoIds.length > 1 ? bomberoIds[1] : null,
      'bombero_3_id': bomberoIds.length > 2 ? bomberoIds[2] : null,
      'bombero_4_id': bomberoIds.length > 3 ? bomberoIds[3] : null,
      'bombero_5_id': bomberoIds.length > 4 ? bomberoIds[4] : null,
      'bombero_6_id': bomberoIds.length > 5 ? bomberoIds[5] : null,
      'bombero_7_id': bomberoIds.length > 6 ? bomberoIds[6] : null,
      'bombero_8_id': bomberoIds.length > 7 ? bomberoIds[7] : null,
      'bombero_9_id': bomberoIds.length > 8 ? bomberoIds[8] : null,
      'bombero_10_id': bomberoIds.length > 9 ? bomberoIds[9] : null,
      'observations': observations,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'modified_by': modifiedBy,
    };
  }

  /// Check if user can edit (within 1 hour and is creator)
  bool canEdit(String userId, DateTime now) {
    if (userId != createdBy) return false;
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < 1;
  }

  /// Check if user can view (within 2 hours)
  bool canView(DateTime now) {
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < 2;
  }

  /// Get all assigned personnel count
  int get assignedCount {
    int count = 0;
    if (maquinista1Id != null) count++;
    if (maquinista2Id != null) count++;
    if (obacId != null) count++;
    count += bomberoIds.where((id) => id != null).length;
    return count;
  }
}

/// Model for Diurna (Weekday) Guard Attendance
/// Same structure as FDS
class GuardAttendanceDiurna {
  final String id;
  final DateTime guardDate;
  final String shiftPeriod; // 'AM' | 'PM'
  
  // Personnel IDs
  final String? maquinista1Id;
  final String? maquinista2Id;
  final String? obacId;
  final List<String?> bomberoIds; // 10 elements
  
  final String? observations;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? modifiedBy;
  
  // Populated user objects
  UserModel? maquinista1;
  UserModel? maquinista2;
  UserModel? obac;
  List<UserModel?> bomberos;

  GuardAttendanceDiurna({
    required this.id,
    required this.guardDate,
    required this.shiftPeriod,
    this.maquinista1Id,
    this.maquinista2Id,
    this.obacId,
    required this.bomberoIds,
    this.observations,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.modifiedBy,
    this.maquinista1,
    this.maquinista2,
    this.obac,
    List<UserModel?>? bomberos,
  }) : bomberos = bomberos ?? List.filled(10, null);

  factory GuardAttendanceDiurna.fromJson(Map<String, dynamic> json) {
    return GuardAttendanceDiurna(
      id: json['id'] as String,
      guardDate: DateTime.parse(json['guard_date'] as String),
      shiftPeriod: json['shift_period'] as String,
      maquinista1Id: json['maquinista_1_id'] as String?,
      maquinista2Id: json['maquinista_2_id'] as String?,
      obacId: json['obac_id'] as String?,
      bomberoIds: [
        json['bombero_1_id'] as String?,
        json['bombero_2_id'] as String?,
        json['bombero_3_id'] as String?,
        json['bombero_4_id'] as String?,
        json['bombero_5_id'] as String?,
        json['bombero_6_id'] as String?,
        json['bombero_7_id'] as String?,
        json['bombero_8_id'] as String?,
        json['bombero_9_id'] as String?,
        json['bombero_10_id'] as String?,
      ],
      observations: json['observations'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      modifiedBy: json['modified_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guard_date': guardDate.toIso8601String().split('T')[0],
      'shift_period': shiftPeriod,
      'maquinista_1_id': maquinista1Id,
      'maquinista_2_id': maquinista2Id,
      'obac_id': obacId,
      'bombero_1_id': bomberoIds.length > 0 ? bomberoIds[0] : null,
      'bombero_2_id': bomberoIds.length > 1 ? bomberoIds[1] : null,
      'bombero_3_id': bomberoIds.length > 2 ? bomberoIds[2] : null,
      'bombero_4_id': bomberoIds.length > 3 ? bomberoIds[3] : null,
      'bombero_5_id': bomberoIds.length > 4 ? bomberoIds[4] : null,
      'bombero_6_id': bomberoIds.length > 5 ? bomberoIds[5] : null,
      'bombero_7_id': bomberoIds.length > 6 ? bomberoIds[6] : null,
      'bombero_8_id': bomberoIds.length > 7 ? bomberoIds[7] : null,
      'bombero_9_id': bomberoIds.length > 8 ? bomberoIds[8] : null,
      'bombero_10_id': bomberoIds.length > 9 ? bomberoIds[9] : null,
      'observations': observations,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'modified_by': modifiedBy,
    };
  }

  bool canEdit(String userId, DateTime now) {
    if (userId != createdBy) return false;
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < 1;
  }

  bool canView(DateTime now) {
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < 2;
  }

  int get assignedCount {
    int count = 0;
    if (maquinista1Id != null) count++;
    if (maquinista2Id != null) count++;
    if (obacId != null) count++;
    count += bomberoIds.where((id) => id != null).length;
    return count;
  }
}

/// Model for Nocturna (Night) Guard Attendance
/// Composition: Maquinista (1) + OBAC (1) + 8 Bomberos = 10 people total
/// Gender restriction: 6 males, 4 females (validated in service)
class GuardAttendanceNocturna {
  final String id;
  final DateTime guardDate; // Date when guard starts (23:00)
  final String? rosterWeekId;
  
  // Personnel IDs (max 10 total)
  final String? maquinistaId;
  final String? obacId;
  final List<String?> bomberoIds; // 8 elements
  
  final String? observations;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? modifiedBy;
  
  // Populated user objects
  UserModel? maquinista;
  UserModel? obac;
  List<UserModel?> bomberos;
  
  // Individual attendance records with status
  List<GuardAttendanceRecord> records;

  GuardAttendanceNocturna({
    required this.id,
    required this.guardDate,
    this.rosterWeekId,
    this.maquinistaId,
    this.obacId,
    required this.bomberoIds,
    this.observations,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.modifiedBy,
    this.maquinista,
    this.obac,
    List<UserModel?>? bomberos,
    List<GuardAttendanceRecord>? records,
  })  : bomberos = bomberos ?? List.filled(8, null),
        records = records ?? [];

  factory GuardAttendanceNocturna.fromJson(Map<String, dynamic> json) {
    return GuardAttendanceNocturna(
      id: json['id'] as String,
      guardDate: DateTime.parse(json['guard_date'] as String),
      rosterWeekId: json['roster_week_id'] as String?,
      maquinistaId: json['maquinista_id'] as String?,
      obacId: json['obac_id'] as String?,
      bomberoIds: [
        json['bombero_1_id'] as String?,
        json['bombero_2_id'] as String?,
        json['bombero_3_id'] as String?,
        json['bombero_4_id'] as String?,
        json['bombero_5_id'] as String?,
        json['bombero_6_id'] as String?,
        json['bombero_7_id'] as String?,
        json['bombero_8_id'] as String?,
      ],
      observations: json['observations'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      modifiedBy: json['modified_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guard_date': guardDate.toIso8601String().split('T')[0],
      'roster_week_id': rosterWeekId,
      'maquinista_id': maquinistaId,
      'obac_id': obacId,
      'bombero_1_id': bomberoIds.length > 0 ? bomberoIds[0] : null,
      'bombero_2_id': bomberoIds.length > 1 ? bomberoIds[1] : null,
      'bombero_3_id': bomberoIds.length > 2 ? bomberoIds[2] : null,
      'bombero_4_id': bomberoIds.length > 3 ? bomberoIds[3] : null,
      'bombero_5_id': bomberoIds.length > 4 ? bomberoIds[4] : null,
      'bombero_6_id': bomberoIds.length > 5 ? bomberoIds[5] : null,
      'bombero_7_id': bomberoIds.length > 6 ? bomberoIds[6] : null,
      'bombero_8_id': bomberoIds.length > 7 ? bomberoIds[7] : null,
      'observations': observations,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'modified_by': modifiedBy,
    };
  }

  bool canEdit(String userId, DateTime now) {
    if (userId != createdBy) return false;
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < 1;
  }

  bool canView(DateTime now) {
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < 2;
  }

  int get assignedCount {
    int count = 0;
    if (maquinistaId != null) count++;
    if (obacId != null) count++;
    count += bomberoIds.where((id) => id != null).length;
    return count;
  }
}

/// Individual attendance record for night guards with status tracking
class GuardAttendanceRecord {
  final String id;
  final String guardAttendanceId;
  final String userId;
  final String position; // 'maquinista' | 'obac' | 'bombero'
  final String status; // 'presente' | 'ausente' | 'permiso' | 'reemplazado'
  final String? replacedById;
  final String? replacesUserId;
  final DateTime createdAt;
  
  // Populated user objects
  UserModel? user;
  UserModel? replacedBy;
  UserModel? replacesUser;

  GuardAttendanceRecord({
    required this.id,
    required this.guardAttendanceId,
    required this.userId,
    required this.position,
    required this.status,
    this.replacedById,
    this.replacesUserId,
    required this.createdAt,
    this.user,
    this.replacedBy,
    this.replacesUser,
  });

  factory GuardAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return GuardAttendanceRecord(
      id: json['id'] as String,
      guardAttendanceId: json['guard_attendance_id'] as String,
      userId: json['user_id'] as String,
      position: json['position'] as String,
      status: json['status'] as String,
      replacedById: json['replaced_by_id'] as String?,
      replacesUserId: json['replaces_user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guard_attendance_id': guardAttendanceId,
      'user_id': userId,
      'position': position,
      'status': status,
      'replaced_by_id': replacedById,
      'replaces_user_id': replacesUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPresent => status == 'presente';
  bool get isAbsent => status == 'ausente';
  bool get hasPermission => status == 'permiso';
  bool get isReplaced => status == 'reemplazado';
}
