import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/services/attendance_service.dart';
import 'package:sexta_app/services/supabase_service.dart';

/// Diálogo de edición rápida con validaciones de tiempo y usuario
class AttendanceQuickEditDialog extends StatefulWidget {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> records;
  final VoidCallback onSaved;

  const AttendanceQuickEditDialog({
    Key? key,
    required this.event,
    required this.records,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<AttendanceQuickEditDialog> createState() => _AttendanceQuickEditDialogState();
}

class _AttendanceQuickEditDialogState extends State<AttendanceQuickEditDialog> {
  late List<Map<String, dynamic>> _editableRecords;
  bool _isSaving = false;
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _editableRecords = List.from(widget.records);
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.parse(widget.event['created_at'] as String);
    final timeRemaining = _getTimeRemaining(createdAt);
    
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Encabezado con advertencia de tiempo
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Edición Rápida',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tiempo restante para editar: $timeRemaining',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Advertencia
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.yellow[100],
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Solo puedes cambiar presente/ausente. Los usuarios con permiso no se pueden modificar.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de usuarios
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _editableRecords.length,
                itemBuilder: (context, index) {
                  final record = _editableRecords[index];
                  return _buildEditableRow(record, index);
                },
              ),
            ),
            
            // Botones
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableRow(Map<String, dynamic> record, int index) {
    final isLocked = record['is_locked'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '${record['nombre']} ${record['apellido']}',
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(
          record['rango'] as String? ?? '',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: isLocked
          ? Chip(
              label: const Text('Con Permiso', style: TextStyle(fontSize: 10)),
              backgroundColor: Colors.orange[100],
              avatar: const Icon(Icons.lock, size: 16),
            )
          : ToggleButtons(
              constraints: const BoxConstraints(minWidth: 60, minHeight: 32),
              isSelected: [
                record['status'] == 'present',
                record['status'] == 'absent',
              ],
              onPressed: (buttonIndex) {
                setState(() {
                  _editableRecords[index]['status'] = buttonIndex == 0 ? 'present' : 'absent';
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('P', style: TextStyle(fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('A', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
      ),
    );
  }

  String _getTimeRemaining(DateTime createdAt) {
    final deadline = createdAt.add(const Duration(hours: 1));
    final remaining = deadline.difference(DateTime.now());
    
    if (remaining.isNegative) {
      return 'Expirado';
    }
    
    return '${remaining.inMinutes} minutos';
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      await _attendanceService.updateAttendanceWithValidation(
        eventId: widget.event['id'] as String,
        currentUserId: currentUser!.id,
        updatedRecords: _editableRecords,
      );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asistencia actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
