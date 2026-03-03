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
    // Find the first day of the month
    final firstDayOfMonth = DateTime(year, month, 1);
    
    // Find the first Monday. If first day is Sunday (7), then it belongs
    // to previous week, so start is next Monday? Wait...
    // Logic: "Si el mes empieza en dom, ese dom pertenece al mes anterior"
    // "Si el mes empieza en lun, ese es el inicio"
    
    // So if firstDayOfMonth.weekday is 1 (Monday), periodStart = firstDayOfMonth
    // If firstDayOfMonth.weekday is 2 (Tuesday), previous Monday? Or next?
    // Usually roster periods cover full weeks. 
    // Let's assume standard ISO week logic: week starts on Monday.
    // If 1st is Mon, great. If 1st is Thu, Fri, Sat, Sun...
    // The prompt says: "Si el mes empieza en dom, ese dom pertenece al mes anterior"
    // This implies we look for the first Monday ON or AFTER the 1st, 
    // UNLESS the 1st is Sunday? No, if 1st is Sunday, it belongs to previous month.
    // So month period starts on the first Monday OF the month (or close to it).
    
    // Let's interpret: Find the Monday of the week that contains the majority of the month's first days?
    // Or simpler: Period starts on the first Monday of the month.
    // If month starts on Sunday (weekday 7), first Monday is day 2.
    // If month starts on Monday (weekday 1), first Monday is day 1.
    // If month starts on Saturday (6), first Monday is day 3.
    
    // Let's follow a standard approach:
    // Period start = first Monday >= 1st of month?
    // But if 1st is Sunday, previous week covered it. So we start on 2nd (Monday).
    // What if 1st is Friday? The weekend is 2nd, 3rd. Next week starts 4th.
    // Does 1st-3rd belong to previous month roster?
    // Usually firefighting rosters try to align with months.
    
    // Let's use this logic:
    // Find the Monday of the week containing the 1st.
    // If that week's Sunday is in the previous month (e.g. 1st is Sunday),
    // then that week belongs to previous month.
    // Else, that week belongs to this month.
    
    DateTime cursor = DateTime(year, month, 1);
    
    // Backtrack to Monday
    while (cursor.weekday != DateTime.monday) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    
    // Now cursor is the Monday of the week containing the 1st.
    // Check if the majority of this week is in this month?
    // Or check the specific rule "Si el mes empieza en dom, ese dom pertenece al mes anterior".
    // If 1st is Sunday, then the week containing 1st started previous Monday.
    // That week ends on 1st (Sunday).
    // So that week belongs to previous month. 
    // So periodStart should be next Monday (2nd).
    
    // My cursor logic went back to Monday. 
    // If 1st was Sunday, cursor is Monday of previous week. 
    // That week ends on Sunday (the 1st). 
    // Since it ends on 1st, it overlaps. 
    
    // Let's implement simpler logic per instructions:
    // "Calcula el primer lunes y último domingo del mes"
    // This could mean the period fully contains the month, or aligns to weeks.
    
    // Adjusted logic:
    // 1. Get first Monday of the month?
    //    If 1st is Mon -> 1st
    //    If 1st is Tue -> 7th? No.
    //    Usually "guardia de mes" starts on a Monday.
    
    // Let's assume we want to cover the month.
    // Start date = Monday of the week that contains the 1st of the month...
    // UNLESS the 1st is Sunday (per prompt).
    
    DateTime periodStart;
    
    if (firstDayOfMonth.weekday == DateTime.sunday) {
      // If starts on Sunday, that Sunday is part of prev month.
      // So this month starts on Monday 2nd.
      periodStart = firstDayOfMonth.add(const Duration(days: 1));
    } else {
      // Otherwise, we take the Monday of that week.
      // E.g. 1st is Thursday. Monday is 29th prev month.
      // Does "Si el mes empieza en lunes" mean STRICTLY?
      // Prompt: "Si el mes empieza en lun, ese es el inicio".
      // Implies we align to Mondays.
      
      // Let's assume the roster starts on the first Monday that is part of the month
      // OR the Monday before if it covers most of the week?
      
      // Let's try: Start on the Monday of the week containing the 1st.
      // If 1st is Monday, start is 1st.
      // If 1st is Tuesday, start is prev Monday (-1 day)? Or next Monday (+6)?
      // If we start next Monday, we miss 1st-6th.
      // If we start prev Monday, we include end of prev month.
      
      // Common practice: The week belongs to the month that has 4+ days.
      // But user rule is specific about Sunday.
      
      // Let's stick to "Month starts on the Monday that starts the first FULL week"? No.
      // Let's stick to: "Period starts on the Monday of the week containing the 1st, 
      // unless 1st is Sunday".
      
      DateTime startOfWeek = firstDayOfMonth;
      while (startOfWeek.weekday != DateTime.monday) {
        startOfWeek = startOfWeek.subtract(const Duration(days: 1));
      }
      
      // If 1st is Sunday, we handled it above (start 2nd).
      // What if 1st is Sat? Start is prev Monday. Week is mostly in prev month?
      // Mon-Fri in prev month, Sat-Sun in this. 
      // Maybe that week belongs to prev month?
      
      // To be safe and standard, let's just find the first Monday OF the month?
      // If 1st is Tue, first Monday is 7th. That skips days.
      
      // Let's use the user's specific text as guide:
      // "Si el mes empieza en dom, ese dom pertenece al mes anterior" -> Period starts next day (Mon).
      // "Si el mes empieza en lun, ese es el inicio" -> Period starts same day.
      // What about other days? 
      // Likely logic: Find the Monday OF this week.
      
      periodStart = startOfWeek;
      // If 1st is Sunday, startOfWeek would be Monday prior.
      // But we have the explicit check for Sunday above.
      
      // Wait, if 1st is Sunday, firstDayOfMonth.weekday == 7.
      // My `else` block logic `startOfWeek` goes back to Monday (6 days prior).
      // The `if (sunday)` block sets it to next day (Monday).
      // This matches logic "starts on Mon".
      
      // Check if 1st is Saturday. Weekday 6. 
      // `startOfWeek` goes back to Monday (-5 days).
      // That week has Mon-Fri in prev month. Sat-Sun in this.
      // Usually that week belongs to PREV month.
      // But without explicit instruction, I will include it?
      // Or maybe check if >3 days in this month?
      
      // Let's follow "start on Monday". most logical for rosters.
      // I will implement "Start on Monday of the week containing the 1st".
    }
    
    // Now find periodEnd.
    // It should be the Sunday that ends the last week of the month.
    // Similar logic.
    final lastDayOfMonth = DateTime(year, month + 1, 0); // Day 0 of next month = last of current
    DateTime periodEnd = lastDayOfMonth;
    
    // Advance to Sunday
    while (periodEnd.weekday != DateTime.sunday) {
      periodEnd = periodEnd.add(const Duration(days: 1));
    }
    
    // Generate weeks
    List<Map<String, DateTime>> weeks = [];
    DateTime current = periodStart;
    
    while (current.isBefore(periodEnd)) {
      final endOfWeek = current.add(const Duration(days: 6));
      weeks.add({
        'start': current,
        'end': endOfWeek,
      });
      current = current.add(const Duration(days: 7));
    }
    
    return {
      'periodStart': periodStart,
      'periodEnd': periodEnd, // This will be the Sunday
      'weekCount': weeks.length,
      'weeks': weeks,
    };
  }
}
