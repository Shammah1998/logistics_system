-- Migration: Add PIN support for drivers
-- Date: 02/12/2025
-- Description: Add full_name to users table and create driver_credentials table for PIN-based auth

-- Add full_name column to users table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'full_name') THEN
        ALTER TABLE users ADD COLUMN full_name TEXT;
    END IF;
END $$;

-- Create driver_credentials table for PIN-based authentication
-- This allows drivers to log in with phone + PIN instead of email + password
CREATE TABLE IF NOT EXISTS driver_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL UNIQUE REFERENCES drivers(id) ON DELETE CASCADE,
    phone TEXT NOT NULL UNIQUE,
    pin_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for phone lookups
CREATE INDEX IF NOT EXISTS idx_driver_credentials_phone ON driver_credentials(phone);

-- Enable RLS on driver_credentials
ALTER TABLE driver_credentials ENABLE ROW LEVEL SECURITY;

-- RLS Policies for driver_credentials
-- Only admins can view/insert/update driver credentials
CREATE POLICY "Admins can view driver credentials"
    ON driver_credentials FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

CREATE POLICY "Admins can insert driver credentials"
    ON driver_credentials FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

CREATE POLICY "Admins can update driver credentials"
    ON driver_credentials FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

CREATE POLICY "Admins can delete driver credentials"
    ON driver_credentials FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_driver_credentials_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS trigger_update_driver_credentials_updated_at ON driver_credentials;
CREATE TRIGGER trigger_update_driver_credentials_updated_at
    BEFORE UPDATE ON driver_credentials
    FOR EACH ROW
    EXECUTE FUNCTION update_driver_credentials_updated_at();

