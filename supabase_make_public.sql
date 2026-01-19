-- ============================================
-- HACER TODAS LAS TABLAS PÚBLICAS PARA TESTING
-- Esto permite leer/escribir sin restricciones durante desarrollo
-- ============================================

-- PASO 1: Deshabilitar RLS en TODAS las tablas
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE auth_credentials DISABLE ROW LEVEL SECURITY;
ALTER TABLE act_types DISABLE ROW LEVEL SECURITY;
ALTER TABLE permissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_events DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_configurations DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_registrations DISABLE ROW LEVEL SECURITY;
ALTER TABLE shift_attendance DISABLE ROW LEVEL SECURITY;

-- PASO 2: Verificar que RLS está deshabilitada
SELECT 
  schemaname,
  tablename,
  rowsecurity as "RLS Habilitada"
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN (
    'users',
    'auth_credentials',
    'act_types', 
    'permissions', 
    'attendance_events',
    'attendance_records',
    'shift_configurations',
    'shift_registrations',
    'shift_attendance'
  )
ORDER BY tablename;

-- PASO 3: Verificar tipos de actos
SELECT 
  COUNT(*) as "Total Act Types",
  COUNT(CASE WHEN is_active = true THEN 1 END) as "Activos"
FROM act_types;

-- PASO 4: Mostrar tipos de actos activos
SELECT 
  name as "Nombre",
  category as "Categoría"
FROM act_types
WHERE is_active = true
ORDER BY category, name;

SELECT '✅ Todas las tablas ahora son públicas (SIN RLS)' as resultado;
SELECT '⚠️ IMPORTANTE: Esto es solo para TESTING. Habilitar RLS en producción.' as advertencia;
