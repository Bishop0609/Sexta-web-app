import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/models/attendance_record_model.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:intl/intl.dart';

/// Servicio para gestión de asistencia con lógica de cross-check automático
class AttendanceService {
  final SupabaseService _supabase = SupabaseService();

  /// LÓGICA CRÍTICA: Verifica si un usuario tiene licencia aprobada para una fecha
  Future<bool> hasApprovedLicense(String userId, DateTime eventDate) async {
    final permissions = await _supabase.getActivePermissions(userId, eventDate);
    return permissions.isNotEmpty;
  }

  /// Prepares attendance list with auto-check of licenses (OPTIMIZED: batch load)
  Future<List<Map<String, dynamic>>> prepareAttendanceList(
    List<UserModel> users,
    DateTime eventDate,
  ) async {
    // OPTIMIZATION: Batch load ALL active licenses for this date in single query
    final allLicenses = await _supabase.getAllActivePermissionsForDate(eventDate);
    
    // Create a Set of user IDs that have active licenses for fast lookup
    final usersWithLicenses = <String>{};
    for (final license in allLicenses) {
      usersWithLicenses.add(license['user_id'] as String);
    }

    final attendanceList = <Map<String, dynamic>>[];

    for (final user in users) {
      final hasLicense = usersWithLicenses.contains(user.id);
      
      attendanceList.add({
        'user': user,
        'status': hasLicense ? AttendanceStatus.licencia : AttendanceStatus.absent,
        'isLocked': hasLicense, // Block editing if has license
        'hasLicense': hasLicense,
      });
    }

    return attendanceList;
  }

  /// Crea evento de asistencia con registros
  Future<String> createAttendanceEvent({
    required String actTypeId,
    required DateTime eventDate,
    required String createdBy,
    required List<Map<String, dynamic>> attendanceRecords,
    String? subtype,
    String? location,
  }) async {
    // 1. Crear evento
    final eventData = {
      'act_type_id': actTypeId,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'created_by': createdBy,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    if (subtype != null) eventData['subtype'] = subtype;
    if (location != null) eventData['location'] = location;
    
    final eventId = await _supabase.createAttendanceEvent(eventData);

    // 2. Crear registros de asistencia
    final records = attendanceRecords.map((record) {
      return {
        'event_id': eventId,
        'user_id': record['userId'],
        'status': record['status'],
        'is_locked': record['isLocked'] ?? false,
        'created_at': DateTime.now().toIso8601String(),
      };
    }).toList();

    await _supabase.createAttendanceRecords(records);

    return eventId;
  }

  /// Obtiene eventos de asistencia con información completa
  Future<List<Map<String, dynamic>>> getAttendanceEventsWithDetails() async {
    return await _supabase.getAttendanceEvents();
  }

  /// Gets attendance records for specific event
  Future<List<Map<String, dynamic>>> getEventAttendanceRecords(String eventId) async {
    return await _supabase.getAttendanceRecordsByEvent(eventId);
  }

  /// Gets user's attendance history (most recent records)
  Future<List<Map<String, dynamic>>> getUserAttendanceHistory(String userId, int limit) async {
    final supabaseClient = _supabase.client;
    
    final response = await supabaseClient
        .from('attendance_records')
        .select('''
          *,
          event:attendance_events!inner(
            event_date,
            act_type:act_types!inner(name, category)
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    final records = response as List;
    
    // Flatten the structure for easier use
    return records.map((record) {
      return {
        'status': record['status'],
        'event_date': record['event']['event_date'],
        'act_type_name': record['event']['act_type']['name'],
        'act_type_category': record['event']['act_type']['category'],
      };
    }).toList();
  }

  /// Actualiza un registro de asistencia (solo si no está bloqueado)
  Future<bool> updateAttendanceRecord({
    required String recordId,
    required AttendanceStatus newStatus,
    required bool isAdmin,
  }) async {
    // Obtener registro actual para verificar si está bloqueado
    final records = await _supabase.getAttendanceRecordsByEvent(recordId);
    if (records.isEmpty) return false;

    final record = records.first;
    final isLocked = record['is_locked'] as bool;

    // Solo admin puede editar registros bloqueados
    if (isLocked && !isAdmin) {
      throw Exception('No se puede modificar un registro con licencia activa. Solo administradores.');
    }

    await _supabase.updateAttendanceRecord(recordId, {
      'status': newStatus.name,
    });

    return true;
  }

  /// Calcula estadísticas individuales (Efectiva vs Abono)
  Future<Map<String, dynamic>> calculateIndividualStats(String userId) async {
    final supabaseClient = _supabase.client;

    // Query que une attendance_records con attendance_events y act_types
    final response = await supabaseClient
        .from('attendance_records')
        .select('''
          status,
          event:attendance_events!inner(
            act_type:act_types!inner(category)
          )
        ''')
        .eq('user_id', userId)
        .eq('status', 'present');

    final records = response as List;
    
    int efectivaCount = 0;
    int abonoCount = 0;

    for (final record in records) {
      final category = record['event']['act_type']['category'];
      if (category == 'efectiva') {
        efectivaCount++;
      } else if (category == 'abono') {
        abonoCount++;
      }
    }

    final total = efectivaCount + abonoCount;
    final efectivaPct = total > 0 ? (efectivaCount / total) * 100 : 0.0;
    final abonoPct = total > 0 ? (abonoCount / total) * 100 : 0.0;

    return {
      'efectiva_count': efectivaCount,
      'abono_count': abonoCount,
      'total': total,
      'efectiva_pct': efectivaPct,
      'abono_pct': abonoPct,
    };
  }

  /// Calcula estadísticas de la compañía por mes (últimos 6 meses) - OPTIMIZADO con RPC
  Future<List<Map<String, dynamic>>> calculateCompanyMonthlyStats() async {
    final supabaseClient = _supabase.client;

    // Llamar a la función RPC que hace la agregación en el servidor
    final response = await supabaseClient.rpc('get_monthly_stats');

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Ranking de asistencia (top performers)
  Future<List<Map<String, dynamic>>> getAttendanceRanking({int limit = 10}) async {
    final supabaseClient = _supabase.client;

    final response = await supabaseClient.rpc('get_attendance_ranking', params: {
      'limit_count': limit,
    });

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Alertas de baja asistencia (semáforo)
  /// TEMPORALMENTE DESHABILITADO - Era muy lento (iteraba todos los usuarios)
  /// TODO: Crear RPC en Supabase para calcular esto en el servidor
  Future<List<Map<String, dynamic>>> getLowAttendanceAlerts({
    double threshold = 0.70,
  }) async {
    // Retornar lista vacía temporalmente para mejorar performance
    // En producción, esto debería ser un RPC que calcule en el servidor
    return [];
    
    /* CÓDIGO ORIGINAL (MUY LENTO):
    final users = await _supabase.getAllUsers();
    final alerts = <Map<String, dynamic>>[];

    for (final user in users) {
      final stats = await calculateIndividualStats(user.id);
      final totalEvents = await _getTotalEventsCount();
      
      if (totalEvents == 0) continue;

      final attendancePct = (stats['total'] as int) / totalEvents;

      if (attendancePct < threshold) {
        alerts.add({
          'user_id': user.id,
          'full_name': user.fullName,
          'rank': user.rank,
          'attendance_pct': attendancePct * 100,
          'severity': attendancePct < 0.50 ? 'critical' : 'warning',
        });
      }
    }

    alerts.sort((a, b) => 
        (a['attendance_pct'] as double).compareTo(b['attendance_pct'] as double));

    return alerts;
    */
  }

  Future<int> _getTotalEventsCount() async {
    final events = await _supabase.getAttendanceEvents();
    return events.length;
  }
}
