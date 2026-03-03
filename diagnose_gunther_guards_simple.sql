-- Diagnóstico simple de guardias para Gunther Hicks

-- 1. Ver estructura de tabla FDS
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'guard_attendance_fds'
ORDER BY ordinal_position;

-- 2. Ver estructura de tabla Diurna
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'guard_attendance_diurna'
ORDER BY ordinal_position;

-- 3. Ver estructura de tabla Nocturna
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'guard_roster_daily'
ORDER BY ordinal_position;

-- 4. Obtener ID de Gunther
SELECT id, full_name FROM users WHERE full_name ILIKE '%Gunther%';

-- 5. Ver todas las guardias FDS futuras (sin filtrar por usuario aún)
SELECT * FROM guard_attendance_fds WHERE guard_date >= CURRENT_DATE ORDER BY guard_date LIMIT 3;

-- 6. Ver todas las guardias Diurna futuras
SELECT * FROM guard_attendance_diurna WHERE guard_date >= CURRENT_DATE ORDER BY guard_date LIMIT 3;

-- 7. Ver guardias Nocturnas publicadas
SELECT grd.*, grw.status 
FROM guard_roster_daily grd
JOIN guard_roster_weekly grw ON grd.roster_week_id = grw.id
WHERE grd.guard_date >= CURRENT_DATE 
  AND grw.status = 'published'
ORDER BY grd.guard_date 
LIMIT 3;
