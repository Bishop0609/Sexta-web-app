import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/permissions/role_permissions.dart';
import '../../models/user_model.dart';
import '../../services/treasury_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import 'payment_registration_tab.dart';
import 'reports_tab.dart';
import 'treasury_user_config_tab.dart';
import '../../widgets/branded_app_bar.dart';
import '../../widgets/app_drawer.dart';

/// Pantalla principal de Tesorería
class TreasuryManagementScreen extends ConsumerStatefulWidget {
  const TreasuryManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TreasuryManagementScreen> createState() => _TreasuryManagementScreenState();
}

class _TreasuryManagementScreenState extends ConsumerState<TreasuryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TreasuryService _treasuryService = TreasuryService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    // Verificar permisos
    if (currentUser == null || !RolePermissions.canAccessTreasury(currentUser.role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tesorería')),
        body: const Center(
          child: Text('No tienes permisos para acceder a este módulo'),
        ),
      );
    }

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Tesorería'),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppTheme.institutionalRed,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(
                  icon: Icon(Icons.payment),
                  text: 'Registro de Pagos',
                ),
                Tab(
                  icon: Icon(Icons.settings),
                  text: 'Configuración',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'Config. Usuarios',
                ),
                Tab(
                  icon: Icon(Icons.assessment),
                  text: 'Reportes',
                ),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PaymentRegistrationTab(treasuryService: _treasuryService),
                _QuotaConfigTab(treasuryService: _treasuryService),
                const TreasuryUserConfigTab(),
                const ReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

/// Tab de configuración de cuotas
class _QuotaConfigTab extends StatefulWidget {
  final TreasuryService treasuryService;

  const _QuotaConfigTab({required this.treasuryService});

  @override
  State<_QuotaConfigTab> createState() => _QuotaConfigTabState();
}

class _QuotaConfigTabState extends State<_QuotaConfigTab> {
  final _formKey = GlobalKey<FormState>();
  final _standardQuotaController = TextEditingController();
  final _reducedQuotaController = TextEditingController();
  
  int _selectedYear = DateTime.now().year;
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _quotaHistory = [];

  @override
  void initState() {
    super.initState();
    _loadQuotaConfig();
  }

  @override
  void dispose() {
    _standardQuotaController.dispose();
    _reducedQuotaController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotaConfig() async {
    setState(() => _isLoading = true);

    try {
      // Cargar configuración del año seleccionado
      final config = await widget.treasuryService.getQuotaConfig(_selectedYear);
      if (config != null) {
        _standardQuotaController.text = config.standardQuota.toString();
        _reducedQuotaController.text = config.reducedQuota.toString();
      } else {
        // Valores por defecto
        _standardQuotaController.text = '5000';
        _reducedQuotaController.text = '2500';
      }

      // Cargar histórico
      final allConfigs = await widget.treasuryService.getAllQuotaConfigs();
      _quotaHistory = allConfigs.map((c) => {
        'year': c.year,
        'standard': c.standardQuota,
        'reduced': c.reducedQuota,
      }).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando configuración: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final standardQuota = int.parse(_standardQuotaController.text);
      final reducedQuota = int.parse(_reducedQuotaController.text);

      final result = await widget.treasuryService.upsertQuotaConfig(
        year: _selectedYear,
        standardQuota: standardQuota,
        reducedQuota: reducedQuota,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadQuotaConfig(); // Recargar
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando configuración: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de año
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración de Cuotas',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Año:', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 16),
                        DropdownButton<int>(
                          value: _selectedYear,
                          items: List.generate(6, (index) {
                            final year = DateTime.now().year - 1 + index;
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedYear = value);
                              _loadQuotaConfig();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Cuota bomberos
                    TextFormField(
                      controller: _standardQuotaController,
                      decoration: const InputDecoration(
                        labelText: 'Cuota Bomberos (mensual)',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                        helperText: 'Cuota para bomberos normales',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Cuota reducida
                    TextFormField(
                      controller: _reducedQuotaController,
                      decoration: const InputDecoration(
                        labelText: 'Cuota Postulantes/Estudiantes (mensual)',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                        helperText: 'Cuota para aspirantes, postulantes y estudiantes',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveConfig,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Guardando...' : 'Guardar Configuración'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Histórico
            if (_quotaHistory.isNotEmpty) ...[
              const Text(
                'Histórico de Configuraciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quotaHistory.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final config = _quotaHistory[index];
                    final isCurrent = config['year'] == _selectedYear;
                    
                    return ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: isCurrent ? AppTheme.institutionalRed : Colors.grey,
                      ),
                      title: Text(
                        'Año ${config['year']}${isCurrent ? ' (actual)' : ''}',
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'Bomberos: \$${config['standard']} | Postulantes/Estudiantes: \$${config['reduced']}',
                      ),
                      trailing: isCurrent
                          ? const Chip(
                              label: Text('Actual'),
                              backgroundColor: AppTheme.institutionalRed,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


