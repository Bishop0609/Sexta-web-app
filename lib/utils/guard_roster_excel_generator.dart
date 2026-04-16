// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:excel/excel.dart';
import '../services/report_service.dart';

/// Genera el Excel del Calendario de Rol de Guardia.
/// Formato simplificado: una tabla por semana, sin merges complejos.
class GuardRosterExcelGenerator {
  // Prioridad OBAC por rank
  static const _obacPriority = {
    'Capitán': 1,
    'Teniente 1°': 2,
    'Teniente 2°': 3,
    'Teniente 3°': 4,
  };

  static final _headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#D6EAF8'),
  );

  static final _boldStyle = CellStyle(bold: true);

  static final _dateStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#E8F0FE'),
  );

  static Uint8List generate(GuardRosterReportData data) {
    final excel = Excel.createExcel();

    // Crear hojas
    _buildNocturnaSheet(excel, data);
    _buildFdsSheet(excel, data);

    // Eliminar Sheet1 default
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes!);
  }

  // =============================================
  // HOJA NOCTURNA
  // =============================================
  static void _buildNocturnaSheet(Excel excel, GuardRosterReportData data) {
    final sheet = excel['Guardia Nocturna'];

    int currentRow = 0;

    // Título
    _setCell(sheet, currentRow, 0, 'CALENDARIO ROL DE GUARDIA NOCTURNA', bold: true, bg: '#D6EAF8');
    currentRow++;
    _setCell(sheet, currentRow, 0, 'Mes: ${data.mes}', bold: true);
    currentRow += 2;

    // Iterar por semana
    for (int wi = 0; wi < data.semanas.length; wi++) {
      final week = data.semanas[wi];
      final nocturnos = week.nocturnos;
      if (nocturnos.isEmpty) continue;

      // Header de semana
      _setCell(sheet, currentRow, 0,
          'Semana ${wi + 1}: ${_formatDateStr(week.weekStartDate)} al ${_formatDateStr(week.weekEndDate)}',
          bold: true, bg: '#D6EAF8');
      currentRow++;

      // Header de columnas: Rol | Lun DD/MM | Mar DD/MM | ...
      _setCell(sheet, currentRow, 0, 'Cargo', bold: true, bg: '#E8F0FE');
      for (int i = 0; i < nocturnos.length; i++) {
        final dayName = _getDayName(nocturnos[i].guardDate);
        final dateStr = _formatDateStr(nocturnos[i].guardDate);
        _setCell(sheet, currentRow, i + 1, '$dayName $dateStr', bold: true, bg: '#E8F0FE');
      }
      currentRow++;

      // Fila MAQUINISTA
      _setCell(sheet, currentRow, 0, 'MAQUINISTA', bold: true);
      for (int i = 0; i < nocturnos.length; i++) {
        final name = _getUserName(nocturnos[i].maquinistaId, data.usuarios);
        _setCell(sheet, currentRow, i + 1, name);
      }
      currentRow++;

      // Fila OBAC
      _setCell(sheet, currentRow, 0, 'OBAC', bold: true);
      for (int i = 0; i < nocturnos.length; i++) {
        final name = _getUserName(nocturnos[i].obacId, data.usuarios);
        _setCell(sheet, currentRow, i + 1, name);
      }
      currentRow++;

      // Filas BOMBERO/A (hasta 8)
      final maxBomberos = _getMaxBomberos(nocturnos);
      for (int b = 0; b < maxBomberos; b++) {
        _setCell(sheet, currentRow, 0, 'BOMBERO/A ${b + 1}', bold: true);
        for (int i = 0; i < nocturnos.length; i++) {
          final sorted = _sortBomberos(nocturnos[i].bomberoIds, data.usuarios);
          final name = b < sorted.length ? _getUserName(sorted[b], data.usuarios) : '';
          _setCell(sheet, currentRow, i + 1, name);
        }
        currentRow++;
      }

      // Fila vacía entre semanas
      currentRow += 2;
    }

    // Ajustar anchos
    sheet.setColumnWidth(0, 18);
    for (int i = 1; i <= 7; i++) {
      sheet.setColumnWidth(i, 30);
    }
  }

  // =============================================
  // HOJA FDS
  // =============================================
  static void _buildFdsSheet(Excel excel, GuardRosterReportData data) {
    final sheet = excel['Guardia FDS'];

    int currentRow = 0;

    // Título
    _setCell(sheet, currentRow, 0, 'CALENDARIO ROL DE GUARDIA FDS (SÁBADO Y DOMINGO)', bold: true, bg: '#D6EAF8');
    currentRow++;
    _setCell(sheet, currentRow, 0, 'Mes: ${data.mes}', bold: true);
    currentRow += 2;

    // Iterar por semana
    for (int wi = 0; wi < data.semanas.length; wi++) {
      final week = data.semanas[wi];
      final fdsRosters = week.fdsRosters;
      if (fdsRosters.isEmpty) continue;

      // Header de semana
      _setCell(sheet, currentRow, 0,
          'Semana ${wi + 1}: ${_formatDateStr(week.weekStartDate)} al ${_formatDateStr(week.weekEndDate)}',
          bold: true, bg: '#D6EAF8');
      currentRow++;

      // Agrupar FDS por fecha
      final Map<String, List<GuardDailyRoster>> byDate = {};
      for (final roster in fdsRosters) {
        byDate.putIfAbsent(roster.guardDate, () => []);
        byDate[roster.guardDate]!.add(roster);
      }

      // Ordenar fechas
      final sortedDates = byDate.keys.toList()..sort();

      for (final date in sortedDates) {
        final rosters = byDate[date]!;
        final dayName = _getDayName(date);
        final dateStr = _formatDateStr(date);

        // Buscar AM y PM
        final amRoster = rosters.where((r) => r.shiftPeriod == 'AM').firstOrNull;
        final pmRoster = rosters.where((r) => r.shiftPeriod == 'PM').firstOrNull;

        // Sub-header del día
        _setCell(sheet, currentRow, 0, '$dayName $dateStr', bold: true, bg: '#E8F0FE');
        _setCell(sheet, currentRow, 1, 'TURNO AM', bold: true, bg: '#E8F0FE');
        _setCell(sheet, currentRow, 2, 'TURNO PM', bold: true, bg: '#E8F0FE');
        currentRow++;

        // MAQUINISTA
        _setCell(sheet, currentRow, 0, 'MAQUINISTA', bold: true);
        _setCell(sheet, currentRow, 1, amRoster != null ? _getUserName(amRoster.maquinistaId, data.usuarios) : '');
        _setCell(sheet, currentRow, 2, pmRoster != null ? _getUserName(pmRoster.maquinistaId, data.usuarios) : '');
        currentRow++;

        // OBAC
        _setCell(sheet, currentRow, 0, 'OBAC', bold: true);
        _setCell(sheet, currentRow, 1, amRoster != null ? _getUserName(amRoster.obacId, data.usuarios) : '');
        _setCell(sheet, currentRow, 2, pmRoster != null ? _getUserName(pmRoster.obacId, data.usuarios) : '');
        currentRow++;

        // BOMBEROS
        final amSorted = amRoster != null ? _sortBomberos(amRoster.bomberoIds, data.usuarios) : <String>[];
        final pmSorted = pmRoster != null ? _sortBomberos(pmRoster.bomberoIds, data.usuarios) : <String>[];
        final maxB = amSorted.length > pmSorted.length ? amSorted.length : pmSorted.length;
        final displayMax = maxB > 0 ? maxB : 8; // mínimo 8 filas

        for (int b = 0; b < displayMax; b++) {
          _setCell(sheet, currentRow, 0, 'BOMBERO/A ${b + 1}', bold: true);
          _setCell(sheet, currentRow, 1, b < amSorted.length ? _getUserName(amSorted[b], data.usuarios) : '');
          _setCell(sheet, currentRow, 2, b < pmSorted.length ? _getUserName(pmSorted[b], data.usuarios) : '');
          currentRow++;
        }

        // Separador entre días
        currentRow++;
      }

      // Separador entre semanas
      currentRow++;
    }

    // Ajustar anchos
    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 35);
    sheet.setColumnWidth(2, 35);
  }

  // =============================================
  // HELPERS
  // =============================================

  /// Resuelve nombre de usuario desde el mapa
  static String _getUserName(String? userId, Map<String, GuardUserInfo> usuarios) {
    if (userId == null || userId.isEmpty) return '';
    final user = usuarios[userId];
    return user?.fullName ?? '';
  }

  /// Formatea "2026-03-23" → "23/03/2026"
  static String _formatDateStr(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return dateStr;
  }

  /// Obtiene nombre del día de la semana
  static String _getDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return days[date.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  /// Obtiene el máximo de bomberos en cualquier noche de la semana
  static int _getMaxBomberos(List<GuardDailyRoster> rosters) {
    int max = 8; // mínimo 8 filas
    for (final r in rosters) {
      if (r.bomberoIds.length > max) max = r.bomberoIds.length;
    }
    return max;
  }

  /// Ordena bombero_ids según reglas de prioridad:
  /// 1. Oficiales prioritarios (Capitán, T1°, T2°, T3°) en orden fijo
  /// 2. Otros oficiales por registro_compania ASC
  /// 3. Bomberos por registro_compania ASC
  static List<String> _sortBomberos(List<String> bomberoIds, Map<String, GuardUserInfo> usuarios) {
    if (bomberoIds.isEmpty) return [];

    final prioritarios = <String>[];
    final otrosOficiales = <String>[];
    final bomberos = <String>[];

    for (final id in bomberoIds) {
      final user = usuarios[id];
      if (user == null) {
        bomberos.add(id);
        continue;
      }

      if (_obacPriority.containsKey(user.rank)) {
        prioritarios.add(id);
      } else if (user.role.startsWith('oficial')) {
        otrosOficiales.add(id);
      } else {
        bomberos.add(id);
      }
    }

    // Ordenar prioritarios por prioridad fija
    prioritarios.sort((a, b) {
      final pa = _obacPriority[usuarios[a]?.rank] ?? 99;
      final pb = _obacPriority[usuarios[b]?.rank] ?? 99;
      return pa.compareTo(pb);
    });

    // Ordenar otros oficiales por registro_compania numérico
    otrosOficiales.sort((a, b) {
      final ra = int.tryParse(usuarios[a]?.registroCompania ?? '9999') ?? 9999;
      final rb = int.tryParse(usuarios[b]?.registroCompania ?? '9999') ?? 9999;
      return ra.compareTo(rb);
    });

    // Ordenar bomberos por registro_compania numérico
    bomberos.sort((a, b) {
      final ra = int.tryParse(usuarios[a]?.registroCompania ?? '9999') ?? 9999;
      final rb = int.tryParse(usuarios[b]?.registroCompania ?? '9999') ?? 9999;
      return ra.compareTo(rb);
    });

    return [...prioritarios, ...otrosOficiales, ...bomberos];
  }

  /// Escribe una celda con texto y estilo opcional
  static void _setCell(
    Sheet sheet,
    int row,
    int col,
    String value, {
    bool bold = false,
    String? bg,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(value);

    if (bg != null && bold) {
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(bg),
      );
    } else if (bg != null) {
      cell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(bg),
      );
    } else if (bold) {
      cell.cellStyle = CellStyle(bold: true);
    }
  }

  /// Descarga el archivo en Flutter Web
  static void downloadExcel(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
