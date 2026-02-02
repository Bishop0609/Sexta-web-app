-- Drop the existing constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Add the new constraint including 'oficial6'
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN (
    'admin', 
    'officer', 
    'firefighter', 
    'oficial1', 
    'oficial2', 
    'oficial3', 
    'oficial4', 
    'oficial5', 
    'oficial6', 
    'bombero'
));
