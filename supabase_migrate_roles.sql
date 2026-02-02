-- ============================================
-- MIGRACIÓN DE ROLES: 3 → 7 ROLES
-- Sistema Sexta Compañía
-- ============================================
-- 
-- IMPORTANTE: Este script permite migración segura sin romper datos existentes
-- Los usuarios mantendrán acceso durante la transición
--
-- MAPEO:
--   admin → admin (sin cambios)
--   firefighter → bombero
--   officer → oficial1 (temporal, ajustar manualmente después)
-- ============================================

-- PASO 1: Verificar usuarios actuales
SELECT 
  role, 
  COUNT(*) as cantidad,
  STRING_AGG(full_name, ', ') as usuarios
FROM users
GROUP BY role
ORDER BY role;

-- PASO 2: Expandir constraint para permitir AMBOS sistemas temporalmente
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check 
  CHECK (role IN (
    -- Roles antiguos (mantener temporalmente)
    'admin', 'officer', 'firefighter',
    -- Roles nuevos
    'oficial1', 'oficial2', 'oficial3', 'oficial4', 'oficial5', 'bombero'
  ));

-- PASO 3: Migración automática de roles
-- 3.1 firefighter → bombero
UPDATE users 
SET role = 'bombero' 
WHERE role = 'firefighter';

-- 3.2 officer → oficial1 (temporal)
UPDATE users 
SET role = 'oficial1' 
WHERE role = 'officer';

-- 3.3 admin se mantiene como admin (no requiere cambio)

-- PASO 4: Verificar migración
SELECT 
  role, 
  COUNT(*) as cantidad,
  STRING_AGG(full_name, ', ' ORDER BY full_name) as usuarios
FROM users
GROUP BY role
ORDER BY role;

-- PASO 5: Mostrar usuarios que necesitan ajuste manual (officers → oficial2-5)
SELECT 
  id,
  full_name,
  rank,
  email,
  role as rol_actual,
  '--- ASIGNAR MANUALMENTE ---' as accion
FROM users
WHERE role = 'oficial1'
ORDER BY rank, full_name;

-- ============================================
-- NOTAS POST-MIGRACIÓN:
-- ============================================
-- 
-- 1. Todos los 'officer' fueron asignados a 'oficial1' temporalmente
-- 2. Usar la pantalla "Gestión de Usuarios" para reasignar cada oficial a su rol correcto:
--    - oficial1: Capitán y Jefe de compañía
--    - oficial2: Solo gestión de actividades
--    - oficial3: Ayudantes
--    - oficial4: Teniente a cargo
--    - oficial5: Solo administración
--
-- 3. Una vez verificado que todo funciona correctamente, ejecutar:
--    (OPCIONAL - solo después de confirmar que todo está OK)
--
-- ALTER TABLE users DROP CONSTRAINT users_role_check;
-- ALTER TABLE users ADD CONSTRAINT users_role_check 
--   CHECK (role IN ('admin', 'oficial1', 'oficial2', 'oficial3', 'oficial4', 'oficial5', 'bombero'));
-- 
-- ============================================
