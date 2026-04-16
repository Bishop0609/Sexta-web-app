import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show Blob, Url, AnchorElement;
import 'package:intl/intl.dart';
import 'package:sexta_app/services/rifa_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RifaReportService {
  final RifaService _rifaService = RifaService();

  /// Formato de moneda chileno
  String _formatCurrency(int amount) {
    return '\$${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

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
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Desarrollado por GuntherSOFT, 2026',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
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
    );
  }

  pw.TableRow _buildTableRow(String label, String value, bool bold, [PdfColor? color]) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> downloadOrPreviewPDF(File pdfFile, String filename) async {
    final bytes = await pdfFile.readAsBytes();
    
    // En web, descargar directamente el archivo
    if (kIsWeb) {
      // Crear blob y descargar
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // En mobile/desktop, mostrar preview
      await Printing.layoutPdf(onLayout: (_) => bytes);
    }
  }

  Future<File?> _saveDocument(pw.Document pdf, String filename) async {
    if (kIsWeb) {
      final bytes = await pdf.save();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return null;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);
      return file;
    }
  }

  // 1. generateResumenGeneral
  Future<File?> generateResumenGeneral(String rifaId) async {
    final pdf = pw.Document();
    final rifa = await _rifaService.getRifaActiva();
    if (rifa == null) return null;
    final resumen = await _rifaService.getResumenGlobal(rifaId);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBranding(
              title: 'SEXTA COMPAÑÍA DE BOMBEROS',
              subtitle: 'RESUMEN GENERAL RIFA',
              additionalLines: [
                'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
              ],
            ),
            pw.Divider(),
          ],
        ),
        footer: _buildFooter,
        build: (context) {
          final enBodega = resumen?['talonarios_en_bodega'] ?? 0;
          final enCalle = resumen?['talonarios_en_calle'] ?? 0;
          final devueltos = resumen?['talonarios_devueltos'] ?? 0;
          final totalTal = rifa.totalTalonarios;
          final pctBodega = totalTal > 0 ? (enBodega / totalTal * 100).toStringAsFixed(1) : '0.0';
          final pctCalle = totalTal > 0 ? (enCalle / totalTal * 100).toStringAsFixed(1) : '0.0';
          final pctDevueltos = totalTal > 0 ? (devueltos / totalTal * 100).toStringAsFixed(1) : '0.0';

          final recaudacionMax = rifa.recaudacionMaxima;
          final montoRecaudado = resumen?['monto_recaudado_total'] ?? 0;
          final montoEntregado = resumen?['monto_entregado_total'] ?? 0;
          final talonariosEnCalle = resumen?['talonarios_en_calle'] as int? ?? 0;
          final precioTalonario = rifa.numerosPorTalonario * rifa.precioNumero;
          final dineroEnCalle = talonariosEnCalle * precioTalonario;
          final pctRecaudacion = recaudacionMax > 0 ? (montoEntregado / recaudacionMax * 100).toStringAsFixed(1) : '0.0';

          return [
            pw.Text('DATOS DE LA RIFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Nombre', rifa.nombre, false),
                _buildTableRow('Año', rifa.anio.toString(), false),
                _buildTableRow('Total Talonarios', rifa.totalTalonarios.toString(), false),
                _buildTableRow('Números por Talonario', rifa.numerosPorTalonario.toString(), false),
                _buildTableRow('Precio por Número', _formatCurrency(rifa.precioNumero), false),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('ESTADO DE TALONARIOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('En Bodega', '$enBodega ($pctBodega%)', false),
                _buildTableRow('En Calle', '$enCalle ($pctCalle%)', false),
                _buildTableRow('Devueltos', '$devueltos ($pctDevueltos%)', false),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('RECAUDACIÓN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Recaudación Máxima', _formatCurrency(recaudacionMax), true),
                _buildTableRow('Recaudación (Ventas)', _formatCurrency(montoRecaudado), false),
                _buildTableRow('Dinero Entregado', _formatCurrency(montoEntregado), true, PdfColors.green),
                _buildTableRow('Dinero en la Calle (por vender)', _formatCurrency(dineroEnCalle), true, dineroEnCalle > 0 ? PdfColors.red : PdfColors.green),
                _buildTableRow('Porcentaje sobre meta', '$pctRecaudacion%', true),
              ],
            ),
          ];
        },
      ),
    );

    return _saveDocument(pdf, 'resumen_general_rifa_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  // 2. generateDetallePorBombero
  Future<File?> generateDetallePorBombero(String rifaId) async {
    final pdf = pw.Document();
    final resumen = await _rifaService.getResumenPorBombero(rifaId);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBranding(
              title: 'SEXTA COMPAÑÍA DE BOMBEROS',
              subtitle: 'DETALLE POR BOMBERO',
              additionalLines: [
                'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
              ],
            ),
            pw.Divider(),
          ],
        ),
        footer: _buildFooter,
        build: (context) {
          int sumTalonarios = 0;
          int sumPendientes = 0;
          int sumDevueltos = 0;
          int sumVendidos = 0;
          int sumRecaudado = 0;
          int sumEntregado = 0;
          int sumDiferencia = 0;

          final rows = resumen.map((b) {
            final talonarios = b['total_talonarios'] as int? ?? 0;
            final pendientes = b['pendientes_devolucion'] as int? ?? 0;
            final devueltos = (b['devueltos_completos'] as int? ?? 0) + (b['devueltos_parciales'] as int? ?? 0) + (b['devueltos_sin_venta'] as int? ?? 0);
            final vendidos = b['total_numeros_vendidos'] as int? ?? 0;
            final recaudado = b['total_monto_recaudado'] as int? ?? 0;
            final entregado = b['total_monto_entregado'] as int? ?? 0;
            final diferencia = b['diferencia_dinero'] as int? ?? 0;

            sumTalonarios += talonarios;
            sumPendientes += pendientes;
            sumDevueltos += devueltos;
            sumVendidos += vendidos;
            sumRecaudado += recaudado;
            sumEntregado += entregado;
            sumDiferencia += diferencia;

            return pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(b['bombero_nombre']?.toString() ?? 'Desconocido', style: const pw.TextStyle(fontSize: 8))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(talonarios.toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(pendientes.toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(devueltos.toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(vendidos.toString(), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatCurrency(recaudado), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatCurrency(entregado), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatCurrency(diferencia), style: pw.TextStyle(fontSize: 8, color: diferencia > 0 ? PdfColors.red : PdfColors.green), textAlign: pw.TextAlign.right)),
              ]
            );
          }).toList();

          return [
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1.5),
                6: const pw.FlexColumnWidth(1.5),
                7: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Bombero', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Talonarios', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Pendientes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Devueltos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('N° Vendidos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Recaudado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Entregado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Diferencia', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                  ]
                ),
                ...rows,
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('TOTALES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(sumTalonarios.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(sumPendientes.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(sumDevueltos.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(sumVendidos.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatCurrency(sumRecaudado), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatCurrency(sumEntregado), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatCurrency(sumDiferencia), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: sumDiferencia > 0 ? PdfColors.red : PdfColors.green), textAlign: pw.TextAlign.right)),
                  ]
                ),
              ],
            ),
          ];
        },
      ),
    );

    return _saveDocument(pdf, 'detalle_bombero_rifa_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  // 3. generateTalonariosPendientes
  Future<File?> generateTalonariosPendientes(String rifaId) async {
    final pdf = pw.Document();
    final talonarios = await _rifaService.getTalonarios(rifaId, estado: 'entregado');

    final ahora = DateTime.now();
    final data = talonarios.map((t) {
      final days = t.fechaEntrega != null ? ahora.difference(t.fechaEntrega!).inDays : 0;
      return {'t': t, 'days': days};
    }).toList();

    data.sort((a, b) => (b['days'] as int).compareTo(a['days'] as int));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBranding(
              title: 'SEXTA COMPAÑÍA DE BOMBEROS',
              subtitle: 'TALONARIOS PENDIENTES DE DEVOLUCIÓN',
              additionalLines: [
                'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
              ],
            ),
            pw.Divider(),
          ],
        ),
        footer: _buildFooter,
        build: (context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('N° Tal.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rango', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Bombero', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fecha Entrega', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Días Pdt.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  ]
                ),
                ...data.map((item) {
                  final t = item['t'] as dynamic; // RifaTalonarioModel
                  final days = item['days'] as int;
                  final fecha = t.fechaEntrega != null ? DateFormat('dd/MM/yyyy').format(t.fechaEntrega!) : 'N/A';
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t.numeroTalonario.toString(), style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t.rangoDisplay, style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t.nombreAsignado ?? 'Desconocido', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(fecha, style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(days.toString(), style: pw.TextStyle(fontSize: 9, color: days > 30 ? PdfColors.red : PdfColors.black))),
                    ]
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return _saveDocument(pdf, 'talonarios_pendientes_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  // 4. generateRendicionDinero
  Future<File?> generateRendicionDinero(String rifaId) async {
    final pdf = pw.Document();
    final resumen = await _rifaService.getResumenPorBombero(rifaId);
    final data = resumen.where((b) => (b['total_monto_recaudado'] as int? ?? 0) > 0).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBranding(
              title: 'SEXTA COMPAÑÍA DE BOMBEROS',
              subtitle: 'RENDICIÓN DE DINERO',
              additionalLines: [
                'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
              ],
            ),
            pw.Divider(),
          ],
        ),
        footer: _buildFooter,
        build: (context) {
          int sumRecaudado = 0;
          int sumEntregado = 0;
          int sumDiferencia = 0;

          final rows = data.map((b) {
            final recaudado = b['total_monto_recaudado'] as int? ?? 0;
            final entregado = b['total_monto_entregado'] as int? ?? 0;
            final diferencia = recaudado - entregado;

            sumRecaudado += recaudado;
            sumEntregado += entregado;
            sumDiferencia += diferencia;

            final estado = diferencia == 0 ? 'OK' : 'Debe ${_formatCurrency(diferencia)}';
            final color = diferencia > 0 ? PdfColors.red : PdfColors.green;

            return pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(b['bombero_nombre']?.toString() ?? 'Desconocido', style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(recaudado), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(entregado), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(diferencia), style: pw.TextStyle(fontSize: 9, color: color), textAlign: pw.TextAlign.right)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(estado, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color), textAlign: pw.TextAlign.center)),
              ]
            );
          }).toList();

          return [
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Bombero', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Recaudado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Entregado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Diferencia', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Estado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                  ]
                ),
                ...rows,
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TOTALES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(sumRecaudado), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(sumEntregado), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(sumDiferencia), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: sumDiferencia > 0 ? PdfColors.red : PdfColors.green), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                  ]
                ),
              ],
            ),
          ];
        },
      ),
    );

    return _saveDocument(pdf, 'rendicion_dinero_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  // 5. generateHistorialMovimientos
  Future<File?> generateHistorialMovimientos(String rifaId) async {
    final pdf = pw.Document();
    final logs = await _rifaService.getLogMovimientos(rifaId);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBranding(
              title: 'SEXTA COMPAÑÍA DE BOMBEROS',
              subtitle: 'HISTORIAL DE MOVIMIENTOS - RIFA',
              additionalLines: [
                'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
              ],
            ),
            pw.Divider(),
          ],
        ),
        footer: _buildFooter,
        build: (context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Acción', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('N° Tal.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Destinatario', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Ejecutado por', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Detalle', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  ]
                ),
                ...logs.map((log) {
                  final fecha = log['created_at'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(log['created_at'].toString()).toLocal()) : '';
                  
                  String accionStr = log['accion']?.toString() ?? '';
                  if (accionStr == 'entrega') accionStr = 'Entrega';
                  else if (accionStr == 'devolucion_total') accionStr = 'Devolución completa';
                  else if (accionStr == 'devolucion_parcial') accionStr = 'Devolución parcial';
                  else if (accionStr == 'devolucion_sin_venta') accionStr = 'Devolución sin venta';
                  else if (accionStr == 'entrega_externa') accionStr = 'Entrega a entidad externa';
                  else if (accionStr == 'devolucion_externa') accionStr = 'Devolución entidad externa';
                  else if (accionStr == 'correccion') accionStr = 'Corrección';
                  else if (accionStr == 'reasignacion') accionStr = 'Reasignación';
                  else if (accionStr == 'devolucion_bodega') accionStr = 'Devolución a bodega';

                  final detalleMap = log['detalle'] as Map<String, dynamic>?;
                  String detalleTexto = '';
                  if (detalleMap != null) {
                    if (detalleMap['numeros_vendidos'] != null) {
                      detalleTexto = 'Vendidos: ${detalleMap['numeros_vendidos']}, Monto: \$${detalleMap['monto_entregado'] ?? 0}';
                    } else if (detalleMap['motivo'] != null) {
                      detalleTexto = detalleMap['motivo'].toString();
                    }
                  }

                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(fecha, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(accionStr, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(log['numero_talonario']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(log['destinatario_nombre']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(log['ejecutado_por_nombre']?.toString() ?? '-', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(detalleTexto, style: const pw.TextStyle(fontSize: 8))),
                    ]
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return _saveDocument(pdf, 'historial_rifa_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  // 6. generateRankingVendedores
  Future<File?> generateRankingVendedores(String rifaId) async {
    final pdf = pw.Document();
    final resumen = await _rifaService.getResumenPorBombero(rifaId);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderWithBranding(
              title: 'SEXTA COMPAÑÍA DE BOMBEROS',
              subtitle: 'RANKING DE VENDEDORES',
              additionalLines: [
                'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
              ],
            ),
            pw.Divider(),
          ],
        ),
        footer: _buildFooter,
        build: (context) {
          int index = 1;
          return [
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Pos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Bombero', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Talonarios', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('N° Vendidos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Recaudado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('% Completado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                  ]
                ),
                ...resumen.map((b) {
                  final devTotales = b['devueltos_completos'] as int? ?? 0;
                  final devCompletados = devTotales; // Ya incluye completos (y parciales se pueden omitir para % completado, el prompt dice dev_comp/total)
                  final totalTal = b['total_talonarios'] as int? ?? 0;
                  final pct = totalTal > 0 ? (devCompletados / totalTal * 100).toStringAsFixed(1) : '0.0';
                  final recaudado = b['total_monto_recaudado'] as int? ?? 0;
                  
                  final isTop3 = index <= 3;
                  final fontWeight = isTop3 ? pw.FontWeight.bold : pw.FontWeight.normal;
                  final textColor = isTop3 ? PdfColors.orange800 : PdfColors.black;

                  final row = pw.TableRow(
                    decoration: isTop3 ? pw.BoxDecoration(color: PdfColors.orange50) : null,
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(index.toString(), style: pw.TextStyle(fontSize: 9, fontWeight: fontWeight, color: textColor), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(b['bombero_nombre']?.toString() ?? 'Desconocido', style: pw.TextStyle(fontSize: 9, fontWeight: fontWeight, color: textColor))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(totalTal.toString(), style: pw.TextStyle(fontSize: 9, fontWeight: fontWeight, color: textColor), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text((b['total_numeros_vendidos'] as int? ?? 0).toString(), style: pw.TextStyle(fontSize: 9, fontWeight: fontWeight, color: textColor), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(recaudado), style: pw.TextStyle(fontSize: 9, fontWeight: fontWeight, color: textColor), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$pct%', style: pw.TextStyle(fontSize: 9, fontWeight: fontWeight, color: textColor), textAlign: pw.TextAlign.center)),
                    ]
                  );
                  index++;
                  return row;
                }),
              ],
            ),
          ];
        },
      ),
    );

    return _saveDocument(pdf, 'ranking_vendedores_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  Future<File?> generateBomberosSinTalonarios(String rifaId) async {
    try {
      final pdf = pw.Document();
      final rifa = await _rifaService.getRifaActiva();
      if (rifa == null) return null;

      // 1. Obtener TODOS los talonarios de la rifa
      final todosTalonarios = await _rifaService.getTalonarios(rifaId);

      // 2. Sacar IDs únicos de bomberos que YA tienen talonarios (internos, no externos)
      final bomberosConTalonarios = todosTalonarios
          .where((t) => t.asignadoA != null)
          .map((t) => t.asignadoA!)
          .toSet();

      // 3. Obtener todos los usuarios activos desde Supabase
      final supabase = Supabase.instance.client;
      final usersResponse = await supabase
          .from('users')
          .select('id, full_name, rank, registro_compania')
          .eq('status', 'activo');

      final allUsers = List<Map<String, dynamic>>.from(usersResponse);

      // 4. Filtrar los que NO tienen talonarios
      final sinTalonarios = allUsers
          .where((u) => !bomberosConTalonarios.contains(u['id']))
          .toList();

      // 5. Ordenar por cargo (usando _getRankSortOrder si existe, sino por nombre)
      sinTalonarios.sort((a, b) {
        final regA = int.tryParse(a['registro_compania']?.toString() ?? '9999') ?? 9999;
        final regB = int.tryParse(b['registro_compania']?.toString() ?? '9999') ?? 9999;
        return regA.compareTo(regB);
      });

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderWithBranding(
                title: 'SEXTA COMPAÑÍA DE BOMBEROS',
                subtitle: 'BOMBEROS SIN TALONARIOS ASIGNADOS',
                additionalLines: [
                  '',
                  'Rifa: ${rifa.nombre}',
                  'Total sin talonarios: ${sinTalonarios.length} de ${allUsers.length}',
                  'Fecha de generación: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                ],
              ),
              pw.Divider(),
            ],
          ),
          footer: _buildFooter,
          build: (context) => [
            pw.SizedBox(height: 20),
            if (sinTalonarios.isEmpty)
              pw.Center(
                child: pw.Text('Todos los bomberos tienen talonarios asignados',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(5),
                  2: const pw.FlexColumnWidth(3),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nº', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nombre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Cargo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...sinTalonarios.map((u) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(u['registro_compania']?.toString() ?? '-')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(u['full_name']?.toString() ?? '')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(u['rank']?.toString() ?? '')),
                    ],
                  )),
                ],
              ),
          ],
        ),
      );

      return _saveDocument(pdf, 'rifa_bomberos_sin_talonarios_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      print('Error generateBomberosSinTalonarios: $e');
      return null;
    }
  }
}
