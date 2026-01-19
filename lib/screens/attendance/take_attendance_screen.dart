import 'package:flutter/material.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/widgets/branded_app_bar.dart';
import 'package:sexta_app/services/supabase_service.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/services/attendance_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/models/attendance_record_model.dart';
import 'package:intl/intl.dart';

/// Módulo 3: Toma de Asistencia con Auto-Crosscheck de Licencias
class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final _supabase = SupabaseService();
  final _authService = AuthService();
  final _attendanceService = AttendanceService();
  
  UserModel? _currentUser;
  DateTime _selectedDate = DateTime.now();
  String? _selectedActTypeId;
  String? _selectedSubtype;
  final TextEditingController _locationController = TextEditingController();
  List<Map<String, dynamic>> _actTypes = [];
  List<Map<String, dynamic>> _attendanceList = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadActTypes();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // Mapa de subtipos por tipo de acto
  Map<String, List<String>> get _actSubtypes => {
    'Emergencia': [
      '10-0',
      '10-1',
      '10-2',
      '10-3',
      '10-4',
      '10-5',
      '10-6',
      '10-7',
      '10-8',
      '10-9',
      '10-10',
      '10-11',
      '10-12',
    ],
    'Reunión de Compañía': [
      'Ordinaria',
      'Extraordinaria',
    ],
  };
  
  Future<void> _loadCurrentUser() async {
    try {
      final userId = _authService.currentUserId;
      if (userId != null) {
        final user = await _supabase.getUserProfile(userId);
        setState(() => _currentUser = user);
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadActTypes() async {
    try {
      final actTypes = await _supabase.getAllActTypes();
      print('✅ Act types loaded: ${actTypes.length} tipos'); // DEBUG
      print('Act types: $actTypes'); // DEBUG
      setState(() => _actTypes = actTypes);
    } catch (e) {
      print('❌ Error loading act types: $e'); // DEBUG
      _showError('Error cargando tipos de acto: $e');
    }
  }

  List<String>? _getSubtypesForActType() {
    if (_selectedActTypeId == null) return null;
    final actType = _actTypes.firstWhere((t) => t['id'] == _selectedActTypeId, orElse: () => {});
    final name = actType['name'] as String?;
    return name != null ? _actSubtypes[name] : null;
  }

  Future<void> _loadAttendanceList() async {
    if (_selectedActTypeId == null) {
      _showError('Por favor seleccione un tipo de acto');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Cargar todos los usuarios
      final users = await _supabase.getAllUsers();
      
      // 2. LÓGICA CRÍTICA: Preparar lista con auto-check de licencias
      final attendanceList = await _attendanceService.prepareAttendanceList(
        users,
        _selectedDate,
      );

      setState(() {
        _attendanceList = attendanceList;
        _isLoading = false;
      });

      // Mostrar info de usuarios con Permiso
      final licensedCount = attendanceList.where((u) => u['hasLicense'] == true).length;
      if (licensedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$licensedCount bombero(s) tienen Permiso aprobado para esta fecha'),
            backgroundColor: AppTheme.abonoColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando lista: $e');
    }
  }

  Future<void> _saveAttendance() async {
    if (_attendanceList.isEmpty) {
      _showError('Primero cargue la lista de asistencia');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Preparar registros de asistencia
      final records = _attendanceList.map((item) {
        final user = item['user'] as UserModel;
        return {
          'userId': user.id,
          'status': (item['status'] as AttendanceStatus).name,
          'isLocked': item['isLocked'] as bool,
        };
      }).toList();

      // Crear evento y registros
      await _attendanceService.createAttendanceEvent(
        actTypeId: _selectedActTypeId!,
        eventDate: _selectedDate,
        createdBy: userId,
        attendanceRecords: records,
        subtype: _selectedSubtype,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asistencia guardada exitosamente'),
            backgroundColor: AppTheme.efectivaColor,
          ),
        );

        // Limpiar formulario
        setState(() {
          _attendanceList = [];
          _selectedActTypeId = null;
        });
      }
    } catch (e) {
      _showError('Error guardando asistencia: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleAttendance(int index) {
    final item = _attendanceList[index];
    
    // No permitir editar si está bloqueado por Permiso
    if (item['isLocked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este registro está bloqueado por Permiso aprobado'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      final currentStatus = item['status'] as AttendanceStatus;
      _attendanceList[index]['status'] = currentStatus == AttendanceStatus.present
          ? AttendanceStatus.absent
          : AttendanceStatus.present;
    });
  }

  Widget _buildDateSelector() {
    // Solo admin y officer pueden seleccionar cualquier fecha
    final canSelectAnyDate = _currentUser?.role == UserRole.admin || 
                             _currentUser?.role == UserRole.officer;
    
    if (!canSelectAnyDate) {
      // Bomberos normales: solo fecha de hoy (sin selector)
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              style: const TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            Tooltip(
              message: 'Solo Admin/Oficiales pueden cambiar la fecha',
              child: Icon(Icons.lock, size: 16, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    
    // Admin/Officer: DatePicker sin restricciones
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020), // Sin límite al pasado
          lastDate: DateTime(2100),  // Sin límite al futuro
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
            _attendanceList = []; // Reset lista si cambia fecha
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.navyBlue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: AppTheme.navyBlue),
            const SizedBox(width: 12),
            Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: AppTheme.navyBlue),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.criticalColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomar Asistencia'),
        actions: [
          if (_attendanceList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveAttendance,
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuración del evento
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración del Evento',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    
                    // Fecha
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha del Evento',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              _buildDateSelector(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Tipo de Acto
                    Text(
                      'Tipo de Acto',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedActTypeId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Seleccione tipo de acto',
                      ),
                      items: _actTypes.map((actType) {
                        final category = actType['category'] as String;
                        final color = category == 'efectiva' 
                            ? AppTheme.efectivaColor 
                            : AppTheme.abonoColor;
                        
                        return DropdownMenuItem(
                          value: actType['id'] as String,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(actType['name'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedActTypeId = value;
                          _selectedSubtype = null; // Reset subtipo al cambiar tipo
                          _attendanceList = []; // Reset lista si cambia tipo
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Subtipo (condicional según tipo de acto)
                    if (_selectedActTypeId != null && _getSubtypesForActType() != null) ...[
                      Text(
                        'Subtipo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedSubtype,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Seleccione  subtipo',
                        ),
                        items: _getSubtypesForActType()!.map((subtype) {
                          return DropdownMenuItem<String>(
                            value: subtype,
                            child: Text(subtype),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSubtype = value);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Ubicación
                    Text(
                      'Ubicación / Dirección',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Av. Costanera 1234',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    
                    // Botón cargar lista
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _loadAttendanceList,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.people),
                        label: Text(_isLoading ? 'Cargando...' : 'Cargar Lista de Asistencia'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Lista de asistencia AGRUPADA POR CATEGORÍA
            if (_attendanceList.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Lista de Asistencia',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Text(
                            '${_attendanceList.where((u) => u['status'] == AttendanceStatus.present).length}/${_attendanceList.length} presentes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.efectivaColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Leyenda
                      Wrap(
                        spacing: 16,
                        children: [
                          _buildLegend(Icons.check_circle, 'Presente', AppTheme.efectivaColor),
                          _buildLegend(Icons.cancel, 'Ausente', Colors.grey),
                          _buildLegend(Icons.lock, 'Licencia (Bloqueado)', AppTheme.warningColor),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // GRUPOS POR CATEGORÍA
                      ..._buildGroupedAttendanceList(),
                      
                      const SizedBox(height: 20),
                      
                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveAttendance,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Guardando...' : 'Guardar Asistencia'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Groups attendance by rank category with proper ordering
  List<Widget> _buildGroupedAttendanceList() {
    // Define categories with EXACT rank matching patterns (priority order matters)
    // More specific patterns checked first to avoid duplicates
    final categories = {
      'OFICIALES DE COMPAÑÍA': {
        'patterns': ['Director', 'Secretari', 'Tesorer', 'Capitán', 'Teniente', 'Ayudante', 'Inspector M.'],
        'orderType': 'hierarchical',
        'hierarchy': {
          'Director': 1,
          'Secretario': 2, 'Secretaria': 2,
          'Tesorero': 3, 'Tesorera': 3,
          'Capitán': 4,
          'Teniente 1°': 5, 'Teniente 2°': 6, 'Teniente 3°': 7,
          'Ayudante 1°': 8, 'Ayudante 2°': 9,
          'Inspector M. Mayor': 10,
          'Inspector M. Menor': 11,
        },
      },
      'OFICIALES DE CUERPO': {
        'patterns': ['Of. General', 'Inspector de Comandancia', 'Ayudante de Comandancia'],
        'orderType': 'hierarchical',
        'hierarchy': {
          'Of. General': 1,
          'Inspector de Comandancia': 2,
          'Ayudante de Comandancia': 3,
        },
      },
      'MIEMBROS HONORARIOS': {
        'patterns': ['Honorario', 'Miembro Honorario'],
        'orderType': 'seniority',
      },
      'BOMBEROS ACTIVOS': {
        'patterns': ['Bombero'],
        'orderType': 'seniority',
      },
      'ASPIRANTES Y POSTULANTES': {
        'patterns': ['Aspirante', 'Postulante'],
        'orderType': 'seniority',
      },
    };

    List<Widget> groups = [];
    final assignedUsers = <String>{}; // Track assigned users to prevent duplicates

    for (var entry in categories.entries) {
      final categoryName = entry.key;
      final categoryConfig = entry.value as Map<String, dynamic>;
      final patterns = categoryConfig['patterns'] as List<String>;
      final orderType = categoryConfig['orderType'] as String;
      
      // Filter users for this category
      final usersInCategory = _attendanceList.where((item) {
        final user = item['user'] as UserModel;
        final userId = user.id;
        
        // Skip if already assigned to another category
        if (assignedUsers.contains(userId)) return false;
        
        final rankLower = user.rank.toLowerCase();
        
        // Special logic for "Bomberos Activos": must contain "Bombero" 
        // but exclude if already categorized as officer or honorary
        if (categoryName == 'BOMBEROS ACTIVOS') {
          final isHonorary = rankLower.contains('honorario');
          final isOfficer = rankLower.contains('director') || 
                           rankLower.contains('secretari') || 
                           rankLower.contains('tesorer') ||
                           rankLower.contains('capitán') || 
                           rankLower.contains('teniente') || 
                           rankLower.contains('general') ||
                           rankLower.contains('inspector');
          
          // Special case: "Ayudante" without "de Comandancia" is an officer
          final isAyudanteOfficer = rankLower.contains('ayudante') && 
                                    !rankLower.contains('de comandancia');
          
          final isVolunteer = rankLower.contains('bombero');
          
          return isVolunteer && !isHonorary && !isOfficer && !isAyudanteOfficer;
        }
        
        // For other categories, use pattern matching
        // More specific checks first to avoid "Ayudante de Comandancia" duplicate
        for (final pattern in patterns) {
          final patternLower = pattern.toLowerCase();
          
          // Exact or contains match
          if (patternLower == 'ayudante de comandancia') {
            // EXACT match for this specific rank
            if (rankLower == patternLower || rankLower.contains('ayudante de comandancia')) {
              return true;
            }
          } else if (patternLower == 'ayudante') {
            // Only match "Ayudante" if NOT "Ayudante de Comandancia"
            if (rankLower.contains('ayudante') && !rankLower.contains('de comandancia')) {
              return true;
            }
          } else {
            // Regular contains match for other patterns
            if (rankLower.contains(patternLower)) {
              return true;
            }
          }
        }
        
        return false;
      }).toList();

      if (usersInCategory.isEmpty) continue;

      // Mark users as assigned
      for (var item in usersInCategory) {
        final user = item['user'] as UserModel;
        assignedUsers.add(user.id);
      }

      // Sort users within category based on order type
      if (orderType == 'hierarchical') {
        final hierarchy = categoryConfig['hierarchy'] as Map<String, int>;
        usersInCategory.sort((a, b) {
          final userA = a['user'] as UserModel;
          final userB = b['user'] as UserModel;
          
          final priorityA = hierarchy[userA.rank] ?? 999;
          final priorityB = hierarchy[userB.rank] ?? 999;
          
          if (priorityA != priorityB) {
            return priorityA.compareTo(priorityB);
          }
          
          // If same hierarchy level, sort alphabetically
          return userA.fullName.compareTo(userB.fullName);
        });
      } else if (orderType == 'seniority') {
        usersInCategory.sort((a, b) {
          final userA = a['user'] as UserModel;
          final userB = b['user'] as UserModel;
          
          // Parse registro_compania as integer (lower = older = first)
          final regA = int.tryParse(userA.registroCompania ?? '999999') ?? 999999;
          final regB = int.tryParse(userB.registroCompania ?? '999999') ?? 999999;
          
          if (regA != regB) {
            return regA.compareTo(regB);
          }
          
          // If same seniority, sort alphabetically
          return userA.fullName.compareTo(userB.fullName);
        });
      }

      groups.add(_buildCategorySection(categoryName, usersInCategory));
      groups.add(const SizedBox(height: 16));
    }

    return groups;
  }

  /// Construye una sección de categoría
  Widget _buildCategorySection(String categoryName, List<Map<String, dynamic>> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de categoría
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Lista de usuarios en esta categoría
        ...users.asMap().entries.map((entry) {
          final globalIndex = _attendanceList.indexOf(entry.value);
          final item = entry.value;
          final user = item['user'] as UserModel;
          final status = item['status'] as AttendanceStatus;
          final isLocked = item['isLocked'] as bool;
          
          return _buildAttendanceRow(globalIndex, user, status, isLocked);
        }).toList(),
      ],
    );
  }

  /// Construye una fila de asistencia
  Widget _buildAttendanceRow(int index, UserModel user, AttendanceStatus status, bool isLocked) {
    Color statusColor;
    IconData statusIcon;
    
    if (status == AttendanceStatus.licencia) {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.lock;
    } else if (status == AttendanceStatus.present) {
      statusColor = AppTheme.efectivaColor;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.cancel;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Checkbox de asistencia
          SizedBox(
            width: 24,
            height: 24,
            child: isLocked
                ? Icon(Icons.lock, size: 18, color: AppTheme.warningColor)
                : Checkbox(
                    value: status == AttendanceStatus.present,
                    onChanged: (_) => _toggleAttendance(index),
                    activeColor: AppTheme.efectivaColor,
                  ),
          ),
          const SizedBox(width: 12),
          
          // Nombre y rango
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (user.rank.isNotEmpty)
                  Text(
                    user.rank,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          
          // Indicador de estado
          Icon(statusIcon, size: 20, color: statusColor),
        ],
      ),
    );
  }

  Widget _buildLegend(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
