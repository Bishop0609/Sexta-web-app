import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/rifa_model.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/rifa_service.dart';

class RifaConfigScreen extends StatefulWidget {
  const RifaConfigScreen({super.key});

  @override
  State<RifaConfigScreen> createState() => _RifaConfigScreenState();
}

class _RifaConfigScreenState extends State<RifaConfigScreen> {
  final RifaService _rifaService = RifaService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  RifaModel? _rifaActiva;

  // Controladores del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _anioController = TextEditingController(text: DateTime.now().year.toString());
  final TextEditingController _numerosPorTalonarioController = TextEditingController(text: '10');
  final TextEditingController _precioNumeroController = TextEditingController(text: '1000');
  final TextEditingController _totalTalonariosController = TextEditingController(text: '100');
  final TextEditingController _numeroCorrelativoInicioController = TextEditingController(text: '1');

  // Valores calculados
  int _numerosPorTalonario = 10;
  int _precioNumero = 1000;
  int _totalTalonarios = 100;
  int _numeroCorrelativoInicio = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupListeners();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _anioController.dispose();
    _numerosPorTalonarioController.dispose();
    _precioNumeroController.dispose();
    _totalTalonariosController.dispose();
    _numeroCorrelativoInicioController.dispose();
    super.dispose();
  }

  void _setupListeners() {
    void updateCalculations() {
      setState(() {
        _numerosPorTalonario = int.tryParse(_numerosPorTalonarioController.text) ?? 0;
        _precioNumero = int.tryParse(_precioNumeroController.text) ?? 0;
        _totalTalonarios = int.tryParse(_totalTalonariosController.text) ?? 0;
        _numeroCorrelativoInicio = int.tryParse(_numeroCorrelativoInicioController.text) ?? 0;
      });
    }

    _numerosPorTalonarioController.addListener(updateCalculations);
    _precioNumeroController.addListener(updateCalculations);
    _totalTalonariosController.addListener(updateCalculations);
    _numeroCorrelativoInicioController.addListener(updateCalculations);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rifa = await _rifaService.getRifaActiva();
      if (mounted) {
        setState(() {
          _rifaActiva = rifa;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar rifa: $e')));
      }
    }
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0).format(value);
  }

  Future<void> _crearRifa() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));
      return;
    }

    final nombre = _nombreController.text.trim();
    final anio = int.parse(_anioController.text);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Nueva Rifa'),
        content: Text(
          '¿Crear rifa "$nombre" con $_totalTalonarios talonarios?\n\n'
          'Esta acción generará $_totalTalonarios talonarios automáticamente (correlativos $_numeroCorrelativoInicio al ${_numeroCorrelativoInicio + (_totalTalonarios * _numerosPorTalonario) - 1}).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.institutionalRed, foregroundColor: Colors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isSaving = true);
    try {
      await _rifaService.crearRifa(
        nombre: nombre,
        anio: anio,
        numerosPorTalonario: _numerosPorTalonario,
        precioNumero: _precioNumero,
        totalTalonarios: _totalTalonarios,
        correlativoInicio: _numeroCorrelativoInicio,
        createdBy: user.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Rifa creada exitosamente'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error al crear rifa: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _cerrarRifa() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Rifa', style: TextStyle(color: Colors.red)),
        content: const Text(
          '¿Está seguro de cerrar la rifa activa?\n\n'
          'Esto detendrá las entregas y devoluciones de esta rifa, y le permitirá crear una nueva. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Cerrar Rifa'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isSaving = true);
    try {
      await _rifaService.cerrarRifa(_rifaActiva!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Rifa cerrada exitosamente'), backgroundColor: Colors.green));
        _loadData(); // Recargar estado (mostrará el formulario vacío para nueva rifa)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error al cerrar rifa: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración de Rifa'), backgroundColor: AppTheme.institutionalRed),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.institutionalRed)),
      );
    }

    final int numeroCorrelativoFin = _numeroCorrelativoInicio + (_totalTalonarios * _numerosPorTalonario) - 1;
    final int totalNumeros = _totalTalonarios * _numerosPorTalonario;
    final int precioTalonario = _numerosPorTalonario * _precioNumero;
    final int recaudacionMaxima = totalNumeros * _precioNumero;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Rifa'),
        backgroundColor: AppTheme.institutionalRed,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_rifaActiva != null) ...[
                  Card(
                    color: Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hay una rifa activa: ${_rifaActiva!.nombre} (${_rifaActiva!.anio})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Debe cerrar la rifa activa antes de poder configurar y crear una nueva.'),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _cerrarRifa,
                              icon: const Icon(Icons.lock),
                              label: const Text('Cerrar Rifa Activa'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Formulario
                Opacity(
                  opacity: _rifaActiva == null ? 1.0 : 0.5,
                  child: AbsorbPointer(
                    absorbing: _rifaActiva != null || _isSaving,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Crear Nueva Rifa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _nombreController,
                                  decoration: const InputDecoration(labelText: 'Nombre de la Rifa', border: OutlineInputBorder()),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _anioController,
                                  decoration: const InputDecoration(labelText: 'Año', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Requerido';
                                    final val = int.tryParse(v);
                                    if (val == null || val < 2024) return 'Inválido';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _numerosPorTalonarioController,
                                  decoration: const InputDecoration(labelText: 'Números x Talonario', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Requerido';
                                    final val = int.tryParse(v);
                                    if (val == null || val <= 0) return '> 0';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _precioNumeroController,
                                  decoration: const InputDecoration(labelText: 'Precio x Número', prefixText: '\$ ', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Requerido';
                                    final val = int.tryParse(v);
                                    if (val == null || val <= 0) return '> 0';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _totalTalonariosController,
                                  decoration: const InputDecoration(labelText: 'Total de Talonarios', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Requerido';
                                    final val = int.tryParse(v);
                                    if (val == null || val <= 0) return '> 0';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _numeroCorrelativoInicioController,
                                  decoration: const InputDecoration(labelText: 'Correlativo Inicio', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Requerido';
                                    final val = int.tryParse(v);
                                    if (val == null || val <= 0) return '> 0';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Vista previa calculada
                          Card(
                            elevation: 0,
                            color: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.visibility, size: 20, color: Colors.grey),
                                      SizedBox(width: 8),
                                      Text('Vista Previa de Parámetros', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ],
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Correlativos de números:'),
                                      Text(
                                        'Del $_numeroCorrelativoInicio al ${numeroCorrelativoFin > 0 ? numeroCorrelativoFin : "?"}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total de números a emitir:'),
                                      Text(
                                        '${totalNumeros > 0 ? totalNumeros : "?"}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Precio por talonario:'),
                                      Text(
                                        precioTalonario > 0 ? _formatCurrency(precioTalonario) : "?",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Recaudación Máxima Posible:'),
                                      Text(
                                        recaudacionMaxima > 0 ? _formatCurrency(recaudacionMaxima) : "?",
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _crearRifa,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.institutionalRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.save),
                              label: const Text('Crear Rifa Base y Talonarios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.institutionalRed),
                        SizedBox(height: 16),
                        Text('Procesando...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
