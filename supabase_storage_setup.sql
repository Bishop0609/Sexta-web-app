-- Configuración de Storage para Adjuntos de Permisos
-- 1. Crear el bucket si no existe (esto suele hacerse desde la UI de Supabase, pero incluimos el insert por si acaso)
INSERT INTO storage.buckets (id, name, public)
VALUES ('permission-attachments', 'permission-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- 2. Políticas de Seguridad (RLS) para el bucket permission-attachments
-- NOTA: Se usan políticas PUBLIC porque la app usa un sistema de auth personalizado
-- y no se autentica contra Supabase Auth, por lo que el cliente es siempre 'anon'.

-- Política: Permitir subir archivos (público/anon)
-- Primero borramos para evitar conflictos si se re-ejecuta
DROP POLICY IF EXISTS "Permitir subida publica" ON storage.objects;
DROP POLICY IF EXISTS "Permitir lectura publica" ON storage.objects;
DROP POLICY IF EXISTS "Permitir borrado publico" ON storage.objects;

-- También borramos las políticas antiguas por si acaso
DROP POLICY IF EXISTS "Usuarios pueden subir adjuntos" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios ven sus propios adjuntos" ON storage.objects;
DROP POLICY IF EXISTS "Oficiales ven todos los adjuntos" ON storage.objects;
DROP POLICY IF EXISTS "Admin puede borrar adjuntos" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios borran sus propios adjuntos" ON storage.objects;

CREATE POLICY "Permitir subida publica"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'permission-attachments');

-- Política: Permitir ver archivos (público/anon)
CREATE POLICY "Permitir lectura publica"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'permission-attachments');

-- Política: Permitir borrar archivos (público/anon)
CREATE POLICY "Permitir borrado publico"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'permission-attachments');
