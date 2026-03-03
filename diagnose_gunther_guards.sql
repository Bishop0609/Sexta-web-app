-- Diagnóstico de guardias para Gunther Hicks
-- Fecha actual: 2026-02-16

-- 1. Obtener ID de usuario
SELECT id, full_name, rut 
FROM users 
WHERE full_name ILIKE '%Gunther%' OR full_name ILIKE '%Hicks%';

-- 2. Verificar guardias FDS asignadas (futuras)
SELECT 
  'FDS' as tipo,
  guard_date,
  shift_period,
  CASE 
    WHEN maquinista_1_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) THEN 'Maquinista 1'
    WHEN maquinista_2_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) THEN 'Maquinista 2'
    WHEN obac_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) THEN 'OBAC'
    WHEN (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) = ANY(bombero_ids) THEN 'Bombero'
  END as posicion
FROM guard_attendance_fds
WHERE guard_date >= CURRENT_DATE
  AND (
    maquinista_1_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1)
    OR maquinista_2_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1)
    OR obac_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1)
    OR (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) = ANY(bombero_ids)
  )
ORDER BY guard_date
LIMIT 5;

-- 3. Verificar guardias Diurnas asignadas (futuras)
SELECT 
  'Diurna' as tipo,
  guard_date,
  shift_period,
  CASE 
    WHEN maquinista_1_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) THEN 'Maquinista 1'
    WHEN maquinista_2_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) THEN 'Maquinista 2'
    WHEN obac_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) THEN 'OBAC'
    WHEN (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) = ANY(bombero_ids) THEN 'Bombero'
  END as posicion
FROM guard_attendance_diurna
WHERE guard_date >= CURRENT_DATE
  AND (
    maquinista_1_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1)
    OR maquinista_2_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1)
    OR obac_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1)
    OR (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) = ANY(bombero_ids)
  )
ORDER BY guard_date
LIMIT 5;

-- 4. Verificar guardias Nocturnas asignadas (futuras, solo publicadas)
SELECT 
  'Nocturna' as tipo,
  grd.guard_date,
  grw.status as roster_status,
  CASE 
    WHEN grd.maquinista_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) THEN 'Maquinista'
    WHEN grd.obac_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) THEN 'OBAC'
    WHEN (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) = ANY(grd.bombero_ids) THEN 'Bombero'
  END as posicion
FROM guard_roster_daily grd
JOIN guard_roster_weekly grw ON grd.roster_week_id = grw.id
WHERE grd.guard_date >= CURRENT_DATE
  AND grw.status = 'published'
  AND (
    grd.maquinista_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1)
    OR grd.obac_id = (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1)
    OR (SELECT id FROM users WHERE full_name ILIKE '%Gunther%' LIMIT 1) = ANY(grd.bombero_ids)
  )
ORDER BY grd.guard_date
LIMIT 5;

-- 5. Verificar si hay roles publicados
SELECT 
  id,
  week_start_date,
  week_end_date,
  status,
  created_at
FROM guard_roster_weekly
WHERE status = 'published'
  AND week_end_date >= CURRENT_DATE
ORDER BY week_start_date
LIMIT 3;
