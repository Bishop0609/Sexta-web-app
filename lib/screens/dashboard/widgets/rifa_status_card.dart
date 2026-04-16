import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/models/rifa_talonario_model.dart';
import 'package:sexta_app/services/rifa_service.dart';

class RifaStatusCard extends StatefulWidget {
  final String userId;

  const RifaStatusCard({super.key, required this.userId});

  @override
  State<RifaStatusCard> createState() => _RifaStatusCardState();
}

class _RifaStatusCardState extends State<RifaStatusCard> {
  final RifaService _rifaService = RifaService();

  bool _isLoading = true;
  Map<String, dynamic>? _estado;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final estado = await _rifaService.getEstadoRifaBombero(widget.userId);
    if (mounted) setState(() { _estado = estado; _isLoading = false; });
  }

  String _formatCurrency(num value) =>
      NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0).format(value);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    // CASO 1: no hay rifa activa
    if (_estado == null) return const SizedBox.shrink();

    final rifaNombre = _estado!['rifa_nombre'] as String? ?? 'Rifa';
    final tieneTalonarios = _estado!['tiene_talonarios'] as bool? ?? false;
    final totalPendientes = _estado!['total_pendientes'] as int? ?? 0;
    final totalDevueltos = _estado!['total_devueltos'] as int? ?? 0;
    final numerosVendidos = _estado!['numeros_vendidos'] as int? ?? 0;
    final montoRecaudado = _estado!['monto_recaudado'] as int? ?? 0;
    final pendientes = (_estado!['talonarios_pendientes'] as List?)?.cast<RifaTalonarioModel>() ?? [];
    final devueltos = (_estado!['talonarios_devueltos'] as List?)?.cast<RifaTalonarioModel>() ?? [];
    final devueltosCompletos = (_estado!['talonarios_devueltos_completos'] as List?)?.cast<RifaTalonarioModel>() ?? [];

    // CASO 2: sin talonarios asignados
    if (!tieneTalonarios) {
      return _buildCard(
        color: Colors.orange,
        icon: Icons.confirmation_number_outlined,
        iconColor: Colors.orange,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎟️ ¡La $rifaNombre está en marcha!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              'Aún no tienes talonarios asignados. Acércate a la oficialidad para retirar tus talonarios y colaborar con la compañía.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      );
    }

    // CASO 5: pendientes + devueltos → mostrar ambos
    if (totalPendientes > 0 && totalDevueltos > 0) {
      return _buildCard(
        color: Colors.blue,
        icon: Icons.sell,
        iconColor: Colors.blue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPendientesContent(totalPendientes, pendientes),
            const Divider(height: 20),
            _buildDevueltosContent(totalDevueltos, devueltos, devueltosCompletos, totalPendientes, numerosVendidos, montoRecaudado, small: true),
          ],
        ),
      );
    }

    // CASO 3: solo pendientes
    if (totalPendientes > 0) {
      return _buildCard(
        color: Colors.blue,
        icon: Icons.sell,
        iconColor: Colors.blue,
        child: _buildPendientesContent(totalPendientes, pendientes),
      );
    }

    // CASO 4: solo devueltos
    return _buildCard(
      color: Colors.green,
      icon: Icons.check_circle,
      iconColor: Colors.green,
      child: _buildDevueltosContent(totalDevueltos, devueltos, devueltosCompletos, totalPendientes, numerosVendidos, montoRecaudado),
    );
  }

  Widget _buildPendientesContent(int totalPendientes, List<RifaTalonarioModel> pendientes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tienes $totalPendientes talonario${totalPendientes == 1 ? '' : 's'} pendiente${totalPendientes == 1 ? '' : 's'} de venta',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        ...pendientes.map((t) => Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            '• Talonario #${t.numeroTalonario} — ${t.rangoDisplay}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        )),
        const SizedBox(height: 8),
        const Text('¡Cada número vendido cuenta! Ayuda a la compañía a alcanzar la meta.',
            style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildDevueltosContent(
    int totalDevueltos,
    List<RifaTalonarioModel> devueltos,
    List<RifaTalonarioModel> devueltosCompletos,
    int totalPendientes,
    int numerosVendidos,
    int montoRecaudado, {
    bool small = false,
  }) {
    final allComplete = totalPendientes == 0 && devueltosCompletos.length == totalDevueltos;
    final style = TextStyle(fontWeight: FontWeight.bold, fontSize: small ? 13 : 15);
    final styleSecond = TextStyle(fontSize: small ? 12 : 13, color: Colors.black87);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          allComplete
              ? '🎉 ¡Excelente trabajo! Has vendido todos tus talonarios.'
              : '✅ Has devuelto $totalDevueltos talonario${totalDevueltos == 1 ? '' : 's'}.',
          style: style,
        ),
        const SizedBox(height: 6),
        ...devueltos.map((t) => Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            '• Talonario #${t.numeroTalonario} — ${t.correlativoDesde} - ${t.correlativoHasta} ✅',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        )),
        const SizedBox(height: 8),
        Text(
          'Total vendido: $numerosVendidos números (${_formatCurrency(montoRecaudado)})',
          style: styleSecond,
        ),
      ],
    );
  }

  Widget _buildCard({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.05),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 14),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
