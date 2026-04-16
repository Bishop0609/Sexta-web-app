import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';

class GuardCompletenessWidget extends StatefulWidget {
  const GuardCompletenessWidget({super.key});

  @override
  State<GuardCompletenessWidget> createState() => _GuardCompletenessWidgetState();
}

class _GuardCompletenessWidgetState extends State<GuardCompletenessWidget> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Si estamos en los primeros 5 días del mes, mostrar el mes anterior por defecto
    if (now.day <= 5) {
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      _selectedMonth = previousMonth.month;
      _selectedYear = previousMonth.year;
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
      final response = await Supabase.instance.client.rpc(
        'get_guard_completeness_report',
        params: {'p_year': _selectedYear, 'p_month': _selectedMonth},
      );
      setState(() {
        _data = Map<String, dynamic>.from(response as Map);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text('Error al cargar datos: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildCard();
  }

  Widget _buildCard() {
    final now = DateTime.now();
    final nocturna = _data!['nocturna'] as Map<String, dynamic>;
    final fds = _data!['fds'] as Map<String, dynamic>;
    final evaluatedUntilStr = _data!['evaluated_until'] as String;
    final evaluatedUntil = DateTime.tryParse(evaluatedUntilStr) ?? now;
    final evaluatedLabel = DateFormat('d MMMM yyyy', 'es_ES').format(evaluatedUntil);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                const Icon(Icons.shield, color: AppTheme.institutionalRed),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Control Asistencias de Guardia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (i) {
                    const meses = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                                    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
                    return DropdownMenuItem(
                      value: i + 1,
                      child: Text(meses[i + 1]),
                    );
                  }),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedMonth = val);
                    _loadData();
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: [DateTime.now().year - 1, DateTime.now().year]
                      .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedYear = val);
                    _loadData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // DOS SECCIONES
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildNocturnaSection(nocturna)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildFdsSection(fds)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildNocturnaSection(nocturna),
                    const SizedBox(height: 20),
                    _buildFdsSection(fds),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Evaluado hasta el $evaluatedLabel',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNocturnaSection(Map<String, dynamic> nocturna) {
    final expected = nocturna['expected'] as int;
    final registered = nocturna['registered'] as int;
    final missingCount = nocturna['missing_count'] as int;
    final completionPct = (nocturna['completion_pct'] as num).toDouble();
    final missingList = nocturna['missing'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🌙 Guardias Nocturnas',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: completionPct / 100,
          backgroundColor: Colors.grey[200],
          color: _progressColor(completionPct),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        Text(
          '$registered/$expected registradas (${completionPct.toStringAsFixed(0)}%)',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (missingCount == 0)
          const Text(
            '✅ Todas las asistencias registradas',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
          )
        else ...[
          Text(
            'Faltan $missingCount asistencias',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Ver detalle faltantes',
              style: TextStyle(fontSize: 13, color: AppTheme.navyBlue),
            ),
            children: [
              DataTable(
                columnSpacing: 16,
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 40,
                columns: const [
                  DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('OBAC Asignado', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: missingList.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value as Map<String, dynamic>;
                  final fecha = _formatFecha(item['date'] as String);
                  final obac = _formatObacName(item['obac_asignado'] as String? ?? '—');
                  return DataRow(
                    color: WidgetStateProperty.all(
                      i.isOdd ? Colors.grey[50] : Colors.white,
                    ),
                    cells: [
                      DataCell(Text(fecha, style: const TextStyle(fontSize: 13))),
                      DataCell(Text(obac, style: const TextStyle(fontSize: 13))),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFdsSection(Map<String, dynamic> fds) {
    final expected = fds['expected'] as int;
    final registered = fds['registered'] as int;
    final missingCount = fds['missing_count'] as int;
    final completionPct = (fds['completion_pct'] as num).toDouble();
    final missingList = fds['missing'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏠 Guardias FDS',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: completionPct / 100,
          backgroundColor: Colors.grey[200],
          color: _progressColor(completionPct),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        Text(
          '$registered/$expected registradas (${completionPct.toStringAsFixed(0)}%)',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (missingCount == 0)
          const Text(
            '✅ Todas las asistencias registradas',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
          )
        else ...[
          Text(
            'Faltan $missingCount asistencias',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Ver detalle faltantes',
              style: TextStyle(fontSize: 13, color: AppTheme.navyBlue),
            ),
            children: [
              DataTable(
                columnSpacing: 16,
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 40,
                columns: const [
                  DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Turno', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('OBAC Asignado', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: missingList.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value as Map<String, dynamic>;
                  final fecha = _formatFecha(item['date'] as String);
                  final turno = item['shift'] as String? ?? '—';
                  return DataRow(
                    color: WidgetStateProperty.all(
                      i.isOdd ? Colors.grey[50] : Colors.white,
                    ),
                    cells: [
                      DataCell(Text(fecha, style: const TextStyle(fontSize: 13))),
                      DataCell(Text(turno, style: const TextStyle(fontSize: 13))),
                      DataCell(Text(
                        item['obac_asignado'] != null 
                          ? _formatObacName(item['obac_asignado'] as String)
                          : '—',
                        style: const TextStyle(fontSize: 13),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _progressColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }

  /// Formatea "2026-03-07" → "Sáb 07/03"
  String _formatFecha(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return _capitalize(DateFormat('E dd/MM', 'es_ES').format(date));
  }

  /// Capitaliza primera letra
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Formatea el nombre del OBAC mostrando primer nombre y primer apellido
  String _formatObacName(String fullName) {
    if (fullName == '—') return fullName;
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return fullName;
    
    // Detectar si primera palabra es abreviatura (termina en ".")
    // Ej: "Ch. Matias Tromben Marcone" → "Ch. Matias Tromben"
    // Ej: "N. Alexander Guerrero Moreno" → "N. Alexander Guerrero"
    if (parts[0].endsWith('.')) {
      if (parts.length >= 4) {
        return '${parts[0]} ${parts[1]} ${parts[2]}';
      }
      return parts.join(' ');
    }
    
    // Nombre normal: primer nombre + apellido paterno (penúltima palabra)
    // Ej: "Felipe Andrés González Caro" → "Felipe González"
    // Ej: "Fernando Antonio Matias Marín Varela" → "Fernando Marín"
    // Ej: "Javiera Isidora Moraga Vergara" → "Javiera Moraga"
    if (parts.length >= 4) {
      return '${parts[0]} ${parts[parts.length - 2]}';
    }
    if (parts.length == 3) {
      return '${parts[0]} ${parts[1]}';
    }
    return fullName;
  }
}
