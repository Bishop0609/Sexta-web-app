-- Script para agregar cuota especial de postulantes estudiantes (solo 2025)
-- Postulantes que son estudiantes pagan $1,000 en 2025

-- Agregar columna para cuota de postulante estudiante
ALTER TABLE treasury_quota_config
ADD COLUMN IF NOT EXISTS postulant_student_quota INTEGER;

-- Comentario descriptivo
COMMENT ON COLUMN treasury_quota_config.postulant_student_quota IS 
'Cuota mensual especial para usuarios con cargo "Postulante" que son estudiantes. Solo aplicable para el año 2025. Si es NULL, se usa reduced_quota.';

-- Actualizar configuración del año 2025
UPDATE treasury_quota_config
SET 
  standard_quota = 4000,
  reduced_quota = 2000,
  postulant_student_quota = 1000
WHERE year = 2025;

-- Si no existe configuración para 2025, crearla
INSERT INTO treasury_quota_config (year, standard_quota, reduced_quota, postulant_student_quota)
SELECT 2025, 4000, 2000, 1000
WHERE NOT EXISTS (
  SELECT 1 FROM treasury_quota_config WHERE year = 2025
);

-- Verificar configuración
SELECT 
  year,
  standard_quota as "Cuota Estándar",
  reduced_quota as "Cuota Reducida (Aspirantes/Estudiantes)",
  postulant_student_quota as "Cuota Postulante Estudiante"
FROM treasury_quota_config
WHERE year >= 2025
ORDER BY year;

-- Nota importante:
-- La lógica de aplicación de cuotas será:
-- 1. Si año = 2025 Y cargo = 'Postulante' Y es_estudiante = true -> postulant_student_quota (1000)
-- 2. Si es_estudiante = true O cargo in ('Aspirante', 'Postulante') -> reduced_quota (2000)
-- 3. Caso contrario -> standard_quota (4000)
