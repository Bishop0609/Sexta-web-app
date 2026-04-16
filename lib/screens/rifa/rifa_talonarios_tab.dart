import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/rifa_model.dart';
import 'package:sexta_app/models/rifa_talonario_model.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/rifa_service.dart';
import 'rifa_entregar_screen.dart';
import 'rifa_recibir_screen.dart';

class RifaTalonariosTab extends StatefulWidget {
  const RifaTalonariosTab({super.key});

  @override
  State<RifaTalonariosTab> createState() => _RifaTalonariosTabState();
}

class _RifaTalonariosTabState extends State<RifaTalonariosTab> {
  final RifaService _rifaService = RifaService();
  
  bool _isLoading = true;
  RifaModel? _rifaActiva;
  List<RifaTalonarioModel> _todosLosTalonarios = [];
  String _filtroActivo = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rifa = await _rifaService.getRifaActiva();
      if (rifa != null) {
        final talonarios = await _rifaService.getTalonarios(rifa.id);
        setState(() {
          _rifaActiva = rifa;
          _todosLosTalonarios = talonarios;
        });
      }
    } catch (e) {
      print('Error cargando talonarios: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<RifaTalonarioModel> get _talonariosFiltrados {
    if (_filtroActivo == 'Todos') return _todosLosTalonarios;
    if (_filtroActivo == 'Disponible') {
      return _todosLosTalonarios.where((t) => t.estaDisponible).toList();
    }
    if (_filtroActivo == 'Entregado') {
      return _todosLosTalonarios.where((t) => t.estaEntregado).toList();
    }
    if (_filtroActivo == 'Devuelto') {
      return _todosLosTalonarios.where((t) => t.fueDevuelto).toList();
    }
    return _todosLosTalonarios;
  }

  String _formatCurrency(num value) {
    final format = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    return format.format(value);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _parseColor(String colorName) {
    switch (colorName) {
      case 'grey':
        return Colors.grey;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.institutionalRed));
    }

    if (_rifaActiva == null) {
      return const Center(
        child: Text('No hay rifa activa para mostrar talonarios', style: TextStyle(color: Colors.grey)),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.institutionalRed,
              onRefresh: _loadData,
              child: _talonariosFiltrados.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No hay talonarios con este filtro',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80, left: 8, right: 8, top: 8),
                      itemCount: _talonariosFiltrados.length,
                      itemBuilder: (context, index) {
                        return _buildTalonarioCard(_talonariosFiltrados[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_recibir',
            backgroundColor: Colors.green,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RifaRecibirScreen(rifaId: _rifaActiva!.id)),
              );
              if (result == true) _loadData();
            },
            child: const Icon(Icons.download),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'fab_entregar',
            backgroundColor: AppTheme.institutionalRed,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RifaEntregarScreen(rifaId: _rifaActiva!.id)),
              );
              if (result == true) _loadData();
            },
            icon: const Icon(Icons.outbox),
            label: const Text('Entregar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['Todos', 'Disponible', 'Entregado', 'Devuelto'].map((filtro) {
          final isSelected = _filtroActivo == filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filtro),
              selected: isSelected,
              selectedColor: AppTheme.institutionalRed.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.institutionalRed : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filtroActivo = filtro);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTalonarioCard(RifaTalonarioModel talonario) {
    final chipColor = _parseColor(talonario.estadoColor());

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.navyBlue.withOpacity(0.1),
          child: Text(
            '${talonario.numeroTalonario}',
            style: const TextStyle(color: AppTheme.navyBlue, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text('Talonario #${talonario.numeroTalonario}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: chipColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: chipColor.withOpacity(0.5)),
              ),
              child: Text(
                talonario.estadoDisplay(),
                style: TextStyle(fontSize: 10, color: chipColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Números: ${talonario.rangoDisplay}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: talonario.estaEntregado
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'devolver_bodega') {
                    await _confirmarDevolverBodega(talonario);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'devolver_bodega',
                    child: Row(
                      children: [
                        Icon(Icons.undo, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Devolver a Bodega'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (talonario.estaEntregado || talonario.fueDevuelto) ...[
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Asignado a: ${talonario.nombreAsignado ?? "Desconocido"}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (talonario.fechaEntrega != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Entregado el: ${_formatDate(talonario.fechaEntrega!)}'),
                      ],
                    ),
                ],
                if (talonario.fueDevuelto) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Números vendidos:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('${talonario.numerosVendidos}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monto recaudado:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_formatCurrency(talonario.montoRecaudado), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (talonario.fechaDevolucion != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fecha devolución:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(_formatDate(talonario.fechaDevolucion!)),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarDevolverBodega(RifaTalonarioModel talonario) async {
    final nombreAsignado = talonario.nombreAsignado ?? 'Sin asignar';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Devolver a Bodega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Devolver el Talonario #${talonario.numeroTalonario} a bodega?'),
            const SizedBox(height: 8),
            Text('Actualmente asignado a: $nombreAsignado',
              style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'El talonario quedará disponible para reasignar. Esta acción queda registrada en el log.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Devolver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    final result = await RifaService().devolverABodega(
      talonarioId: talonario.id,
      ejecutadoPor: currentUser.id,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Talonario #${talonario.numeroTalonario} devuelto a bodega'), backgroundColor: Colors.green),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.red),
      );
    }
  }
}
