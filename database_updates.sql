-- Add account_active column to profiles table
ALTER TABLE profiles 
ADD COLUMN account_active BOOLEAN DEFAULT true;

-- Add comment to explain the column
COMMENT ON COLUMN profiles.account_active IS 'Indicates whether the user account is active (true) or deactivated (false)';

-- Update existing records to be active by default
UPDATE profiles SET account_active = true WHERE account_active IS NULL;
