import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/models/shift_config_model.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Servicio para gestión de guardias con validación de cupos
class ShiftService {
  final SupabaseService _supabase = SupabaseService();

  /// VALIDACIÓN CRÍTICA: Verifica cupo de género para una guardia
  Future<Map<String, dynamic>> validateShiftRegistration(
    DateTime shiftDate,
    String userId,
  ) async {
    // Obtener perfil del usuario para verificar género
    final user = await _supabase.getUserProfile(userId);
    if (user == null) {
      return {
        'canRegister': false,
        'error': 'Usuario no encontrado',
      };
    }

    // Contar registros actuales por género
    final maleCount = await _supabase.getShiftRegistrationCount(
      shiftDate,
      'M',
    );
    final femaleCount = await _supabase.getShiftRegistrationCount(
      shiftDate,
      'F',
    );

    // Validar cupo según género del usuario
    if (user.gender == Gender.male) {
      if (maleCount >= AppConstants.maxMalesPerShift) {
        return {
          'canRegister': false,
          'error': 'Cupo de hombres completo ($maleCount/${AppConstants.maxMalesPerShift})',
          'current_count': maleCount,
          'max_count': AppConstants.maxMalesPerShift,
        };
      }
    } else if (user.gender == Gender.female) {
      if (femaleCount >= AppConstants.maxFemalesPerShift) {
        return {
          'canRegister': false,
          'error': 'Cupo de mujeres completo ($femaleCount/${AppConstants.maxFemalesPerShift})',
          'current_count': femaleCount,
          'max_count': AppConstants.maxFemalesPerShift,
        };
      }
    }

    return {
      'canRegister': true,
      'male_count': maleCount,
      'female_count': femaleCount,
    };
  }

  /// Registra a un bombero para una guardia
  Future<void> registerForShift({
    required String configId,
    required String userId,
    required DateTime shiftDate,
  }) async {
    // Primero validar cupo
    final validation = await validateShiftRegistration(shiftDate, userId);
    if (validation['canRegister'] != true) {
      throw Exception(validation['error']);
    }

    // Registrar
    await _supabase.createShiftRegistration({
      'config_id': configId,
      'user_id': userId,
      'shift_date': shiftDate.toIso8601String().split('T')[0],
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Obtiene configuraciones de guardia
  Future<List<ShiftConfigModel>> getShiftConfigurations() async {
    final configs = await _supabase.getShiftConfigurations();
    return configs.map((json) => ShiftConfigModel.fromJson(json)).toList();
  }

  /// Calcula cumplimiento de guardias por usuario
  Future<Map<String, dynamic>> calculateShiftCompliance(
    String configId,
  ) async {
    final registrations = await _supabase.getShiftRegistrations(configId);
    final complianceData = <String, Map<String, dynamic>>{};

    // Agrupar por usuario
    for (final reg in registrations) {
      final userId = reg['user_id'];
      final user = reg['user'] as Map<String, dynamic>;
      final shiftDate = DateTime.parse(reg['shift_date']);
      
      if (!complianceData.containsKey(userId)) {
        final maritalStatus = user['marital_status'];
        final required = maritalStatus == 'single' 
            ? AppConstants.shiftsPerWeekSingle 
            : AppConstants.shiftsPerWeekMarried;
        
        complianceData[userId] = {
          'user_id': userId,
          'full_name': user['full_name'],
          'rank': user['rank'],
          'marital_status': maritalStatus,
          'required_per_week': required,
          'shift_dates': <DateTime>[],
        };
      }
      
      (complianceData[userId]!['shift_dates'] as List<DateTime>).add(shiftDate);
    }

    // Calcular promedio semanal
    final results = <Map<String, dynamic>>[];
    for (final userData in complianceData.values) {
      final shiftDates = userData['shift_dates'] as List<DateTime>;
      final weeks = _getWeeksInPeriod(shiftDates);
      final avgPerWeek = weeks > 0 ? shiftDates.length / weeks : 0.0;
      final required = userData['required_per_week'] as int;
      
      results.add({
        'user_id': userData['user_id'],
        'full_name': userData['full_name'],
        'rank': userData['rank'],
        'marital_status': userData['marital_status'],
        'required_shifts_per_week': required,
        'average_shifts_per_week': avgPerWeek,
        'total_shifts': shiftDates.length,
        'meets_requirement': avgPerWeek >= required,
      });
    }

    return {
      'compliance_data': results,
      'total_users': results.length,
      'compliant_users': results.where((u) => u['meets_requirement'] == true).length,
    };
  }

  int _getWeeksInPeriod(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    dates.sort();
    final firstDate = dates.first;
    final lastDate = dates.last;
    return ((lastDate.difference(firstDate).inDays) / 7).ceil() + 1;
  }

  /// Genera PDF del rol de guardia semanal
  Future<void> generateShiftSchedulePDF(
    String configId,
    DateTime weekStart,
  ) async {
    final pdf = pw.Document();
    final registrations = await _supabase.getShiftRegistrations(configId);
    
    // Agrupar por fecha
    final scheduleByDate = <String, List<Map<String, dynamic>>>{};
    for (final reg in registrations) {
      final date = reg['shift_date'] as String;
      final regDate = DateTime.parse(date);
      
      // Filtrar solo la semana seleccionada
      if (regDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          regDate.isBefore(weekStart.add(const Duration(days: 7)))) {
        if (!scheduleByDate.containsKey(date)) {
          scheduleByDate[date] = [];
        }
        scheduleByDate[date]!.add(reg);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Rol de Guardia Semanal',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Semana: ${DateFormat('dd/MM/yyyy').format(weekStart)} - ${DateFormat('dd/MM/yyyy').format(weekStart.add(const Duration(days: 6)))}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              ...scheduleByDate.entries.map((entry) {
                final date = DateTime.parse(entry.key);
                final dateStr = DateFormat('EEEE dd/MM/yyyy', 'es_ES').format(date);
                final firefighters = entry.value;
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 10),
                    pw.Text(
                      dateStr.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    ...firefighters.map((ff) {
                      final user = ff['user'] as Map<String, dynamic>;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 20, top: 3),
                        child: pw.Text(
                          '• ${user['rank']} ${user['full_name']}',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    // Abrir vista de impresión
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// Obtiene asistencia de guardia para una fecha
  Future<List<Map<String, dynamic>>> getShiftAttendance(DateTime date) async {
    return await _supabase.getShiftAttendance(date);
  }

  /// Registra check-in de guardia
  Future<void> checkInShift({
    required DateTime shiftDate,
    required String userId,
  }) async {
    await _supabase.createShiftAttendance({
      'shift_date': shiftDate.toIso8601String().split('T')[0],
      'user_id': userId,
      'checked_in': true,
      'is_extra': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Registra reemplazo (Abono)
  Future<void> registerReplacement({
    required DateTime shiftDate,
    required String originalUserId,
    required String replacementUserId,
  }) async {
    await _supabase.createShiftAttendance({
      'shift_date': shiftDate.toIso8601String().split('T')[0],
      'user_id': originalUserId,
      'checked_in': false,
      'replacement_user_id': replacementUserId,
      'is_extra': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Registra bombero extra
  Future<void> registerExtraFirefighter({
    required DateTime shiftDate,
    required String userId,
  }) async {
    await _supabase.createShiftAttendance({
      'shift_date': shiftDate.toIso8601String().split('T')[0],
      'user_id': userId,
      'checked_in': true,
      'is_extra': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
