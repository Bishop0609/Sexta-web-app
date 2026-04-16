import 'package:flutter/material.dart';
import 'package:sexta_app/services/attendance_pdf_service.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/screens/attendance/modify_attendance_screen.dart';
import 'package:intl/intl.dart';

/// Diálogo de vista de solo lectura con generación de PDF
class AttendanceViewDialog extends StatelessWidget {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> records;

  const AttendanceViewDialog({
    Key? key,
    required this.event,
    required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final grouped = groupAttendanceRecords(records);
    
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.navyBlue,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Asistencia - ${event['act_types']['name']}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Información general
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Fecha', DateFormat('dd/MM/yyyy').format(DateTime.parse(event['event_date'] as String))),
                  _buildInfoRow('Subtipo', event['subtype'] as String? ?? 'N/A'),
                  _buildInfoRow('Ubicación', event['location'] as String? ?? 'N/A'),
                  _buildInfoRow('Registrado por', event['users']?['full_name'] as String? ?? 'Desconocido'),
                ],
              ),
            ),
            
            // Totales
            _buildTotalsSection(),
            
            // Lista de asistencia
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: grouped.entries.map((entry) {
                  return _buildCategorySection(entry.key, entry.value);
                }).toList(),
              ),
            ),
            
            // Botón de generar PDF
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generar PDF'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => _generatePdf(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final totals = _calculateTotals();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTotalItem('Presentes', totals['present']!, Colors.green),
          _buildTotalItem('Ausentes', totals['absent']!, Colors.red),
          _buildTotalItem('Permisos', totals['permiso']!, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<Map<String, dynamic>> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...users.map((user) => _buildUserRow(user)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    Color statusColor;
    IconData statusIcon;
    
    switch (user['status']) {
      case 'present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'permiso':
        statusColor = Colors.orange;
        statusIcon = Icons.event_busy;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              user['user']?['full_name'] as String? ?? 'Sin nombre',
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Text(
            user['user']?['rank'] as String? ?? '',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateTotals() {
    int present = 0, absent = 0, permiso = 0;
    for (final record in records) {
      switch (record['status']) {
        case 'present': present++; break;
        case 'absent': absent++; break;
        case 'permiso': permiso++; break;
      }
    }
    return {'present': present, 'absent': absent, 'permiso': permiso};
  }

  Future<void> _generatePdf() async {
    await AttendancePdfService.generateAttendancePdf(
      event: event,
      records: records,
      totals: _calculateTotals(),
    );
  }
}
