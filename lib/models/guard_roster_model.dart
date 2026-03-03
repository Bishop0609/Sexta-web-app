import 'package:sexta_app/models/user_model.dart';

/// Weekly night guard roster (Monday to Sunday)
class GuardRosterWeekly {
  final String id;
  final DateTime weekStartDate; // Monday
  final DateTime weekEndDate;   // Sunday
  final String status; // 'draft' | 'published'
  final String guardType; // 'nocturna', 'fds', 'diurna'
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Daily assignments for the week
  List<GuardRosterDaily> dailyAssignments;

  GuardRosterWeekly({
    required this.id,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.status,
    this.guardType = 'nocturna',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    List<GuardRosterDaily>? dailyAssignments,
  }) : dailyAssignments = dailyAssignments ?? [];

  factory GuardRosterWeekly.fromJson(Map<String, dynamic> json) {
    return GuardRosterWeekly(
      id: json['id'] as String,
      weekStartDate: DateTime.parse(json['week_start_date'] as String),
      weekEndDate: DateTime.parse(json['week_end_date'] as String),
      status: json['status'] as String,
      guardType: json['guard_type'] as String? ?? 'nocturna',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'week_start_date': weekStartDate.toIso8601String().split('T')[0],
      'week_end_date': weekEndDate.toIso8601String().split('T')[0],
      'status': status,
      'guard_type': guardType,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
}

/// Daily night guard assignment within a weekly roster
/// Max 10 people: Maquinista (1) + OBAC (1) + Bomberos (8)
/// Gender restriction: 6 males, 4 females (validated in service)
class GuardRosterDaily {
  final String id;
  final String rosterWeekId;
  final DateTime guardDate;
  final String shiftPeriod; // 'NOCTURNA' | 'AM' | 'PM'
  
  // Personnel IDs
  final String? maquinistaId;
  final String? obacId;
  final List<String> bomberoIds; // Up to 8 IDs
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Populated user objects
  UserModel? maquinista;
  UserModel? obac;
  List<UserModel> bomberos;

  GuardRosterDaily({
    required this.id,
    required this.rosterWeekId,
    required this.guardDate,
    this.shiftPeriod = 'NOCTURNA',
    this.maquinistaId,
    this.obacId,
    required this.bomberoIds,
    required this.createdAt,
    required this.updatedAt,
    this.maquinista,
    this.obac,
    List<UserModel>? bomberos,
  }) : bomberos = bomberos ?? [];

  factory GuardRosterDaily.fromJson(Map<String, dynamic> json) {
    // Parse bombero_ids array
    List<String> bomberoIdsList = [];
    if (json['bombero_ids'] != null) {
      if (json['bombero_ids'] is List) {
        bomberoIdsList = (json['bombero_ids'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return GuardRosterDaily(
      id: json['id'] as String,
      rosterWeekId: json['roster_week_id'] as String,
      guardDate: DateTime.parse(json['guard_date'] as String),
      shiftPeriod: json['shift_period'] as String? ?? 'NOCTURNA',
      maquinistaId: json['maquinista_id'] as String?,
      obacId: json['obac_id'] as String?,
      bomberoIds: bomberoIdsList,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      maquinista: json['maquinista'] != null && json['maquinista'] is Map
          ? UserModel.fromJson(json['maquinista'] as Map<String, dynamic>)
          : null,
      obac: json['obac'] != null && json['obac'] is Map
          ? UserModel.fromJson(json['obac'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roster_week_id': rosterWeekId,
      'guard_date': guardDate.toIso8601String().split('T')[0],
      'shift_period': shiftPeriod,
      'maquinista_id': maquinistaId,
      'obac_id': obacId,
      'bombero_ids': bomberoIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get total assigned count
  int get assignedCount {
    int count = 0;
    if (maquinistaId != null) count++;
    if (obacId != null) count++;
    count += bomberoIds.length;
    return count;
  }

  /// Check if roster is full (10 people)
  bool get isFull => assignedCount >= 10;

  /// Get available slots
  int get availableSlots => 10 - assignedCount;
  
  /// Alias for assignedCount (for compatibility)
  int get totalAssigned => assignedCount;
  
  /// Check if roster is complete (same as isFull)
  bool get isComplete => isFull;
  
  /// Get all assigned user IDs
  List<String> get allAssignedIds {
    final ids = <String>[];
    if (maquinistaId != null) ids.add(maquinistaId!);
    if (obacId != null) ids.add(obacId!);
    ids.addAll(bomberoIds);
    return ids;
  }
  
  /// Get gender distribution from assigned users
  Map<String, int> getGenderDistribution() {
    int males = 0;
    int females = 0;
    
    if (maquinista != null) {
      if (maquinista!.gender == Gender.male) males++; else females++;
    }
    if (obac != null) {
      if (obac!.gender == Gender.male) males++; else females++;
    }
    for (final bombero in bomberos) {
      if (bombero.gender == Gender.male) males++; else females++;
    }
    
    return {'males': males, 'females': females};
  }
  
  /// Validate gender distribution (at least 1 of each if >= 2 assigned)
  bool isGenderDistributionValid() {
    if (assignedCount < 2) return true;
    
    final dist = getGenderDistribution();
    return dist['males']! > 0 && dist['females']! > 0;
  }
}


/// Compliance analysis for weekly night guard roster
class GuardComplianceAnalysis {
  final DateTime weekStartDate;
  final Map<String, int> userShiftCounts; // userId -> shift count
  final List<UserComplianceStatus> complianceStatus;

  GuardComplianceAnalysis({
    required this.weekStartDate,
    required this.userShiftCounts,
    required this.complianceStatus,
  });

  /// Get users not meeting minimum requirements
  List<UserComplianceStatus> get usersNotMeetingMinimum {
    return complianceStatus.where((status) => status.deficit > 0).toList();
  }

  /// Get users exceeding requirements
  List<UserComplianceStatus> get usersExceedingMinimum {
    return complianceStatus.where((status) => status.surplus > 0).toList();
  }

  /// Get users meeting exact requirements
  List<UserComplianceStatus> get usersMeetingMinimum {
    return complianceStatus
        .where((status) => status.deficit == 0 && status.surplus == 0)
        .toList();
  }
}

/// Individual user compliance status
class UserComplianceStatus {
  final UserModel user;
  final int requiredShifts; // Based on marital status
  final int assignedShifts;
  final int deficit; // Negative if below minimum
  final int surplus; // Positive if above minimum

  UserComplianceStatus({
    required this.user,
    required this.requiredShifts,
    required this.assignedShifts,
  })  : deficit = requiredShifts > assignedShifts
            ? requiredShifts - assignedShifts
            : 0,
        surplus = assignedShifts > requiredShifts
            ? assignedShifts - requiredShifts
            : 0;

  bool get meetingMinimum => deficit == 0;
  bool get belowMinimum => deficit > 0;
  bool get aboveMinimum => surplus > 0;

  /// Display string for compliance (e.g., "-2", "+3", "0")
  String get complianceDisplay {
    if (deficit > 0) return '-$deficit';
    if (surplus > 0) return '+$surplus';
    return '0';
  }
}
