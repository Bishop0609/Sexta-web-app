import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/rifa_model.dart';
import 'package:sexta_app/models/rifa_talonario_model.dart';
import 'package:sexta_app/services/rifa_service.dart';

class RifaBomberoTab extends StatefulWidget {
  const RifaBomberoTab({super.key});

  @override
  State<RifaBomberoTab> createState() => _RifaBomberoTabState();
}

class _RifaBomberoTabState extends State<RifaBomberoTab> {
  final RifaService _rifaService = RifaService();

  bool _isLoading = true;
  RifaModel? _rifaActiva;
  List<Map<String, dynamic>> _resumenBomberos = [];
  List<Map<String, dynamic>> _filteredBomberos = [];
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBomberos = _resumenBomberos.where((b) {
        final nombre = (b['bombero_nombre'] as String? ?? '').toLowerCase();
        return nombre.contains(query);
      }).toList();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rifa = await _rifaService.getRifaActiva();
      if (rifa != null) {
        final resumen = await _rifaService.getResumenPorBombero(rifa.id);
        setState(() {
          _rifaActiva = rifa;
          _resumenBomberos = resumen;
          _filteredBomberos = resumen;
        });
      }
    } catch (e) {
      print('Error cargando resumen bomberos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0).format(value);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'B';
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.institutionalRed));
    }

    if (_rifaActiva == null) {
      return const Center(
        child: Text('No hay rifa activa', style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar bombero',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _filteredBomberos.isEmpty
              ? const Center(child: Text('No se encontraron bomberos.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 16.0),
                  itemCount: _filteredBomberos.length,
                  itemBuilder: (context, index) {
                    final data = _filteredBomberos[index];
                    return _BomberoExpandableCard(
                      data: data,
                      rifaActiva: _rifaActiva!,
                      rifaService: _rifaService,
                      formatCurrency: _formatCurrency,
                      getInitials: _getInitials,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BomberoExpandableCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final RifaModel rifaActiva;
  final RifaService rifaService;
  final String Function(num) formatCurrency;
  final String Function(String) getInitials;

  const _BomberoExpandableCard({
    required this.data,
    required this.rifaActiva,
    required this.rifaService,
    required this.formatCurrency,
    required this.getInitials,
  });

  @override
  State<_BomberoExpandableCard> createState() => _BomberoExpandableCardState();
}

class _BomberoExpandableCardState extends State<_BomberoExpandableCard> {
  bool _isLoadingTalonarios = false;
  List<RifaTalonarioModel> _talonarios = [];
  bool _hasLoaded = false;

  Future<void> _loadTalonarios() async {
    if (_hasLoaded) return;
    setState(() => _isLoadingTalonarios = true);
    try {
      final bomberoId = widget.data['bombero_id'] as String;
      final talonarios = await widget.rifaService.getTalonariosPorBombero(widget.rifaActiva.id, bomberoId);
      setState(() {
        _talonarios = talonarios;
        _hasLoaded = true;
      });
    } catch (e) {
      print('Error cargando talonarios del bombero: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTalonarios = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bomberoNombre = widget.data['bombero_nombre'] as String? ?? 'Desconocido';
    final totalTalonarios = widget.data['total_talonarios'] ?? 0;
    final totalNumerosVendidos = widget.data['total_numeros_vendidos'] ?? 0;
    final montoRecaudado = widget.data['total_monto_recaudado'] ?? 0;
    final pendientesDevolucion = widget.data['pendientes_devolucion'] ?? 0;
    
    final devueltosCompletos = widget.data['devueltos_completos'] ?? 0;
    final devueltosParciales = widget.data['devueltos_parciales'] ?? 0;
    final devueltosSinVenta = widget.data['devueltos_sin_venta'] ?? 0;
    
    final montoEntregado = widget.data['total_monto_entregado'] ?? 0;
    final diferenciaDinero = widget.data['diferencia_dinero'] ?? 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) {
            _loadTalonarios();
          }
        },
        leading: CircleAvatar(
          backgroundColor: AppTheme.institutionalRed.withOpacity(0.1),
          foregroundColor: AppTheme.institutionalRed,
          child: Text(widget.getInitials(bomberoNombre), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(bomberoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$totalTalonarios talonarios | $totalNumerosVendidos números vendidos'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.formatCurrency(montoRecaudado), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (pendientesDevolucion > 0)
              Text('$pendientesDevolucion pdts.', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))
            else
              const Text('Al día', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        childrenPadding: const EdgeInsets.all(16.0).copyWith(top: 0),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const Text('Resumen de Talonarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCol('Total', '$totalTalonarios', Colors.black),
              _buildStatCol('Pdts.', '$pendientesDevolucion', Colors.red),
              _buildStatCol('Complet.', '$devueltosCompletos', Colors.green),
              _buildStatCol('Parcial.', '$devueltosParciales', Colors.orange),
              _buildStatCol('S/Venta', '$devueltosSinVenta', Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Balance de Dinero', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monto Recaudado (Ventas)'),
                    Text(widget.formatCurrency(montoRecaudado), style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dinero Entregado'),
                    Text(widget.formatCurrency(montoEntregado), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                if (diferenciaDinero != 0) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diferencia', style: TextStyle(color: diferenciaDinero > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                      Text(
                        widget.formatCurrency(diferenciaDinero),
                        style: TextStyle(fontWeight: FontWeight.bold, color: diferenciaDinero > 0 ? Colors.red : Colors.green),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Detalle de Talonarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          if (_isLoadingTalonarios)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.institutionalRed)))
          else if (_talonarios.isEmpty)
            const Text('No se encontraron talonarios asociados.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
          else
            ..._talonarios.map((t) {
              Color _getEstadoColor(String estado) {
                switch (estado) {
                  case 'disponible': return Colors.grey;
                  case 'entregado': return Colors.orange;
                  case 'devuelto_total': return Colors.green;
                  case 'devuelto_parcial': return Colors.blue;
                  case 'devuelto_sin_venta': return Colors.red;
                  default: return Colors.grey;
                }
              }
              final color = _getEstadoColor(t.estado);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${t.numeroTalonario}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('(${t.rangoDisplay}) - ${t.estadoDisplay()}'),
                    ),
                    Text(
                      '${t.numerosVendidos}/${widget.rifaActiva.numerosPorTalonario}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}
