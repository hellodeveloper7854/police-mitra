-- Add current_availability_status column to registrations table
ALTER TABLE registrations ADD COLUMN current_availability_status VARCHAR(20) DEFAULT 'not-available';

-- Update existing records if needed
-- UPDATE registrations SET current_availability_status = 'not-available' WHERE current_availability_status IS NULL;