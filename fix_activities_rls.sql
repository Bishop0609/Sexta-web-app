-- Arreglar políticas RLS para tabla activities
-- El problema es que la política INSERT requiere verificar el rol,
-- pero debemos asegurar que funcione correctamente

-- 1. Eliminar política INSERT existente
DROP POLICY IF EXISTS "Officers and admins can insert activities" ON activities;

-- 2. Crear nueva política INSERT que permite a usuarios autenticados
--    con rol 'officer' o 'admin' insertar actividades
CREATE POLICY "Officers and admins can insert activities"
ON activities
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('officer', 'admin')
  )
);

-- 3. Verificar que las demás políticas estén correctas
-- SELECT: Todos pueden ver
DROP POLICY IF EXISTS "Anyone can view activities" ON activities;
CREATE POLICY "Anyone can view activities"
ON activities
FOR SELECT
TO authenticated
USING (true);

-- UPDATE: Solo officer/admin
DROP POLICY IF EXISTS "Officers and admins can update activities" ON activities;
CREATE POLICY "Officers and admins can update activities"
ON activities
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('officer', 'admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('officer', 'admin')
  )
);

-- DELETE: Solo officer/admin
DROP POLICY IF EXISTS "Officers and admins can delete activities" ON activities;
CREATE POLICY "Officers and admins can delete activities"
ON activities
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('officer', 'admin')
  )
);
