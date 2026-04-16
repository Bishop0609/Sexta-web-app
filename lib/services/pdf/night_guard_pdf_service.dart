import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html show Blob, Url, AnchorElement;

class NightGuardPdfService {
  pw.Widget _buildHeaderWithBranding({
    required String title,
    required String subtitle,
    List<String>? additionalLines,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                subtitle,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              if (additionalLines != null)
                ...additionalLines.map((line) => pw.Text(line)),
            ],
          ),
        ),
        pw.Text(
          'Desarrollado por\nGuntherSOFT, 2026',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.right,
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    final now = DateTime.now();
    final fechaGen = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} hrs';
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado por GuntherSOFT - $fechaGen',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
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
    );
  }

  String _formatNumber(dynamic val) => val?.toString() ?? '0';

  Future<void> generateReport(Map<String, dynamic> data, int year, int month) async {
    final pdf = pw.Document();

    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final byUser = List<Map<String, dynamic>>.from(data['by_user'] as List<dynamic>? ?? []);
    final rankings = data['rankings'] as Map<String, dynamic>? ?? {};

    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final mesStr = '${monthNames[month - 1]} $year';
    final pStartDate = summary['month_start']?.toString() ?? '';
    final pEndDate = summary['month_end']?.toString() ?? '';
    
    // PORTADA Y RESUMEN (Portrait)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBranding(
              title: 'SEXTA COMPAÑÍA DE BOMBEROS',
              subtitle: 'Reporte Mensual de Guardia Nocturna',
              additionalLines: [
                'Período: $mesStr',
                if (pStartDate.isNotEmpty && pEndDate.isNotEmpty)
                  'Rango de fechas: $pStartDate a $pEndDate',
              ],
            ),
            pw.Divider(),
          ],
        ),
        footer: _buildFooter,
        build: (context) {
          final pct = double.tryParse(_formatNumber(summary['compliance_percentage'])) ?? 0;
          return [
            pw.SizedBox(height: 10),
            pw.Text('RESUMEN EJECUTIVO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              padding: const pw.EdgeInsets.all(0),
              children: [
                _buildSummaryBox('Cumplimiento Global', '$pct%', pct >= 80 ? PdfColors.green800 : (pct >= 60 ? PdfColors.orange800 : PdfColors.red800)),
                _buildSummaryBox('Asignaciones Totales', _formatNumber(summary['total_assignments'])),
                _buildSummaryBox('Presentes', _formatNumber(summary['total_presente']), PdfColors.green800),
                _buildSummaryBox('Ausencias', _formatNumber(summary['total_ausente']), PdfColors.red800),
                _buildSummaryBox('Reemplazadas', _formatNumber(summary['total_reemplazado_cubierto']), PdfColors.blue800),
                _buildSummaryBox('Sin registro', _formatNumber(summary['total_sin_registro']), PdfColors.orange800),
              ],
            ),
          ];
        },
      ),
    );

    // DETALLE POR BOMBERO (Landscape)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBranding(
              title: 'SEXTA COMPAÑÍA DE BOMBEROS',
              subtitle: 'DETALLE POR BOMBERO - $mesStr',
            ),
            pw.Divider(),
          ],
        ),
        footer: _buildFooter,
        build: (context) {
          return [
            pw.Text('DETALLE DE ASISTENCIA Y CUMPLIMIENTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1.2),
                6: const pw.FlexColumnWidth(1),
                7: const pw.FlexColumnWidth(1),
                8: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Bombero', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Asig.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Pres.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Aus.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Perm.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Reemp.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('S/R', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Cubrió', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                  ]
                ),
                ...byUser.map((b) {
                  final asig = _formatNumber(b['asignadas']);
                  final pres = _formatNumber(b['presente']);
                  final aus = _formatNumber(b['ausente']);
                  final perm = _formatNumber(b['permiso']);
                  final reem = _formatNumber(b['reemplazado_cubierto']);
                  final sr = _formatNumber(b['sin_registro']);
                  final cubrio = _formatNumber(b['cubriendo_otros']);
                  final pctStr = _formatNumber(b['porcentaje_cumplimiento']);
                  final pct = double.tryParse(pctStr) ?? 0;

                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(b['full_name']?.toString() ?? '', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(b['rank']?.toString() ?? '', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                        ]
                      )),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(asig, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(pres, style: const pw.TextStyle(fontSize: 9, color: PdfColors.green800), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(aus, style: pw.TextStyle(fontSize: 9, color: aus == '0' ? PdfColors.black : PdfColors.red800), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(perm, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(reem, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(sr, style: pw.TextStyle(fontSize: 9, color: sr == '0' ? PdfColors.black : PdfColors.orange800), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(cubrio, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$pctStr%', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: pct >= 80 ? PdfColors.green800 : (pct >= 60 ? PdfColors.orange800 : PdfColors.red800)), textAlign: pw.TextAlign.center)),
                    ]
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Leyenda: Asig.=Asignadas - Perm.=Permiso justificado - Reemp.=Reemplazado - S/R=Sin registro - Cubrió=Noches como reemplazante.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            )
          ];
        },
      ),
    );

    // RANKINGS (Portrait)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBranding(
              title: 'SEXTA COMPAÑÍA DE BOMBEROS',
              subtitle: 'RANKINGS DEL MES - $mesStr',
            ),
            pw.Divider(),
          ],
        ),
        footer: _buildFooter,
        build: (context) {
          final topCumplidores = List<Map<String, dynamic>>.from(rankings['top_cumplidores'] as List<dynamic>? ?? []);
          final topAusentes = List<Map<String, dynamic>>.from(rankings['top_ausentes'] as List<dynamic>? ?? []);
          final topCubridores = List<Map<String, dynamic>>.from(rankings['top_cubridores'] as List<dynamic>? ?? []);

          return [
            _buildRankingSection('Top Cumplidores', topCumplidores, 'porcentaje', 'asignadas', isPositive: true),
            pw.SizedBox(height: 20),
            _buildRankingSection('Top Ausencias', topAusentes, 'ausente', 'asignadas', isAusencia: true),
            pw.SizedBox(height: 20),
            _buildRankingSection('Top Cubridores', topCubridores, 'cubriendo_otros', '', isCubridor: true),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final filename = 'reporte_guardia_${year}_${month.toString().padLeft(2, '0')}.pdf';
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  pw.Widget _buildSummaryBox(String title, String value, [PdfColor? color]) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.black)),
        ],
      ),
    );
  }

  pw.Widget _buildRankingSection(String title, List<Map<String, dynamic>> data, String valKey, String totalKey, {bool isPositive = false, bool isAusencia = false, bool isCubridor = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (data.isEmpty)
            pw.Text('Sin datos para este mes.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            ...data.asMap().entries.map((req) {
              final idx = req.key + 1;
              final item = req.value;
              String detail = '';
              if (isAusencia) {
                detail = '${_formatNumber(item[valKey])} faltas de ${_formatNumber(item[totalKey])} asignadas';
              } else if (isCubridor) {
                detail = 'Cubrió ${_formatNumber(item[valKey])} veces';
              } else {
                detail = '${_formatNumber(item[totalKey])} asignadas, ${_formatNumber(item[valKey])}% cumplimiento';
              }
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  children: [
                    pw.SizedBox(width: 20, child: pw.Text('$idx.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Expanded(child: pw.Text(item['full_name']?.toString() ?? '', style: pw.TextStyle(fontSize: 10))),
                    pw.Text(detail, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
