import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Servicio para generar PDFs de asistencia
class AttendancePdfService {
  /// Genera PDF de asistencia con formato profesional y compacto
  static Future<void> generateAttendancePdf({
    required Map<String, dynamic> event,
    required List<Map<String, dynamic>> records,
    required Map<String, int> totals,
  }) async {
    final pdf = pw.Document();
    
    // Agrupar registros por categoría
    final grouped = _groupRecordsByCategory(records);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Encabezado
          _buildHeader(event),
          pw.SizedBox(height: 20),
          
          // Totales
          _buildTotals(totals),
          pw.SizedBox(height: 20),
          
          // Lista de asistencia por categorías
          ...grouped.entries.map((entry) => 
            _buildCategorySection(entry.key, entry.value)
          ),
        ],
      ),
    );
    
    // Compartir PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'asistencia_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }
  
  static pw.Widget _buildHeader(Map<String, dynamic> event) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'REGISTRO DE ASISTENCIA',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Tipo: ${event['act_types']['name']}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Subtipo: ${event['subtype'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Ubicación: ${event['location'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(event['event_date']))}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Hora: ${DateFormat('HH:mm').format(DateTime.parse(event['created_at']))}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Registrado por: ${event['usuarios']['nombre']} ${event['usuarios']['apellido']}', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildTotals(Map<String, int> totals) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem('Presentes', totals['present'] ?? 0, PdfColors.green),
          _buildTotalItem('Ausentes', totals['absent'] ?? 0, PdfColors.red),
          _buildTotalItem('Con Permiso', totals['permiso'] ?? 0, PdfColors.orange),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTotalItem(String label, int count, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(
          count.toString(),
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }
  
  static pw.Widget _buildCategorySection(String category, List<Map<String, dynamic>> users) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          category,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellHeight: 15,
          data: [
            ['Nombre', 'Rango', 'Estado'],
            ...users.map((u) => [
              '${u['nombre']} ${u['apellido']}',
              u['rango'],
              _getStatusText(u['status']),
            ]),
          ],
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }
  
  static Map<String, List<Map<String, dynamic>>> _groupRecordsByCategory(
    List<Map<String, dynamic>> records
  ) {
    // Configuración de categorías (replicado de take_attendance_screen.dart)
    const attendanceCategories = {
      'OFICIALES DE COMPAÑÍA': {
        'patterns': ['Director', 'Secretari', 'Pro-Secretari', 'Tesorer', 'Pro-Tesorer', 'Capitán', 'Teniente', 'Ayudante', 'Inspector M.'],
      },
      'OFICIALES SUPERIORES': {
        'patterns': ['Comandante', 'Superintendente', 'Director G.'],
      },
      'BOMBEROS ACTIVOS': {
        'patterns': ['Bombero'],
      },
      'ASPIRANTES Y POSTULANTES': {
        'patterns': ['Aspirante', 'Postulante'],
      },
    };

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final record in records) {
      final rango = record['rango'] as String? ?? '';
      
      String? categoryName;
      for (final entry in attendanceCategories.entries) {
        final patterns = entry.value['patterns'] as List;
        if (patterns.any((pattern) => rango.contains(pattern as String))) {
          categoryName = entry.key;
          break;
        }
      }
      
      categoryName ??= 'OTROS';
      
      if (!grouped.containsKey(categoryName)) {
        grouped[categoryName] = [];
      }
      grouped[categoryName]!.add(record);
    }

    // Ordenar cada categoría por antigüedad
    for (final category in grouped.values) {
      category.sort((a, b) {
        final seniorityA = a['seniority'] as int? ?? 0;
        final seniorityB = b['seniority'] as int? ?? 0;
        return seniorityB.compareTo(seniorityA);
      });
    }

    return grouped;
  }
  
  static String _getStatusText(String status) {
    switch (status) {
      case 'present': return 'Presente';
      case 'absent': return 'Ausente';
      case 'permiso': return 'Con Permiso';
      default: return status;
    }
  }
}
