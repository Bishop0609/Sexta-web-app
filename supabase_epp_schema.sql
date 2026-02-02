-- Script para crear las tablas de gestión de EPP (Equipo de Protección Personal)
-- Ejecutar este script en Supabase SQL Editor

-- =====================================================
-- TABLA: epp_assignments (Asignaciones de EPP)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.epp_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  epp_type TEXT NOT NULL,
  internal_code TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  color TEXT,
  condition TEXT NOT NULL,
  reception_date DATE NOT NULL,
  observations TEXT,
  is_returned BOOLEAN DEFAULT FALSE,
  created_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_epp_assignments_user_id ON public.epp_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_epp_assignments_is_returned ON public.epp_assignments(is_returned);
CREATE INDEX IF NOT EXISTS idx_epp_assignments_epp_type ON public.epp_assignments(epp_type);

-- =====================================================
-- TABLA: epp_returns (Devoluciones de EPP)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.epp_returns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES public.epp_assignments(id) ON DELETE CASCADE,
  return_date DATE NOT NULL,
  return_reason TEXT NOT NULL,
  returned_condition TEXT,
  returned_by UUID NOT NULL REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_epp_returns_assignment_id ON public.epp_returns(assignment_id);
CREATE INDEX IF NOT EXISTS idx_epp_returns_return_date ON public.epp_returns(return_date);

-- =====================================================
-- Deshabilitar RLS (SIN RESTRICCIONES - UNRESTRICTED)
-- =====================================================

-- Deshabilitar RLS en ambas tablas para acceso sin restricciones
ALTER TABLE public.epp_assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.epp_returns DISABLE ROW LEVEL SECURITY;

-- Eliminar todas las políticas existentes si las hay
DROP POLICY IF EXISTS "EPP assignments are viewable by all authenticated users" ON public.epp_assignments;
DROP POLICY IF EXISTS "EPP assignments can be created by admin" ON public.epp_assignments;
DROP POLICY IF EXISTS "EPP assignments can be updated by admin" ON public.epp_assignments;
DROP POLICY IF EXISTS "EPP assignments can be deleted by admin" ON public.epp_assignments;
DROP POLICY IF EXISTS "EPP returns are viewable by all authenticated users" ON public.epp_returns;
DROP POLICY IF EXISTS "EPP returns can be created by admin" ON public.epp_returns;

-- =====================================================
-- Trigger para actualizar updated_at automáticamente
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_epp_assignments_updated_at ON public.epp_assignments;
CREATE TRIGGER update_epp_assignments_updated_at
BEFORE UPDATE ON public.epp_assignments
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Comentarios para documentación
-- =====================================================
COMMENT ON TABLE public.epp_assignments IS 'Registro de asignaciones de Equipo de Protección Personal a bomberos';
COMMENT ON TABLE public.epp_returns IS 'Registro de devoluciones de EPP';

COMMENT ON COLUMN public.epp_assignments.epp_type IS 'Tipo de EPP: casco, uniformeEstructural, uniformeMultirrol, uniformeParada, guantesEstructurales, guantesRescate, botas, linterna, capucha, arnes, cuerda, mosqueton, otro';
COMMENT ON COLUMN public.epp_assignments.condition IS 'Estado del EPP: nuevo, bueno, regular, malo';
COMMENT ON COLUMN public.epp_assignments.is_returned IS 'Indica si el EPP ha sido devuelto';

-- =====================================================
-- Verificación
-- =====================================================
SELECT 'Tablas de EPP creadas exitosamente (SIN RESTRICCIONES RLS)' AS status;
