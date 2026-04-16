import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Servicio para generación de reportes PDF
class PdfService {
  /// Genera reporte PDF de permisos entre fechas
  /// [statusFilter]: 'approved' | 'rejected' | 'all'
  Future<void> generatePermissionsReport({
    required List<Map<String, dynamic>> permissions,
    required DateTime startDate,
    required DateTime endDate,
    String? firefighterName,
    String statusFilter = 'approved',
    String? activityName,
    bool groupByType = false,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final startStr = dateFormat.format(startDate);
    final endStr = dateFormat.format(endDate);
    final generatedStr = dateFormat.format(DateTime.now());

    final String statusLabel = statusFilter == 'approved'
        ? 'Aprobados'
        : statusFilter == 'rejected'
            ? 'Rechazados'
            : 'Aprobados y Rechazados';

    final String emptyMsg = statusFilter == 'all'
        ? 'No se encontraron permisos en el rango de fechas seleccionado.'
        : 'No se encontraron permisos $statusLabel en el rango de fechas seleccionado.';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SEXTA COMPAÑÍA DE BOMBEROS',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'REPORTE DE PERMISOS',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    if (activityName != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '$activityName - $startStr',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Estado: $statusLabel',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ] else ...[
                      pw.Text(
                        'Período: $startStr - $endStr',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Bombero: ${firefighterName ?? 'Todos'}  |  Estado: $statusLabel',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                    pw.Text(
                      'Fecha de generación: $generatedStr',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Text(
                  'Desarrollado por\nGuntherSOFT, 2026',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.right,
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) {
          if (permissions.isEmpty) {
            return [
              pw.Center(
                child: pw.Text(
                  emptyMsg,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ];
          }

          if (groupByType) {
            final activityPerms =
                permissions.where((p) => p['_report_group'] == 'actividad').toList();
            final periodPerms =
                permissions.where((p) => p['_report_group'] == 'periodo').toList();

            List<pw.Widget> widgets = [];

            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                color: PdfColors.grey200,
                child: pw.Text(
                  'PERMISOS SOLICITADOS PARA ESTA ACTIVIDAD (${activityPerms.length})',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));

            if (activityPerms.isEmpty) {
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  'No hay permisos solicitados para esta actividad.',
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ));
            } else {
              widgets.addAll(activityPerms.map((p) => _buildPermissionCard(p, dateFormat)));
            }

            widgets.add(pw.SizedBox(height: 12));
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                color: PdfColors.blue50,
                child: pw.Text(
                  'PERMISOS POR PERIODO QUE CUBREN ESTA FECHA (${periodPerms.length})',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));

            if (periodPerms.isEmpty) {
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  'No hay permisos por periodo que cubran esta fecha.',
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ));
            } else {
              widgets.addAll(periodPerms.map((p) => _buildPermissionCard(p, dateFormat)));
            }

            return widgets;
          }

          return permissions.map((p) => _buildPermissionCard(p, dateFormat)).toList();
        },
        footer: (context) => pw.Column(
          children: [
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Desarrollado por GuntherSOFT, 2026',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Pág. ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'Documento generado automáticamente · Sistema de Gestión Integral · Sexta Compañía de Bomberos',
                style: pw.TextStyle(fontSize: 6, color: PdfColors.grey500),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Widget _buildPermissionCard(
      Map<String, dynamic> permission, DateFormat dateFormat) {
    final user = permission['user'] as Map<String, dynamic>;
    final name = user['full_name'] as String;
    final rank = user['rank'] as String? ?? '';
    final reason = permission['reason'] as String;
    final permStatus = permission['status'] as String;
    final rejectionReason = permission['rejection_reason'] as String?;
    final tipoPermiso = permission['tipo_permiso'] as String? ?? 'fecha';
    final bool isActivityPermission = tipoPermiso == 'actividad';

    DateTime? permStartDate;
    DateTime? permEndDate;
    int? daysRequested;
    String? activityTitle;
    DateTime? activityDate;

    if (isActivityPermission) {
      final activity = permission['activity'] as Map<String, dynamic>?;
      if (activity != null) {
        activityTitle = activity['title'] as String?;
        if (activity['activity_date'] != null) {
          activityDate = DateTime.parse(activity['activity_date']);
        }
      }
    } else {
      if (permission['start_date'] != null) {
        permStartDate = DateTime.parse(permission['start_date']);
      }
      if (permission['end_date'] != null) {
        permEndDate = DateTime.parse(permission['end_date']);
      }
      if (permStartDate != null && permEndDate != null) {
        daysRequested = permEndDate.difference(permStartDate).inDays + 1;
      }
    }

    final bool isRejected = permStatus == 'rejected';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: isRejected ? PdfColors.red300 : PdfColors.grey400,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    name,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (rank.isNotEmpty)
                    pw.Text(rank, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: isRejected ? PdfColors.red100 : PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  isRejected ? 'Rechazado' : 'Aprobado',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: isRejected ? PdfColors.red800 : PdfColors.green800,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _buildRow('Motivo:', reason),
          pw.SizedBox(height: 4),
          if (isActivityPermission) ...[
            _buildRow('Actividad:', activityTitle ?? 'Sin nombre'),
            pw.SizedBox(height: 4),
            if (activityDate != null)
              _buildRow('Fecha:', dateFormat.format(activityDate)),
          ] else ...[
            if (permStartDate != null && permEndDate != null) ...[
              _buildRow(
                'Período:',
                'Desde ${dateFormat.format(permStartDate)} hasta ${dateFormat.format(permEndDate)}',
              ),
              pw.SizedBox(height: 4),
              _buildRow(
                'Días:',
                '${daysRequested ?? 0} ${(daysRequested ?? 0) == 1 ? "día" : "días"}',
              ),
            ] else
              _buildRow('Período:', 'No especificado'),
          ],
          if (isRejected && rejectionReason != null) ...[
            pw.SizedBox(height: 4),
            _buildRow('Motivo rechazo:', rejectionReason,
                labelColor: PdfColors.red700),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildRow(String label, String value,
      {PdfColor labelColor = PdfColors.black}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: labelColor,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}
