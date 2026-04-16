import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/models/user_model.dart';
import 'package:sexta_app/core/permissions/role_permissions.dart';

import 'package:sexta_app/providers/user_provider.dart';

// Provider definition removed - importing from user_provider.dart

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Update provider with current user on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _authService.currentUser;
      ref.read(currentUserProvider.notifier).state = user;
      print('🔍 AppDrawer initialized - User: ${user?.fullName}, Role: ${user?.role.name}');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current user from the provider
    final currentUser = ref.watch(currentUserProvider);
    
    final userEmail = currentUser?.email ?? 'usuario@sexta.cl';
    final userName = currentUser?.fullName ?? 'Usuario';
    final userRole = currentUser?.role ?? UserRole.bombero;
    final userRoleDisplay = currentUser?.getRoleDisplayName() ?? 'Bombero';
    
    // Debug logging
    print('🎨 AppDrawer build - User: $userName, Role: ${userRole.name}');
    print('   Role Display: $userRoleDisplay');

    return Drawer(
      child: Column(
        children: [
          // Header con info del usuario
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.institutionalRed,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.local_fire_department,
                          size: 36,
                          color: AppTheme.institutionalRed,
                        ),
                      ),
                      Text(
                        AppConstants.appVersion,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sexta Compañía',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/',
                  visible: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.business,
                  title: 'Dashboard Compañía',
                  route: '/company-dashboard',
                  visible: RolePermissions.canViewDashboardCompany(userRole),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.person,
                  title: 'Mi Perfil',
                  route: '/profile',
                  visible: true,
                ),
                const Divider(),
                
                // Permisos
                _buildMenuSection('PERMISOS'),
                _buildMenuItem(
                  context,
                  icon: Icons.request_page,
                  title: 'Solicitar Permiso',
                  route: '/request-permission',
                  visible: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.approval,
                  title: 'Gestionar Permisos',
                  route: '/manage-permissions',
                  visible: RolePermissions.canManagePermissions(userRole),
                ),
                const Divider(),
                
                // Asistencia
                _buildMenuSection('ASISTENCIA'),
                _buildMenuItem(
                  context,
                  icon: Icons.how_to_reg,
                  title: 'Tomar Asistencia',
                  route: '/take-attendance',
                  visible: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.edit_note,
                  title: 'Modificar Asistencias',
                  route: '/modify-attendance',
                  visible: RolePermissions.canModifyAttendance(userRole),
                ),
                const Divider(),
                
                // Guardias
                _buildMenuSection('GUARDIAS'),
                _buildMenuItem(
                  context,
                  icon: Icons.wb_sunny,
                  title: 'Asist. Guardia FDS',
                  route: '/guard-fds',
                  visible: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.light_mode,
                  title: 'Asist. Guardia Diurna',
                  route: '/guard-diurna',
                  visible: userRole == UserRole.admin,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.nightlight_round,
                  title: 'Asist. Guardia Nocturna',
                  route: '/guard-nocturna',
                  visible: true,
                ),
                
                // Rol de Guardia Nocturna
                _buildMenuSection('ROL DE GUARDIA'),
                _buildMenuItem(
                  context,
                  icon: Icons.date_range,
                  title: 'Períodos de Inscripción',
                  route: '/guard-registration-periods',
                  visible: userRole == UserRole.admin || userRole == UserRole.oficial1 || userRole == UserRole.oficial3,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.how_to_reg,
                  title: 'Inscribir Disponibilidad',
                  route: '/guard-availability',
                  visible: true,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Ver Mi Rol',
                  route: '/view-guard-roster',
                  visible: userRole == UserRole.admin,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.auto_awesome,
                  title: 'Generar Rol Semanal',
                  route: '/generate-guard-roster',
                  visible: RolePermissions.canGenerateShiftSchedule(userRole),
                ),
                const Divider(),
                
                // Administración
                _buildMenuSection('ADMINISTRACIÓN'),
                _buildMenuItem(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'Gestión de Guardias',
                  route: '/manage-guard-attendance',
                  visible: RolePermissions.canManageAllGuardAttendance(userRole),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  title: 'Gestión de Usuarios',
                  route: '/user-management',
                  visible: RolePermissions.canManageUsers(userRole),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.category,
                  title: 'Tipos de Acto',
                  route: '/act-types',
                  visible: RolePermissions.canManageActTypes(userRole),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.build_circle,
                  title: 'Mantenimiento',
                  route: '/maintenance',
                  visible: RolePermissions.canAccessMaintenance(userRole),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.event_note,
                  title: 'Gestionar Actividades',
                  route: '/manage-activities',
                  visible: RolePermissions.canManageActivities(userRole),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.safety_divider,
                  title: 'Gestión de EPP',
                  route: '/epp-management',
                  visible: RolePermissions.canManageEPP(userRole),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Tesorería',
                  route: '/treasury',
                  visible: RolePermissions.canAccessTreasury(userRole),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.calendar_month,
                  title: 'Feriados',
                  route: '/holidays',
                  visible: userRole == UserRole.admin || userRole == UserRole.oficial1,
                ),
                const Divider(),
                _buildMenuSection('RIFA'),
                _buildMenuItem(
                  context,
                  icon: Icons.confirmation_number,
                  title: 'Rifa 2026',
                  route: '/rifa',
                  visible: userRole == UserRole.admin || userRole == UserRole.oficial6 || userRole == UserRole.oficial2,
                ),
                const Divider(),
                _buildMenuSection('REPORTES'),
                _buildMenuItem(
                  context,
                  icon: Icons.assessment,
                  title: 'Reportes Mensuales',
                  route: '/reports',
                  visible: RolePermissions.canAccessReports(userRole),
                ),
              ],
            ),
          ),

          // Logout button
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.criticalColor),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: AppTheme.criticalColor),
              ),
              onTap: () async {
                await _authService.logout();
                // Update provider to null
                ref.read(currentUserProvider.notifier).state = null;
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();

    final currentRoute = GoRouterState.of(context).uri.toString();
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.institutionalRed : AppTheme.navyBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.institutionalRed : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.institutionalRed.withOpacity(0.1),
      onTap: () {
        context.go(route);
        Scaffold.of(context).closeDrawer();
      },
    );
  }
}
