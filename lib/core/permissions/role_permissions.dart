import '../../models/user_model.dart';

/// Sistema de permisos basado en roles
/// 
/// Define qué puede hacer cada tipo de usuario en el sistema.
/// Basado en la matriz de permisos aprobada (roles.pdf).
/// 
/// MATRIZ DE REFERENCIA:
/// - Todos: Dashboard, Solicitar Permiso, Mi Perfil, Tomar Asistencia,
///          Asist. Guardias (FDS/Diurna/Nocturna), Periodo Inscripción,
///          Inscribir disponibilidad, Ver mi rol
/// - Admin: TODO
/// - Oficial1: Todo excepto Mantenimiento
/// - Oficial2: Gestionar Actividades
/// - Oficial3: Dashboard Cía, Gestionar Permisos, Modificar Asistencias,
///             Gestión Guardias, Gestión Usuarios, Gestionar Actividades
/// - Oficial4: Gestionar Actividades, Gestión EPP
/// - Oficial5: Gestión EPP
/// - Oficial6: Gestionar Actividades, Tesorería
/// - Bombero: Solo permisos base
class RolePermissions {
  
  // ============================================
  // DASHBOARD Y PERFIL
  // ============================================
  
  /// Todos pueden ver su dashboard personal
  static bool canViewDashboardPersonal(UserRole role) => true;
  
  /// Dashboard de compañía: Admin, Oficial1, Oficial2, Oficial3, Oficial4
  static bool canViewDashboardCompany(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial2,
      UserRole.oficial3,
      UserRole.oficial4,
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
  
  /// Gestionar permisos: Admin, Oficial1, Oficial3
  static bool canManagePermissions(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial2,
      UserRole.oficial3,
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
  // ASISTENCIA A GUARDIAS (FDS, DIURNA, NOCTURNA)
  // ============================================
  
  /// Todos pueden ver asistencias de guardias (dentro de ventana de 2 horas)
  static bool canViewGuardAttendance(UserRole role) => true;
  
  /// Todos pueden crear asistencias de guardias
  static bool canCreateGuardAttendance(UserRole role) => true;
  
  /// Todos pueden editar sus propias asistencias (dentro de ventana de 1 hora)
  static bool canEditOwnGuardAttendance(UserRole role) => true;
  
  /// Gestionar todas las asistencias de guardias: Admin, Oficial1, Oficial3
  /// Permite ver, editar y eliminar cualquier asistencia sin restricciones de tiempo
  static bool canManageAllGuardAttendance(UserRole role) {
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
  
  /// Gestionar actividades: Admin, Oficial1, Oficial2, Oficial3, Oficial4, Oficial6
  static bool canManageActivities(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial2,
      UserRole.oficial3,
      UserRole.oficial4,
      UserRole.oficial6,
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
      UserRole.oficial2,
      UserRole.oficial3,
    ].contains(role);
  }

  /// Crear usuarios: Admin, Oficial1, Oficial2, Oficial3
  static bool canCreateUsers(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial2,
      UserRole.oficial3,
    ].contains(role);
  }

  /// Eliminar usuarios: Admin, Oficial1, Oficial2, Oficial3
  static bool canDeleteUsers(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial2,
      UserRole.oficial3,
    ].contains(role);
  }

  // ============================================
  // GESTIÓN DE EPP
  // ============================================
  
  /// Gestionar EPP: Admin, Oficial1, Oficial4, Oficial5
  static bool canManageEPP(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial4,
      UserRole.oficial5,
    ].contains(role);
  }

  // ============================================
  // CONFIGURACIÓN DEL SISTEMA
  // ============================================
  
  /// Gestionar tipos de acto: Solo Admin
  static bool canManageActTypes(UserRole role) {
    return [
      UserRole.admin,
    ].contains(role);
  }
  
  /// Mantenimiento del sistema: Solo Admin
  static bool canAccessMaintenance(UserRole role) {
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
  
  /// Registrar pagos de cuotas: Admin, Oficial1, Oficial6
  static bool canRegisterPayments(UserRole role) {
    return canAccessTreasury(role);
  }
  
  /// Generar reportes de tesorería: Admin, Oficial1, Oficial6
  static bool canGenerateTreasuryReports(UserRole role) {
    return canAccessTreasury(role);
  }

  // ============================================
  // REPORTES
  // ============================================

  /// Acceder a reportes de asistencia: Admin, Oficial1, Oficial3
  static bool canAccessReports(UserRole role) {
    return [
      UserRole.admin,
      UserRole.oficial1,
      UserRole.oficial3,
    ].contains(role);
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
