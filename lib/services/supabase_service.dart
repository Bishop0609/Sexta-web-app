import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:sexta_app/models/user_model.dart';

/// Singleton service for Supabase interactions
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  // ============================================
  // AUTHENTICATION
  // ============================================

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ============================================
  // USERS
  // ============================================

  Future<UserModel?> getUserProfile(String userId) async {
    final response = await client
        .from(AppConstants.usersTable)
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<List<UserModel>> getAllUsers() async {
    final response = await client
        .from(AppConstants.usersTable)
        .select();
    
    final users = (response as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
    
    // Ordenar por jerarquía de la compañía
    users.sort((a, b) {
      final orderA = _getRankOrder(a.rank);
      final orderB = _getRankOrder(b.rank);
      return orderA.compareTo(orderB);
    });
    
    return users;
  }
  
  /// Orden jerárquico de cargos en la compañía
  int _getRankOrder(String rank) {
    // Normalizar: trim y lowercase
    final normalized = rank.trim().toLowerCase();
    
    const rankOrder = {
      'director': 1,
      'directora': 1,
      'secretario': 2,
      'secretaria': 2,
      'tesorero': 3,
      'tesorera': 3,
      'capitán': 4,
      'capitan': 4,
      'teniente 1°': 5,
      'teniente 1': 5,
      'teniente primero': 5,
      'teniente 2°': 6,
      'teniente 2': 6,
      'teniente segundo': 6,
      'teniente 3°': 7,
      'teniente 3': 7,
      'teniente tercero': 7,
      'ayudante 1°': 8,
      'ayudante 1': 8,
      'ayudante primero': 8,
      'ayudante 2°': 9,
      'ayudante 2': 9,
      'ayudante segundo': 9,
      'inspector m. mayor': 10,
      'inspector m mayor': 10,
      'inspector mayor': 10,
      'inspector m. menor': 11,
      'inspector m menor': 11,
      'inspector menor': 11,
      'bombero': 12,
    };
    
    return rankOrder[normalized] ?? 999;
  }

  Future<void> createUser(UserModel user) async {
    final userData = user.toJson();
    // Remover campos que se generan automáticamente
    userData.remove('id');
    userData.remove('created_at');
    
    await client.from(AppConstants.usersTable).insert(userData);
  }

  Future<void> updateUser(UserModel user) async {
    final userData = user.toJson();
    // Remover campos que no se deben actualizar
    userData.remove('id');
    userData.remove('rut'); // RUT no se puede cambiar
    userData.remove('created_at');
    
    await client.from(AppConstants.usersTable)
        .update(userData)
        .eq('id', user.id);
  }

  Future<void> deleteUser(String userId) async {
    await client.from(AppConstants.usersTable).delete().eq('id', userId);
  }

  Future<List<UserModel>> getUsersByGender(String gender) async {
    final response = await client
        .from(AppConstants.usersTable)
        .select()
        .eq('gender', gender);
    
    return (response as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  Future<UserModel?> getUserByRut(String rut) async {
    final response = await client
        .from(AppConstants.usersTable)
        .select()
        .eq('rut', rut)
        .maybeSingle();
    
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  // ============================================
  // AUTHENTICATION
  // ============================================

  Future<Map<String, dynamic>?> getAuthCredentials(String userId) async {
    final response = await client
        .from('auth_credentials')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    return response;
  }

  Future<void> createAuthCredentials(String userId, String passwordHash) async {
    await client.from('auth_credentials').insert({
      'user_id': userId,
      'password_hash': passwordHash,
      'requires_password_change': true,
    });
  }

  Future<void> updatePassword(
    String userId, 
    String newPasswordHash, {
    bool requiresPasswordChange = false,
  }) async {
    await client.from('auth_credentials').update({
      'password_hash': newPasswordHash,
      'requires_password_change': requiresPasswordChange,
      'password_changed_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  /// Update password with password change requirement (for admin reset)
  Future<void> updatePasswordWithReset(String userId, String newPasswordHash) async {
    await updatePassword(userId, newPasswordHash, requiresPasswordChange: true);
  }

  Future<void> incrementFailedAttempts(String userId) async {
    final creds = await getAuthCredentials(userId);
    if (creds != null) {
      final currentAttempts = creds['failed_attempts'] as int? ?? 0;
      await client.from('auth_credentials').update({
        'failed_attempts': currentAttempts + 1,
      }).eq('user_id', userId);
    }
  }

  Future<void> resetFailedAttempts(String userId) async {
    await client.from('auth_credentials').update({
      'failed_attempts': 0,
      'locked_until': null,
    }).eq('user_id', userId);
  }

  Future<void> lockAccount(String userId, {int minutes = 15}) async {
    final lockedUntil = DateTime.now().add(Duration(minutes: minutes));
    await client.from('auth_credentials').update({
      'locked_until': lockedUntil.toIso8601String(),
    }).eq('user_id', userId);
  }

  Future<void> updateLastLogin(String userId) async {
    await client.from('auth_credentials').update({
      'last_login': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  // ============================================
  // ACT TYPES
  // ============================================

  Future<List<Map<String, dynamic>>> getAllActTypes() async {
    return await client
        .from(AppConstants.actTypesTable)
        .select()
        .eq('is_active', true)
        .order('name');
  }

  Future<Map<String, dynamic>?> getActType(String actTypeId) async {
    return await client
        .from(AppConstants.actTypesTable)
        .select()
        .eq('id', actTypeId)
        .maybeSingle();
  }

  Future<void> createActType(Map<String, dynamic> actType) async {
    await client.from(AppConstants.actTypesTable).insert(actType);
  }

  Future<void> updateActType(String actTypeId, Map<String, dynamic> updates) async {
    await client
        .from(AppConstants.actTypesTable)
        .update(updates)
        .eq('id', actTypeId);
  }

  Future<void> deleteActType(String actTypeId) async {
    await client.from(AppConstants.actTypesTable).delete().eq('id', actTypeId);
  }

  // ============================================
  // PERMISSIONS
  // ============================================

  Future<List<Map<String, dynamic>>> getPermissionsByStatus(String status) async {
    return await client
        .from(AppConstants.permissionsTable)
        .select('*, user:user_id(*)')
        .eq('status', status)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getPermissionsByUser(String userId) async {
    return await client
        .from(AppConstants.permissionsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getActivePermissions(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await client
        .from(AppConstants.permissionsTable)
        .select()
        .eq('user_id', userId)
        .eq('status', 'approved')
        .lte('start_date', dateStr)
        .gte('end_date', dateStr);
  }

  /// Batch load all active permissions for a given date (OPTIMIZED for attendance)
  Future<List<Map<String, dynamic>>> getAllActivePermissionsForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await client
        .from(AppConstants.permissionsTable)
        .select()
        .eq('status', 'approved')
        .lte('start_date', dateStr)
        .gte('end_date', dateStr);
  }

  Future<void> createPermission(Map<String, dynamic> permission) async {
    await client.from(AppConstants.permissionsTable).insert(permission);
  }

  Future<void> updatePermissionStatus(
    String permissionId,
    String status,
    String reviewedBy,
  ) async {
    await client.from(AppConstants.permissionsTable).update({
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', permissionId);
  }

  // ============================================
  // ATTENDANCE
  // ============================================

  Future<String> createAttendanceEvent(Map<String, dynamic> event) async {
    final response = await client
        .from(AppConstants.attendanceEventsTable)
        .insert(event)
        .select()
        .single();
    return response['id'];
  }

  Future<void> createAttendanceRecords(List<Map<String, dynamic>> records) async {
    await client.from(AppConstants.attendanceRecordsTable).insert(records);
  }

  Future<List<Map<String, dynamic>>> getAttendanceEvents({int limit = 50}) async {
    return await client
        .from(AppConstants.attendanceEventsTable)
        .select('*, act_type:act_type_id(*), creator:created_by(*)')
        .order('event_date', ascending: false)
        .limit(limit);
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecordsByEvent(String eventId) async {
    return await client
        .from(AppConstants.attendanceRecordsTable)
        .select('*, user:user_id(*)')
        .eq('event_id', eventId);
  }

  Future<void> updateAttendanceRecord(
    String recordId,
    Map<String, dynamic> updates,
  ) async {
    await client
        .from(AppConstants.attendanceRecordsTable)
        .update(updates)
        .eq('id', recordId);
  }

  // ============================================
  // SHIFTS
  // ============================================

  Future<List<Map<String, dynamic>>> getShiftConfigurations() async {
    return await client
        .from(AppConstants.shiftConfigsTable)
        .select()
        .order('start_date', ascending: false);
  }

  Future<void> createShiftConfiguration(Map<String, dynamic> config) async {
    await client.from(AppConstants.shiftConfigsTable).insert(config);
  }

  Future<List<Map<String, dynamic>>> getShiftRegistrations(
    String configId, {
    DateTime? specificDate,
  }) async {
    var query = client
        .from(AppConstants.shiftRegistrationsTable)
        .select('*, user:user_id(*)')
        .eq('config_id', configId);
    
    if (specificDate != null) {
      final dateStr = specificDate.toIso8601String().split('T')[0];
      query = query.eq('shift_date', dateStr);
    }
    
    return await query;
  }

  Future<int> getShiftRegistrationCount(DateTime date, String gender) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await client
        .from(AppConstants.shiftRegistrationsTable)
        .select('*, user:user_id!inner(*)')
        .eq('shift_date', dateStr)
        .eq('user.gender', gender);
    
    return (response as List).length;
  }

  Future<void> createShiftRegistration(Map<String, dynamic> registration) async {
    await client.from(AppConstants.shiftRegistrationsTable).insert(registration);
  }

  Future<void> deleteShiftRegistration(String registrationId) async {
    await client
        .from(AppConstants.shiftRegistrationsTable)
        .delete()
        .eq('id', registrationId);
  }

  Future<List<Map<String, dynamic>>> getShiftAttendance(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await client
        .from(AppConstants.shiftAttendanceTable)
        .select('*, user:user_id(*), replacement:replacement_user_id(*)')
        .eq('shift_date', dateStr);
  }

  Future<void> createShiftAttendance(Map<String, dynamic> attendance) async {
    await client.from(AppConstants.shiftAttendanceTable).insert(attendance);
  }

  Future<void> updateShiftAttendance(
    String attendanceId,
    Map<String, dynamic> updates,
  ) async {
    await client
        .from(AppConstants.shiftAttendanceTable)
        .update(updates)
        .eq('id', attendanceId);
  }

  // Modify Attendance - Event management  
  Future<void> updateAttendanceEvent(
    String eventId, 
    DateTime newDate, 
    String newActTypeId, 
    String userId, {
    String? subtype, 
    String? location
  }) async {
    final updateData = {
      'event_date': newDate.toIso8601String().split('T')[0],
      'act_type_id': newActTypeId,
      'modified_by': userId,
      'modified_at': DateTime.now().toIso8601String(),
    };
    if (subtype != null) updateData['subtype'] = subtype;
    if (location != null) updateData['location'] = location;
    
    await client.from(AppConstants.attendanceEventsTable).update(updateData).eq('id', eventId);
  }

  Future<void> deleteAttendanceEvent(String eventId) async {
    await client.from(AppConstants.attendanceEventsTable).delete().eq('id', eventId);
  }

  Future<void> updateAttendanceRecord2(String recordId, String status, bool isLocked) async {
    await updateAttendanceRecord(recordId, {
      'status': status,
      'is_locked': isLocked,
    });
  }

  // ============================================
  // ACTIVITIES (Calendario Semanal)
  // ============================================

  /// Obtener actividades de una semana específica
  Future<List<Map<String, dynamic>>> getWeeklyActivities(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startStr = weekStart.toIso8601String().split('T')[0];
    final endStr = weekEnd.toIso8601String().split('T')[0];
    
    return await client
        .from('activities')
        .select('*, creator:created_by(*)')
        .gte('activity_date', startStr)
        .lte('activity_date', endStr)
        .order('activity_date')
        .order('start_time');
  }

  /// Obtener actividades de un día específico
  Future<List<Map<String, dynamic>>> getDailyActivities(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    return await client
        .from('activities')
        .select('*, creator:created_by(*)')
        .eq('activity_date', dateStr)
        .order('start_time');
  }

  /// Crear nueva actividad (admin/officer)
  Future<String> createActivity(Map<String, dynamic> activity) async {
    final response = await client
        .from('activities')
        .insert(activity)
        .select()
        .single();
    return response['id'];
  }

  /// Actualizar una actividad existente
  Future<void> updateActivity(String activityId, Map<String, dynamic> updates, String userId) async {
    try {
      // Agregar campos de auditoría
      updates['modified_by'] = userId;
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await client
          .from('activities')
          .update(updates)
          .eq('id', activityId);
    } catch (e) {
      throw Exception('Error updating activity: $e');
    }
  }

  /// Eliminar actividad (admin/officer)
  Future<void> deleteActivity(String activityId) async {
    await client.from('activities').delete().eq('id', activityId);
  }

  /// Obtener próximas actividades (para pantalla de gestión)
  Future<List<Map<String, dynamic>>> getUpcomingActivities({int limit = 5}) async {
    return await client
        .from('activities')
        .select('*')  // Seleccionar todos los campos incluyendo modified_by/modified_at
        .gte('activity_date', DateTime.now().toIso8601String().split('T')[0])
        .order('activity_date')
        .order('start_time')
        .limit(limit);
  }
}
