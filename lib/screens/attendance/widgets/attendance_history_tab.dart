import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/services/attendance_service.dart';
import 'package:sexta_app/services/attendance_pdf_service.dart';
import 'package:sexta_app/models/attendance_event_model.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'attendance_view_dialog.dart';
import 'attendance_quick_edit_dialog.dart';

/// Tab de historial de asistencias (últimas 2 horas)
class AttendanceHistoryTab extends StatefulWidget {
  const AttendanceHistoryTab({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryTab> createState() => _AttendanceHistoryTabState();
}

class _AttendanceHistoryTabState extends State<AttendanceHistoryTab> {
  List<Map<String, dynamic>> _historyEvents = [];
  bool _isLoading = true;
  String? _currentUserId;
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtener usuario actual
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('auth_id', user.id)
            .single();
        _currentUserId = userData['id'] as String;
      }
      
      // Cargar historial de últimas 2 horas
      final events = await _attendanceService.getRecentAttendanceHistory();
      
      setState(() {
        _historyEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay asistencias recientes',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Las asistencias se muestran durante 2 horas',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyEvents.length,
        itemBuilder: (context, index) {
          final event = _historyEvents[index];
          return _buildHistoryCard(event);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> event) {
    final createdAt = DateTime.parse(event['created_at'] as String);
    final eventModel = AttendanceEventModel.fromJson(event);
    final canEdit = eventModel.canBeEdited(_currentUserId ?? '');
    final timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['act_types']['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (event['subtype'] != null)
                        Text(
                          event['subtype'] as String,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                    ],
                  ),
                ),
                Text(
                  timeAgo,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Información
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(event['event_date'] as String))}',
              style: const TextStyle(fontSize: 14),
            ),
            if (event['location'] != null)
              Text(
                'Ubicación: ${event['location']}',
                style: const TextStyle(fontSize: 14),
              ),
            
            const SizedBox(height: 12),
            
            // Totales
            Row(
              children: [
                _buildTotalChip('Presentes', event['total_present'] as int? ?? 0, Colors.green),
                const SizedBox(width: 8),
                _buildTotalChip('Ausentes', event['total_absent'] as int? ?? 0, Colors.red),
                const SizedBox(width: 8),
                _buildTotalChip('Permisos', event['total_licencia'] as int? ?? 0, Colors.orange),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('Ver'),
                  onPressed: () => _showViewDialog(event),
                ),
                if (canEdit) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    onPressed: () => _showEditDialog(event),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalChip(String label, int count, Color color) {
    return Chip(
      label: Text('$label: $count', style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else {
      return 'Hace ${diff.inHours}h ${diff.inMinutes % 60}min';
    }
  }

  Future<void> _showViewDialog(Map<String, dynamic> event) async {
    // Cargar registros de asistencia
    final records = await _attendanceService.getEventAttendanceRecords(event['id'] as String);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AttendanceViewDialog(
          event: event,
          records: records,
        ),
      );
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> event) async {
    final records = await _attendanceService.getEventAttendanceRecords(event['id'] as String);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AttendanceQuickEditDialog(
          event: event,
          records: records,
          onSaved: _loadHistory,
        ),
      );
    }
  }
}
