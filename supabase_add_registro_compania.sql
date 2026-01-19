-- Agregar campo registro_compania a la tabla users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS registro_compania VARCHAR(50);

-- Verificar la estructura actualizada
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;
