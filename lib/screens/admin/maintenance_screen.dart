import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  
  // Estadísticas
  int _totalPermissionsAttachments = 0;
  int _oldAttachmentsCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      // Contar total de permisos con adjuntos
      final totalResponse = await _supabase
          .from('permissions')
          .select('id')
          .not('attachment_path', 'is', null)
          .count(CountOption.exact);
      
      _totalPermissionsAttachments = totalResponse.count;

      // Calcular fecha límite (2 años atrás)
      final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730)); // Aprox 2 años
      
      // Contar adjuntos antiguos
      final oldResponse = await _supabase
          .from('permissions')
          .select('id')
          .not('attachment_path', 'is', null)
          .lt('created_at', twoYearsAgo.toIso8601String())
          .count(CountOption.exact);
          
      _oldAttachmentsCount = oldResponse.count;
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando estadísticas: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cleanOldAttachments() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Limpieza'),
        content: Text(
          '¿Está seguro que desea eliminar $_oldAttachmentsCount archivos adjuntos antiguos? '
          'Esta acción liberará espacio pero no se podrá deshacer. Los archivos eliminados no podrán recuperarse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.criticalColor),
            child: const Text('Eliminar Archivos'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730));
      
      // Obtener los permisos a limpiar
      final permissionsToClean = await _supabase
          .from('permissions')
          .select('id, attachment_path')
          .not('attachment_path', 'is', null)
          .lt('created_at', twoYearsAgo.toIso8601String());
      
      int deletedCount = 0;
      
      for (final perm in permissionsToClean) {
        final path = perm['attachment_path'] as String?;
        if (path != null) {
          // Eliminar archivo de storage
          await _supabase.storage.from('permission-attachments').remove([path]);
          
          // Actualizar registro en BD
          await _supabase
              .from('permissions')
              .update({'attachment_path': null})
              .eq('id', perm['id']);
              
          deletedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Limpieza completada. Se eliminaron $deletedCount archivos.'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );
        _loadStatistics(); // Recargar estadísticas
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error durante la limpieza: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Mantenimiento del Sistema'),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Almacenamiento',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Administre el espacio utilizado por archivos adjuntos y realice tareas de limpieza.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    
                    // Tarjeta de Permisos
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.folder_shared, color: AppTheme.navyBlue, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Adjuntos de Permisos',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildStatRow(
                              'Total de archivos adjuntos', 
                              _totalPermissionsAttachments.toString(),
                              Icons.description,
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow(
                              'Archivos antiguos (> 2 años)', 
                              _oldAttachmentsCount.toString(),
                              Icons.history,
                              isWarning: _oldAttachmentsCount > 0,
                            ),
                            const SizedBox(height: 24),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _oldAttachmentsCount > 0 ? _cleanOldAttachments : null,
                                icon: const Icon(Icons.cleaning_services),
                                label: const Text('Limpiar Archivos Antiguos'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.warningColor,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (_oldAttachmentsCount == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'No hay archivos antiguos para limpiar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Nota informativa
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'La limpieza eliminará permanentemente los archivos físicos de Supabase Storage y su referencia en la base de datos. Los registros de permisos permanecerán intactos.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {bool isWarning = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isWarning ? AppTheme.warningColor : AppTheme.navyBlue,
          ),
        ),
      ],
    );
  }
}
