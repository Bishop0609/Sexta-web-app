import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/models/viper_emergencia_model.dart';

class ViperService {
  final _supabase = Supabase.instance.client;

  /// Importa un archivo Excel con registros VIPER y los guarda en Supabase.
  /// Retorna un mapa con conteos: { 'inserted', 'updated', 'skipped' }.
  Future<Map<String, dynamic>> importExcel(Uint8List fileBytes, String userId) async {
    final excel = Excel.decodeBytes(fileBytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.isEmpty) {
      return {'inserted': 0, 'updated': 0, 'skipped': 0};
    }

    // Obtener headers (primera fila)
    final headerRow = sheet.rows.first;
    int colFecha = -1, colCorrelativo = -1, colClave = -1;
    int colCalle = -1, colEsquina = -1, colComuna = -1, colCarro = -1;

    for (int i = 0; i < headerRow.length; i++) {
      final header = (headerRow[i]?.value?.toString() ?? '').trim().toUpperCase();
      switch (header) {
        case 'FECHA':        colFecha = i;        break;
        case 'CORRELATIVO':  colCorrelativo = i;  break;
        case 'CLAVE':        colClave = i;        break;
        case 'CALLE':        colCalle = i;        break;
        case 'ESQUINA':      colEsquina = i;      break;
        case 'COMUNA':       colComuna = i;       break;
        case 'CARRO':        colCarro = i;        break;
      }
    }

    final Map<int, ViperEmergenciaModel> grouped = {};
    int skipped = 0;

    // Iterar filas desde la segunda
    for (int rowIdx = 1; rowIdx < sheet.rows.length; rowIdx++) {
      final row = sheet.rows[rowIdx];

      String _cell(int col) {
        if (col < 0 || col >= row.length) return '';
        return row[col]?.value?.toString().trim() ?? '';
      }

      // FILTRO 1: carro permitido
      final carro = _cell(colCarro);
      if (carro != 'B-6' && carro != 'BM-6' && carro != 'J-6') {
        skipped++;
        continue;
      }

      final clave = _cell(colClave);
      final claveUpper = clave.toUpperCase();

      // Determinar código para filtros
      String codigoFiltro;
      if (claveUpper.contains('ALARMA')) {
        codigoFiltro = clave;
      } else if (clave.contains('(')) {
        codigoFiltro = clave.split('(')[0].trim();
      } else {
        codigoFiltro = clave;
      }



      final correlativoStr = _cell(colCorrelativo);
      final correlativo = int.tryParse(correlativoStr);
      if (correlativo == null) {
        skipped++;
        continue;
      }

      final fecha = _cell(colFecha);
      final calle = _cell(colCalle);
      final esquina = colEsquina >= 0 ? _cell(colEsquina) : null;
      final comuna = colComuna >= 0 ? _cell(colComuna) : null;

      if (grouped.containsKey(correlativo)) {
        // Agregar carro a la lista existente
        final existing = grouped[correlativo]!;
        final updatedCarros = [...(existing.carros ?? [])];
        if (!updatedCarros.contains(carro)) updatedCarros.add(carro);
        grouped[correlativo] = ViperEmergenciaModel(
          id: existing.id,
          correlativo: existing.correlativo,
          fecha: existing.fecha,
          codigoEmergencia: existing.codigoEmergencia,
          codigoPrincipal: existing.codigoPrincipal,
          tipoEmergencia: existing.tipoEmergencia,
          direccion: existing.direccion,
          carros: updatedCarros.cast<String>(),
          comuna: existing.comuna,
          attendanceEventId: existing.attendanceEventId,
          estadoMatching: existing.estadoMatching,
          notas: existing.notas,
          importedAt: existing.importedAt,
          importedBy: existing.importedBy,
          updatedAt: existing.updatedAt,
        );
      } else {
        grouped[correlativo] = ViperEmergenciaModel.fromExcelRow(
          correlativo: correlativo,
          fecha: fecha,
          clave: clave,
          calle: calle,
          esquina: esquina,
          carro: carro,
          comuna: comuna,
          importedByUserId: userId,
        );
      }
    }

    int insertCount = 0;
    int updateCount = 0;
    int skipCount = 0;

    for (final modelo in grouped.values) {
      final carrosList = modelo.carros ?? [];

      final existing = await _supabase
          .from('viper_emergencias')
          .select('id, estado_matching')
          .eq('correlativo', modelo.correlativo)
          .maybeSingle();

      if (existing == null) {
        // INSERT
        await _supabase.from('viper_emergencias').insert({
          ...modelo.toJson(),
          'carros': carrosList,
        });
        insertCount++;
      } else if (existing['estado_matching'] != 'vinculada') {
        // UPDATE (no sobreescribir vinculadas)
        await _supabase
            .from('viper_emergencias')
            .update({
              ...modelo.toJson(),
              'carros': carrosList,
            })
            .eq('id', existing['id'] as String);
        updateCount++;
      } else {
        // Ya vinculada, no tocar
        skipCount++;
      }
    }

    return {'inserted': insertCount, 'updated': updateCount, 'skipped': skipCount};
  }

  /// Ejecuta el auto-match entre registros VIPER y eventos de asistencia.
  Future<List<Map<String, dynamic>>> runAutoMatch() async {
    final response = await _supabase.rpc('auto_match_viper_emergencias');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Vincula manualmente una emergencia VIPER con un evento de asistencia.
  Future<void> linkManual(String viperEmergenciaId, String attendanceEventId) async {
    await _supabase
        .from('viper_emergencias')
        .update({
          'attendance_event_id': attendanceEventId,
          'estado_matching': 'vinculada',
        })
        .eq('id', viperEmergenciaId);
  }

  /// Marca una emergencia VIPER como descartada con notas.
  Future<void> markDescartada(String viperEmergenciaId, String notas) async {
    await _supabase
        .from('viper_emergencias')
        .update({'estado_matching': 'descartada', 'notas': notas})
        .eq('id', viperEmergenciaId);
  }

  /// Marca una emergencia VIPER como "no aplica".
  Future<void> markNoAplica(String viperEmergenciaId) async {
    await _supabase
        .from('viper_emergencias')
        .update({'estado_matching': 'no_aplica'})
        .eq('id', viperEmergenciaId);
  }

  /// Obtiene estadísticas del dashboard VIPER para un mes determinado.
  Future<Map<String, dynamic>> getDashboardStats(int year, int month) async {
    final response = await _supabase.rpc(
      'get_viper_dashboard_stats',
      params: {'p_year': year, 'p_month': month},
    );
    return response as Map<String, dynamic>;
  }

  /// Obtiene todas las emergencias VIPER de un mes, ordenadas por fecha descendente.
  Future<List<ViperEmergenciaModel>> getByMonth(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final startOfNextMonth = DateTime(year, month + 1, 1);

    final response = await _supabase
        .from('viper_emergencias')
        .select()
        .gte('fecha', startOfMonth.toIso8601String())
        .lt('fecha', startOfNextMonth.toIso8601String())
        .order('fecha', ascending: false);

    return (response as List)
        .map((e) => ViperEmergenciaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene eventos de emergencia del sistema que NO están vinculados a un VIPER.
  Future<List<Map<String, dynamic>>> getUnmatchedSystemEvents(int year, int month) async {
    // IDs de attendance_events ya vinculados
    final vinculadas = await _supabase
        .from('viper_emergencias')
        .select('attendance_event_id')
        .not('attendance_event_id', 'is', null);

    final vinculadaIds = (vinculadas as List)
        .map((e) => e['attendance_event_id'] as String)
        .toList();

    // act_type_id de Emergencia
    final actType = await _supabase
        .from('act_types')
        .select('id')
        .eq('activity_type_key', 'emergencia')
        .single();

    // Calcular fecha inicio mes siguiente
    final nextMonthDate = DateTime(year, month + 1, 1).toIso8601String();
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';

    final results = await _supabase
        .from('attendance_events')
        .select('id, event_date, subtype, location')
        .eq('act_type_id', actType['id'] as String)
        .gte('event_date', startDate)
        .lt('event_date', nextMonthDate)
        .order('event_date');

    // Filtrar en cliente los no vinculados
    return (results as List)
        .where((e) => !vinculadaIds.contains(e['id'] as String))
        .cast<Map<String, dynamic>>()
        .toList();
  }
}
