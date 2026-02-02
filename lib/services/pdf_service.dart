import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Servicio para generación de reportes PDF
class PdfService {
  /// Genera reporte PDF de permisos aprobados entre fechas
  Future<void> generatePermissionsReport({
    required List<Map<String, dynamic>> permissions,
    required DateTime startDate,
    required DateTime endDate,
    String? firefighterName, // Opcional: nombre del bombero filtrado
  }) async {
    final pdf = pw.Document();
    
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startStr = dateFormat.format(startDate);
    final endStr = dateFormat.format(endDate);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return [
            // Título principal
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Sexta Compañía',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Sistema de Gestión Integral',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Permisos entre fechas $startStr y $endStr',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (firefighterName != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Bombero: $firefighterName',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ] else ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Todos los bomberos',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),

            // Verificar si hay permisos
            if (permissions.isEmpty)
              pw.Center(
                child: pw.Text(
                  'No se encontraron permisos aprobados en el rango de fechas seleccionado.',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              )
            else
              // Lista de permisos
              ...permissions.map((permission) {
                final user = permission['user'] as Map<String, dynamic>;
                final firefighterName = user['full_name'] as String;
                final reason = permission['reason'] as String;
                final permStartDate = DateTime.parse(permission['start_date']);
                final permEndDate = DateTime.parse(permission['end_date']);
                final daysRequested = permEndDate.difference(permStartDate).inDays + 1;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Nombre del bombero
                      pw.Text(
                        firefighterName,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      
                      // Motivo
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 80,
                            child: pw.Text(
                              'Motivo:',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              reason,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      
                      // Período
                      pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 80,
                            child: pw.Text(
                              'Período:',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            'Desde ${dateFormat.format(permStartDate)} hasta ${dateFormat.format(permEndDate)}',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      
                      // Días solicitados
                      pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 80,
                            child: pw.Text(
                              'Días:',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            '$daysRequested ${daysRequested == 1 ? "día" : "días"}',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Column(
              children: [
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Desarrollado por GuntherSOFT, 2026',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.Text(
                      'Página ${context.pageNumber} de ${context.pagesCount}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Mostrar vista de impresión/compartir
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
