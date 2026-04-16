import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rifa_model.dart';
import '../models/rifa_talonario_model.dart';
import '../models/rifa_entidad_externa_model.dart';

class RifaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<RifaModel?> getRifaActiva() async {
    try {
      final response = await _supabase
          .from('rifas')
          .select()
          .eq('estado', 'activa')
          .maybeSingle();

      if (response != null) {
        return RifaModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error en getRifaActiva: $e');
      return null;
    }
  }

  Future<String?> crearRifa({
    required String nombre,
    required int anio,
    required int numerosPorTalonario,
    required int precioNumero,
    required int totalTalonarios,
    required int correlativoInicio,
    required String createdBy,
  }) async {
    try {
      final response = await _supabase.rpc('crear_rifa', params: {
        'p_nombre': nombre,
        'p_anio': anio,
        'p_numeros_por_talonario': numerosPorTalonario,
        'p_precio_numero': precioNumero,
        'p_total_talonarios': totalTalonarios,
        'p_correlativo_inicio': correlativoInicio,
        'p_created_by': createdBy,
      });

      return response as String?;
    } catch (e) {
      print('Error en crearRifa: $e');
      return null;
    }
  }

  Future<List<RifaTalonarioModel>> getTalonarios(
    String rifaId, {
    String? estado,
    String? bomberoId,
  }) async {
    try {
      var query = _supabase
          .from('rifa_talonarios')
          .select('*, users!asignado_a(full_name), rifa_entidades_externas!entidad_externa_id(nombre, porcentaje_descuento)')
          .eq('rifa_id', rifaId);

      if (estado != null) {
        query = query.eq('estado', estado);
      }
      if (bomberoId != null) {
        query = query.eq('asignado_a', bomberoId);
      }

      final response = await query.order('numero_talonario', ascending: true);

      return (response as List)
          .map((json) => RifaTalonarioModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error en getTalonarios: $e');
      return [];
    }
  }

  Future<List<RifaTalonarioModel>> getTalonariosDisponibles(
      String rifaId) async {
    return getTalonarios(rifaId, estado: 'disponible');
  }

  Future<List<RifaTalonarioModel>> getTalonariosPorBombero(
      String rifaId, String bomberoId) async {
    return getTalonarios(rifaId, bomberoId: bomberoId);
  }

  Future<Map<String, dynamic>> entregarTalonarios({
    required String rifaId,
    required List<String> talonarioIds,
    required String bomberoId,
    required String entregadoPor,
  }) async {
    try {
      final response = await _supabase.rpc('entregar_talonarios', params: {
        'p_rifa_id': rifaId,
        'p_talonario_ids': talonarioIds,
        'p_bombero_id': bomberoId,
        'p_entregado_por': entregadoPor,
      });

      return {'success': true, 'data': response};
    } catch (e) {
      print('Error en entregarTalonarios: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> recibirTalonario({
    required String talonarioId,
    required int numerosVendidos,
    required int montoEntregado,
    required String recibidoPor,
    String? notas,
  }) async {
    try {
      final response = await _supabase.rpc('recibir_talonario', params: {
        'p_talonario_id': talonarioId,
        'p_numeros_vendidos': numerosVendidos,
        'p_monto_entregado': montoEntregado,
        'p_recibido_por': recibidoPor,
        'p_notas': notas,
      });

      return {'success': true, 'data': response};
    } catch (e) {
      print('Error en recibirTalonario: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getResumenGlobal(String rifaId) async {
    try {
      return await _supabase
          .from('rifa_resumen_global')
          .select()
          .eq('rifa_id', rifaId)
          .maybeSingle();
    } catch (e) {
      print('Error en getResumenGlobal: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getResumenPorBombero(String rifaId) async {
    try {
      final response = await _supabase
          .from('rifa_resumen_por_bombero')
          .select()
          .eq('rifa_id', rifaId)
          .order('total_numeros_vendidos', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getResumenPorBombero: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLogMovimientos(String rifaId) async {
    try {
      final logsResponse = await _supabase
          .from('rifa_log')
          .select('*, rifa_talonarios!talonario_id(numero_talonario)')
          .eq('rifa_id', rifaId)
          .order('created_at', ascending: false);

      final logs = List<Map<String, dynamic>>.from(logsResponse);

      final userIds = <String>{};
      for (final log in logs) {
        if (log['ejecutado_por'] != null) userIds.add(log['ejecutado_por'] as String);
        if (log['usuario_destino'] != null) userIds.add(log['usuario_destino'] as String);
      }

      final entidadIds = <String>{};
      for (final log in logs) {
        final detalle = log['detalle'] as Map<String, dynamic>?;
        if (detalle != null && detalle['entidad_id'] != null) {
          entidadIds.add(detalle['entidad_id'] as String);
        }
      }

      final userMap = <String, String>{};
      if (userIds.isNotEmpty) {
        final usersResponse = await _supabase
            .from('users')
            .select('id, full_name')
            .inFilter('id', userIds.toList());
        for (final u in List<Map<String, dynamic>>.from(usersResponse)) {
          userMap[u['id']] = u['full_name'] ?? '';
        }
      }

      final entidadMap = <String, String>{};
      if (entidadIds.isNotEmpty) {
        final entResponse = await _supabase
            .from('rifa_entidades_externas')
            .select('id, nombre')
            .inFilter('id', entidadIds.toList());
        for (final e in List<Map<String, dynamic>>.from(entResponse)) {
          entidadMap[e['id']] = e['nombre'] ?? '';
        }
      }

      for (final log in logs) {
        log['ejecutado_por_nombre'] = userMap[log['ejecutado_por']] ?? '-';

        final detalle = log['detalle'] as Map<String, dynamic>?;

        if (log['usuario_destino'] != null) {
          log['destinatario_nombre'] = userMap[log['usuario_destino']] ?? '-';
        } else if (detalle != null && detalle['entidad_id'] != null) {
          log['destinatario_nombre'] = entidadMap[detalle['entidad_id']] ?? '-';
        } else {
          log['destinatario_nombre'] = '-';
        }

        final tal = log['rifa_talonarios'] as Map<String, dynamic>?;
        log['numero_talonario'] = tal?['numero_talonario'];
      }

      return logs;
    } catch (e) {
      print('Error en getLogMovimientos: $e');
      return [];
    }
  }

  Future<bool> cerrarRifa(String rifaId) async {
    try {
      await _supabase
          .from('rifas')
          .update({'estado': 'cerrada'})
          .eq('id', rifaId);
      return true;
    } catch (e) {
      print('Error en cerrarRifa: $e');
      return false;
    }
  }

  Future<List<RifaEntidadExternaModel>> getEntidadesExternas() async {
    try {
      final response = await _supabase
          .from('rifa_entidades_externas')
          .select()
          .order('nombre');
      return (response as List)
          .map((json) => RifaEntidadExternaModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error en getEntidadesExternas: $e');
      return [];
    }
  }

  Future<String?> crearEntidadExterna({
    required String nombre,
    required String tipo,
    String? contacto,
    String? telefono,
    required int porcentajeDescuento,
    String? notas,
  }) async {
    try {
      final response = await _supabase.from('rifa_entidades_externas').insert({
        'nombre': nombre,
        'tipo': tipo,
        'contacto': contacto,
        'telefono': telefono,
        'porcentaje_descuento': porcentajeDescuento,
        'notas': notas,
      }).select().single();
      return response['id'] as String;
    } catch (e) {
      print('Error en crearEntidadExterna: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> entregarTalonariosExterna({
    required String rifaId,
    required List<String> talonarioIds,
    required String entidadId,
    required String entregadoPor,
  }) async {
    try {
      final response = await _supabase.rpc('entregar_talonarios_externa', params: {
        'p_rifa_id': rifaId,
        'p_talonario_ids': talonarioIds,
        'p_entidad_id': entidadId,
        'p_entregado_por': entregadoPor,
      });

      return {'success': true, 'data': response};
    } catch (e) {
      print('Error en entregarTalonariosExterna: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> recibirTalonarioExterna({
    required String talonarioId,
    required int numerosVendidos,
    required int montoEntregado,
    required String recibidoPor,
    String? notas,
  }) async {
    try {
      final response = await _supabase.rpc('recibir_talonario_externa', params: {
        'p_talonario_id': talonarioId,
        'p_numeros_vendidos': numerosVendidos,
        'p_monto_entregado': montoEntregado,
        'p_recibido_por': recibidoPor,
        'p_notas': notas,
      });

      return {'success': true, 'data': response};
    } catch (e) {
      print('Error en recibirTalonarioExterna: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getResumenPorEntidad(String rifaId) async {
    try {
      final response = await _supabase
          .from('rifa_resumen_por_entidad')
          .select()
          .eq('rifa_id', rifaId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getResumenPorEntidad: $e');
      return [];
    }
  }

  /// Devuelve un talonario entregado a bodega (queda disponible para reasignar)
  Future<Map<String, dynamic>> devolverABodega({
    required String talonarioId,
    required String ejecutadoPor,
    String? motivo,
  }) async {
    try {
      final response = await _supabase.rpc('devolver_a_bodega', params: {
        'p_talonario_id': talonarioId,
        'p_ejecutado_por': ejecutadoPor,
        'p_motivo': motivo,
      });
      return {'success': true, 'data': response};
    } catch (e) {
      print('Error en devolverABodega: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Obtener estado de rifa para un bombero específico (para el dashboard)
  Future<Map<String, dynamic>?> getEstadoRifaBombero(String bomberoId) async {
    try {
      // 1. Verificar si hay rifa activa
      final rifa = await getRifaActiva();
      if (rifa == null) return null;

      // 2. Obtener talonarios asignados a este bombero
      final talonarios = await getTalonariosPorBombero(rifa.id, bomberoId);

      // 3. Clasificar
      final entregados = talonarios.where((t) => t.estado == 'entregado').toList();
      final devueltos = talonarios.where((t) => t.estado.startsWith('devuelto')).toList();
      final devueltosCompletos = talonarios.where((t) => t.estado == 'devuelto_total').toList();

      return {
        'rifa_nombre': rifa.nombre,
        'rifa_id': rifa.id,
        'tiene_talonarios': talonarios.isNotEmpty,
        'talonarios_pendientes': entregados,
        'talonarios_devueltos': devueltos,
        'talonarios_devueltos_completos': devueltosCompletos,
        'total_asignados': talonarios.length,
        'total_pendientes': entregados.length,
        'total_devueltos': devueltos.length,
        'numeros_vendidos': talonarios.fold<int>(0, (sum, t) => sum + t.numerosVendidos),
        'monto_recaudado': talonarios.fold<int>(0, (sum, t) => sum + t.montoRecaudado),
      };
    } catch (e) {
      print('Error obteniendo estado rifa bombero: $e');
      return null;
    }
  }
}
