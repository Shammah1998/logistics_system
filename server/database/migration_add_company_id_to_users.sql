-- Migration: Add company_id column to users table
-- Run this if you've already applied schema.sql without the company_id column
-- This migration adds the company_id column and foreign key constraint

-- Add company_id column to users table (without foreign key first)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS company_id UUID;

-- Add foreign key constraint (drop first if exists to avoid errors)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'fk_users_company_id'
    ) THEN
        ALTER TABLE users 
        ADD CONSTRAINT fk_users_company_id 
        FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Add index for company_id
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id);

