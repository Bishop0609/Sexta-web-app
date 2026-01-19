import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sexta_app/core/constants/app_constants.dart';
import 'package:sexta_app/core/theme/app_theme.dart';
import 'package:sexta_app/services/auth_service.dart';
import 'package:sexta_app/screens/auth/change_password_screen.dart';

// Screens
import 'package:sexta_app/screens/auth/login_screen.dart';
import 'package:sexta_app/screens/dashboard/dashboard_screen.dart';
import 'package:sexta_app/screens/profile/profile_screen.dart';
import 'package:sexta_app/screens/permissions/request_permission_screen.dart';
import 'package:sexta_app/screens/permissions/manage_permissions_screen.dart';
import 'package:sexta_app/screens/attendance/take_attendance_screen.dart';
import 'package:sexta_app/screens/attendance/modify_attendance_screen.dart';
import 'package:sexta_app/screens/shifts/shift_config_screen.dart';
import 'package:sexta_app/screens/shifts/shift_registration_screen.dart';
import 'package:sexta_app/screens/shifts/generate_schedule_screen.dart';
import 'package:sexta_app/screens/shifts/shift_attendance_screen.dart';
import 'package:sexta_app/screens/users/user_management_screen.dart';
import 'package:sexta_app/screens/settings/act_types_screen.dart';
import 'package:sexta_app/screens/activities/manage_activities_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase con ANON KEY (correcto para producción)
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey, // ✅ Usando anon key
  );
  
  // Inicializar servicio de autenticación completo y restaurar sesión
  await AuthService().initialize();
  
  runApp(const ProviderScope(child: SextaApp()));
}

class SextaApp extends StatelessWidget {
  const SextaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sistema Sexta Compañía',
      theme: AppTheme.theme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final _authService = AuthService();

// Router simplificado SIN redirect async
final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/request-permission',
      builder: (context, state) => const RequestPermissionScreen(),
    ),
    GoRoute(
      path: '/manage-permissions',
      builder: (context, state) => const ManagePermissionsScreen(),
    ),
    GoRoute(
      path: '/take-attendance',
      builder: (context, state) => const TakeAttendanceScreen(),
    ),
    GoRoute(
      path: '/modify-attendance',
      builder: (context, state) => const ModifyAttendanceScreen(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),    
    GoRoute(
      path: '/shift-config',
      builder: (context, state) => const ShiftConfigScreen(),
    ),
    GoRoute(
      path: '/shift-registration',
      builder: (context, state) => const ShiftRegistrationScreen(),
    ),
    GoRoute(
      path: '/generate-schedule',
      builder: (context, state) => const GenerateScheduleScreen(),
    ),
    GoRoute(
      path: '/shift-attendance',
      builder: (context, state) => const ShiftAttendanceScreen(),
    ),
    GoRoute(
      path: '/user-management',
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: '/act-types',
      builder: (context, state) => const ActTypesScreen(),
    ),
    GoRoute(
      path: '/manage-activities',
      builder: (context, state) => const ManageActivitiesScreen(),
    ),
  ],
);
