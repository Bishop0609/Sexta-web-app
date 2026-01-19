-- Desactivar RLS en la tabla activities para mantener consistencia
-- con el resto de las tablas del sistema

-- Eliminar todas las políticas RLS existentes
DROP POLICY IF EXISTS "Anyone can view activities" ON activities;
DROP POLICY IF EXISTS "Officers and admins can insert activities" ON activities;
DROP POLICY IF EXISTS "Officers and admins can update activities" ON activities;
DROP POLICY IF EXISTS "Officers and admins can delete activities" ON activities;

-- Desactivar RLS completamente
ALTER TABLE activities DISABLE ROW LEVEL SECURITY;
