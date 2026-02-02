-- Script para agregar fechas de estudiante a la tabla users
-- Esto permite controlar períodos específicos en los que un usuario es estudiante

-- Agregar columnas de fecha de estudiante
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS student_start_date DATE,
ADD COLUMN IF NOT EXISTS student_end_date DATE;

-- Comentarios descriptivos
COMMENT ON COLUMN users.student_start_date IS 
'Fecha de inicio del período como estudiante. Si está vacío, el usuario nunca ha sido estudiante.';

COMMENT ON COLUMN users.student_end_date IS 
'Fecha de fin del período como estudiante (opcional). Si está vacío pero student_start_date tiene valor, el usuario es estudiante actualmente.';

-- Migración de datos existentes:
-- Los usuarios que actualmente tienen is_student = true, les asignamos fecha de inicio
UPDATE users
SET student_start_date = payment_start_date
WHERE is_student = true 
  AND student_start_date IS NULL
  AND payment_start_date IS NOT NULL;

-- Mostrar usuarios actualizados
SELECT 
  id,
  full_name,
  rank,
  is_student,
  student_start_date,
  student_end_date,
  payment_start_date
FROM users
WHERE is_student = true
ORDER BY rank;
