-- Script simple para desactivar RLS en activities
-- Ejecutar línea por línea en Supabase SQL Editor

-- Paso 1: Verificar estado actual de RLS
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'activities';
-- Si rowsecurity = true, entonces RLS está activado

-- Paso 2: Desactivar RLS (ejecutar siempre, incluso si ya está desactivado)
ALTER TABLE public.activities DISABLE ROW LEVEL SECURITY;

-- Paso 3: Verificar que se desactivó (debería mostrar rowsecurity = false)
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'activities';
