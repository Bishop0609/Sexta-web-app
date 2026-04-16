import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:sexta_app/models/guard_registration_period_model.dart';
import 'package:intl/intl.dart';

class GuardRegistrationPeriodService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'guard_registration_periods';

  /// Get active registration period (if any)
  Future<GuardRegistrationPeriod?> getActivePeriod() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('status', 'open')
        .maybeSingle();

    if (response == null) return null;
    return GuardRegistrationPeriod.fromJson(response);
  }

  /// Open a new registration period
  Future<GuardRegistrationPeriod> openPeriod({
    required DateTime periodStart,
    required DateTime periodEnd,
    required String userId,
  }) async {
    // Check if any period is already open
    final active = await getActivePeriod();
    if (active != null) {
      throw Exception('Ya existe un período de inscripción abierto');
    }

    final data = {
      'period_start': periodStart.toIso8601String().split('T')[0],
      'period_end': periodEnd.toIso8601String().split('T')[0],
      'status': 'open',
      'opened_by': userId,
      'opened_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from(_tableName)
        .insert(data)
        .select()
        .single();

    return GuardRegistrationPeriod.fromJson(response);
  }

  /// Close a registration period
  Future<void> closePeriod(String periodId) async {
    await _supabase.from(_tableName).update({
      'status': 'closed',
      'closed_at': DateTime.now().toIso8601String(),
    }).eq('id', periodId);
  }

  /// Reopen a closed registration period
  Future<void> reopenPeriod(String periodId) async {
    // Check if any period is already open
    final active = await getActivePeriod();
    if (active != null) {
      throw Exception('Ya existe un período de inscripción abierto');
    }

    await _supabase.from(_tableName).update({
      'status': 'open',
      'closed_at': null,
    }).eq('id', periodId);
  }

  /// Get all registration periods ordered recent first
  Future<List<GuardRegistrationPeriod>> getAllPeriods({
    int limit = 12,
  }) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => GuardRegistrationPeriod.fromJson(e))
        .toList();
  }

  /// Calculate weeks for a given month (aligned to Monday start)
  /// Returns {periodStart, periodEnd, weekCount, weeks}
  Map<String, dynamic> calculateMonthWeeks(int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1);
    
    // Encontrar periodStart: lunes de la semana que contiene el 1ro
    // Si el 1ro es domingo, pertenece al mes anterior, empezar el lunes 2
    DateTime periodStart;
    if (firstDayOfMonth.weekday == DateTime.sunday) {
      periodStart = DateTime(year, month, 2);
    } else {
      // Retroceder al lunes de esa semana
      int daysBack = firstDayOfMonth.weekday - DateTime.monday;
      periodStart = DateTime(year, month, 1 - daysBack);
    }
    
    // Encontrar periodEnd: domingo de la semana que contiene el último día del mes
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    DateTime periodEnd;
    if (lastDayOfMonth.weekday == DateTime.sunday) {
      periodEnd = lastDayOfMonth;
    } else {
      int daysForward = DateTime.sunday - lastDayOfMonth.weekday;
      periodEnd = DateTime(year, month + 1, 0 + daysForward);
    }
    
    // Generar semanas usando DateTime constructor (sin Duration)
    List<Map<String, DateTime>> weeks = [];
    int dayOffset = 0;
    while (true) {
      final weekStart = DateTime(periodStart.year, periodStart.month, periodStart.day + dayOffset);
      final weekEnd = DateTime(periodStart.year, periodStart.month, periodStart.day + dayOffset + 6);
      if (weekStart.isAfter(periodEnd)) break;
      weeks.add({
        'start': weekStart,
        'end': weekEnd,
      });
      dayOffset += 7;
    }
    
    return {
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'weekCount': weeks.length,
      'weeks': weeks,
      'targetMonth': DateTime(year, month, 1),
    };
  }
}
