-- Add new columns to attendance_events for better event differentiation
-- subtype: stores codes like "10-0", "10-1", etc for emergencies or "Ordinaria"/"Extraordinaria" for meetings
-- location: stores the address/location of the event

ALTER TABLE attendance_events 
ADD COLUMN IF NOT EXISTS subtype VARCHAR(50),
ADD COLUMN IF NOT EXISTS location TEXT;

-- Add comments for documentation
COMMENT ON COLUMN attendance_events.subtype IS 'Emergency codes (10-0 to 10-12) or meeting types (Ordinaria/Extraordinaria)';
COMMENT ON COLUMN attendance_events.location IS 'Address or location where the event took place';
