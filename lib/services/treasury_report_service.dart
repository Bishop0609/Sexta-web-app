import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show Blob, Url, AnchorElement;
import '../models/user_model.dart';
import '../models/monthly_quota_model.dart';
import '../models/treasury_payment_model.dart';
import '../services/treasury_service.dart';
import '../services/user_service.dart';

/// Servicio para generación de reportes PDF de tesorería
class TreasuryReportService {
  final TreasuryService _treasuryService = TreasuryService();
  final UserService _userService = UserService();

  /// Formato de moneda chileno
  String _formatCurrency(int amount) {
    return '\$${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  /// Obtener nombre del mes
  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  /// Orden de cargos para reportes (mismo que asistencia)
  /// 1. Oficiales de Compañía, 2. Oficiales de Cuerpo, 3. Miembros Honorarios, 4. Bomberos, 5. Aspirantes/Postulantes
  int _getRankSortOrder(String rank) {
    // Oficiales de Compañía (categoría 1)
    const oficialesCompania = [
      'Director', 'Secretario', 'Pro-Secretario', 'Tesorero', 'Pro-Tesorero',
      'Capitán', 'Teniente 1°', 'Teniente 2°', 'Teniente 3°',
      'Ayudante 1°', 'Ayudante 2°', 'Inspector M. Mayor', 'Inspector M. Menor'
    ];
    
    // Oficiales de Cuerpo (categoría 2)
    const oficialesCuerpo = [
      'Of. General', 'Inspector de Comandancia', 'Ayudante de Comandancia'
    ];
    
    // Miembros Honorarios (categoría 3)
    if (rank == 'Miembro Honorario') return 3000;
    
    // Bomberos (categoría 4)
    if (rank == 'Bombero') return 4000;
    
    // Aspirantes y Postulantes (categoría 5)
    if (rank == 'Aspirante') return 5000;
    if (rank == 'Postulante') return 5001;
    
    // Oficiales de Compañía (orden específico dentro de categoría 1)
    final indexCompania = oficialesCompania.indexOf(rank);
    if (indexCompania != -1) return 1000 + indexCompania;
    
    // Oficiales de Cuerpo (orden específico dentro de categoría 2)
    final indexCuerpo = oficialesCuerpo.indexOf(rank);
    if (indexCuerpo != -1) return 2000 + indexCuerpo;
    
    // Si no se encuentra, ponerlo al final
    return 9000;
  }

  // ============================================
  // REPORTE MENSUAL GENERAL
  // ============================================

  /// Generar reporte mensual general
  Future<File?> generateMonthlyReport({
    required int month,
    required int year,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Obtener datos
      final quotas = await _treasuryService.getQuotasForMonth(month: month, year: year);
      final summary = await _treasuryService.getMonthSummary(month: month, year: year);
      final allUsers = await _userService.getAllUsers();
      
      // Crear mapa de usuarios
      final userMap = <String, UserModel>{};
      for (var user in allUsers) {
        userMap[user.id] = user;
      }

      
      // Aplicar filtros
      var filteredQuotas = quotas;
      if (userId != null) {
        filteredQuotas = filteredQuotas.where((q) => q.userId == userId).toList();
      }
      // Note: startDate/endDate no aplican para reporte mensual ya que es de un mes específico

      // Agrupar por estado
      final paidQuotas = filteredQuotas.where((q) => q.status == QuotaStatus.paid).toList();
      final pendingQuotas = filteredQuotas.where((q) => q.status == QuotaStatus.pending).toList();
      final partialQuotas = filteredQuotas.where((q) => q.status == QuotaStatus.partial).toList();

      // Ordenar SOLO por cargo (igual que asistencia, NO por monto)
      paidQuotas.sort((a, b) {
        final userA = userMap[a.userId];
        final userB = userMap[b.userId];
        if (userA == null || userB == null) return 0;
        return _getRankSortOrder(userA.rank).compareTo(_getRankSortOrder(userB.rank));
      });
      pendingQuotas.sort((a, b) {
        final userA = userMap[a.userId];
        final userB = userMap[b.userId];
        if (userA == null || userB == null) return 0;
        return _getRankSortOrder(userA.rank).compareTo(_getRankSortOrder(userB.rank));
      });
      partialQuotas.sort((a, b) {
        final userA = userMap[a.userId];
        final userB = userMap[b.userId];
        if (userA == null || userB == null) return 0;
        return _getRankSortOrder(userA.rank).compareTo(_getRankSortOrder(userB.rank));
      });

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SEXTA COMPAÑÍA DE BOMBEROS',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'REPORTE DE TESORERÍA',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Período: ${_getMonthName(month)} $year'),
                  pw.Text('Fecha de generación: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  pw.Divider(),
                ],
              ),
            ),

            // Resumen general
            pw.SizedBox(height: 20),
            pw.Text('RESUMEN GENERAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Total de usuarios', '${summary['total_users'] ?? 0}', true),
                _buildTableRow('Usuarios al día', '${summary['paid_count'] ?? 0}', false),
                _buildTableRow('Usuarios pendientes', '${summary['pending_count'] ?? 0}', false),
                _buildTableRow('Pagos parciales', '${summary['partial_count'] ?? 0}', false),
                _buildTableRow('Monto esperado', _formatCurrency(summary['total_expected'] ?? 0), true),
                _buildTableRow('Monto recaudado', _formatCurrency(summary['total_collected'] ?? 0), true),
                _buildTableRow('% Recaudación', '${summary['collection_percentage'] ?? 0}%', true),
              ],
            ),

            // Usuarios al día
            if (paidQuotas.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('USUARIOS AL DÍA (${paidQuotas.length})', 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nombre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Cargo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Monto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...paidQuotas.map((q) {
                    final user = userMap[q.userId];
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(user?.fullName ?? 'N/A')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(user?.rank ?? 'N/A')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(q.paidAmount))),
                      ],
                    );
                  }),
                ],
              ),
            ],

            // Usuarios pendientes
            if (pendingQuotas.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('USUARIOS PENDIENTES (${pendingQuotas.length})', 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nombre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Cargo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Adeuda', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...pendingQuotas.map((q) {
                    final user = userMap[q.userId];
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(user?.fullName ?? 'N/A')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(user?.rank ?? 'N/A')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(q.expectedAmount))),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      );

      // Guardar o retornar PDF según plataforma
      if (kIsWeb) {
        // En web, retornar bytes directamente (no hay sistema de archivos)
        final bytes = await pdf.save();
        // Crear un "pseudo-file" para compatibilidad
        return _createInMemoryFile(bytes, 'reporte_mensual_${month}_$year.pdf');
      } else {
        // En mobile/desktop, guardar en disco
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/reporte_mensual_${month}_$year.pdf');
        await file.writeAsBytes(await pdf.save());
        return file;
      }
    } catch (e) {
      print('Error generating monthly report: $e');
      return null;
    }
  }

  /// Crear archivo en memoria para web
  File? _createInMemoryFile(List<int> bytes, String filename) {
    // En web, descargar directamente y retornar null
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      
      // Retornar null porque ya descargamos
      return null;
    }
    return null;
  }

  // ============================================
  // REPORTE INDIVIDUAL
  // ============================================

  /// Generar reporte individual de usuario
  Future<File?> generateIndividualReport({
    required UserModel user,
    required int year,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Obtener cuotas del año
      final allQuotas = await _treasuryService.getUserQuotas(user.id);
      final yearQuotas = allQuotas.where((q) => q.year == year).toList();
      yearQuotas.sort((a, b) => a.month.compareTo(b.month));

      // Calcular totales
      int totalExpected = yearQuotas.fold(0, (sum, q) => sum + q.expectedAmount);
      int totalPaid = yearQuotas.fold(0, (sum, q) => sum + q.paidAmount);
      int totalOwed = totalExpected - totalPaid;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SEXTA COMPAÑÍA DE BOMBEROS',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'REPORTE INDIVIDUAL DE CUOTAS',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Año: $year'),
                  pw.Text('Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  pw.Divider(),
                ],
              ),
            ),

            // Datos del usuario
            pw.SizedBox(height: 20),
            pw.Text('DATOS DEL BOMBERO', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Nombre', user.fullName, false),
                _buildTableRow('RUT', user.rut, false),
                _buildTableRow('Cargo', user.rank, false),
                _buildTableRow('N° Víctor', user.victorNumber, false),
                _buildTableRow('Tipo', user.isStudent ? 'Estudiante (Cuota reducida)' : 'Bombero', false),
              ],
            ),

            // Resumen anual
            pw.SizedBox(height: 20),
            pw.Text('RESUMEN ANUAL $year', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Total esperado', _formatCurrency(totalExpected), true),
                _buildTableRow('Total pagado', _formatCurrency(totalPaid), true),
                _buildTableRow('Total adeudado', _formatCurrency(totalOwed), true, totalOwed > 0 ? PdfColors.red : PdfColors.green),
              ],
            ),

            // Detalle mensual
            pw.SizedBox(height: 20),
            pw.Text('DETALLE MENSUAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Mes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Esperado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Pagado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Estado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...yearQuotas.map((q) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_getMonthName(q.month))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(q.expectedAmount))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(q.paidAmount))),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          q.status == QuotaStatus.paid ? 'Pagado' : 
                          q.status == QuotaStatus.partial ? 'Parcial' : 'Pendiente',
                          style: pw.TextStyle(
                            color: q.status == QuotaStatus.paid ? PdfColors.green : PdfColors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );

      // Guardar o retornar PDF según plataforma
      if (kIsWeb) {
        final bytes = await pdf.save();
        return _createInMemoryFile(bytes, 'reporte_individual_${user.rut}_$year.pdf');
      } else {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/reporte_individual_${user.rut}_$year.pdf');
        await file.writeAsBytes(await pdf.save());
        return file;
      }
    } catch (e) {
      print('Error generating individual report: $e');
      return null;
    }
  }

  // ============================================
  // REPORTE DE MOROSIDAD
  // ============================================

  /// Generar reporte de morosidad
  Future<File?> generateDelinquencyReport({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Obtener todos los usuarios
      var allUsers = await _userService.getAllUsers();
      
      // Aplicar filtro de usuario si está presente
      if (userId != null) {
        allUsers = allUsers.where((u) => u.id == userId).toList();
      }
      
      final usersWithDebt = <Map<String, dynamic>>[];

      // Calcular deudas
      for (var user in allUsers) {
        if (user.paymentStartDate == null) continue;
        
        final debtInfo = await _treasuryService.calculateUserDebt(user.id);
        final monthsOwed = debtInfo['months_owed'] ?? 0;
        
        if (monthsOwed > 0) {
          usersWithDebt.add({
            'user': user,
            'months_owed': monthsOwed,
            'total_amount': debtInfo['total_amount'] ?? 0,
          });
        }
      }

      // Ordenar SOLO por cargo (igual que asistencia, NO por monto)
      usersWithDebt.sort((a, b) {
        final userA = a['user'] as UserModel;
        final userB = b['user'] as UserModel;
        return _getRankSortOrder(userA.rank).compareTo(_getRankSortOrder(userB.rank));
      });

      // Calcular totales
      int totalDebtors = usersWithDebt.length;
      int totalDebt = usersWithDebt.fold(0, (sum, item) => sum + (item['total_amount'] as int));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SEXTA COMPAÑÍA DE BOMBEROS',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'REPORTE DE MOROSIDAD',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  pw.Divider(),
                ],
              ),
            ),

            // Resumen
            pw.SizedBox(height: 20),
            pw.Text('RESUMEN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Total de deudores', '$totalDebtors', true, PdfColors.red),
                _buildTableRow('Deuda total', _formatCurrency(totalDebt), true, PdfColors.red),
              ],
            ),

            // Lista de deudores
            pw.SizedBox(height: 20),
            pw.Text('DETALLE DE DEUDORES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nombre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Cargo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Meses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Deuda', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...usersWithDebt.map((item) {
                  final user = item['user'] as UserModel;
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(user.fullName)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(user.rank)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item['months_owed']}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(item['total_amount'] as int))),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );

      // Guardar o retornar PDF según plataforma
      if (kIsWeb) {
        final bytes = await pdf.save();
        return _createInMemoryFile(bytes, 'reporte_morosidad_${DateTime.now().millisecondsSinceEpoch}.pdf');
      } else {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/reporte_morosidad_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());
        return file;
      }
    } catch (e) {
      print('Error generating delinquency report: $e');
      return null;
    }
  }

  // ============================================
  // REPORTE DE BASE DE DATOS COMPLETA
  // ============================================

  /// Generar reporte completo de base de datos
  Future<File?> generateCompleteDatabaseReport({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Obtener todos los usuarios con payment_start_date
      final allUsers = await _userService.getAllUsers();
      var payingUsers = allUsers.where((u) => u.paymentStartDate != null).toList();
      
      // Aplicar filtro de usuario si está presente
      if (userId != null) {
        payingUsers = payingUsers.where((u) => u.id == userId).toList();
      }
      
      // Calcular información de cada usuario
      final userDataList = <Map<String, dynamic>>[];
      
      for (var user in payingUsers) {
        final debtInfo = await _treasuryService.calculateUserDebt(user.id);
        final quotas = await _treasuryService.getUserQuotas(user.id);
        
        // Encontrar último pago
        DateTime? lastPaymentDate;
        int? lastPaymentAmount;
        
        for (var quota in quotas) {
          if (quota.status == QuotaStatus.paid || quota.status == QuotaStatus.partial) {
            final payments = await _treasuryService.getQuotaPayments(quota.id);
            if (payments.isNotEmpty) {
              payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
              if (lastPaymentDate == null || payments.first.paymentDate.isAfter(lastPaymentDate)) {
                lastPaymentDate = payments.first.paymentDate;
                lastPaymentAmount = payments.first.amount;
              }
            }
          }
        }
        
        final monthsSinceStart = debtInfo['months_owed'] != null
            ? (quotas.where((q) => q.status == QuotaStatus.paid).length + (debtInfo['months_owed'] as int))
            : 0;
        
        userDataList.add({
          'user': user,
          'months_since_start': monthsSinceStart,
          'months_paid': quotas.where((q) => q.status == QuotaStatus.paid).length,
          'months_owed': debtInfo['months_owed'] ?? 0,
          'total_amount_owed': debtInfo['total_amount'] ?? 0,
          'last_payment_date': lastPaymentDate,
          'last_payment_amount': lastPaymentAmount,
        });
      }
      
      // Ordenar SOLO por cargo (igual que asistencia, NO por monto)
      userDataList.sort((a, b) {
        final userA = a['user'] as UserModel;
        final userB = b['user'] as UserModel;
        return _getRankSortOrder(userA.rank).compareTo(_getRankSortOrder(userB.rank));
      });

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter.landscape, // Horizontal para más columnas
          margin: const pw.EdgeInsets.all(30),
          build: (context) => [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SEXTA COMPAÑÍA DE BOMBEROS',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'REPORTE COMPLETO - BASE DE DATOS TESORERÍA',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  pw.Text('Total usuarios con obligación de pago: ${payingUsers.length}'),
                  pw.Divider(),
                ],
              ),
            ),

            // Tabla completa
            pw.SizedBox(height: 15),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1),
                6: const pw.FlexColumnWidth(1),
                7: const pw.FlexColumnWidth(1.5),
                8: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildHeaderCell('Nombre'),
                    _buildHeaderCell('RUT'),
                    _buildHeaderCell('Cargo'),
                    _buildHeaderCell('Inicio\nPagos'),
                    _buildHeaderCell('Meses\nTotal'),
                    _buildHeaderCell('Meses\nPagados'),
                    _buildHeaderCell('Meses\nDeuda'),
                    _buildHeaderCell('Monto\nAdeudado'),
                    _buildHeaderCell('Último Pago'),
                  ],
                ),
                ...userDataList.map((data) {
                  final user = data['user'] as UserModel;
                  final lastPayDate = data['last_payment_date'] as DateTime?;
                  
                  return pw.TableRow(
                    children: [
                      _buildDataCell(user.fullName, fontSize: 8),
                      _buildDataCell(user.rut, fontSize: 8),
                      _buildDataCell(user.rank, fontSize: 7),
                      _buildDataCell(
                        '${user.paymentStartDate!.month}/${user.paymentStartDate!.year}',
                        fontSize: 8,
                      ),
                      _buildDataCell('${data['months_since_start']}', fontSize: 8),
                      _buildDataCell('${data['months_paid']}', fontSize: 8, 
                        color: data['months_paid'] > 0 ? PdfColors.green : null),
                      _buildDataCell('${data['months_owed']}', fontSize: 8,
                        color: data['months_owed'] > 0 ? PdfColors.red : PdfColors.green),
                      _buildDataCell(_formatCurrency(data['total_amount_owed'] as int), fontSize: 8,
                        color: data['total_amount_owed'] > 0 ? PdfColors.red : PdfColors.green),
                      _buildDataCell(
                        lastPayDate != null
                            ? '${lastPayDate.day}/${lastPayDate.month}/${lastPayDate.year}\n${_formatCurrency(data['last_payment_amount'] as int)}'
                            : 'Sin pagos',
                        fontSize: 7,
                      ),
                    ],
                  );
                }),
              ],
            ),

            // Resumen final
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('RESUMEN:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('• Usuarios al día: ${userDataList.where((d) => d['months_owed'] == 0).length}'),
                  pw.Text('• Usuarios con deuda: ${userDataList.where((d) => d['months_owed'] > 0).length}'),
                  pw.Text('• Deuda total: ${_formatCurrency(userDataList.fold(0, (sum, d) => sum + (d['total_amount_owed'] as int)))}'),
                ],
              ),
            ),
          ],
        ),
      );

      // Guardar o retornar PDF según plataforma
      if (kIsWeb) {
        final bytes = await pdf.save();
        return _createInMemoryFile(bytes, 'reporte_completo_bd_${DateTime.now().millisecondsSinceEpoch}.pdf');
      } else {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/reporte_completo_bd_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());
        return file;
      }
    } catch (e) {
      print('Error generating complete database report: $e');
      return null;
    }
  }

  // ============================================
  // REPORTE DE INCONSISTENCIAS
  // ============================================

  /// Generar reporte de inconsistencias en datos
  Future<File?> generateInconsistenciesReport() async {
    try {
      final pdf = pw.Document();
      final issues = <Map<String, dynamic>>[];
      
      // Obtener datos
      final allUsers = await _userService.getAllUsers();
      
      // ISSUE 1: Usuarios con pagos pero sin payment_start_date
      for (var user in allUsers) {
        if (user.paymentStartDate == null) {
          final quotas = await _treasuryService.getUserQuotas(user.id);
          if (quotas.isNotEmpty) {
            issues.add({
              'type': 'Sin fecha de inicio',
              'severity': 'ALTA',
              'user': user.fullName,
              'rut': user.rut,
              'description': 'Usuario tiene ${quotas.length} cuotas pero sin payment_start_date',
            });
          }
        }
      }
      
      // ISSUE 2: Cuotas con forced_paid = true
      for (var user in allUsers.where((u) => u.paymentStartDate != null)) {
        final quotas = await _treasuryService.getUserQuotas(user.id);
        final forcedQuotas = quotas.where((q) {
          // Simular verificación de forced_paid (necesitaríamos agregarlo al modelo)
          return q.status == QuotaStatus.paid && q.paidAmount < q.expectedAmount;
        }).toList();
        
        if (forcedQuotas.isNotEmpty) {
          issues.add({
            'type': 'Pagos autorizados',
            'severity': 'MEDIA',
            'user': user.fullName,
            'rut': user.rut,
            'description': '${forcedQuotas.length} cuota(s) marcada(s) como pagada con monto menor',
          });
        }
      }
      
      // ISSUE 3: Cuotas parciales antiguas (>3 meses)
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      for (var user in allUsers.where((u) => u.paymentStartDate != null)) {
        final quotas = await _treasuryService.getUserQuotas(user.id);
        final oldPartials = quotas.where((q) {
          if (q.status != QuotaStatus.partial) return false;
          final quotaDate = DateTime(q.year, q.month);
          return quotaDate.isBefore(threeMonthsAgo);
        }).toList();
        
        if (oldPartials.isNotEmpty) {
          issues.add({
            'type': 'Deuda parcial antigua',
            'severity': 'ALTA',
            'user': user.fullName,
            'rut': user.rut,
            'description': '${oldPartials.length} cuota(s) parcial(es) de hace >3 meses',
          });
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SEXTA COMPAÑÍA DE BOMBEROS',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'REPORTE DE INCONSISTENCIAS EN DATOS',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  pw.Text('Total de problemas detectados: ${issues.length}'),
                  pw.Divider(),
                ],
              ),
            ),

            // Resumen por severidad
            pw.SizedBox(height: 20),
            pw.Text('RESUMEN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildTableRow('Alta severidad', '${issues.where((i) => i['severity'] == 'ALTA').length}', true, PdfColors.red),
                _buildTableRow('Media severidad', '${issues.where((i) => i['severity'] == 'MEDIA').length}', true, PdfColors.orange),
                _buildTableRow('Baja severidad', '${issues.where((i) => i['severity'] == 'BAJA').length}', true, PdfColors.yellow800),
              ],
            ),

            // Lista de issues
            if (issues.isNotEmpty) ...[ 
              pw.SizedBox(height: 20),
              pw.Text('DETALLE DE INCONSISTENCIAS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildHeaderCell('Severidad'),
                      _buildHeaderCell('Tipo'),
                      _buildHeaderCell('Usuario'),
                      _buildHeaderCell('RUT'),
                      _buildHeaderCell('Descripción'),
                    ],
                  ),
                  ...issues.map((issue) {
                    final sevColor = issue['severity'] == 'ALTA'
                        ? PdfColors.red
                        : issue['severity'] == 'MEDIA'
                            ? PdfColors.orange
                            : PdfColors.yellow800;
                    
                    return pw.TableRow(
                      children: [
                        _buildDataCell(issue['severity'], color: sevColor, fontSize: 9),
                        _buildDataCell(issue['type'], fontSize: 9),
                        _buildDataCell(issue['user'], fontSize: 9),
                        _buildDataCell(issue['rut'], fontSize: 9),
                        _buildDataCell(issue['description'], fontSize: 8),
                      ],
                    );
                  }),
                ],
              ),
            ] else ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green),
                ),
                child: pw.Row(
                  children: [
                    pw.Icon(const pw.IconData(0xe876), color: PdfColors.green, size: 24),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'No se detectaron inconsistencias en los datos',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.green700, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

      // Guardar o retornar PDF según plataforma
      if (kIsWeb) {
        final bytes = await pdf.save();
        return _createInMemoryFile(bytes, 'reporte_inconsistencias_${DateTime.now().millisecondsSinceEpoch}.pdf');
      } else {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/reporte_inconsistencias_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());
        return file;
      }
    } catch (e) {
      print('Error generating inconsistencies report: $e');
      return null;
    }
  }

  // ============================================
  // HELPERS
  // ============================================

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

  // ============================================
  // HELPERS
  // ============================================

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

  /// Previsualizar o descargar PDF según plataforma
  Future<void> downloadOrPreviewPDF(File pdfFile, String filename) async {
    final bytes = await pdfFile.readAsBytes();
    
    // En web, descargar directamente el archivo
    if (kIsWeb) {
      // Crear blob y descargar
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // En mobile/desktop, mostrar preview
      await Printing.layoutPdf(onLayout: (_) => bytes);
    }
  }

  /// Previsualizar PDF (legacy - usar downloadOrPreviewPDF)
  @Deprecated('Use downloadOrPreviewPDF instead')
  Future<void> previewPDF(File pdfFile) async {
    final filename = pdfFile.path.split('/').last;
    await downloadOrPreviewPDF(pdfFile, filename);
  }

  /// Compartir PDF
  Future<void> sharePDF(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }
}
