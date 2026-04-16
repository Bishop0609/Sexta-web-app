import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/models/rifa_entidad_externa_model.dart';
import 'package:sexta_app/models/rifa_talonario_model.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/rifa_service.dart';

class RifaEntregarScreen extends StatefulWidget {
  final String rifaId;

  const RifaEntregarScreen({super.key, required this.rifaId});

  @override
  State<RifaEntregarScreen> createState() => _RifaEntregarScreenState();
}

class _RifaEntregarScreenState extends State<RifaEntregarScreen> {
  final _supabase = Supabase.instance.client;
  final RifaService _rifaService = RifaService();
  final AuthService _authService = AuthService();

  // Tipo de entrega
  bool _esExterna = false;

  // Estado general
  bool _isLoadingTal = true;
  bool _isLoadingOptions = true;
  bool _isSubmitting = false;

  // Talonarios
  List<RifaTalonarioModel> _talonariosDisponibles = [];
  final Set<String> _selectedTalonarioIds = {};

  // Bombero (flujo interno)
  List<Map<String, dynamic>> _bomberos = [];
  Map<String, dynamic>? _selectedBombero;

  // Entidad externa
  List<RifaEntidadExternaModel> _entidades = [];
  RifaEntidadExternaModel? _selectedEntidad;

  @override
  void initState() {
    super.initState();
    _loadTalonarios();
    _loadUsers();
    _loadEntidades();
  }

  Future<void> _loadTalonarios() async {
    setState(() => _isLoadingTal = true);
    try {
      final talonarios = await _rifaService.getTalonariosDisponibles(widget.rifaId);
      if (mounted) setState(() => _talonariosDisponibles = talonarios);
    } catch (e) {
      print('Error cargando talonarios: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTal = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _supabase.from('users').select('id, full_name, rut').eq('status', 'activo');
      if (mounted) {
        setState(() {
          _bomberos = List<Map<String, dynamic>>.from(response);
          _bomberos.sort((a, b) => (a['full_name'] as String).compareTo(b['full_name'] as String));
          _isLoadingOptions = false;
        });
      }
    } catch (_) {
      try {
        final response = await _supabase.from('users').select('id, full_name, rut').eq('status', 'activo');
        if (mounted) {
          setState(() {
            _bomberos = List<Map<String, dynamic>>.from(response);
            _bomberos.sort((a, b) => (a['full_name'] as String).compareTo(b['full_name'] as String));
            _isLoadingOptions = false;
          });
        }
      } catch (e2) {
        print('Error cargando usuarios: $e2');
        if (mounted) setState(() => _isLoadingOptions = false);
      }
    }
  }

  Future<void> _loadEntidades() async {
    try {
      final entidades = await _rifaService.getEntidadesExternas();
      if (mounted) setState(() => _entidades = entidades);
    } catch (e) {
      print('Error cargando entidades: $e');
    }
  }

  Future<void> _showCrearEntidadDialog() async {
    final nombreCtrl = TextEditingController();
    final contactoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final descuentoCtrl = TextEditingController(text: '50');
    String tipoSelected = 'compania';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva Compañía / Entidad'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tipoSelected,
                    decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'compania', child: Text('Compañía de Bomberos')),
                      DropdownMenuItem(value: 'empresa', child: Text('Empresa')),
                      DropdownMenuItem(value: 'particular', child: Text('Particular')),
                    ],
                    onChanged: (v) => setDialogState(() => tipoSelected = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contactoCtrl,
                    decoration: const InputDecoration(labelText: 'Contacto (opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono (opcional)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descuentoCtrl,
                    decoration: const InputDecoration(labelText: 'Porcentaje Descuento *', suffixText: '%', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final n = int.tryParse(v);
                      if (n == null || n < 0 || n > 100) return '0-100';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final id = await _rifaService.crearEntidadExterna(
                  nombre: nombreCtrl.text.trim(),
                  tipo: tipoSelected,
                  contacto: contactoCtrl.text.trim().isEmpty ? null : contactoCtrl.text.trim(),
                  telefono: telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                  porcentajeDescuento: int.parse(descuentoCtrl.text),
                );
                if (id != null) {
                  Navigator.pop(ctx, true);
                } else {
                  Navigator.pop(ctx, false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.institutionalRed, foregroundColor: Colors.white),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _loadEntidades();
      if (_entidades.isNotEmpty && mounted) {
        setState(() => _selectedEntidad = _entidades.last);
      }
    }
  }

  Future<void> _entregar() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    if (!_esExterna && _selectedBombero == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un bombero'), backgroundColor: Colors.red));
      return;
    }
    if (_esExterna && _selectedEntidad == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una compañía'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedTalonarioIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos un talonario'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);

    Map<String, dynamic> result;
    if (_esExterna) {
      result = await _rifaService.entregarTalonariosExterna(
        rifaId: widget.rifaId,
        talonarioIds: _selectedTalonarioIds.toList(),
        entidadId: _selectedEntidad!.id,
        entregadoPor: currentUser.id,
      );
    } else {
      result = await _rifaService.entregarTalonarios(
        rifaId: widget.rifaId,
        talonarioIds: _selectedTalonarioIds.toList(),
        bomberoId: _selectedBombero!['id'],
        entregadoPor: currentUser.id,
      );
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Talonarios entregados exitosamente'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: ${result['error']}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregar Talonarios', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.institutionalRed,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingTal || _isLoadingOptions
          ? const Center(child: CircularProgressIndicator(color: AppTheme.institutionalRed))
          : Column(
              children: [
                _buildTipoSelector(),
                const Divider(height: 1),
                Expanded(
                  child: Column(
                    children: [
                      _esExterna ? _buildEntidadSelector() : _buildBomberoSelector(),
                      const Divider(),
                      Expanded(child: _buildTalonariosList()),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildTipoSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, icon: Icon(Icons.person), label: Text('Bombero')),
          ButtonSegment(value: true, icon: Icon(Icons.business), label: Text('Compañía Externa')),
        ],
        selected: {_esExterna},
        onSelectionChanged: (selection) {
          setState(() {
            _esExterna = selection.first;
            _selectedBombero = null;
            _selectedEntidad = null;
            _selectedTalonarioIds.clear();
          });
        },
        style: ButtonStyle(
          iconColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Colors.white : AppTheme.institutionalRed),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Colors.white : AppTheme.institutionalRed),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppTheme.institutionalRed : Colors.white),
        ),
      ),
    );
  }

  Widget _buildBomberoSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. Seleccionar Bombero', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Autocomplete<Map<String, dynamic>>(
            optionsBuilder: (TextEditingValue val) {
              if (val.text.isEmpty) return const Iterable.empty();
              final q = val.text.toLowerCase();
              return _bomberos.where((b) => (b['full_name'] as String).toLowerCase().contains(q));
            },
            displayStringForOption: (o) => o['full_name'] as String,
            onSelected: (option) => setState(() => _selectedBombero = option),
            fieldViewBuilder: (ctx, ctrl, focusNode, onComplete) => TextField(
              controller: ctrl,
              focusNode: focusNode,
              onEditingComplete: onComplete,
              decoration: InputDecoration(
                labelText: 'Buscar bombero por nombre',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _selectedBombero != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ctrl.clear();
                          setState(() => _selectedBombero = null);
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_selectedBombero != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Asignar a: ${_selectedBombero!['full_name']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntidadSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. Seleccionar Compañía', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: _showCrearEntidadDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.institutionalRed),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _entidades.isEmpty
              ? const Text('No hay compañías registradas. Crea una nueva.', style: TextStyle(color: Colors.grey))
              : DropdownButtonFormField<RifaEntidadExternaModel>(
                  value: _selectedEntidad,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar entidad',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.business),
                  ),
                  items: _entidades.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.nombre, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedEntidad = v),
                ),

        ],
      ),
    );
  }

  Widget _buildTalonariosList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. Seleccionar Talonarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedTalonarioIds.length == _talonariosDisponibles.length) {
                      _selectedTalonarioIds.clear();
                    } else {
                      _selectedTalonarioIds.addAll(_talonariosDisponibles.map((t) => t.id));
                    }
                  });
                },
                child: Text(
                  _selectedTalonarioIds.length == _talonariosDisponibles.length ? 'Desmarcar todos' : 'Marcar todos',
                  style: const TextStyle(color: AppTheme.institutionalRed),
                ),
              ),
            ],
          ),
          if (_talonariosDisponibles.isEmpty)
            const Expanded(child: Center(child: Text('No hay talonarios disponibles', style: TextStyle(color: Colors.grey))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _talonariosDisponibles.length,
                itemBuilder: (context, index) {
                  final talonario = _talonariosDisponibles[index];
                  final isSelected = _selectedTalonarioIds.contains(talonario.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? AppTheme.institutionalRed : Colors.transparent, width: isSelected ? 2 : 0),
                    ),
                    color: isSelected ? AppTheme.institutionalRed.withOpacity(0.05) : null,
                    child: CheckboxListTile(
                      activeColor: AppTheme.institutionalRed,
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTalonarioIds.add(talonario.id);
                          } else {
                            _selectedTalonarioIds.remove(talonario.id);
                          }
                        });
                      },
                      secondary: CircleAvatar(
                        backgroundColor: AppTheme.navyBlue.withOpacity(0.1),
                        child: Text('${talonario.numeroTalonario}', style: const TextStyle(color: AppTheme.navyBlue, fontWeight: FontWeight.bold)),
                      ),
                      title: Text('Talonario #${talonario.numeroTalonario}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Números: ${talonario.rangoDisplay}'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final String? nombreSeleccionado = _esExterna
        ? (_selectedEntidad != null ? '${_selectedEntidad!.nombre} (descuento ${_selectedEntidad!.porcentajeDescuento}%)' : '...')
        : (_selectedBombero?['full_name'] ?? '...');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 8)],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_esExterna ? Icons.business : Icons.person, color: AppTheme.navyBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entregar ${_selectedTalonarioIds.length} talonarios a $nombreSeleccionado',
                    style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.navyBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting || _selectedTalonarioIds.isEmpty || (_esExterna ? _selectedEntidad == null : _selectedBombero == null)
                    ? null
                    : _entregar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.institutionalRed,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Procesando...' : 'Entregar ${_selectedTalonarioIds.length} talonarios',
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
