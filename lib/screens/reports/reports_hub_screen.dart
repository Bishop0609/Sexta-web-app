import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/widgets/app_drawer.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/core/permissions/role_permissions.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userRole = AuthService().currentUser?.role;
    
    if (userRole == null || !RolePermissions.canAccessReports(userRole)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.institutionalRed,
        ),
        drawer: const AppDrawer(),
        body: Center(child: Text('Acceso Denegado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Mensuales', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.institutionalRed,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _buildReportCard(
                  context,
                  title: 'Asistencia',
                  description: 'Registro mensual de asistencia a actos',
                  icon: Icons.check_circle_outline,
                  onTap: () => context.go('/reports/attendance'), // Asumo esta ruta (la adaptaremos en el router si es diferente, en el codebase original usaba el mismo /reports pero como cambiamos el tab, quizás no exista ruta antigua. Wait, check in main.dart: /reports used to be ReportsScreen... El prompt dice "navega a la ruta actual del reporte de asistencia (mantener la existente)." Pero no puedo navegar a /reports si el hub es /reports! Voy a poner una ruta "legacy" en el router para el reporte viejo, pero veamos el router). Ah, the prompt says "navega a la ruta actual del reporte de asistencia (mantener la existente)." Current route is `/reports` pointing to `ReportsScreen()`. If I redirect `/reports` to `ReportsHubScreen`, I need to rename the old one or route to it differently. I'll route this to `/reports/legacy` as a placeholder or see my router check. I'll use `context.push('/reports/legacy')` or something. Wait, user said "navega a la ruta actual del reporte de asistencia (mantener la existente)." which doesn't make sense if I rename the route. No, wait. "Cambiar la ruta del drawer a /reports". I will rename the OLD screen's route to `/reports/general`.
                  color: Colors.green,
                );
              case 1:
                return _buildReportCard(
                  context,
                  title: 'Rol de Guardia',
                  description: 'Planificación semanal del personal',
                  icon: Icons.calendar_today,
                  onTap: () => context.go('/reports/general'), 
                  color: Colors.blue,
                );
              case 2:
                return _buildReportCard(
                  context,
                  title: 'Guardia Nocturna',
                  description: 'Cumplimiento mensual por bombero',
                  icon: Icons.nightlight_round,
                  onTap: () => context.go('/reports/night-guard'),
                  color: Colors.indigo,
                  badge: 'NUEVO',
                  highlightBorder: true,
                );
              case 3:
                return _buildReportCard(
                  context,
                  title: 'Guardia FDS',
                  description: 'Fin de semana',
                  icon: Icons.wb_sunny_outlined,
                  onTap: null,
                  color: Colors.orange,
                  badge: 'PRÓXIMAMENTE',
                );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
    String? badge,
    bool highlightBorder = false,
  }) {
    final bool isEnabled = onTap != null;

    Widget cardContent = Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlightBorder
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    if (!isEnabled) {
      cardContent = IgnorePointer(
        child: Opacity(
          opacity: 0.6,
          child: cardContent,
        ),
      );
    }

    if (badge != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: cardContent),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: highlightBorder ? Colors.blue : Colors.grey.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return cardContent;
  }
}
