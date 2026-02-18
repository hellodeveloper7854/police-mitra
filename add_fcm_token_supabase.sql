-- Add FCM token column to registrations table in Supabase
-- Run this in your Supabase SQL Editor

-- Add the column
ALTER TABLE registrations
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add index for faster lookups by FCM token
CREATE INDEX IF NOT EXISTS idx_registrations_fcm_token ON registrations(fcm_token);

-- Add comment
COMMENT ON COLUMN registrations.fcm_token IS 'Firebase Cloud Messaging token for sending push notifications to the user (synced from PostgreSQL backend)';

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'registrations'
AND column_name = 'fcm_token';
