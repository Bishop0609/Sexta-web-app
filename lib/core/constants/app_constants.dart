/// Constantes de configuración de la aplicación
class AppConstants {
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
  
  // Configuración de Resend (placeholder)
  static const String resendApiKey = String.fromEnvironment(
    'RESEND_API_KEY',
    defaultValue: 're_hg4Arbih_8RmYpopH5oXjiEKF6KMgqaPa',
  );
  static const String resendFromEmail = 'notificaciones@sexta.cl';
  
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
}
