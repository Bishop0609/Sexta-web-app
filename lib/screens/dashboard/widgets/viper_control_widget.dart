import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/viper_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/models/viper_emergencia_model.dart';

class ViperControlWidget extends StatefulWidget {
  const ViperControlWidget({super.key});

  @override
  State<ViperControlWidget> createState() => _ViperControlWidgetState();
}

class _ViperControlWidgetState extends State<ViperControlWidget> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<ViperEmergenciaModel> _registros = [];
  bool _isImporting = false;
  late int _selectedMonth;
  late int _selectedYear;

  final _meses = const [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (now.day <= 5) {
      final prev = DateTime(now.year, now.month - 1);
      _selectedMonth = prev.month;
      _selectedYear = prev.year;
    } else {
      _selectedMonth = now.month;
      _selectedYear = now.year;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stats = await ViperService().getDashboardStats(_selectedYear, _selectedMonth);
      final registros = await ViperService().getByMonth(_selectedYear, _selectedMonth);
      if (mounted) {
        setState(() {
          _stats = stats;
          _registros = registros;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _importExcel() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null) {
        setState(() => _isImporting = false);
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        setState(() => _isImporting = false);
        return;
      }

      final currentUser = AuthService().currentUser;
      final userId = currentUser?.id ?? '';

      final importResult = await ViperService().importExcel(bytes, userId);

      final matchResult = await ViperService().runAutoMatch();
      final vinculadas = matchResult.where((m) => m['match_status'] == 'vinculada').length;

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Importados: ${importResult['inserted']}, '
            'Actualizados: ${importResult['updated']}, '
            'Vinculados: $vinculadas',
          ),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _runMatching() async {
    try {
      final results = await ViperService().runAutoMatch();
      final vinculadas = results.where((m) => m['match_status'] == 'vinculada').length;
      final sinMatch = results.where((m) => m['match_status'] == 'sin_match').length;
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Matching: $vinculadas vinculadas, $sinMatch sin match'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showLinkDialog(ViperEmergenciaModel registro) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vincular emergencia ${registro.correlativo}'),
        content: SizedBox(
          width: 500,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: ViperService().getUnmatchedSystemEvents(_selectedYear, _selectedMonth),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const Text(
                  'No hay emergencias del sistema sin vincular para este período.',
                  style: TextStyle(color: Colors.grey),
                );
              }
              return SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final rawDate = event['event_date'] as String? ?? '';
                    String fechaDisplay = rawDate;
                    try {
                      fechaDisplay = DateFormat('dd/MM/yyyy').format(DateTime.parse(rawDate));
                    } catch (_) {}
                    final subtype = event['subtype'] as String? ?? '';
                    final location = event['location'] as String? ?? '';
                    return ListTile(
                      title: Text('$fechaDisplay — $subtype'),
                      subtitle: location.isNotEmpty ? Text(location) : null,
                      onTap: () async {
                        await ViperService().linkManual(registro.id, event['id'] as String);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vinculada correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDescartarDialog(ViperEmergenciaModel registro) async {
    final notaController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Descartar emergencia ${registro.correlativo}'),
        content: TextField(
          controller: notaController,
          decoration: const InputDecoration(
            labelText: 'Razón o notas',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final nota = notaController.text.trim();
              await ViperService().markDescartada(registro.id, nota);
              if (ctx.mounted) Navigator.of(ctx).pop();
              await _loadData();
            },
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    notaController.dispose();
  }

  Future<void> _markNoAplica(ViperEmergenciaModel registro) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Marcar correlativo ${registro.correlativo} como No aplica?'),
        content: const Text('Esta emergencia no será considerada en el control de vinculación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ViperService().markNoAplica(registro.id);
      await _loadData();
    }
  }

  Widget _buildStatCard(String label, String sublabel, dynamic value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value?.toString() ?? '—',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            Text(
              sublabel,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistroItem(ViperEmergenciaModel registro) {
    Color borderColor;
    Color iconColor;
    IconData iconData;

    switch (registro.estadoMatching) {
      case 'vinculada':
        borderColor = Colors.green;
        iconColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'descartada':
        borderColor = Colors.grey;
        iconColor = Colors.grey;
        iconData = Icons.cancel;
        break;
      case 'no_aplica':
        borderColor = Colors.grey.shade400;
        iconColor = Colors.grey.shade400;
        iconData = Icons.remove_circle_outline;
        break;
      default: // pendiente
        borderColor = Colors.orange;
        iconColor = Colors.orange;
        iconData = Icons.warning;
    }

    String fechaFormateada = '';
    try {
      final raw = DateFormat('E dd/MM', 'es_ES').format(registro.fecha);
      fechaFormateada = raw[0].toUpperCase() + raw.substring(1);
    } catch (_) {
      fechaFormateada = registro.fecha.toIso8601String().substring(0, 10);
    }

    final tituloTexto = '$fechaFormateada — ${registro.codigoEmergencia}';
    final subtituloTexto = [registro.tipoEmergencia, registro.direccion]
        .where((s) => s != null && s.isNotEmpty)
        .join(' — ');
    final carrosTexto = 'Carros: ${(registro.carros ?? []).join(', ')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor, width: 3)),
        color: Colors.grey.shade50,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloTexto,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (subtituloTexto.isNotEmpty)
                  Text(
                    subtituloTexto,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  carrosTexto,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (registro.estadoMatching == 'pendiente')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (action) {
                switch (action) {
                  case 'vincular':
                    _showLinkDialog(registro);
                    break;
                  case 'descartar':
                    _showDescartarDialog(registro);
                    break;
                  case 'no_aplica':
                    _markNoAplica(registro);
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'vincular', child: Text('Vincular manualmente')),
                PopupMenuItem(value: 'descartar', child: Text('Descartar')),
                PopupMenuItem(value: 'no_aplica', child: Text('No aplica')),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final pendientes = _stats?['pendientes'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: AppTheme.institutionalRed),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Control Emergencias',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownButton<int>(
                  value: _selectedMonth,
                  underline: const SizedBox(),
                  isDense: true,
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(_meses[i], style: const TextStyle(fontSize: 13)),
                  )),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMonth = val);
                      _loadData();
                    }
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  underline: const SizedBox(),
                  isDense: true,
                  items: [
                    DropdownMenuItem(value: currentYear - 1, child: Text('${currentYear - 1}', style: const TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: currentYear, child: Text('$currentYear', style: const TextStyle(fontSize: 13))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                      _loadData();
                    }
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: _isImporting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_file, size: 16),
                  label: const Text('Importar Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.institutionalRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isImporting ? null : _importExcel,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CONTENIDO
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              Text('Error: $_error', style: const TextStyle(color: Colors.red))
            else ...[
              // STATS BAR
              if (_stats != null) ...[
                Row(
                  children: [
                    _buildStatCard('Viper', 'emergencias en Excel', _stats!['total_viper'], AppTheme.navyBlue),
                    const SizedBox(width: 8),
                    _buildStatCard('Sistema', 'emergencias registradas', _stats!['total_sistema'], AppTheme.navyBlue),
                    const SizedBox(width: 8),
                    _buildStatCard('Vinculadas', 'coinciden ambos', _stats!['vinculadas'], Colors.green),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Pendientes',
                      'faltan en sistema',
                      _stats!['pendientes'],
                      pendientes > 0 ? Colors.red : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // BANNER RESUMEN
                Builder(builder: (_) {
                  final totalViper = _stats!['total_viper'] as int? ?? 0;
                  if (pendientes > 0) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hay $pendientes emergencia${pendientes > 1 ? 's' : ''} en el Excel de Viper que no están registradas en el sistema. Deben ser ingresadas manualmente por el ayudante.',
                              style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (totalViper > 0) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '✅ Todas las emergencias del Excel están registradas en el sistema.',
                        style: TextStyle(fontSize: 12, color: Colors.green[800]),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 16),
              ],

              // LISTA DIVIDIDA EN SECCIONES
              if (_registros.isEmpty && (_stats == null || (_stats!['total_viper'] == 0 || _stats!['total_viper'] == null)))
                const Center(
                  child: Text(
                    'No hay datos importados para este período',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                )
              else ...[
                // SECCIÓN 1: Pendientes
                Builder(builder: (_) {
                  final pendientesList = _registros.where((r) => r.estadoMatching == 'pendiente').toList();
                  if (pendientesList.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '⚠️ Pendientes (${pendientesList.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...pendientesList.map(_buildRegistroItem),
                    ],
                  );
                }),

                // SECCIÓN 2: Vinculadas/descartadas/no_aplica
                Builder(builder: (_) {
                  final vinculadasList = _registros.where((r) => r.estadoMatching != 'pendiente').toList();
                  if (vinculadasList.isEmpty) return const SizedBox.shrink();
                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      '✅ Vinculadas (${vinculadasList.length})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: false,
                    children: vinculadasList.map(_buildRegistroItem).toList(),
                  );
                }),
              ],

              // FOOTER
              if (_stats?['ultima_importacion'] != null) ...[
                const Divider(),
                Builder(builder: (_) {
                  String fechaImport = '';
                  try {
                    fechaImport = DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(_stats!['ultima_importacion'] as String));
                  } catch (_) {
                    fechaImport = _stats!['ultima_importacion'].toString();
                  }
                  final usuario = _stats!['ultima_importacion_usuario'] as String? ?? '';
                  return Text(
                    'Última importación: $fechaImport${usuario.isNotEmpty ? ' por $usuario' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }),
              ],

              if (pendientes > 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Buscar coincidencias'),
                        onPressed: _runMatching,
                      ),
                      Text(
                        'Intenta vincular pendientes con emergencias recién ingresadas al sistema',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
