-- ============================================
-- DESACTIVAR TIPOS NO DESEADOS Y ACTIVAR SOLO LOS 6 CORRECTOS
-- No borra nada, solo cambia is_active
-- ============================================

-- PASO 1: Desactivar TODOS los tipos de actos
UPDATE act_types SET is_active = false;

-- PASO 2: Activar SOLO los 6 tipos correctos (por nombre)
UPDATE act_types 
SET is_active = true
WHERE name IN (
  'Emergencia',
  'Reunión de Compañía',
  'Academia de Compañía',
  'Academia de Cuerpo',
  'Citación de Comandancia',
  'Citación de Superintendencia'
);

-- PASO 3: Insertar los que falten (si no existen)
INSERT INTO act_types (name, category, is_active) VALUES
  ('Emergencia', 'efectiva', true),
  ('Reunión de Compañía', 'efectiva', true),
  ('Academia de Compañía', 'efectiva', true),
  ('Academia de Cuerpo', 'abono', true),
  ('Citación de Comandancia', 'abono', true),
  ('Citación de Superintendencia', 'abono', true)
ON CONFLICT (name) DO UPDATE 
  SET is_active = true;

-- PASO 4: Verificar cuántos activos hay
SELECT 
  COUNT(*) as "Total Activos",
  COUNT(CASE WHEN category = 'efectiva' THEN 1 END) as "Efectiva",
  COUNT(CASE WHEN category = 'abono' THEN 1 END) as "Abono"
FROM act_types
WHERE is_active = true;

-- PASO 5: Mostrar solo los activos
SELECT 
  name as "Tipo de Acto",
  category as "Categoría"
FROM act_types
WHERE is_active = true
ORDER BY 
  CASE category 
    WHEN 'efectiva' THEN 1 
    WHEN 'abono' THEN 2 
  END,
  name;

SELECT '✅ Solo 6 tipos de actos están activos (los demás están desactivados, no borrados)' as resultado;
