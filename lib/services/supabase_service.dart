import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:intl/intl.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  // ===========================================================================
  // AUTHENTICATION & CREDENTIALS
  // ===========================================================================

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<UserModel?> getUserByRut(String rut) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('rut', rut)
          .maybeSingle();
      return response != null ? UserModel.fromJson(response) : null;
    } catch (e) {
      print('Error getting user by RUT: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAuthCredentials(String userId) async {
    try {
      final response = await client
          .from('auth_credentials')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting auth credentials: $e');
      return null;
    }
  }

  Future<void> createAuthCredentials(String userId, String passwordHash) async {
    await client.from('auth_credentials').insert({
      'user_id': userId,
      'password_hash': passwordHash,
      'failed_attempts': 0,
    });
  }

  // ===========================================================================
  // USER MANAGEMENT
  // ===========================================================================

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers({bool includeInactive = false}) async {
    try {
      var query = client.from('users').select();
      if (!includeInactive) {
        query = query.eq('status', 'activo');
      }
      final response = await query.order('victor_number');
      return (response as List).map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Future<UserModel> createUser(UserModel user) async {
    final userData = user.toJson();
    userData.remove('id'); // Let Supabase auto-generate UUID
    userData.remove('created_at'); // Permitir que Postgres asigne NOW()
    userData.remove('updated_at'); // Permitir que Postgres asigne NOW()
    final response = await client.from('users').insert(userData).select().single();
    return UserModel.fromJson(response);
  }

  Future<void> updateUser(UserModel user) async {
    await updateUserProfile(user); 
  }

  /// Actualiza solo los datos de perfil del usuario.
  /// NO modifica campos de tesorería (payment_start_date, is_student, etc.)
  /// — esos son responsabilidad exclusiva de TreasuryUserConfigTab.
  Future<void> updateUserProfile(UserModel user) async {
    await client.from('users').update({
      'full_name': user.fullName,
      'gender': user.gender == Gender.male ? 'M' : 'F',
      'marital_status': user.maritalStatus == MaritalStatus.single ? 'single' : 'married',
      'rank': user.rank,
      'role': user.role.name,
      'victor_number': user.victorNumber,
      'registro_compania': user.registroCompania,
      'rut': user.rut,
      'email': user.email,
    }).eq('id', user.id);
  }

  Future<void> deleteUser(String userId) async {
    await client.from('users').delete().eq('id', userId);
  }

  /// Actualiza solo los campos de configuración de tesorería.
  /// NO modifica datos de perfil (nombre, cargo, rol, etc.)
  Future<void> updateTreasuryConfig(UserModel user) async {
    await client.from('users').update({
      'is_student': user.isStudent,
      'payment_start_date': user.paymentStartDate?.toIso8601String(),
      'student_start_date': user.studentStartDate?.toIso8601String(),
      'student_end_date': user.studentEndDate?.toIso8601String(),
    }).eq('id', user.id);
  }

  // ===========================================================================
  // PERMISOS
  // ===========================================================================

   Future<List<Map<String, dynamic>>> getPermissionsByUser(String userId) async {
    return await client.from('permissions').select('*, user:users!user_id(*), activity:activities!actividad_id(title, activity_date, activity_type)').eq('user_id', userId).order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getPermissionsByStatus(String status) async {
     return await client.from('permissions')
     .select('*, user:users!user_id(*), activity:activities!actividad_id(title, activity_date, activity_type)')
     .eq('status', status)
     .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> createPermission(Map<String, dynamic> data) async {
    return await client.from('permissions').insert(data).select().single();
  }

  Future<void> updatePermission(String id, Map<String, dynamic> data) async {
    await client.from('permissions').update(data).eq('id', id);
  }
  
  Future<void> updatePermissionStatus(String id, String status, String reviewedBy, {String? reason}) async {
    final Map<String, dynamic> data = {
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': DateTime.now().toIso8601String(),
    };
    if (reason != null) data['rejection_reason'] = reason;
    await client.from('permissions').update(data).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getActivePermissions(String userId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return await client.from('permissions')
      .select()
      .eq('user_id', userId)
      .eq('status', 'approved')
      .eq('tipo_permiso', 'fecha')
      .lte('start_date', dateStr)
      .gte('end_date', dateStr);
  }

  Future<List<Map<String, dynamic>>> getAllActivePermissionsForDate(DateTime date) async {
     final dateStr = DateFormat('yyyy-MM-dd').format(date);
     return await client.from('permissions')
      .select('*, user:users!user_id(*), activity:activities!actividad_id(title, activity_date, activity_type)')
      .eq('status', 'approved')
      .eq('tipo_permiso', 'fecha')
      .lte('start_date', dateStr)
      .gte('end_date', dateStr);
  }

  Future<List<Map<String, dynamic>>> getApprovedPermissionsBetweenDates(DateTime start, DateTime end, {String? userId}) async {
    return await getPermissionsByStatusBetweenDates('approved', start, end, userId: userId);
  }

  Future<List<Map<String, dynamic>>> getPermissionsByStatusBetweenDates(
    String status,
    DateTime start,
    DateTime end, {
    String? userId,
  }) async {
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);

    var query = client
        .from('permissions')
        .select('*, user:users!user_id(*), activity:activities!actividad_id(title, activity_date, activity_type)')
        .eq('status', status)
        .or('and(start_date.gte.$startStr,start_date.lte.$endStr),'
            'and(end_date.gte.$startStr,end_date.lte.$endStr),'
            'and(start_date.lte.$startStr,end_date.gte.$endStr)');

    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    return await query;
  }

  // ===========================================================================
  // ACTIVITIES & ACT TYPES
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getAllActTypes() async {
    return await client.from('act_types')
      .select()
      .eq('is_active', true)
      .order('orden', ascending: true)
      .order('name');
  }

  Future<void> createActType(Map<String, dynamic> data) async {
    await client.from('act_types').insert(data);
  }

  Future<void> updateActType(String id, Map<String, dynamic> data) async {
    await client.from('act_types').update(data).eq('id', id);
  }
  Future<void> deleteActType(String id) async {
    await client.from('act_types').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivities(DateTime startDate, DateTime endDate) async {
    final start = DateFormat('yyyy-MM-dd').format(startDate);
    final end = DateFormat('yyyy-MM-dd').format(endDate);

    try {
      print('[SupabaseService] getWeeklyActivities: $start to $end');
      final response = await client
          .from('activities')
          .select('*, creator:users!created_by(*)')
          .gte('activity_date', start)
          .lte('activity_date', end)
          .order('activity_date', ascending: true); // Retain original order by activity_date
      final activities = List<Map<String, dynamic>>.from(response);
      print('[SupabaseService] getWeeklyActivities: Found ${activities.length} activities');
      return activities;
    } catch (e) {
      print('❌ Error loading activities: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingActivities({int limit = 50}) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await client.from('activities')
      .select('*, creator:users!created_by(*)')
      .gte('activity_date', today)
      .order('activity_date')
      .limit(limit);
  }

  Future<List<Map<String, dynamic>>> createActivity(Map<String, dynamic> data) async {
      final response = await client.from('activities').insert(data).select();
      return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateActivity(String id, Map<String, dynamic> data, String userId) async {
     final Map<String, dynamic> updateData = Map.from(data);
     updateData['modified_by'] = userId; 
     updateData['modified_at'] = DateTime.now().toIso8601String();
     await client.from('activities').update(updateData).eq('id', id);
  }

  Future<void> deleteActivity(String id) async {
    await client.from('activities').delete().eq('id', id);
  }

  // ===========================================================================
  // ATTENDANCE
  // ===========================================================================

  Future<String> createAttendanceEvent(Map<String, dynamic> data) async {
    final response = await client.from('attendance_events').insert(data).select().single();
    return response['id'] as String;
  }
  
  Future<void> createAttendanceRecords(List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return;
    await client.from('attendance_records').insert(records);
  }

  Future<List<Map<String, dynamic>>> getAttendanceEvents() async {
    return await client.from('attendance_events')
      .select('*, act_type:act_types(*), creator:users!created_by(*)')
      .order('event_date', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecordsByEvent(String eventId) async {
    return await client.from('attendance_records')
      .select('*, user:users!user_id(*)')
      .eq('event_id', eventId)
      .order('user(victor_number)'); 
  }

  Future<void> updateAttendanceRecord(String id, Map<String, dynamic> data) async {
    await client.from('attendance_records').update(data).eq('id', id);
  }

  Future<void> updateAttendanceRecord2(String id, String status, bool isLocked) async {
    final Map<String, dynamic> data = {
      'status': status,
      'is_locked': isLocked,
    };
    await client.from('attendance_records').update(data).eq('id', id);
  }

  Future<void> deleteAttendanceEvent(String id) async {
    await client.from('attendance_records').delete().eq('event_id', id);
    await client.from('attendance_events').delete().eq('id', id);
  }

  Future<void> updateAttendanceEvent(
    String id, 
    DateTime date, 
    String actTypeId, 
    String modifiedBy, 
    {String? subtype, String? location}
  ) async {
    final Map<String, dynamic> data = {
      'event_date': date.toIso8601String().split('T')[0],
      'act_type_id': actTypeId,
      'modified_by': modifiedBy,
      'modified_at': DateTime.now().toIso8601String(),
    };
    if (subtype != null) data['subtype'] = subtype;
    if (location != null) data['location'] = location;
    
    await client.from('attendance_events').update(data).eq('id', id);
  }

  Future<void> getAttendanceHistory(String userId) async {
      // Stub as used in previous implementation
  }

  // ===========================================================================
  // SHIFTS (GUARDIAS)
  // ===========================================================================

  Future<int> getShiftRegistrationCount(DateTime date, String gender) async {
     final dateStr = DateFormat('yyyy-MM-dd').format(date);
     final count = await client.from('shift_registrations')
       .count(CountOption.exact)
       .eq('shift_date', dateStr)
       .eq('user.gender', gender == 'M' ? 'M' : 'F');
     return count;
  }

  Future<void> createShiftRegistration(Map<String, dynamic> data) async {
    await client.from('shift_registrations').insert(data);
  }

  Future<List<Map<String, dynamic>>> getShiftConfigurations() async {
    return await client.from('shift_configurations').select().eq('active', true).order('created_at');
  }

  Future<List<Map<String, dynamic>>> getShiftRegistrations(String configId) async {
    return await client.from('shift_registrations')
      .select('*, user:users!user_id(*)')
      .order('shift_date')
      .order('created_at'); 
  }

  Future<void> deleteShiftRegistration(String id) async {
    await client.from('shift_registrations').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getShiftAttendance(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return await client.from('shift_attendance')
      .select('*, user:users!user_id(*), replacement:users!replacement_user_id(*)')
      .eq('shift_date', dateStr);
  }

  Future<void> createShiftAttendance(Map<String, dynamic> data) async {
    await client.from('shift_attendance').insert(data);
  }

  /// Retorna las próximas guardias nocturnas asignadas al usuario
  /// dentro de los próximos 15 días (máx 3)
  Future<List<Map<String, dynamic>>> getNextUserShifts(String userId) async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final limitDate = DateTime.now().add(const Duration(days: 15));
      final limitStr = DateFormat('yyyy-MM-dd').format(limitDate);

      final guards = await client
          .from('guard_roster_daily')
          .select('guard_date, maquinista_id, obac_id, bombero_ids, '
                  'roster_week:guard_roster_weekly!roster_week_id(status)')
          .eq('shift_period', 'NOCTURNA')
          .gte('guard_date', todayStr)
          .lte('guard_date', limitStr)
          .order('guard_date', ascending: true);

      final List<Map<String, dynamic>> result = [];

      for (final guard in guards) {
        final rosterWeek = guard['roster_week'];
        if (rosterWeek == null || rosterWeek['status'] != 'published') continue;

        if (_isUserInNocturnaGuard(userId, guard)) {
          result.add({
            'shift_date': guard['guard_date'],
            'guard_type': 'Nocturna',
          });
          if (result.length >= 3) break;
        }
      }

      return result;
    } catch (e) {
      print('[getNextUserShifts] Error: $e');
      return [];
    }
  }
  
  /// Helper: Check if user is assigned in FDS/Diurna guard
  bool _isUserInGuard(String userId, Map<String, dynamic> guard) {
    if (guard['maquinista_1_id'] == userId) return true;
    if (guard['maquinista_2_id'] == userId) return true;
    if (guard['obac_id'] == userId) return true;
    
    // Check all 10 bombero columns
    for (int i = 1; i <= 10; i++) {
      if (guard['bombero_${i}_id'] == userId) return true;
    }
    
    return false;
  }
  
  /// Helper: Check if user is assigned in Nocturna guard
  bool _isUserInNocturnaGuard(String userId, Map<String, dynamic> guard) {
    if (guard['maquinista_id'] == userId) return true;
    if (guard['obac_id'] == userId) return true;

    final bomberoIds = guard['bombero_ids'];
    if (bomberoIds is List) {
      return bomberoIds.any((id) => id.toString() == userId);
    }
    return false;
  }

}
