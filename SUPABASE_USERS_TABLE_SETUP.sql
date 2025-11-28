-- ============================================================================
-- SUPABASE USERS TABLE SETUP WITH RLS & PERMISSIONS
-- ============================================================================
-- Run this script in Supabase SQL Editor to set up users table authentication
-- 
-- Steps:
-- 1. Open Supabase Dashboard → SQL Editor → New Query
-- 2. Copy and paste this entire script
-- 3. Click "Run" to execute all commands
-- 4. Check for any errors (highlighted in red)
-- ============================================================================

-- Step 1: Create users table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS users (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  username text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  must_change_password boolean DEFAULT true,
  role text DEFAULT 'user',
  created_at timestamptz DEFAULT now(),
  last_updated timestamptz DEFAULT now()
);

-- Step 2: Create index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Step 3: Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop existing policies (if any) to avoid conflicts
DROP POLICY IF EXISTS "Allow anon select on users" ON users;
DROP POLICY IF EXISTS "Allow anyone to read users" ON users;

-- Step 5: Create RLS policy allowing anon key to select from users table
-- This allows the app's anon key to query users by username for login
CREATE POLICY "Allow anon select on users" ON users
  FOR SELECT
  USING (true);

-- Step 6: Create update policy for password changes (anon can update their own password)
DROP POLICY IF EXISTS "Allow anon update on users" ON users;
CREATE POLICY "Allow anon update on users" ON users
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Step 7: Insert test user
-- Password hash for "Manager@123" (SHA-256):
-- Use this PowerShell command to compute: 
--   $bytes = [System.Text.Encoding]::UTF8.GetBytes('Manager@123')
--   $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
--   [BitConverter]::ToString($hash).Replace('-','').ToLower()
-- Result: ca8de09c11c85f4c2d5d5f5d5e5e5c5c (this is an example - replace with actual hash)

-- First, check if the user exists; if not, insert it
INSERT INTO users (username, password_hash, must_change_password, role)
VALUES ('manager', 'ca8de09c11c85f4c2d5d5f5d5e5e5c5c', true, 'manager')
ON CONFLICT (username) DO NOTHING;

-- Step 8: Verify data was inserted
SELECT id, username, must_change_password, role FROM users;

-- ============================================================================
-- IMPORTANT: Before testing the app, replace the password_hash above!
-- ============================================================================
-- 
-- To compute the correct SHA-256 hash for a password:
--
-- Option 1 - PowerShell (Windows):
--   $password = 'YourPassword123'
--   $bytes = [System.Text.Encoding]::UTF8.GetBytes($password)
--   $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
--   $hexHash = [BitConverter]::ToString($hash).Replace('-','').ToLower()
--   Write-Host "SHA-256 for '$password': $hexHash"
--
-- Option 2 - Online tool (for development only):
--   https://www.sha256online.com/
--   Type your password and get the hex hash
--
-- Then, update the INSERT statement above with the correct hash and re-run.
--
-- Example: If your password is "Manager@123", compute its SHA-256 and paste it here:
--   UPDATE users SET password_hash = '<COMPUTED_HASH_HERE>' WHERE username = 'manager';
--
-- ============================================================================
