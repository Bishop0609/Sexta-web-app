import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:sexta_app/models/guard_attendance_model.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/services/auth_service.dart';

/// Service for managing guard attendance (FDS, Diurna, Nocturna)
class GuardAttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // GUARDIAS FDS (Weekend/Holiday Guards)
  // ============================================================================

  /// Create FDS guard attendance
  Future<Map<String, dynamic>> createFdsAttendance({
    required DateTime guardDate,
    required String shiftPeriod,
    String? maquinista1Id,
    String? maquinista2Id,
    String? obacId,
    required List<String?> bomberoIds,
    String? observations,
  }) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Validate it's a weekend or holiday
    if (!isWeekendOrHoliday(guardDate)) {
      throw Exception('Las guardias FDS solo pueden registrarse en fines de semana o feriados');
    }

    // Check for duplicates
    final isDuplicate = await isGuardAlreadyRegistered(
      AppConstants.guardAttendanceFdsTable,
      guardDate,
      shiftPeriod,
    );
    if (isDuplicate) {
      throw Exception('Guardia ya registrada');
    }

    final data = {
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
      'created_by': userId,
    };

    final response = await _supabase
        .from(AppConstants.guardAttendanceFdsTable)
        .insert(data)
        .select()
        .single();

    return response;
  }

  /// Get FDS guard attendance for a specific date and period
  Future<GuardAttendanceFds?> getFdsAttendance(
    DateTime date,
    String period,
  ) async {
    final response = await _supabase
        .from(AppConstants.guardAttendanceFdsTable)
        .select()
        .eq('guard_date', date.toIso8601String().split('T')[0])
        .eq('shift_period', period)
        .maybeSingle();

    if (response == null) return null;
    return GuardAttendanceFds.fromJson(response);
  }

  /// Get FDS guard attendance history
  Future<List<GuardAttendanceFds>> getFdsAttendanceHistory({
    int limit = 30,
  }) async {
    final response = await _supabase
        .from(AppConstants.guardAttendanceFdsTable)
        .select()
        .order('guard_date', ascending: false)
        .order('shift_period', ascending: true)
        .limit(limit);

    return (response as List).map((e) => GuardAttendanceFds.fromJson(e)).toList();
  }

  /// Update FDS guard attendance
  Future<void> updateFdsAttendance(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _supabase
        .from(AppConstants.guardAttendanceFdsTable)
        .update(data)
        .eq('id', id);
  }

  /// Delete FDS guard attendance
  Future<void> deleteFdsAttendance(String id) async {
    await _supabase
        .from(AppConstants.guardAttendanceFdsTable)
        .delete()
        .eq('id', id);
  }

  // ============================================================================
  // GUARDIAS DIURNAS (Weekday Guards)
  // ============================================================================

  /// Create Diurna guard attendance
  Future<Map<String, dynamic>> createDiurnaAttendance({
    required DateTime guardDate,
    required String shiftPeriod,
    String? maquinista1Id,
    String? maquinista2Id,
    String? obacId,
    required List<String?> bomberoIds,
    String? observations,
  }) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Validate it's a weekday (not weekend or holiday)
    if (!isWeekday(guardDate)) {
      throw Exception('Las guardias diurnas solo pueden registrarse en días de semana (lunes a viernes, no feriados)');
    }

    // Check for duplicates
    final isDuplicate = await isGuardAlreadyRegistered(
      AppConstants.guardAttendanceDiurnaTable,
      guardDate,
      shiftPeriod,
    );
    if (isDuplicate) {
      throw Exception('Guardia ya registrada');
    }

    final data = {
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
      'created_by': userId,
    };

    final response = await _supabase
        .from(AppConstants.guardAttendanceDiurnaTable)
        .insert(data)
        .select()
        .single();

    return response;
  }

  /// Get Diurna guard attendance for a specific date and period
  Future<GuardAttendanceDiurna?> getDiurnaAttendance(
    DateTime date,
    String period,
  ) async {
    final response = await _supabase
        .from(AppConstants.guardAttendanceDiurnaTable)
        .select()
        .eq('guard_date', date.toIso8601String().split('T')[0])
        .eq('shift_period', period)
        .maybeSingle();

    if (response == null) return null;
    return GuardAttendanceDiurna.fromJson(response);
  }

  /// Get Diurna guard attendance history
  Future<List<GuardAttendanceDiurna>> getDiurnaAttendanceHistory({
    int limit = 30,
  }) async {
    final response = await _supabase
        .from(AppConstants.guardAttendanceDiurnaTable)
        .select()
        .order('guard_date', ascending: false)
        .order('shift_period', ascending: true)
        .limit(limit);

    return (response as List).map((e) => GuardAttendanceDiurna.fromJson(e)).toList();
  }

  /// Update Diurna guard attendance
  Future<void> updateDiurnaAttendance(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _supabase
        .from(AppConstants.guardAttendanceDiurnaTable)
        .update(data)
        .eq('id', id);
  }

  /// Delete Diurna guard attendance
  Future<void> deleteDiurnaAttendance(String id) async {
    await _supabase
        .from(AppConstants.guardAttendanceDiurnaTable)
        .delete()
        .eq('id', id);
  }

  // ============================================================================
  // GUARDIAS NOCTURNAS (Night Guards)
  // ============================================================================

  /// Create Nocturna guard attendance
  Future<Map<String, dynamic>> createNocturnaAttendance({
    required DateTime guardDate,
    String? rosterWeekId,
    String? maquinistaId,
    String? obacId,
    required List<String?> bomberoIds,
    List<Map<String, dynamic>>? records,
    String? observations,
  }) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Check for duplicates
    final isDuplicate = await isGuardAlreadyRegistered(
      AppConstants.guardAttendanceNocturnaTable,
      guardDate,
      null,
    );
    if (isDuplicate) {
      throw Exception('Guardia ya registrada');
    }

    final data = {
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
      'created_by': userId,
    };

    final response = await _supabase
        .from(AppConstants.guardAttendanceNocturnaTable)
        .insert(data)
        .select()
        .single();

    // Insert attendance records if provided
    if (records != null && records.isNotEmpty) {
      final recordsData = records.map((record) {
        return {
          'guard_attendance_id': response['id'],
          ...record,
        };
      }).toList();

      await _supabase
          .from(AppConstants.guardAttendanceNocturnaRecordsTable)
          .insert(recordsData);
    }

    return response;
  }

  /// Get Nocturna guard attendance for a specific date
  Future<GuardAttendanceNocturna?> getNocturnaAttendance(DateTime date) async {
    final response = await _supabase
        .from(AppConstants.guardAttendanceNocturnaTable)
        .select()
        .eq('guard_date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    if (response == null) return null;

    final attendance = GuardAttendanceNocturna.fromJson(response);

    // Load attendance records
    final recordsResponse = await _supabase
        .from(AppConstants.guardAttendanceNocturnaRecordsTable)
        .select()
        .eq('guard_attendance_id', attendance.id);

    attendance.records = (recordsResponse as List)
        .map((e) => GuardAttendanceRecord.fromJson(e))
        .toList();

    return attendance;
  }

  /// Get Nocturna guard attendance history
  Future<List<GuardAttendanceNocturna>> getNocturnaAttendanceHistory({
    int limit = 30,
  }) async {
    final response = await _supabase
        .from(AppConstants.guardAttendanceNocturnaTable)
        .select()
        .order('guard_date', ascending: false)
        .limit(limit);

    return (response as List).map((e) => GuardAttendanceNocturna.fromJson(e)).toList();
  }

  /// Update Nocturna guard attendance
  Future<void> updateNocturnaAttendance(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _supabase
        .from(AppConstants.guardAttendanceNocturnaTable)
        .update(data)
        .eq('id', id);
  }

  /// Delete Nocturna guard attendance
  Future<void> deleteNocturnaAttendance(String id) async {
    // Delete records first (cascade should handle this, but being explicit)
    await _supabase
        .from(AppConstants.guardAttendanceNocturnaRecordsTable)
        .delete()
        .eq('guard_attendance_id', id);

    await _supabase
        .from(AppConstants.guardAttendanceNocturnaTable)
        .delete()
        .eq('id', id);
  }

  // ============================================================================
  // VALIDATION UTILITIES
  // ============================================================================

  /// Check if guard is already registered
  Future<bool> isGuardAlreadyRegistered(
    String tableName,
    DateTime date,
    String? period,
  ) async {
    var query = _supabase
        .from(tableName)
        .select('id')
        .eq('guard_date', date.toIso8601String().split('T')[0]);

    if (period != null) {
      query = query.eq('shift_period', period);
    }

    final response = await query.maybeSingle();
    return response != null;
  }

  /// Check if user can edit guard attendance
  bool canEditGuardAttendance({
    required String createdBy,
    required DateTime createdAt,
    required String currentUserId,
    required DateTime now,
  }) {
    if (currentUserId != createdBy) return false;
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < AppConstants.guardEditWindowHours;
  }

  /// Check if guard is within view window
  bool canViewGuardAttendance({
    required DateTime createdAt,
    required DateTime now,
  }) {
    final hoursSinceCreation = now.difference(createdAt).inHours;
    return hoursSinceCreation < AppConstants.guardViewWindowHours;
  }

  /// Check if date is weekend or holiday
  bool isWeekendOrHoliday(DateTime date) {
    // Weekend check
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return true;
    }

    // TODO: Add holiday check from database or configuration
    // For now, just check weekends
    return false;
  }

  /// Check if date is weekday (not weekend or holiday)
  bool isWeekday(DateTime date) {
    return !isWeekendOrHoliday(date);
  }

  /// Get guard start date for night guards
  /// If current time is before 08:00, the guard date is yesterday
  /// Otherwise, it's today
  DateTime getGuardStartDate(DateTime currentTime) {
    if (currentTime.hour < AppConstants.nightGuardEndHour) {
      return currentTime.subtract(const Duration(days: 1));
    }
    return currentTime;
  }

  /// Validate today's date for normal users
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Validate yesterday's date (for night guards)
  bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
