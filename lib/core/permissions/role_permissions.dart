import '../../models/user_model.dart';

/// Sistema de permisos basado en roles
/// 
/// Define qué puede hacer cada tipo de usuario en el sistema.
/// Basado en la matriz de permisos aprobada.
class RolePermissions {
  
  // ============================================
  // DASHBOARD Y PERFIL
  // ============================================
  
  /// Todos pueden ver su dashboard personal
  static bool canViewDashboardPersonal(UserRole role) => true;
  
  /// Dashboard de compañía: Admin, Oficial1, Oficial3
  static bool canViewDashboardCompany(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial3,
    ].contains(role);
  }

  /// Todos pueden ver su perfil
  static bool canViewProfile(UserRole role) => true;

  /// Todos pueden cambiar su contraseña
  static bool canChangePassword(UserRole role) => true;

  // ============================================
  // PERMISOS/LICENCIAS
  // ============================================
  
  /// Todos pueden solicitar permisos
  static bool canRequestPermission(UserRole role) => true;
  
  /// Gestionar permisos: Admin, Oficial1
  static bool canManagePermissions(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
    ].contains(role);
  }

  // ============================================
  // ASISTENCIA
  // ============================================
  
  /// Todos pueden tomar asistencia
  static bool canTakeAttendance(UserRole role) => true;
  
  /// Modificar asistencias: Admin, Oficial1, Oficial3
  static bool canModifyAttendance(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial3,
    ].contains(role);
  }

  // ============================================
  // GUARDIAS NOCTURNAS
  // ============================================
  
  /// Todos pueden inscribirse a guardia
  static bool canRegisterShift(UserRole role) => true;
  
  /// Todos pueden ver asistencia de guardia
  static bool canViewShiftAttendance(UserRole role) => true;
  
  /// Configurar guardia: Admin, Oficial1, Oficial3
  static bool canConfigureShift(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial3,
    ].contains(role);
  }
  
  /// Generar rol de guardia: Admin, Oficial1, Oficial3
  static bool canGenerateShiftSchedule(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial3,
    ].contains(role);
  }

  // ============================================
  // ACTIVIDADES
  // ============================================
  
  /// Ver actividades: Todos
  static bool canViewActivities(UserRole role) => true;
  
  /// Gestionar actividades: Admin, Oficial1, Oficial2, Oficial4, Oficial5, Oficial6
  static bool canManageActivities(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial2,
      UserRole.oficial4,
      UserRole.oficial5,
      UserRole.oficial6, // Tesorero también gestiona actividades
    ].contains(role);
  }

  // ============================================
  // GESTIÓN DE USUARIOS
  // ============================================
  
  /// Ver usuarios: Todos (para ver lista en diferentes funcionalidades)
  static bool canViewUsers(UserRole role) => true;
  
  /// Gestionar usuarios: Admin, Oficial1, Oficial3
  static bool canManageUsers(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial3,
    ].contains(role);
  }

  // ============================================
  // GESTIÓN DE EPP
  // ============================================
  
  /// Gestionar EPP: Admin, Oficial1
  static bool canManageEPP(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
    ].contains(role);
  }

  // ============================================
  // CONFIGURACIÓN DEL SISTEMA
  // ============================================
  
  /// Gestionar tipos de acto: Solo Admin
  static bool canManageActTypes(UserRole role) {
    return role == UserRole.admin;
  }

  // ============================================
  // TESORERÍA
  // ============================================
  
  /// Acceder al módulo de tesorería: Admin, Oficial6
  static bool canAccessTreasury(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial6,
    ].contains(role);
  }
  
  /// Registrar pagos de cuotas: Admin, Oficial6
  static bool canRegisterPayments(UserRole role) {
    return canAccessTreasury(role);
  }
  
  /// Generar reportes de tesorería: Admin, Oficial6
  static bool canGenerateTreasuryReports(UserRole role) {
    return canAccessTreasury(role);
  }

  // ============================================
  // HELPERS
  // ============================================
  
  /// Verifica si el usuario es administrador
  static bool isAdmin(UserRole role) => role == UserRole.admin;
  
  /// Verifica si el usuario es oficial (cualquier tipo)
  static bool isOficial(UserRole role) {
    return [
      UserRole.oficial1,
      UserRole.oficial2,
      UserRole.oficial3,
      UserRole.oficial4,
      UserRole.oficial5,
      UserRole.oficial6,
      UserRole.officer, // Backward compatibility
    ].contains(role);
  }
  
  /// Verifica si el usuario es bombero base
  static bool isBombero(UserRole role) {
    return role == UserRole.bombero || role == UserRole.firefighter;
  }
}
