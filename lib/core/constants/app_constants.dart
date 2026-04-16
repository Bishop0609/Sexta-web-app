/// Constantes de configuración de la aplicación
class AppConstants {
  // ── VERSIÓN DE LA APP ── cambiar aquí al publicar nueva versión
  static const String appVersion = 'V.01.15';

  // Configuración de Supabase (placeholder - usuario debe configurar)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://taizxujpxyutpjcworti.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhaXp4dWpweHl1dHBqY3dvcnRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc2NDY3OTAsImV4cCI6MjA4MzIyMjc5MH0.tH7J8RwSjUdGSbPgmmNW-Vof5jV6IIskll1JR0W0faA',
  );
  
  // Service Role Key - bypasses RLS for internal app
  // IMPORTANT: Keep this secure, only for internal company use
  static const String supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhaXp4dWpweHl1dHBqY3dvcnRpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzY0Njc5MCwiZXhwIjoyMDgzMjIyNzkwfQ.kpR9aMyIGNz8AbPX2A9iR47s0-MVgPGSYeetm9ZOPSY',
  );
  
  // Configuración de Brevo (anteriormente Sendinblue)
  // TODO: Reemplaza 'TU_API_KEY_AQUI' con tu API Key real de Brevo
  // Obtén tu API Key en: https://app.brevo.com/ → Settings → SMTP & API → API Keys
  static const String brevoApiKey = String.fromEnvironment(
    'BREVO_API_KEY',
    defaultValue: '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',
  );
  
  // Email verificado en Brevo para envío de notificaciones
  // Dominio sextacoquimbo.cl verificado en Brevo
  static const String brevoFromEmail = 'notificaciones@sextacoquimbo.cl';
  
  // Configuración de guardia
  static const int maxMalesPerShift = 6;
  static const int maxFemalesPerShift = 4;
  
  // Configuración de cumplimiento
  static const int shiftsPerWeekSingle = 2;
  static const int shiftsPerWeekMarried = 1;
  
  // Umbrales de asistencia (para semáforo)
  static const double lowAttendanceWarning = 0.70; // 70%
  static const double lowAttendanceCritical = 0.50; // 50%
  
  // Nombres de tablas Supabase
  static const String usersTable = 'users';
  static const String actTypesTable = 'act_types';
  static const String permissionsTable = 'permissions';
  static const String attendanceEventsTable = 'attendance_events';
  static const String attendanceRecordsTable = 'attendance_records';
  static const String shiftConfigsTable = 'shift_configurations';
  static const String shiftRegistrationsTable = 'shift_registrations';
  static const String shiftAttendanceTable = 'shift_attendance';
  static const String eppAssignmentsTable = 'epp_assignments';
  static const String eppReturnsTable = 'epp_returns';
  
  // Nombres de tablas - Guardias
  static const String guardAttendanceFdsTable = 'guard_attendance_fds';
  static const String guardAttendanceDiurnaTable = 'guard_attendance_diurna';
  static const String guardAttendanceNocturnaTable = 'guard_attendance_nocturna';
  static const String guardAttendanceNocturnaRecordsTable = 'guard_attendance_nocturna_records';
  static const String guardRosterWeeklyTable = 'guard_roster_weekly';
  static const String guardRosterDailyTable = 'guard_roster_daily';
  static const String guardAvailabilityTable = 'guard_availability';
  
  // Configuración de guardias - DIURNAS (FDS y Diurna)
  static const int maxBomberosPerDayGuard = 10; // Bomberos en guardias diurnas
  static const int maxTotalDayGuard = 13; // Total: Maq1 + Maq2 + OBAC + 10 Bomberos
  
  // Configuración de guardias - NOCTURNAS
  static const int maxTotalNightGuard = 10; // Total de camas disponibles
  static const int maxBomberosPerNightGuard = 8; // Bomberos (10 - maquinista - obac)
  static const int maxMalesPerNightGuard = 6; // Máximo hombres
  static const int maxFemalesPerNightGuard = 4; // Máximo mujeres
  
  // Ventanas de tiempo para edición de guardias
  static const int guardViewWindowHours = 2;
  static const int guardEditWindowHours = 1;
  
  // Horarios de guardia nocturna
  static const int nightGuardStartHour = 23; // 23:00
  static const int nightGuardEndHour = 8; // 08:00
}
