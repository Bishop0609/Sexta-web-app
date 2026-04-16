import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/core/permissions/role_permissions.dart';

final nightGuardReportProvider = FutureProvider.family<Map<String, dynamic>, ({int year, int month})>(
  (ref, params) async {
    final userRole = AuthService().currentUser?.role;
    
    if (userRole == null || !RolePermissions.canAccessReports(userRole)) {
      throw Exception('Permisos insuficientes para acceder a este reporte.');
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'get_night_guard_monthly_report',
        params: {'p_year': params.year, 'p_month': params.month},
      );
      
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al obtener reporte de guardia nocturna: $e');
    }
  },
);
