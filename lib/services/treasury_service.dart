import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/monthly_quota_model.dart';
import '../models/treasury_payment_model.dart';
import '../models/quota_config_model.dart';

/// Servicio para gestión de tesorería
class TreasuryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache para lista de usuarios (reduce queries repetidas)
  List<Map<String, dynamic>>? _cachedUsers;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);
  
  /// Obtener usuarios con caché
  Future<List<Map<String, dynamic>>> _getUsersWithCache() async {
    final now = DateTime.now();
    
    // Retornar caché si es válido
    if (_cachedUsers != null && 
        _cacheTime != null && 
        now.difference(_cacheTime!) < _cacheDuration) {
      return _cachedUsers!;
    }
    
    // Actualizar caché
    final response = await _supabase
        .from('users')
        .select('id, full_name, rut, rank, is_student, payment_start_date');
    
    _cachedUsers = List<Map<String, dynamic>>.from(response);
    _cacheTime = now;
    
    return _cachedUsers!;
  }
  
  /// Invalidar caché de usuarios (llamar después de crear/actualizar usuarios)
  void invalidateUserCache() {
    _cachedUsers = null;
    _cacheTime = null;
  }

  // ============================================
  // CONFIGURACIÓN DE CUOTAS
  // ============================================

  /// Obtener configuración de cuotas de un año
  Future<QuotaConfig?> getQuotaConfig(int year) async {
    try {
      final response = await _supabase
          .from('treasury_quota_config')
          .select()
          .eq('year', year)
          .maybeSingle();

      if (response == null) {
        // Si no existe, obtener la más reciente
        final latestResponse = await _supabase
            .from('treasury_quota_config')
            .select()
            .order('year', ascending: false)
            .limit(1)
            .maybeSingle();

        if (latestResponse == null) return null;
        return QuotaConfig.fromJson(latestResponse);
      }

      return QuotaConfig.fromJson(response);
    } catch (e) {
      print('Error getting quota config: $e');
      return null;
    }
  }

  /// Obtener todas las configuraciones de cuotas
  Future<List<QuotaConfig>> getAllQuotaConfigs() async {
    try {
      final response = await _supabase
          .from('treasury_quota_config')
          .select()
          .order('year', ascending: false);

      return (response as List)
          .map((json) => QuotaConfig.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all quota configs: $e');
      return [];
    }
  }

  /// Crear o actualizar configuración de cuotas
  Future<QuotaConfig?> upsertQuotaConfig({
    required int year,
    required int standardQuota,
    required int reducedQuota,
  }) async {
    try {
      final response = await _supabase.rpc('upsert_quota_config', params: {
        'p_year': year,
        'p_standard_quota': standardQuota,
        'p_reduced_quota': reducedQuota,
      }).maybeSingle();

      if (response == null) return null;
      return QuotaConfig.fromJson(response);
    } catch (e) {
      print('Error upserting quota config: $e');
      return null;
    }
  }

  // ============================================
  // CUOTAS MENSUALES
  // ============================================

  /// Generar cuotas para un mes específico
  Future<List<Map<String, dynamic>>> generateMonthlyQuotas({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _supabase.rpc('generate_monthly_quotas', params: {
        'p_month': month,
        'p_year': year,
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error generating monthly quotas: $e');
      return [];
    }
  }

  /// Obtener cuotas de un mes específico
  Future<List<MonthlyQuota>> getQuotasForMonth({
    required int month,
    required int year,
  }) async {
    try {
      final response = await _supabase
          .from('treasury_monthly_quotas')
          .select()
          .eq('month', month)
          .eq('year', year)
          .order('user_id');

      return (response as List)
          .map((json) => MonthlyQuota.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting quotas for month: $e');
      return [];
    }
  }

  /// Obtener cuotas de un usuario
  Future<List<MonthlyQuota>> getUserQuotas(String userId) async {
    try {
      final response = await _supabase
          .from('treasury_monthly_quotas')
          .select()
          .eq('user_id', userId)
          .order('year', ascending: false)
          .order('month', ascending: false);

      return (response as List)
          .map((json) => MonthlyQuota.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user quotas: $e');
      return [];
    }
  }

  // ============================================
  // PAGOS
  // ============================================

  /// Registrar un pago
  Future<bool> registerPayment({
    required String quotaId,
    required String userId,
    required int amount,
    required DateTime paymentDate,
    required PaymentMethod paymentMethod,
    String? receiptNumber,
    String? notes,
    required String registeredBy,
    bool markAsPaid = false,
  }) async {
    try {
      // 1. Registrar el pago
      await _supabase.from('treasury_payments').insert({
        'quota_id': quotaId,
        'user_id': userId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'payment_method': paymentMethod.name,
        'receipt_number': receiptNumber,
        'notes': notes,
        'registered_by': registeredBy,
      });

      // 2. Si se solicitó autorizar como pagado, marcar el flag
      if (markAsPaid) {
        await _supabase.rpc('mark_quota_as_forced_paid', params: {
          'p_quota_id': quotaId,
          'p_forced': true,
        });
      }

      return true;
    } catch (e) {
      print('Error registering payment: $e');
      return false;
    }
  }

  /// Obtener pagos de una cuota
  Future<List<TreasuryPayment>> getQuotaPayments(String quotaId) async {
    try {
      final response = await _supabase
          .from('treasury_payments')
          .select()
          .eq('quota_id', quotaId)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => TreasuryPayment.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting quota payments: $e');
      return [];
    }
  }

  /// Obtener historial de pagos de un usuario
  Future<List<TreasuryPayment>> getUserPaymentHistory(String userId) async {
    try {
      final response = await _supabase
          .from('treasury_payments')
          .select()
          .eq('user_id', userId)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => TreasuryPayment.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user payment history: $e');
      return [];
    }
  }

  // ============================================
  // CÁLCULO DE DEUDAS
  // ============================================

  /// Calcular deuda de un usuario
  Future<Map<String, dynamic>> calculateUserDebt(String userId) async {
    try {
      final response = await _supabase
          .rpc('calculate_user_debt', params: {'p_user_id': userId})
          .maybeSingle();

      if (response == null) {
        return {
          'months_owed': 0,
          'total_amount': 0,
          'pending_quotas': [],
        };
      }

      return {
        'months_owed': response['months_owed'] ?? 0,
        'total_amount': response['total_amount'] ?? 0,
        'pending_quotas': response['pending_quotas'] ?? [],
      };
    } catch (e) {
      print('Error calculating user debt: $e');
      return {
        'months_owed': 0,
        'total_amount': 0,
        'pending_quotas': [],
      };
    }
  }

  /// Obtener resumen de recaudación de un mes
  Future<Map<String, dynamic>> getMonthSummary({
    required int month,
    required int year,
  }) async {
    try {
      final quotas = await getQuotasForMonth(month: month, year: year);

      int totalUsers = quotas.length;
      int paidCount = quotas.where((q) => q.status == QuotaStatus.paid).length;
      int pendingCount = quotas.where((q) => q.status == QuotaStatus.pending).length;
      int partialCount = quotas.where((q) => q.status == QuotaStatus.partial).length;

      int totalExpected = quotas.fold(0, (sum, q) => sum + q.expectedAmount);
      int totalCollected = quotas.fold(0, (sum, q) => sum + q.paidAmount);

      return {
        'total_users': totalUsers,
        'paid_count': paidCount,
        'pending_count': pendingCount,
        'partial_count': partialCount,
        'total_expected': totalExpected,
        'total_collected': totalCollected,
        'collection_percentage': totalExpected > 0 
            ? (totalCollected / totalExpected * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      print('Error getting month summary: $e');
      return {};
    }
  }

  // ============================================
  // UTILIDADES
  // ============================================

  /// Calcular cuota esperada para un usuario en un período específico
  Future<int> calculateExpectedQuota({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _supabase.rpc('calculate_expected_quota', params: {
        'p_user_id': userId,
        'p_month': month,
        'p_year': year,
      });

      return response as int? ?? 5000; // Default fallback
    } catch (e) {
      print('Error calculating expected quota: $e');
      return 5000; // Default fallback
    }
  }

  /// Obtener estadísticas generales de tesorería
  Future<Map<String, dynamic>> getGeneralStatistics() async {
    try {
      // Total de usuarios que deben pagar
      final usersResponse = await _supabase
          .from('users')
          .select('id')
          .not('payment_start_date', 'is', null);
      
      int totalPayingUsers = (usersResponse as List).length;

      // Cuotas pendientes totales
      final pendingQuotas = await _supabase
          .from('treasury_monthly_quotas')
          .select('expected_amount, paid_amount')
          .neq('status', 'paid');

      int totalPending = 0;
      for (var quota in pendingQuotas as List) {
        totalPending += (quota['expected_amount'] as int) - (quota['paid_amount'] as int? ?? 0);
      }

      // Recaudación del año actual
      final currentYear = DateTime.now().year;
      final yearQuotas = await _supabase
          .from('treasury_monthly_quotas')
          .select('paid_amount')
          .eq('year', currentYear);

      int yearCollection = (yearQuotas as List)
          .fold(0, (sum, q) => sum + (q['paid_amount'] as int? ?? 0));

      return {
        'total_paying_users': totalPayingUsers,
        'total_pending_amount': totalPending,
        'year_collection': yearCollection,
        'current_year': currentYear,
      };
    } catch (e) {
      print('Error getting general statistics: $e');
      return {};
    }
  }

  /// Promover usuario a Bombero
  /// Actualiza el cargo, quita estado de estudiante y recalcula cuotas futuras
  Future<Map<String, dynamic>> promoteToFirefighter(
    String userId,
    DateTime promotionDate,
  ) async {
    try {
      final response = await _supabase.rpc('promote_to_firefighter', params: {
        'p_user_id': userId,
        'p_promotion_date': promotionDate.toIso8601String(),
      });

      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      print('Error promoting to firefighter: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
