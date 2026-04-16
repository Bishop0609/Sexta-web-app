import 'dart:typed_data';
import 'dart:html' as html show Blob, Url, AnchorElement;
import 'package:excel/excel.dart';
import '../services/report_service.dart';

class AttendanceExcelGenerator {
  static const _headerBg = '#D6EAF8';

  static Uint8List generate(MonthlyReportData data) {
    final excel = Excel.createExcel();

    // Excel crea una hoja "Sheet1" por defecto; la eliminamos al final
    _buildEmergenciasSheet(excel, data);
    _buildCitacionesSheet(excel, data);

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded!);
  }

  static void downloadExcel(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ─── HOJA EMERGENCIAS ──────────────────────────────────────────────────────

  static void _buildEmergenciasSheet(Excel excel, MonthlyReportData data) {
    final sheet = excel['Emergencias'];

    final bomberos = data.bomberos;
    final eventos = data.emergencias.eventos.cast<ReportEmergencyEvent>();
    final asistencia = data.emergencias.asistencia;
    final n = eventos.length;

    // Índices de columna (0-based)
    // A=0, B=1, C=2, D=3, E=4..E+n-1, separador=4+n, resumen cols=5+n..
    final sepCol = 4 + n;
    final resNCol = sepCol + 1;
    final resFechaCol = sepCol + 2;
    final resSubtipoCol = sepCol + 3;
    final resDirCol = sepCol + 4;

    // Fila 1: vacía (índice 0)

    // Fila 2: título
    _setCell(sheet, 1, 1, 'ESTADISTICA EMERGENCIAS', bold: true);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1),
    );

    // Fila 3: MES
    _setCell(sheet, 2, 1, 'MES:');
    _setCell(sheet, 2, 2, data.mes);

    // Fila 4: vacía

    // Fila 5: headers principales
    _setCell(sheet, 4, 0, 'Nº', bold: true, bg: _headerBg);
    _setCell(sheet, 4, 1, 'Nombre', bold: true, bg: _headerBg);
    _setCell(sheet, 4, 2, 'RUT', bold: true, bg: _headerBg);
    // col D vacía (índice 3)
    for (var i = 0; i < n; i++) {
      _setCell(sheet, 4, 4 + i, (i + 1).toString(), bold: true, bg: _headerBg);
    }
    _setCell(sheet, 4, resNCol, 'EMERGENCIAS', bold: true, bg: _headerBg);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: resNCol, rowIndex: 4),
      CellIndex.indexByColumnRow(columnIndex: resDirCol, rowIndex: 4),
    );

    // Fila 6: sub-headers del resumen
    _setCell(sheet, 5, 0, 'Nº', bold: true, bg: _headerBg);
    _setCell(sheet, 5, 1, 'Nombre', bold: true, bg: _headerBg);
    _setCell(sheet, 5, 2, 'RUT', bold: true, bg: _headerBg);
    _setCell(sheet, 5, resNCol, 'Nº', bold: true, bg: _headerBg);
    _setCell(sheet, 5, resFechaCol, 'Fecha', bold: true, bg: _headerBg);
    _setCell(sheet, 5, resSubtipoCol, 'SUBTIPO', bold: true, bg: _headerBg);
    _setCell(sheet, 5, resDirCol, 'DIRECCION', bold: true, bg: _headerBg);

    // Filas de datos (desde fila 7, índice 6)
    for (var bi = 0; bi < bomberos.length; bi++) {
      final bombero = bomberos[bi];
      final row = 6 + bi;

      _setCell(sheet, row, 0, (bi + 1).toString());
      _setCell(sheet, row, 1, bombero.fullName);
      _setCell(sheet, row, 2, bombero.rut);

      for (var ei = 0; ei < n; ei++) {
        final key = '${bombero.id}::${eventos[ei].id}';
        final val = asistencia[key] ?? 0.0;
        _setAttendanceCell(sheet, row, 4 + ei, val);
      }

      // Cuadro resumen: solo para las primeras N filas
      if (bi < n) {
        final evento = eventos[bi];
        _setCell(sheet, row, resNCol, (bi + 1).toString());
        _setCell(sheet, row, resFechaCol, _formatDate(evento.eventDate));
        _setCell(sheet, row, resSubtipoCol, evento.subtype);
        _setCell(sheet, row, resDirCol, evento.location);
      }
    }

    // Anchos de columna
    sheet.setColumnWidth(1, 35); // B: Nombre
    sheet.setColumnWidth(2, 15); // C: RUT
    for (var i = 0; i < n; i++) {
      sheet.setColumnWidth(4 + i, 5);
    }
    sheet.setColumnWidth(resFechaCol, 14);
    sheet.setColumnWidth(resSubtipoCol, 16);
    sheet.setColumnWidth(resDirCol, 30);
  }

  // ─── HOJA CITACIONES ───────────────────────────────────────────────────────

  static void _buildCitacionesSheet(Excel excel, MonthlyReportData data) {
    final sheet = excel['Citaciones'];

    final bomberos = data.bomberos;
    final eventos = data.citaciones.eventos.cast<ReportCitationEvent>();
    final asistencia = data.citaciones.asistencia;
    final n = eventos.length;

    final sepCol = 4 + n;
    final resNCol = sepCol + 1;
    final resFechaCol = sepCol + 2;
    final resCitacionCol = sepCol + 3;

    // Fila 2: título
    _setCell(sheet, 1, 1, 'ESTADISTICA CITACIONES', bold: true);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1),
    );

    // Fila 3: MES
    _setCell(sheet, 2, 1, 'MES:');
    _setCell(sheet, 2, 2, data.mes);

    // Fila 5: headers principales
    _setCell(sheet, 4, 0, 'Nº', bold: true, bg: _headerBg);
    _setCell(sheet, 4, 1, 'Nombre', bold: true, bg: _headerBg);
    _setCell(sheet, 4, 2, 'RUT', bold: true, bg: _headerBg);
    for (var i = 0; i < n; i++) {
      _setCell(sheet, 4, 4 + i, (i + 1).toString(), bold: true, bg: _headerBg);
    }
    _setCell(sheet, 4, resNCol, 'CITACIONES', bold: true, bg: _headerBg);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: resNCol, rowIndex: 4),
      CellIndex.indexByColumnRow(columnIndex: resCitacionCol, rowIndex: 4),
    );

    // Fila 6: sub-headers
    _setCell(sheet, 5, 0, 'Nº', bold: true, bg: _headerBg);
    _setCell(sheet, 5, 1, 'Nombre', bold: true, bg: _headerBg);
    _setCell(sheet, 5, 2, 'RUT', bold: true, bg: _headerBg);
    _setCell(sheet, 5, resNCol, 'Nº', bold: true, bg: _headerBg);
    _setCell(sheet, 5, resFechaCol, 'Fecha', bold: true, bg: _headerBg);
    _setCell(sheet, 5, resCitacionCol, 'Citación', bold: true, bg: _headerBg);

    // Filas de datos
    for (var bi = 0; bi < bomberos.length; bi++) {
      final bombero = bomberos[bi];
      final row = 6 + bi;

      _setCell(sheet, row, 0, (bi + 1).toString());
      _setCell(sheet, row, 1, bombero.fullName);
      _setCell(sheet, row, 2, bombero.rut);

      for (var ei = 0; ei < n; ei++) {
        final key = '${bombero.id}::${eventos[ei].id}';
        final val = asistencia[key] ?? 0.0;
        _setAttendanceCell(sheet, row, 4 + ei, val);
      }

      if (bi < n) {
        final evento = eventos[bi];
        _setCell(sheet, row, resNCol, (bi + 1).toString());
        _setCell(sheet, row, resFechaCol, _formatDate(evento.eventDate));
        _setCell(sheet, row, resCitacionCol, evento.actTypeName);
      }
    }

    // Anchos
    sheet.setColumnWidth(1, 35);
    sheet.setColumnWidth(2, 15);
    for (var i = 0; i < n; i++) {
      sheet.setColumnWidth(4 + i, 5);
    }
    sheet.setColumnWidth(resFechaCol, 14);
    sheet.setColumnWidth(resCitacionCol, 28);
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

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
    
    if (bg != null) {
      cell.cellStyle = CellStyle(
        bold: bold,
        backgroundColorHex: ExcelColor.fromHexString(bg),
      );
    } else {
      cell.cellStyle = CellStyle(
        bold: bold,
      );
    }
  }

  static void _setAttendanceCell(Sheet sheet, int row, int col, double val) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    // Mostrar 0.5 como "0,5" (como texto para formato chileno)
    if (val == 0.5) {
      cell.value = TextCellValue('0,5');
    } else {
      cell.value = IntCellValue(val.toInt());
    }
  }

  /// Convierte "2026-03-15" → "15/03/2026"
  static String _formatDate(String raw) {
    try {
      final parts = raw.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return raw;
  }
}
