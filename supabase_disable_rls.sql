-- ============================================
-- DESHABILITAR RLS EN TODAS LAS TABLAS
-- Para permitir acceso con autenticación personalizada
-- ============================================

-- IMPORTANTE: Esto hace que las tablas sean accesibles sin restricciones
-- para usuarios autenticados. Solo usar si tienes autenticación custom.

ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE act_types DISABLE ROW LEVEL SECURITY;
ALTER TABLE permissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_events DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_configurations DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_registrations DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE auth_credentials DISABLE ROW LEVEL SECURITY;

-- Verificar que todas las tablas tienen RLS deshabilitado
SELECT 
    tablename as "Tabla",
    rowsecurity as "RLS Habilitado"
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename IN (
        'users', 
        'act_types', 
        'permissions', 
        'attendance_events', 
        'attendance_records',
        'shift_configurations',
        'shift_registrations',
        'shift_attendance',
        'auth_credentials'
    )
ORDER BY tablename;

SELECT '✅ RLS deshabilitado en todas las tablas' as resultado;
