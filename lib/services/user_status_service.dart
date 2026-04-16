import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/user_status_history_model.dart';

/// Servicio para gestión de estados de bomberos
class UserStatusService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // CAMBIO DE ESTADO
  // ============================================

  /// Cambia el status de un usuario y registra el historial.
  /// Ambas operaciones son cuasi-atómicas: si falla el insert de historial,
  /// se revierte el update.
  Future<void> changeUserStatus({
    required String userId,
    required String newStatus,
    required DateTime effectiveDate,
    required String reason,
    required String changedBy,
  }) async {
    try {
      await _supabase.rpc('change_user_status', params: {
        'p_user_id': userId,
        'p_new_status': newStatus,
        'p_effective_date': effectiveDate.toIso8601String().split('T')[0],
        'p_reason': reason,
        'p_changed_by': changedBy,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Reactiva un usuario (hardcodea p_new_status = 'activo').
  Future<void> reactivateUser({
    required String userId,
    required DateTime effectiveDate,
    required String reason,
    required String changedBy,
  }) async {
    try {
      await _supabase.rpc('change_user_status', params: {
        'p_user_id': userId,
        'p_new_status': 'activo',
        'p_effective_date': effectiveDate.toIso8601String().split('T')[0],
        'p_reason': reason,
        'p_changed_by': changedBy,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // HISTORIAL
  // ============================================

  /// Historial de cambios de estado de un usuario específico.
  Future<List<UserStatusHistory>> getUserStatusHistory(String userId) async {
    try {
      final response = await _supabase
          .from('user_status_history')
          .select('''
            *,
            user:users!user_status_history_user_id_fkey(full_name),
            changer:users!user_status_history_changed_by_fkey(full_name)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final map = Map<String, dynamic>.from(json);
        map['user_name'] = (json['user'] as Map?)?['full_name'];
        map['changed_by_name'] = (json['changer'] as Map?)?['full_name'];
        return UserStatusHistory.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener historial de estado: $e');
    }
  }

  /// Historial global con filtros opcionales (para tab Reportes).
  Future<List<UserStatusHistory>> getAllStatusHistory({
    String? filterStatus,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase
          .from('user_status_history')
          .select('''
            *,
            user:users!user_status_history_user_id_fkey(full_name),
            changer:users!user_status_history_changed_by_fkey(full_name)
          ''');

      if (filterStatus != null) {
        query = query.eq('new_status', filterStatus);
      }
      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        // Incluir todo el día toDate
        final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
        query = query.lte('created_at', end.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((json) {
        final map = Map<String, dynamic>.from(json);
        map['user_name'] = (json['user'] as Map?)?['full_name'];
        map['changed_by_name'] = (json['changer'] as Map?)?['full_name'];
        return UserStatusHistory.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener historial global: $e');
    }
  }

  // ============================================
  // CONSULTAS DE USUARIOS POR ESTADO
  // ============================================

  /// Lista de usuarios filtrados por status.
  Future<List<UserModel>> getUsersByStatus(String status) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('status', status)
          .order('full_name');

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios con estado "$status": $e');
    }
  }

  /// Conteo de usuarios agrupados por status (para badges en tabs).
  Future<Map<String, int>> getStatusSummary() async {
    try {
      final response = await _supabase
          .from('users')
          .select('status');

      final counts = <String, int>{};
      for (final row in response as List) {
        final s = row['status'] as String? ?? 'activo';
        counts[s] = (counts[s] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      throw Exception('Error al obtener resumen de estados: $e');
    }
  }
}
