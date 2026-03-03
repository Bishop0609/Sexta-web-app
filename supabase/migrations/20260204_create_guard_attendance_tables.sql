-- Migration: Create Guard Attendance Tables
-- Description: Creates all tables needed for the guard attendance system
-- Date: 2026-02-04

-- ============================================================================
-- TABLE 1: guard_attendance_fds (Weekend and Holiday Guards)
-- ============================================================================
CREATE TABLE IF NOT EXISTS guard_attendance_fds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guard_date DATE NOT NULL,
    shift_period TEXT NOT NULL CHECK (shift_period IN ('AM', 'PM')),
    
    -- Personnel (13 total: Maq1 + Maq2 + OBAC + 10 Bomberos)
    maquinista_1_id UUID REFERENCES users(id) ON DELETE SET NULL,
    maquinista_2_id UUID REFERENCES users(id) ON DELETE SET NULL,
    obac_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_1_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_2_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_3_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_4_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_5_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_6_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_7_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_8_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_9_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_10_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    observations TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Prevent duplicate registrations for same date and period
    CONSTRAINT unique_fds_guard UNIQUE (guard_date, shift_period)
);

-- Index for faster queries
CREATE INDEX idx_guard_fds_date ON guard_attendance_fds(guard_date DESC);
CREATE INDEX idx_guard_fds_created_by ON guard_attendance_fds(created_by);

-- ============================================================================
-- TABLE 2: guard_attendance_diurna (Weekday Daytime Guards)
-- ============================================================================
CREATE TABLE IF NOT EXISTS guard_attendance_diurna (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guard_date DATE NOT NULL,
    shift_period TEXT NOT NULL CHECK (shift_period IN ('AM', 'PM')),
    
    -- Personnel (13 total: Maq1 + Maq2 + OBAC + 10 Bomberos)
    maquinista_1_id UUID REFERENCES users(id) ON DELETE SET NULL,
    maquinista_2_id UUID REFERENCES users(id) ON DELETE SET NULL,
    obac_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_1_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_2_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_3_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_4_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_5_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_6_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_7_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_8_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_9_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_10_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    observations TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Prevent duplicate registrations for same date and period
    CONSTRAINT unique_diurna_guard UNIQUE (guard_date, shift_period)
);

-- Index for faster queries
CREATE INDEX idx_guard_diurna_date ON guard_attendance_diurna(guard_date DESC);
CREATE INDEX idx_guard_diurna_created_by ON guard_attendance_diurna(created_by);

-- ============================================================================
-- TABLE 3: guard_roster_weekly (Weekly Night Guard Roster)
-- ============================================================================
CREATE TABLE IF NOT EXISTS guard_roster_weekly (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    week_start_date DATE NOT NULL, -- Monday of the week
    week_end_date DATE NOT NULL,   -- Sunday of the week
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- One roster per week
    CONSTRAINT unique_weekly_roster UNIQUE (week_start_date)
);

CREATE INDEX idx_roster_weekly_date ON guard_roster_weekly(week_start_date DESC);

-- ============================================================================
-- TABLE 4: guard_roster_daily (Daily Night Guard Assignments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS guard_roster_daily (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    roster_week_id UUID NOT NULL REFERENCES guard_roster_weekly(id) ON DELETE CASCADE,
    guard_date DATE NOT NULL,
    
    -- Personnel (max 10 total: Maquinista + OBAC + 8 Bomberos)
    -- Gender restriction: 6 males, 4 females (validated in backend)
    maquinista_id UUID REFERENCES users(id) ON DELETE SET NULL,
    obac_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_ids UUID[] DEFAULT '{}', -- Array of up to 8 bombero IDs
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- One assignment per date per roster
    CONSTRAINT unique_daily_roster UNIQUE (roster_week_id, guard_date)
);

CREATE INDEX idx_roster_daily_date ON guard_roster_daily(guard_date DESC);
CREATE INDEX idx_roster_daily_week ON guard_roster_daily(roster_week_id);

-- ============================================================================
-- TABLE 5: guard_availability (Night Guard Availability Registration)
-- ============================================================================
CREATE TABLE IF NOT EXISTS guard_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    available_date DATE NOT NULL,
    is_driver BOOLEAN NOT NULL DEFAULT false, -- Register as maquinista
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- One registration per user per date
    CONSTRAINT unique_user_availability UNIQUE (user_id, available_date)
);

CREATE INDEX idx_availability_date ON guard_availability(available_date);
CREATE INDEX idx_availability_user ON guard_availability(user_id);

-- ============================================================================
-- TABLE 6: guard_attendance_nocturna (Night Guard Attendance)
-- ============================================================================
CREATE TABLE IF NOT EXISTS guard_attendance_nocturna (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guard_date DATE NOT NULL, -- Date when guard starts (23:00)
    roster_week_id UUID REFERENCES guard_roster_weekly(id) ON DELETE SET NULL,
    
    -- Personnel (max 10 total: Maquinista + OBAC + 8 Bomberos)
    maquinista_id UUID REFERENCES users(id) ON DELETE SET NULL,
    obac_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_1_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_2_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_3_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_4_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_5_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_6_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_7_id UUID REFERENCES users(id) ON DELETE SET NULL,
    bombero_8_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    observations TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- One night guard per date
    CONSTRAINT unique_nocturna_guard UNIQUE (guard_date)
);

CREATE INDEX idx_guard_nocturna_date ON guard_attendance_nocturna(guard_date DESC);
CREATE INDEX idx_guard_nocturna_created_by ON guard_attendance_nocturna(created_by);

-- ============================================================================
-- TABLE 7: guard_attendance_nocturna_records (Individual Attendance Records)
-- ============================================================================
CREATE TABLE IF NOT EXISTS guard_attendance_nocturna_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guard_attendance_id UUID NOT NULL REFERENCES guard_attendance_nocturna(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    position TEXT NOT NULL CHECK (position IN ('maquinista', 'obac', 'bombero')),
    status TEXT NOT NULL CHECK (status IN ('presente', 'ausente', 'permiso', 'reemplazado')),
    
    -- Replacement tracking
    replaced_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
    replaces_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_nocturna_records_guard ON guard_attendance_nocturna_records(guard_attendance_id);
CREATE INDEX idx_nocturna_records_user ON guard_attendance_nocturna_records(user_id);

-- ============================================================================
-- RLS POLICIES - DISABLED FOR CONSISTENCY
-- ============================================================================
-- NOTE: RLS is currently DISABLED on all existing tables (UNRESTRICTED status).
-- To maintain consistency, RLS is also DISABLED for guard attendance tables.
-- 
-- When implementing RLS across the entire application, uncomment the following:
-- 
-- ALTER TABLE guard_attendance_fds ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE guard_attendance_diurna ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE guard_roster_weekly ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE guard_roster_daily ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE guard_availability ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE guard_attendance_nocturna ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE guard_attendance_nocturna_records ENABLE ROW LEVEL SECURITY;
--
-- And add appropriate policies (see rls_security_analysis.md for recommendations)

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_guard_fds_updated_at
    BEFORE UPDATE ON guard_attendance_fds
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guard_diurna_updated_at
    BEFORE UPDATE ON guard_attendance_diurna
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guard_nocturna_updated_at
    BEFORE UPDATE ON guard_attendance_nocturna
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roster_weekly_updated_at
    BEFORE UPDATE ON guard_roster_weekly
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roster_daily_updated_at
    BEFORE UPDATE ON guard_roster_daily
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE guard_attendance_fds IS 'Weekend and holiday guard attendance (AM/PM shifts)';
COMMENT ON TABLE guard_attendance_diurna IS 'Weekday daytime guard attendance (AM/PM shifts)';
COMMENT ON TABLE guard_attendance_nocturna IS 'Night guard attendance (23:00-08:00)';
COMMENT ON TABLE guard_attendance_nocturna_records IS 'Individual attendance records for night guards with status tracking';
COMMENT ON TABLE guard_roster_weekly IS 'Weekly night guard roster (Monday to Sunday)';
COMMENT ON TABLE guard_roster_daily IS 'Daily night guard assignments within a weekly roster';
COMMENT ON TABLE guard_availability IS 'User availability registration for night guards';

COMMENT ON COLUMN guard_attendance_fds.shift_period IS 'AM or PM shift';
COMMENT ON COLUMN guard_attendance_diurna.shift_period IS 'AM or PM shift';
COMMENT ON COLUMN guard_attendance_nocturna.guard_date IS 'Date when guard starts at 23:00';
COMMENT ON COLUMN guard_roster_daily.bombero_ids IS 'Array of up to 8 bombero UUIDs (max 10 total with maquinista and OBAC)';
COMMENT ON COLUMN guard_availability.is_driver IS 'Whether user registers as maquinista (driver)';
COMMENT ON COLUMN guard_attendance_nocturna_records.status IS 'presente, ausente, permiso, or reemplazado';
