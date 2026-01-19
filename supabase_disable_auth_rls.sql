-- ============================================
-- DESHABILITAR RLS EN auth_credentials
-- Permite autenticación custom en producción
-- ============================================

-- Deshabilitar Row Level Security en la tabla de credenciales
ALTER TABLE auth_credentials DISABLE ROW LEVEL SECURITY;

-- Verificar el estado de RLS
SELECT 
    tablename as "Tabla",
    rowsecurity as "RLS Habilitado"
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename = 'auth_credentials';

SELECT '✅ RLS deshabilitado en auth_credentials - La app web ahora funcionará en producción' as resultado;
