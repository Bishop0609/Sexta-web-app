import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/rifa_model.dart';
import 'package:sexta_app/models/rifa_talonario_model.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/rifa_service.dart';

class RifaRecibirScreen extends StatefulWidget {
  final String rifaId;

  const RifaRecibirScreen({super.key, required this.rifaId});

  @override
  State<RifaRecibirScreen> createState() => _RifaRecibirScreenState();
}

class _RifaRecibirScreenState extends State<RifaRecibirScreen> {
  final RifaService _rifaService = RifaService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isSubmitting = false;

  RifaModel? _rifaActiva;
  List<RifaTalonarioModel> _talonariosEntregados = [];
  RifaTalonarioModel? _selectedTalonario;

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String _filtroChip = 'Todos';

  final TextEditingController _numerosController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  int _montoEsperado = 0;
  int _montoConDescuento = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _numerosController.addListener(_onNumerosChanged);
    _montoController.addListener(() => setState(() {}));
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numerosController.dispose();
    _montoController.dispose();
    _notasController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rifa = await _rifaService.getRifaActiva();
      if (rifa != null) {
        final talonarios = await _rifaService.getTalonarios(widget.rifaId, estado: 'entregado');
        setState(() {
          _rifaActiva = rifa;
          _talonariosEntregados = talonarios;
        });
      }
    } catch (e) {
      print('Error cargando datos para recibir: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<RifaTalonarioModel> get _talonariosFiltrados {
    var lista = _talonariosEntregados;

    // Filtro chip
    if (_filtroChip == 'Bomberos') {
      lista = lista.where((t) => t.esInterno).toList();
    } else if (_filtroChip == 'Externos') {
      lista = lista.where((t) => t.esExterno).toList();
    }

    // Filtro texto
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista.where((t) {
        final nombre = (t.nombreAsignado ?? '').toLowerCase();
        final num = t.numeroTalonario.toString();
        return nombre.contains(q) || num.contains(q);
      }).toList();
    }

    return lista;
  }

  void _onNumerosChanged() {
    if (_rifaActiva == null) return;

    final numerosStr = _numerosController.text.trim();
    if (numerosStr.isEmpty) {
      setState(() { _montoEsperado = 0; _montoConDescuento = 0; });
      return;
    }

    int numeros = int.tryParse(numerosStr) ?? 0;
    if (numeros > _rifaActiva!.numerosPorTalonario) {
      numeros = _rifaActiva!.numerosPorTalonario;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _numerosController.text = numeros.toString();
        _numerosController.selection = TextSelection.fromPosition(TextPosition(offset: _numerosController.text.length));
      });
    }

    final bruto = numeros * _rifaActiva!.precioNumero;
    final descuentoPct = _selectedTalonario?.entidadDescuento ?? 0;
    final descuentoMonto = (bruto * descuentoPct / 100).round();

    setState(() {
      _montoEsperado = bruto;
      _montoConDescuento = bruto - descuentoMonto;
    });
  }

  void _onTalonarioSelected(RifaTalonarioModel? talonario) {
    setState(() {
      _selectedTalonario = talonario;
      _numerosController.clear();
      _montoController.clear();
      _notasController.clear();
      _montoEsperado = 0;
      _montoConDescuento = 0;
    });
  }

  void _rellenarMonto() {
    final monto = _selectedTalonario?.esExterno == true ? _montoConDescuento : _montoEsperado;
    if (_montoController.text.isEmpty && monto > 0) {
      _montoController.text = monto.toString();
    }
  }

  Future<void> _submitDevolucion() async {
    if (_selectedTalonario == null) return;

    final numeros = int.tryParse(_numerosController.text.trim()) ?? 0;
    final monto = int.tryParse(_montoController.text.trim()) ?? 0;

    if (_numerosController.text.trim().isEmpty || _montoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Completa los números vendidos y el monto entregado'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    Map<String, dynamic> result;
    if (_selectedTalonario!.esExterno) {
      result = await _rifaService.recibirTalonarioExterna(
        talonarioId: _selectedTalonario!.id,
        numerosVendidos: numeros,
        montoEntregado: monto,
        recibidoPor: currentUser.id,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );
    } else {
      result = await _rifaService.recibirTalonario(
        talonarioId: _selectedTalonario!.id,
        numerosVendidos: numeros,
        montoEntregado: monto,
        recibidoPor: currentUser.id,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Devolución registrada exitosamente'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Error: ${result['error']}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String _formatCurrency(num value) =>
      NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0).format(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recibir Devolución', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.institutionalRed,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.institutionalRed))
          : _talonariosEntregados.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchAndFilters(),
                      const SizedBox(height: 8),
                      _buildTalonariosList(),
                      const SizedBox(height: 24),
                      if (_selectedTalonario != null) _buildForm(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text('No hay talonarios pendientes de devolución', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por bombero, compañía o Nº talonario...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Todos', 'Bomberos', 'Externos'].map((filtro) {
              final isSelected = _filtroChip == filtro;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(filtro),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    _filtroChip = filtro;
                    _onTalonarioSelected(null);
                  }),
                  selectedColor: AppTheme.institutionalRed.withOpacity(0.15),
                  checkmarkColor: AppTheme.institutionalRed,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.institutionalRed : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${_talonariosFiltrados.length} talonarios encontrados',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildTalonariosList() {
    final lista = _talonariosFiltrados;
    if (lista.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('No hay resultados para esta búsqueda', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: lista.map((t) => _buildTalonarioTile(t)).toList(),
    );
  }

  Widget _buildTalonarioTile(RifaTalonarioModel t) {
    final isSelected = _selectedTalonario?.id == t.id;
    final fechaStr = t.fechaEntrega != null ? _formatDate(t.fechaEntrega!) : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? AppTheme.institutionalRed : Colors.grey.shade300, width: isSelected ? 2 : 1),
      ),
      color: isSelected ? AppTheme.institutionalRed.withOpacity(0.05) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onTalonarioSelected(t),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Radio<String>(
                value: t.id,
                groupValue: _selectedTalonario?.id,
                onChanged: (_) => _onTalonarioSelected(t),
                activeColor: AppTheme.institutionalRed,
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 18,
                backgroundColor: t.esExterno ? Colors.blue.shade100 : AppTheme.institutionalRed.withOpacity(0.1),
                child: Icon(
                  t.esExterno ? Icons.business : Icons.person,
                  size: 18,
                  color: t.esExterno ? Colors.blue.shade700 : AppTheme.institutionalRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Talonario #${t.numeroTalonario}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(t.rangoDisplay, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.nombreAsignado ?? 'Desconocido',
                            style: TextStyle(fontSize: 13, color: t.esExterno ? Colors.blue.shade700 : Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (t.esExterno && t.entidadDescuento != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text('Dcto ${t.entidadDescuento}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Entregado: $fechaStr', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final esExterno = _selectedTalonario!.esExterno;
    final descuentoPct = _selectedTalonario!.entidadDescuento ?? 0;
    final montoEntregadoStr = _montoController.text.trim();
    final montoEntregado = int.tryParse(montoEntregadoStr) ?? 0;
    final montoReferencia = esExterno ? _montoConDescuento : _montoEsperado;
    final diferencia = montoReferencia - montoEntregado;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar Devolución - Talonario #${_selectedTalonario!.numeroTalonario}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (esExterno) ...[
              const SizedBox(height: 4),
              Text(
                'Compañía: ${_selectedTalonario!.entidadNombre} — Descuento ${descuentoPct}%',
                style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
              ),
            ],
            const Divider(height: 24),

            // Números vendidos + panel montos
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numerosController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Números Vendidos',
                      hintText: 'Max ${_rifaActiva!.numerosPorTalonario}',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: esExterno ? Colors.blue.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: esExterno ? Colors.blue.shade200 : Colors.grey.shade300),
                    ),
                    child: esExterno
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bruto:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              Text(_formatCurrency(_montoEsperado), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Dcto $descuentoPct%:', style: TextStyle(fontSize: 11, color: Colors.red.shade600)),
                              Text('-${_formatCurrency(_montoEsperado - _montoConDescuento)}', style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.w500)),
                              const Divider(height: 10),
                              const Text('A cobrar:', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                              Text(_formatCurrency(_montoConDescuento), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monto Esperado:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(_formatCurrency(_montoEsperado), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Monto entregado
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto Dinero Entregado',
                hintText: _formatCurrency(montoReferencia),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.attach_money),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'Completar automáticamente',
                  onPressed: _rellenarMonto,
                ),
              ),
            ),

            // Diferencia
            if (montoEntregadoStr.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (diferencia != 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: diferencia > 0 ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(diferencia > 0 ? Icons.warning_amber_rounded : Icons.info_outline,
                          color: diferencia > 0 ? Colors.red : Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        diferencia > 0
                            ? 'Falta rendir: ${_formatCurrency(diferencia)}'
                            : 'Monto excedente: ${_formatCurrency(diferencia.abs())}',
                        style: TextStyle(
                          color: diferencia > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text('Montos cuadran exactamente', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),

            // Notas
            TextField(
              controller: _notasController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notas (Opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitDevolucion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.institutionalRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Guardando...' : 'Registrar Devolución',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
