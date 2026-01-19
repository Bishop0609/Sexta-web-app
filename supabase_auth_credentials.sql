-- ============================================
-- AUTHENTICATION CREDENTIALS TABLE
-- Stores password hashes and security metadata
-- ============================================

-- Create auth_credentials table
CREATE TABLE IF NOT EXISTS auth_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  password_hash TEXT NOT NULL,
  requires_password_change BOOLEAN DEFAULT true,
  failed_attempts INTEGER DEFAULT 0,
  locked_until TIMESTAMPTZ,
  last_login TIMESTAMPTZ,
  password_changed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Index for faster user lookups
CREATE INDEX IF NOT EXISTS idx_auth_credentials_user ON auth_credentials(user_id);

-- Enable RLS (configure policies separately for production)
ALTER TABLE auth_credentials ENABLE ROW LEVEL SECURITY;

-- For testing: Allow all access (DISABLE THIS IN PRODUCTION)
DROP POLICY IF EXISTS "Allow all access to auth_credentials for testing" ON auth_credentials;
CREATE POLICY "Allow all access to auth_credentials for testing"
  ON auth_credentials
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Verification query
SELECT 
  'auth_credentials table created successfully' as status,
  COUNT(*) as existing_records
FROM auth_credentials;

-- Display table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'auth_credentials'
ORDER BY ordinal_position;
