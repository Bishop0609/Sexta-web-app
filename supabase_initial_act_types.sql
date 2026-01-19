-- ============================================
-- VERIFICAR Y AGREGAR TIPOS DE ACTOS
-- Ejecuta este script COMPLETO en Supabase SQL Editor
-- ============================================

-- PASO 1: Verificar qué hay actualmente
SELECT 
  id,
  name as "Nombre",
  category as "Categoría",
  is_active as "Activo"
FROM act_types
ORDER BY name;

-- PASO 2: Si la tabla anterior está vacía, ejecuta esto:
-- Insertar tipos de actos (usar ON CONFLICT para evitar duplicados)
INSERT INTO act_types (name, category, is_active) VALUES
  ('Emergencia', 'efectiva', true),
  ('Reunión de Compañía', 'efectiva', true),
  ('Academia de Compañía', 'efectiva', true),
  ('Academia de Cuerpo', 'abono', true),
  ('Citación de Comandancia', 'abono', true),
  ('Citación de Superintendencia', 'abono', true)
ON CONFLICT (name) DO UPDATE 
  SET 
    is_active = EXCLUDED.is_active,
    category = EXCLUDED.category;

-- PASO 3: Verificar nuevamente
SELECT 
  id,
  name as "Nombre",
  category as "Categoría",
  is_active as "Activo",
  created_at as "Fecha Creación"
FROM act_types
ORDER BY category, name;

-- PASO 4: Contar tipos activos
SELECT 
  COUNT(*) as "Total Tipos Activos",
  COUNT(CASE WHEN category = 'efectiva' THEN 1 END) as "Efectiva",
  COUNT(CASE WHEN category = 'abono' THEN 1 END) as "Abono"
FROM act_types
WHERE is_active = true;
