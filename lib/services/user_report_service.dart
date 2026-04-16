import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show Blob, Url, AnchorElement;
import '../models/user_model.dart';
import '../models/user_status_history_model.dart';
import '../services/user_status_service.dart';
import '../services/user_service.dart';

/// Servicio para generación de reportes PDF de gestión de usuarios
class UserReportService {
  final UserService _userService = UserService();
  final UserStatusService _statusService = UserStatusService();

  // ============================================
  // HELPERS COMPARTIDOS
  // ============================================

  int _getRankSortOrder(String rank) {
    const oficialesCompania = [
      'Director', 'Secretario', 'Pro-Secretario', 'Tesorero', 'Pro-Tesorero',
      'Capitán', 'Teniente 1°', 'Teniente 2°', 'Teniente 3°',
      'Ayudante 1°', 'Ayudante 2°', 'Inspector M. Mayor', 'Inspector M. Menor',
    ];
    const oficialesCuerpo = [
      'Of. General', 'Inspector de Comandancia', 'Ayudante de Comandancia',
    ];

    if (rank == 'Miembro Honorario') return 3000;
    if (rank == 'Bombero') return 4000;
    if (rank == 'Aspirante') return 5000;
    if (rank == 'Postulante') return 5001;

    final indexCompania = oficialesCompania.indexOf(rank);
    if (indexCompania != -1) return 1000 + indexCompania;

    final indexCuerpo = oficialesCuerpo.indexOf(rank);
    if (indexCuerpo != -1) return 2000 + indexCuerpo;

    return 9000;
  }

  String _rankCategory(String rank) {
    const compania = [
      'Director', 'Secretario', 'Pro-Secretario', 'Tesorero', 'Pro-Tesorero',
      'Capitán', 'Teniente 1°', 'Teniente 2°', 'Teniente 3°',
      'Ayudante 1°', 'Ayudante 2°', 'Inspector M. Mayor', 'Inspector M. Menor',
    ];
    const cuerpo = [
      'Of. General', 'Inspector de Comandancia', 'Ayudante de Comandancia',
    ];
    if (compania.contains(rank)) return 'OFICIALES DE COMPAÑÍA';
    if (cuerpo.contains(rank)) return 'OFICIALES DE CUERPO';
    if (rank == 'Miembro Honorario') return 'MIEMBROS HONORARIOS';
    if (rank == 'Bombero') return 'BOMBEROS';
    if (rank == 'Aspirante' || rank == 'Postulante') return 'ASPIRANTES / POSTULANTES';
    return 'OTROS';
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _today() => _formatDate(DateTime.now());

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
              pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(subtitle, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              if (additionalLines != null) ...additionalLines.map((line) => pw.Text(line)),
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

  pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildDataCell(String text, {double fontSize = 9, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize, color: color),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.TableRow _buildTableRow(String label, String value, bool bold, [PdfColor? color]) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(value, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ),
      ],
    );
  }

  File? _createInMemoryFile(List<int> bytes, String filename) {
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return null;
    }
    return null;
  }

  PdfColor _statusColor(UserStatus status) {
    switch (status) {
      case UserStatus.activo:
        return PdfColors.green700;
      case UserStatus.suspendido:
        return PdfColors.orange700;
      case UserStatus.renunciado:
        return PdfColors.grey700;
      case UserStatus.expulsado:
        return PdfColors.red700;
      case UserStatus.separado:
        return PdfColors.blueGrey700;
      case UserStatus.fallecido:
        return PdfColors.grey900;
    }
  }

  Future<void> downloadOrPreviewPDF(File pdfFile, String filename) async {
    final bytes = await pdfFile.readAsBytes();
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.layoutPdf(onLayout: (_) => bytes);
    }
  }

  // ============================================
  // 1. NÓMINA DE BOMBEROS ACTIVOS
  // ============================================

  Future<File?> generateActiveRosterReport() async {
    try {
      final users = await _userService.getAllUsers();
      users.sort((a, b) => _getRankSortOrder(a.rank).compareTo(_getRankSortOrder(b.rank)));

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter.landscape,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderWithBranding(
                title: 'SEXTA COMPAÑÍA DE BOMBEROS',
                subtitle: 'NÓMINA DE BOMBEROS ACTIVOS',
                additionalLines: ['', 'Fecha de generación: ${_today()}', 'Total: ${users.length} bomberos activos'],
              ),
              pw.Divider(),
            ],
          ),
          footer: _buildFooter,
          build: (context) => [
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.2),
                6: const pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildHeaderCell('N°'),
                    _buildHeaderCell('Nombre'),
                    _buildHeaderCell('RUT'),
                    _buildHeaderCell('Cargo'),
                    _buildHeaderCell('Reg.\nCompañía'),
                    _buildHeaderCell('Reg.\nGeneral'),
                    _buildHeaderCell('Email'),
                  ],
                ),
                ...users.asMap().entries.map((e) {
                  final i = e.key + 1;
                  final u = e.value;
                  return pw.TableRow(
                    children: [
                      _buildDataCell('$i', fontSize: 8),
                      _buildDataCell(u.fullName, fontSize: 8),
                      _buildDataCell(u.rut, fontSize: 8),
                      _buildDataCell(u.rank, fontSize: 8),
                      _buildDataCell(u.registroCompania?.toString() ?? '-', fontSize: 8),
                      _buildDataCell(u.victorNumber ?? '-', fontSize: 8),
                      _buildDataCell(u.email ?? '-', fontSize: 7),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text('Total: ${users.length} bomberos activos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ],
        ),
      );

      if (kIsWeb) {
        return _createInMemoryFile(await pdf.save(), 'nomina_activos_${DateTime.now().millisecondsSinceEpoch}.pdf');
      }
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/nomina_activos_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('Error generating active roster report: $e');
      return null;
    }
  }

  // ============================================
  // 2. NÓMINA POR CARGO
  // ============================================

  Future<File?> generateRosterByRankReport() async {
    try {
      final users = await _userService.getAllUsers();

      // Agrupar por categoría en orden jerárquico
      const categoryOrder = [
        'OFICIALES DE COMPAÑÍA',
        'OFICIALES DE CUERPO',
        'MIEMBROS HONORARIOS',
        'BOMBEROS',
        'ASPIRANTES / POSTULANTES',
        'OTROS',
      ];
      final Map<String, List<UserModel>> grouped = {};
      for (final u in users) {
        final cat = _rankCategory(u.rank);
        grouped[cat] ??= [];
        grouped[cat]!.add(u);
      }
      for (final cat in grouped.keys) {
        grouped[cat]!.sort((a, b) => _getRankSortOrder(a.rank).compareTo(_getRankSortOrder(b.rank)));
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter.landscape,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderWithBranding(
                title: 'SEXTA COMPAÑÍA DE BOMBEROS',
                subtitle: 'NÓMINA POR CARGO',
                additionalLines: ['', 'Fecha de generación: ${_today()}', 'Total: ${users.length} bomberos activos'],
              ),
              pw.Divider(),
            ],
          ),
          footer: _buildFooter,
          build: (context) {
            final widgets = <pw.Widget>[];
            for (final cat in categoryOrder) {
              final catUsers = grouped[cat];
              if (catUsers == null || catUsers.isEmpty) continue;

              widgets.add(pw.SizedBox(height: 16));
              widgets.add(pw.Text(cat, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)));
              widgets.add(pw.SizedBox(height: 6));
              widgets.add(pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(25),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildHeaderCell('N°'),
                      _buildHeaderCell('Nombre'),
                      _buildHeaderCell('RUT'),
                      _buildHeaderCell('Email'),
                    ],
                  ),
                  ...catUsers.asMap().entries.map((e) {
                    final u = e.value;
                    return pw.TableRow(
                      children: [
                        _buildDataCell('${e.key + 1}', fontSize: 8),
                        _buildDataCell(u.fullName, fontSize: 8),
                        _buildDataCell(u.rut, fontSize: 8),
                        _buildDataCell(u.email ?? '-', fontSize: 7),
                      ],
                    );
                  }),
                ],
              ));
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Text('Subtotal $cat: ${catUsers.length}',
                  style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)));
            }
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(pw.Text('Total general: ${users.length} bomberos activos',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)));
            return widgets;
          },
        ),
      );

      if (kIsWeb) {
        return _createInMemoryFile(await pdf.save(), 'nomina_por_cargo_${DateTime.now().millisecondsSinceEpoch}.pdf');
      }
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/nomina_por_cargo_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('Error generating roster by rank report: $e');
      return null;
    }
  }

  // ============================================
  // 3. BOMBEROS INACTIVOS
  // ============================================

  Future<File?> generateInactiveReport() async {
    try {
      final allUsers = await _userService.getAllUsers(includeInactive: true);
      final inactive = allUsers.where((u) => u.status != UserStatus.activo).toList();
      inactive.sort((a, b) => _getRankSortOrder(a.rank).compareTo(_getRankSortOrder(b.rank)));

      // Obtener último cambio de estado para cada inactivo
      final Map<String, UserStatusHistory?> lastChange = {};
      for (final u in inactive) {
        try {
          final hist = await _statusService.getUserStatusHistory(u.id);
          lastChange[u.id] = hist.isNotEmpty ? hist.first : null;
        } catch (_) {
          lastChange[u.id] = null;
        }
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderWithBranding(
                title: 'SEXTA COMPAÑÍA DE BOMBEROS',
                subtitle: 'BOMBEROS INACTIVOS',
                additionalLines: ['', 'Fecha de generación: ${_today()}', 'Total inactivos: ${inactive.length}'],
              ),
              pw.Divider(),
            ],
          ),
          footer: _buildFooter,
          build: (context) => [
            pw.SizedBox(height: 10),
            inactive.isEmpty
                ? pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green)),
                    child: pw.Text('No hay bomberos inactivos registrados.',
                        style: pw.TextStyle(color: PdfColors.green700)),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(22),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FlexColumnWidth(1.8),
                      3: const pw.FlexColumnWidth(2),
                      4: const pw.FlexColumnWidth(1.5),
                      5: const pw.FlexColumnWidth(1.5),
                      6: const pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _buildHeaderCell('N°'),
                          _buildHeaderCell('Nombre'),
                          _buildHeaderCell('RUT'),
                          _buildHeaderCell('Cargo'),
                          _buildHeaderCell('Estado'),
                          _buildHeaderCell('Fecha\nCambio'),
                          _buildHeaderCell('Motivo'),
                        ],
                      ),
                      ...inactive.asMap().entries.map((e) {
                        final u = e.value;
                        final hist = lastChange[u.id];
                        final fechaStr = hist != null ? _formatDate(hist.effectiveDate) : '-';
                        final motivo = hist?.reason ?? '-';
                        return pw.TableRow(
                          children: [
                            _buildDataCell('${e.key + 1}', fontSize: 8),
                            _buildDataCell(u.fullName, fontSize: 8),
                            _buildDataCell(u.rut, fontSize: 8),
                            _buildDataCell(u.rank, fontSize: 8),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                u.getStatusDisplayName(),
                                style: pw.TextStyle(fontSize: 8, color: _statusColor(u.status), fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            _buildDataCell(fechaStr, fontSize: 8),
                            _buildDataCell(motivo, fontSize: 7),
                          ],
                        );
                      }),
                    ],
                  ),
          ],
        ),
      );

      if (kIsWeb) {
        return _createInMemoryFile(await pdf.save(), 'bomberos_inactivos_${DateTime.now().millisecondsSinceEpoch}.pdf');
      }
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/bomberos_inactivos_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('Error generating inactive report: $e');
      return null;
    }
  }

  // ============================================
  // 4. HISTORIAL DE CAMBIOS DE ESTADO
  // ============================================

  Future<File?> generateStatusHistoryReport({DateTime? fromDate, DateTime? toDate}) async {
    try {
      final history = await _statusService.getAllStatusHistory(fromDate: fromDate, toDate: toDate);

      String dateRangeStr = '';
      if (fromDate != null && toDate != null) {
        dateRangeStr = 'Período: ${_formatDate(fromDate)} - ${_formatDate(toDate)}';
      } else if (fromDate != null) {
        dateRangeStr = 'Desde: ${_formatDate(fromDate)}';
      } else if (toDate != null) {
        dateRangeStr = 'Hasta: ${_formatDate(toDate)}';
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(35),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderWithBranding(
                title: 'SEXTA COMPAÑÍA DE BOMBEROS',
                subtitle: 'HISTORIAL DE CAMBIOS DE ESTADO',
                additionalLines: [
                  '',
                  if (dateRangeStr.isNotEmpty) dateRangeStr,
                  'Fecha de generación: ${_today()}',
                  'Total de registros: ${history.length}',
                ],
              ),
              pw.Divider(),
            ],
          ),
          footer: _buildFooter,
          build: (context) => [
            pw.SizedBox(height: 10),
            history.isEmpty
                ? pw.Text('No hay registros para el período seleccionado.',
                    style: pw.TextStyle(color: PdfColors.grey600))
                : pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.5),
                      1: const pw.FlexColumnWidth(2.5),
                      2: const pw.FlexColumnWidth(1.8),
                      3: const pw.FlexColumnWidth(1.8),
                      4: const pw.FlexColumnWidth(3),
                      5: const pw.FlexColumnWidth(2.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _buildHeaderCell('Fecha'),
                          _buildHeaderCell('Bombero'),
                          _buildHeaderCell('Estado\nAnterior'),
                          _buildHeaderCell('Nuevo\nEstado'),
                          _buildHeaderCell('Motivo'),
                          _buildHeaderCell('Realizado por'),
                        ],
                      ),
                      ...history.map((h) {
                        return pw.TableRow(
                          children: [
                            _buildDataCell(_formatDate(h.effectiveDate), fontSize: 8),
                            _buildDataCell(h.userName ?? h.userId, fontSize: 8),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                h.previousStatus.name,
                                style: pw.TextStyle(fontSize: 8, color: _statusColor(h.previousStatus)),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                h.newStatus.name,
                                style: pw.TextStyle(fontSize: 8, color: _statusColor(h.newStatus), fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            _buildDataCell(h.reason, fontSize: 7),
                            _buildDataCell(h.changedByName ?? h.changedBy, fontSize: 8),
                          ],
                        );
                      }),
                    ],
                  ),
          ],
        ),
      );

      if (kIsWeb) {
        return _createInMemoryFile(await pdf.save(), 'historial_estados_${DateTime.now().millisecondsSinceEpoch}.pdf');
      }
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/historial_estados_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('Error generating status history report: $e');
      return null;
    }
  }

  // ============================================
  // 5. RESUMEN ESTADÍSTICO
  // ============================================

  Future<File?> generateSummaryReport() async {
    try {
      final statusSummary = await _statusService.getStatusSummary();
      final activeUsers = await _userService.getAllUsers();

      // Conteo por cargo (solo activos)
      final Map<String, int> rankCount = {};
      for (final u in activeUsers) {
        rankCount[u.rank] = (rankCount[u.rank] ?? 0) + 1;
      }
      final sortedRanks = rankCount.entries.toList()
        ..sort((a, b) => _getRankSortOrder(a.key).compareTo(_getRankSortOrder(b.key)));

      // Totales generales
      final totalAll = statusSummary.values.fold(0, (a, b) => a + b);
      final totalActive = statusSummary['activo'] ?? 0;
      final totalInactive = totalAll - totalActive;

      final allStatuses = ['activo', 'suspendido', 'renunciado', 'expulsado', 'separado', 'fallecido'];

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderWithBranding(
                title: 'SEXTA COMPAÑÍA DE BOMBEROS',
                subtitle: 'RESUMEN ESTADÍSTICO',
                additionalLines: ['', 'Fecha de generación: ${_today()}'],
              ),
              pw.Divider(),
            ],
          ),
          footer: _buildFooter,
          build: (context) => [
            // Totales generales
            pw.SizedBox(height: 16),
            pw.Text('TOTALES GENERALES', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Total registros en sistema', '$totalAll', true),
                _buildTableRow('Bomberos activos', '$totalActive', true, PdfColors.green700),
                _buildTableRow('Bomberos inactivos', '$totalInactive', true, PdfColors.red700),
              ],
            ),

            // Por estado
            pw.SizedBox(height: 20),
            pw.Text('DESGLOSE POR ESTADO', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildHeaderCell('Estado'),
                    _buildHeaderCell('Cantidad'),
                    _buildHeaderCell('Porcentaje'),
                  ],
                ),
                ...allStatuses.map((s) {
                  final count = statusSummary[s] ?? 0;
                  final pct = totalAll > 0 ? (count * 100 / totalAll).toStringAsFixed(1) : '0.0';
                  final uStatus = UserModel.parseStatus(s);
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(s[0].toUpperCase() + s.substring(1),
                            style: pw.TextStyle(color: _statusColor(uStatus))),
                      ),
                      _buildDataCell('$count'),
                      _buildDataCell('$pct%'),
                    ],
                  );
                }),
              ],
            ),

            // Por cargo (solo activos)
            pw.SizedBox(height: 20),
            pw.Text('DESGLOSE POR CARGO (solo activos)', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildHeaderCell('Cargo'),
                    _buildHeaderCell('Cantidad'),
                    _buildHeaderCell('Porcentaje'),
                  ],
                ),
                ...sortedRanks.map((e) {
                  final pct = totalActive > 0 ? (e.value * 100 / totalActive).toStringAsFixed(1) : '0.0';
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 9))),
                      _buildDataCell('${e.value}'),
                      _buildDataCell('$pct%'),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total activos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    _buildDataCell('$totalActive', color: PdfColors.green700),
                    _buildDataCell('100%'),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      if (kIsWeb) {
        return _createInMemoryFile(await pdf.save(), 'resumen_estadistico_${DateTime.now().millisecondsSinceEpoch}.pdf');
      }
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/resumen_estadistico_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('Error generating summary report: $e');
      return null;
    }
  }
}
