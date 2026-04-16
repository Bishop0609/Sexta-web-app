import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/rifa_model.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/rifa_service.dart';
import 'rifa_config_screen.dart';

class RifaDashboardTab extends StatefulWidget {
  const RifaDashboardTab({super.key});

  @override
  State<RifaDashboardTab> createState() => _RifaDashboardTabState();
}

class _RifaDashboardTabState extends State<RifaDashboardTab> {
  final RifaService _rifaService = RifaService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  RifaModel? _rifaActiva;
  Map<String, dynamic>? _resumenGlobal;
  List<Map<String, dynamic>> _topVendedores = [];

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
        final resumen = await _rifaService.getResumenGlobal(rifa.id);
        final ranking = await _rifaService.getResumenPorBombero(rifa.id);
        
        setState(() {
          _rifaActiva = rifa;
          _resumenGlobal = resumen;
          _topVendedores = ranking.take(5).toList();
        });
      }
    } catch (e) {
      print('Error cargando dashboard rifa: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(num value) {
    final format = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.institutionalRed),
      );
    }

    if (_rifaActiva == null) {
      final user = _authService.currentUser;
      final isAdmin = user?.role == UserRole.admin;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay rifa activa',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RifaConfigScreen()),
                  );
                  if (result == true) {
                    _loadData(); // Recargar dashboard
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear Rifa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.institutionalRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ]
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.institutionalRed,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResumenGeneralCard(),
            const SizedBox(height: 16),
            _buildEstadoTalonariosCard(),
            const SizedBox(height: 16),
            _buildRecaudacionCard(),
            const SizedBox(height: 16),
            _buildTopVendedoresCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenGeneralCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.institutionalRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _rifaActiva!.nombre,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.institutionalRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVA',
                    style: TextStyle(
                      color: AppTheme.institutionalRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('Talonarios', '${_rifaActiva!.totalTalonarios}'),
                _buildInfoCol('Lote', '${_rifaActiva!.numerosPorTalonario} núms'),
                _buildInfoCol('Valor Núm', _formatCurrency(_rifaActiva!.precioNumero)),
                _buildInfoCol('Valor Tal', _formatCurrency(_rifaActiva!.precioTalonario)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Números', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('${_rifaActiva!.totalNumeros}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recaudación Máxima', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)),
                  Text(
                    _formatCurrency(_rifaActiva!.recaudacionMaxima),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildEstadoTalonariosCard() {
    final disponibles = _resumenGlobal?['talonarios_en_bodega'] ?? 0;
    final enCalle = _resumenGlobal?['talonarios_en_calle'] ?? 0;
    final devueltos = _resumenGlobal?['talonarios_devueltos'] ?? 0;
    final total = _rifaActiva!.totalTalonarios;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppTheme.institutionalRed),
                SizedBox(width: 8),
                Text('Estado de Talonarios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildEstadoIndicator('Bodega', disponibles, total, Colors.grey)),
                Expanded(child: _buildEstadoIndicator('En Calle', enCalle, total, Colors.orange)),
                Expanded(child: _buildEstadoIndicator('Devolución', devueltos, total, Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoIndicator(String label, int cantidad, int total, Color color) {
    final pct = total > 0 ? (cantidad / total * 100) : 0.0;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('$cantidad', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildRecaudacionCard() {
    final montoEntregado = _resumenGlobal?['monto_entregado_total'] ?? 0;
    final montoRecaudado = _resumenGlobal?['monto_recaudado_total'] ?? 0;
    final maximo = _rifaActiva!.recaudacionMaxima;
    final pct = maximo > 0 ? (montoEntregado / maximo) : 0.0;
    final diferencia = montoRecaudado - montoEntregado;
    
    final talonariosEnCalle = _resumenGlobal?['talonarios_en_calle'] as int? ?? 0;
    final precioTalonario = _rifaActiva!.numerosPorTalonario * _rifaActiva!.precioNumero;
    final dineroEnCalle = talonariosEnCalle * precioTalonario;
    final pctEnCalle = maximo > 0 ? (dineroEnCalle / maximo) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: AppTheme.institutionalRed),
                SizedBox(width: 8),
                Text('Recaudación Real', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatCurrency(montoEntregado), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                Text('de ${_formatCurrency(maximo)}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 12,
                color: Colors.grey.shade200,
                child: Row(
                  children: [
                    Expanded(flex: (pct * 1000).round(), child: Container(color: Colors.green)),
                    Expanded(flex: (pctEnCalle * 1000).round(), child: Container(color: Colors.orange)),
                    Expanded(flex: (((1.0 - pct - pctEnCalle).clamp(0.0, 1.0)) * 1000).round(), child: Container(color: Colors.grey.shade200)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Text('Recaudado ${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Text('En calle ${(pctEnCalle * 100).toStringAsFixed(1)}% (${_formatCurrency(dineroEnCalle)})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVendedoresCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.leaderboard_outlined, color: AppTheme.institutionalRed),
                SizedBox(width: 8),
                Text('Top Vendedores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (_topVendedores.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text('No hay ventas registradas', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._topVendedores.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index < 3 ? Colors.orange.shade100 : Colors.grey.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index < 3 ? Colors.orange.shade800 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(data['bombero_nombre'] ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${data['total_numeros_vendidos'] ?? 0} núms', style: TextStyle(color: Colors.grey.shade600)),
                  trailing: Text(
                    _formatCurrency(data['total_monto_recaudado'] ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }),
          ],
        ),
      ),
    );
  }
}
