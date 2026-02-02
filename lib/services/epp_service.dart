import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:sexta_app/models/epp_assignment_model.dart';

/// Servicio para gestión de EPP (Equipo de Protección Personal)
class EPPService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Asignar EPP a un bombero
  Future<EPPAssignmentModel> assignEPP({
    required String userId,
    required EPPType eppType,
    required String internalCode,
    String? brand,
    String? model,
    String? color,
    required EPPCondition condition,
    required DateTime receptionDate,
    String? observations,
    required String createdBy,
  }) async {
    final data = {
      'user_id': userId,
      'epp_type': eppType.displayName,
      'internal_code': internalCode,
      'brand': brand,
      'model': model,
      'color': color,
      'condition': condition.displayName,
      'reception_date': receptionDate.toIso8601String().split('T')[0],
      'observations': observations,
      'is_returned': false,
      'created_by': createdBy,
    };

    final response = await _client
        .from(AppConstants.eppAssignmentsTable)
        .insert(data)
        .select()
        .single();

    return EPPAssignmentModel.fromJson(response);
  }

  /// Actualizar asignación de EPP
  Future<void> updateAssignment({
    required String assignmentId,
    required String updatedBy,
    String? internalCode,
    String? brand,
    String? model,
    String? color,
    EPPCondition? condition,
    DateTime? receptionDate,
    String? observations,
  }) async {
    final Map<String, dynamic> updates = {
      'updated_by': updatedBy,
    };

    if (internalCode != null) updates['internal_code'] = internalCode;
    if (brand != null) updates['brand'] = brand;
    if (model != null) updates['model'] = model;
    if (color != null) updates['color'] = color;
    if (condition != null) updates['condition'] = condition.displayName;
    if (receptionDate != null) {
      updates['reception_date'] = receptionDate.toIso8601String().split('T')[0];
    }
    if (observations != null) updates['observations'] = observations;

    await _client
        .from(AppConstants.eppAssignmentsTable)
        .update(updates)
        .eq('id', assignmentId);
  }

  /// Marcar EPP como devuelto
  Future<void> returnEPP({
    required String assignmentId,
    required DateTime returnDate,
    required String returnReason,
    required String returnedBy,
  }) async {
    // Crear registro de devolución
    await _client.from(AppConstants.eppReturnsTable).insert({
      'assignment_id': assignmentId,
      'return_date': returnDate.toIso8601String().split('T')[0],
      'return_reason': returnReason,
      'returned_by': returnedBy,
    });

    // Marcar asignación como devuelta
    await _client
        .from(AppConstants.eppAssignmentsTable)
        .update({
          'is_returned': true,
          'updated_by': returnedBy,
        })
        .eq('id', assignmentId);
  }

  /// Obtener EPP activos de un bombero
  Future<List<EPPAssignmentModel>> getActiveEPPByUser(String userId) async {
    final response = await _client
        .from(AppConstants.eppAssignmentsTable)
        .select()
        .eq('user_id', userId)
        .eq('is_returned', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => EPPAssignmentModel.fromJson(json))
        .toList();
  }

  /// Obtener todas las asignaciones de un bombero (incluyendo devueltas)
  Future<List<EPPAssignmentModel>> getAllEPPByUser(String userId) async {
    final response = await _client
        .from(AppConstants.eppAssignmentsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => EPPAssignmentModel.fromJson(json))
        .toList();
  }

  /// Obtener estadísticas de EPP asignados por tipo
  Future<Map<EPPType, int>> getEPPStatisticsByType() async {
    final response = await _client
        .from(AppConstants.eppAssignmentsTable)
        .select('epp_type')
        .eq('is_returned', false);

    final Map<EPPType, int> statistics = {};
    
    for (final row in response as List) {
      final type = EPPType.fromString(row['epp_type'] as String);
      statistics[type] = (statistics[type] ?? 0) + 1;
    }

    return statistics;
  }

  /// Obtener devolución por ID de asignación
  Future<EPPReturnModel?> getReturnByAssignmentId(String assignmentId) async {
    final response = await _client
        .from(AppConstants.eppReturnsTable)
        .select()
        .eq('assignment_id', assignmentId)
        .maybeSingle();

    if (response == null) return null;
    return EPPReturnModel.fromJson(response);
  }

  /// Obtener todas las asignaciones (para admin)
  Future<List<EPPAssignmentModel>> getAllAssignments() async {
    final response = await _client
        .from(AppConstants.eppAssignmentsTable)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => EPPAssignmentModel.fromJson(json))
        .toList();
  }
}
