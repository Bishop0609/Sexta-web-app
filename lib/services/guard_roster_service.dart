import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:sexta_app/models/guard_roster_model.dart';
import 'package:sexta_app/models/guard_availability_model.dart';
import 'package:sexta_app/models/user_model.dart';

/// Service for managing night guard rosters and availability
class GuardRosterService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // AVAILABILITY MANAGEMENT
  // ============================================================================

  /// Register user availability for a specific date
  Future<Map<String, dynamic>> registerAvailability({
    required String userId,
    required DateTime date,
    required bool isDriver,
  }) async {
    // Validar capacidad antes de insertar
    final validation = await canUserRegister(
      userId: userId,
      date: date,
      isDriver: isDriver,
    );

    if (validation['allowed'] != true) {
      throw Exception(validation['reason'] ?? 'No se puede registrar disponibilidad');
    }

    final data = {
      'user_id': userId,
      'available_date': date.toIso8601String().split('T')[0],
      'is_driver': isDriver,
    };

    final response = await _supabase
        .from(AppConstants.guardAvailabilityTable)
        .insert(data)
        .select()
        .single();

    return response;
  }

  /// Remove user availability
  Future<void> removeAvailability(String availabilityId) async {
    await _supabase
        .from(AppConstants.guardAvailabilityTable)
        .delete()
        .eq('id', availabilityId);
  }

  /// Get availability for a specific date
  Future<List<GuardAvailability>> getAvailabilityForDate(DateTime date) async {
    final response = await _supabase
        .from(AppConstants.guardAvailabilityTable)
        .select('*, user:users!user_id(*)')
        .eq('available_date', date.toIso8601String().split('T')[0])
        .order('is_driver', ascending: false)
        .order('created_at', ascending: true);

    return (response as List).map((e) => GuardAvailability.fromJson(e)).toList();
  }

  /// Get availability for a week (Monday to Sunday)
  Future<Map<DateTime, List<GuardAvailability>>> getWeeklyAvailability(
    DateTime weekStart, {
    String guardType = 'nocturna',
    String? shiftPeriod,
  }) async {
    final weekEnd = DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

    var query = _supabase
        .from(AppConstants.guardAvailabilityTable)
        .select('*, user:users!user_id(*)')
        .gte('available_date', weekStart.toIso8601String().split('T')[0])
        .lte('available_date', weekEnd.toIso8601String().split('T')[0])
        .eq('guard_type', guardType);

    query = query.eq('shift_period', shiftPeriod ?? 'NOCTURNA');

    final response = await query
        .order('available_date', ascending: true)
        .order('is_driver', ascending: false);

    final availabilities = (response as List)
        .map((e) => GuardAvailability.fromJson(e))
        .toList();

    // Group by date
    final Map<DateTime, List<GuardAvailability>> grouped = {};
    for (var availability in availabilities) {
      final date = availability.availableDate;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(availability);
    }

    return grouped;
  }

  /// Get user's availability registrations
  Future<List<GuardAvailability>> getUserAvailability(
    String userId, {
    DateTime? startDate,
  }) async {
    var query = _supabase
        .from(AppConstants.guardAvailabilityTable)
        .select()
        .eq('user_id', userId);

    if (startDate != null) {
      query = query.gte('available_date', startDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('available_date', ascending: true);
    return (response as List).map((e) => GuardAvailability.fromJson(e)).toList();
  }

  // ============================================================================
  // CAPACITY VALIDATION
  // ============================================================================

  /// Get capacity information for a specific date
  Future<Map<String, dynamic>> getDateCapacity(DateTime date) async {
    final response = await _supabase.rpc(
      'get_day_capacity',
      params: {'p_date': date.toIso8601String().split('T')[0]},
    );
    return response as Map<String, dynamic>;
  }

  /// Get capacity information for a date range
  Future<List<Map<String, dynamic>>> getRangeCapacity(
    DateTime start,
    DateTime end, {
    String guardType = 'nocturna',
    String? shiftPeriod,
  }) async {
    final response = await _supabase.rpc(
      'get_range_capacity',
      params: {
        'p_start': start.toIso8601String().split('T')[0],
        'p_end': end.toIso8601String().split('T')[0],
        'p_guard_type': guardType,
        'p_shift_period': shiftPeriod ?? 'NOCTURNA',
      },
    );
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Check if a user can register for a specific date
  Future<Map<String, dynamic>> canUserRegister({
    required String userId,
    required DateTime date,
    required bool isDriver,
  }) async {
    // Obtener capacidad del día
    final capacity = await getDateCapacity(date);
    final total = capacity['total'] as int? ?? 0;
    final males = capacity['males'] as int? ?? 0;
    final females = capacity['females'] as int? ?? 0;
    final hasDriver = capacity['has_driver'] as bool? ?? false;

    // Obtener género del usuario
    final userResponse = await _supabase
        .from('users')
        .select('gender')
        .eq('id', userId)
        .single();
    
    final userGender = userResponse['gender'] as String?;

    // Validaciones
    if (total >= 10) {
      return {'allowed': false, 'reason': 'Día completo (10/10)'};
    }

    if (isDriver && hasDriver) {
      return {'allowed': false, 'reason': 'Ya hay un maquinista inscrito'};
    }

    if (userGender == 'M' && males >= 6) {
      return {'allowed': false, 'reason': 'Cupo de hombres completo (6/6)'};
    }

    if (userGender == 'F' && females >= 4) {
      return {'allowed': false, 'reason': 'Cupo de mujeres completo (4/4)'};
    }

    return {'allowed': true, 'reason': ''};
  }

  // ============================================================================
  // WEEKLY ROSTER MANAGEMENT
  // ============================================================================

  /// Create weekly roster
  Future<GuardRosterWeekly> createWeeklyRoster({
    required DateTime weekStart,
    required DateTime weekEnd,
    required String createdBy,
    String guardType = 'nocturna',
  }) async {
    final data = {
      'week_start_date': weekStart.toIso8601String().split('T')[0],
      'week_end_date': weekEnd.toIso8601String().split('T')[0],
      'status': 'draft',
      'guard_type': guardType,
      'created_by': createdBy,
    };

    final response = await _supabase
        .from(AppConstants.guardRosterWeeklyTable)
        .insert(data)
        .select()
        .single();

    return GuardRosterWeekly.fromJson(response);
  }

  /// Get weekly roster
  Future<GuardRosterWeekly?> getWeeklyRoster(
    DateTime weekStart, {
    String guardType = 'nocturna',
  }) async {
    final response = await _supabase
        .from(AppConstants.guardRosterWeeklyTable)
        .select()
        .eq('week_start_date', weekStart.toIso8601String().split('T')[0])
        .eq('guard_type', guardType)
        .maybeSingle();

    if (response == null) return null;
    return GuardRosterWeekly.fromJson(response);
  }

  /// Get all weekly rosters
  Future<List<GuardRosterWeekly>> getAllWeeklyRosters({
    int limit = 10,
  }) async {
    final response = await _supabase
        .from(AppConstants.guardRosterWeeklyTable)
        .select()
        .order('week_start_date', ascending: false)
        .limit(limit);

    return (response as List).map((e) => GuardRosterWeekly.fromJson(e)).toList();
  }

  /// Publish weekly roster
  Future<void> publishWeeklyRoster(String rosterId) async {
    await _supabase
        .from(AppConstants.guardRosterWeeklyTable)
        .update({'status': 'published'})
        .eq('id', rosterId);
  }

  /// Delete weekly roster
  Future<void> deleteWeeklyRoster(String rosterId) async {
    await _supabase
        .from(AppConstants.guardRosterWeeklyTable)
        .delete()
        .eq('id', rosterId);
  }

  // ============================================================================
  // DAILY ROSTER MANAGEMENT
  // ============================================================================

  /// Create or update daily roster
  Future<GuardRosterDaily> saveDailyRoster({
    required String rosterWeekId,
    required DateTime guardDate,
    String? maquinistaId,
    String? obacId,
    required List<String> bomberoIds,
    String? shiftPeriod,
  }) async {
    // Validate total count (max 10)
    int totalCount = 0;
    if (maquinistaId != null) totalCount++;
    if (obacId != null) totalCount++;
    totalCount += bomberoIds.length;

    if (totalCount > AppConstants.maxTotalNightGuard) {
      throw Exception('Máximo ${AppConstants.maxTotalNightGuard} personas por guardia nocturna');
    }

    final data = {
      'roster_week_id': rosterWeekId,
      'guard_date': guardDate.toIso8601String().split('T')[0],
      'shift_period': shiftPeriod ?? 'NOCTURNA',
      'maquinista_id': maquinistaId,
      'obac_id': obacId,
      'bombero_ids': bomberoIds,
    };

    // Upsert (insert or update if exists)
    final response = await _supabase
        .from(AppConstants.guardRosterDailyTable)
        .upsert(data, onConflict: 'roster_week_id,guard_date,shift_period')
        .select()
        .single();

    return GuardRosterDaily.fromJson(response);
  }

  /// Get daily rosters for a week
  Future<List<GuardRosterDaily>> getDailyRostersForWeek(
    String rosterWeekId,
  ) async {
    final response = await _supabase
        .from(AppConstants.guardRosterDailyTable)
        .select('*, maquinista:users!maquinista_id(*), obac:users!obac_id(*)')
        .eq('roster_week_id', rosterWeekId)
        .order('guard_date', ascending: true);

    return (response as List).map((e) => GuardRosterDaily.fromJson(e)).toList();
  }

  /// Get daily roster for specific date
  Future<GuardRosterDaily?> getDailyRoster(
    String rosterWeekId,
    DateTime date,
  ) async {
    final response = await _supabase
        .from(AppConstants.guardRosterDailyTable)
        .select()
        .eq('roster_week_id', rosterWeekId)
        .eq('guard_date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    if (response == null) return null;
    return GuardRosterDaily.fromJson(response);
  }

  // ============================================================================
  // ROSTER GENERATION & COMPLIANCE
  // ============================================================================

  /// Selecciona OBAC según rango militar o antigüedad
  /// Prioridad: Capitán > Teniente 1° > Teniente 2° > Teniente 3° > menor registroCompania
  String? _selectObac(List<GuardAvailability> available) {
    if (available.isEmpty) return null;

    // Orden de prioridad de rangos
    final rankPriority = [
      'Capitán',
      'Teniente 1',
      'Teniente 2',
      'Teniente 3',
    ];

    // Buscar por rango en orden de prioridad
    for (final rankPrefix in rankPriority) {
      final officer = available.firstWhere(
        (a) => a.user?.rank?.contains(rankPrefix) ?? false,
        orElse: () => GuardAvailability(
          id: '',
          userId: '',
          availableDate: DateTime.now(),
          isDriver: false,
          createdAt: DateTime.now(),
        ),
      );
      if (officer.id.isNotEmpty) return officer.userId;
    }

    // Si no hay oficial, tomar el de menor registroCompania (más antiguo)
    GuardAvailability? mostSenior;
    int? lowestRegistro;

    for (final a in available) {
      final registroStr = a.user?.registroCompania;
      if (registroStr != null && registroStr.isNotEmpty) {
        final registro = int.tryParse(registroStr);
        if (registro != null) {
          if (lowestRegistro == null || registro < lowestRegistro) {
            lowestRegistro = registro;
            mostSenior = a;
          }
        }
      }
    }

    return mostSenior?.userId ?? available.first.userId;
  }

  /// Generate weekly roster automatically based on availability
  /// This assigns OBAC automatically and distributes shifts fairly
  Future<List<GuardRosterDaily>> generateWeeklyRoster({
    required String rosterWeekId,
    required DateTime weekStart,
    required List<UserModel> allUsers,
  }) async {
    final weekEnd = DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
    final dailyRosters = <GuardRosterDaily>[];

    // Get availability for the week
    final availabilityMap = await getWeeklyAvailability(weekStart);

    // Get user shift counts for compliance tracking
    final userShiftCounts = <String, int>{};
    for (var user in allUsers) {
      userShiftCounts[user.id] = 0;
    }

    // Process each day
    for (int i = 0; i < 7; i++) {
      final currentDate = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
      final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);
      
      // Buscar disponibilidad comparando solo fecha
      List<GuardAvailability> available = [];
      for (var entry in availabilityMap.entries) {
        final entryDate = DateTime(entry.key.year, entry.key.month, entry.key.day);
        if (entryDate == dateKey) {
          available = List.from(entry.value);
          break;
        }
      }
      
      if (available.isEmpty) continue;

      // Separate drivers and non-drivers
      final drivers = available.where((a) => a.isDriver).toList();
      final nonDrivers = available.where((a) => !a.isDriver).toList();

      // Select maquinista (prefer drivers)
      String? maquinistaId;
      if (drivers.isNotEmpty) {
        maquinistaId = drivers.first.userId;
        available.removeWhere((a) => a.userId == maquinistaId);
      }

      // Select OBAC (highest rank from remaining)
      final obacId = _selectObac(available);
      if (obacId != null) {
        available.removeWhere((a) => a.userId == obacId);
      }

      // Select up to 8 bomberos
      final bomberoIds = available
          .take(AppConstants.maxBomberosPerNightGuard)
          .map((a) => a.userId)
          .toList();

      // Save daily roster
      final dailyRoster = await saveDailyRoster(
        rosterWeekId: rosterWeekId,
        guardDate: currentDate,
        maquinistaId: maquinistaId,
        obacId: obacId,
        bomberoIds: bomberoIds,
      );

      dailyRosters.add(dailyRoster);

      // Update shift counts
      if (maquinistaId != null) {
        userShiftCounts[maquinistaId] = (userShiftCounts[maquinistaId] ?? 0) + 1;
      }
      if (obacId != null) {
        userShiftCounts[obacId] = (userShiftCounts[obacId] ?? 0) + 1;
      }
      for (var bomberoId in bomberoIds) {
        userShiftCounts[bomberoId] = (userShiftCounts[bomberoId] ?? 0) + 1;
      }
    }

    return dailyRosters;
  }

  /// Analyze compliance for a weekly roster
  Future<GuardComplianceAnalysis> analyzeCompliance({
    required String rosterWeekId,
    required DateTime weekStart,
    required List<UserModel> allUsers,
  }) async {
    // Get daily rosters
    final dailyRosters = await getDailyRostersForWeek(rosterWeekId);

    // Count shifts per user
    final userShiftCounts = <String, int>{};
    for (var roster in dailyRosters) {
      if (roster.maquinistaId != null) {
        userShiftCounts[roster.maquinistaId!] =
            (userShiftCounts[roster.maquinistaId!] ?? 0) + 1;
      }
      if (roster.obacId != null) {
        userShiftCounts[roster.obacId!] =
            (userShiftCounts[roster.obacId!] ?? 0) + 1;
      }
      for (var bomberoId in roster.bomberoIds) {
        userShiftCounts[bomberoId] = (userShiftCounts[bomberoId] ?? 0) + 1;
      }
    }

    // Calculate compliance status for each user
    final complianceStatus = <UserComplianceStatus>[];
    for (var user in allUsers) {
      final requiredShifts = user.maritalStatus == MaritalStatus.single
          ? AppConstants.shiftsPerWeekSingle
          : AppConstants.shiftsPerWeekMarried;
      final assignedShifts = userShiftCounts[user.id] ?? 0;

      complianceStatus.add(UserComplianceStatus(
        user: user,
        requiredShifts: requiredShifts,
        assignedShifts: assignedShifts,
      ));
    }

    return GuardComplianceAnalysis(
      weekStartDate: weekStart,
      userShiftCounts: userShiftCounts,
      complianceStatus: complianceStatus,
    );
  }

  /// Validate gender distribution for a daily roster
  bool validateGenderDistribution(List<UserModel> assignedUsers) {
    final males = assignedUsers.where((u) => u.gender == Gender.male).length;
    final females = assignedUsers.where((u) => u.gender == Gender.female).length;

    return males <= AppConstants.maxMalesPerNightGuard &&
        females <= AppConstants.maxFemalesPerNightGuard;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get Monday of the week for a given date
  DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Get Sunday of the week for a given date
  DateTime getWeekEnd(DateTime date) {
    final weekStart = getWeekStart(date);
    return DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
  }

  /// Check if user has already registered for a date
  Future<bool> hasUserRegistered(String userId, DateTime date) async {
    final response = await _supabase
        .from(AppConstants.guardAvailabilityTable)
        .select('id')
        .eq('user_id', userId)
        .eq('available_date', date.toIso8601String().split('T')[0])
        .maybeSingle();

    return response != null;
  }

  /// Get published daily roster for a specific date (for attendance taking)
  /// Returns null if no published roster exists for that date
  Future<GuardRosterDaily?> getPublishedDailyRosterForDate(
    DateTime date, {
    String guardType = 'nocturna',
    String? shiftPeriod,
  }) async {
    // First, find the weekly roster that contains this date
    final weekStart = getWeekStart(date);
    
    final weeklyRoster = await _supabase
        .from(AppConstants.guardRosterWeeklyTable)
        .select()
        .eq('week_start_date', weekStart.toIso8601String().split('T')[0])
        .eq('guard_type', guardType)
        .eq('status', 'published')
        .maybeSingle();

    if (weeklyRoster == null) return null;

    // Get the daily roster for this specific date with full user details
    var dailyQuery = _supabase
        .from(AppConstants.guardRosterDailyTable)
        .select('''
          *,
          maquinista:users!maquinista_id(*),
          obac:users!obac_id(*)
        ''')
        .eq('roster_week_id', weeklyRoster['id'])
        .eq('guard_date', date.toIso8601String().split('T')[0]);

    dailyQuery = dailyQuery.eq('shift_period', shiftPeriod ?? 'NOCTURNA');

    final response = await dailyQuery.maybeSingle();

    if (response == null) return null;

    // Load bomberos separately
    final dailyRoster = GuardRosterDaily.fromJson(response);
    
    // Load bombero users
    if (dailyRoster.bomberoIds.isNotEmpty) {
      final bomberosResponse = await _supabase
          .from('users')
          .select()
          .inFilter('id', dailyRoster.bomberoIds);
      
      dailyRoster.bomberos = (bomberosResponse as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
    }

    return dailyRoster;
  }

  /// Registrar disponibilidad para guardia FDS
  Future<void> registerFdsAvailability({
    required String userId,
    required DateTime date,
    required String shiftPeriod, // 'AM' o 'PM'
    required bool isDriver,
  }) async {
    await _supabase.from(AppConstants.guardAvailabilityTable).upsert(
      {
        'user_id': userId,
        'available_date': date.toIso8601String().split('T')[0],
        'guard_type': 'fds',
        'shift_period': shiftPeriod,
        'is_driver': isDriver,
      },
      onConflict: 'user_id,available_date,guard_type,shift_period',
    );
  }
}

