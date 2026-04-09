-- Add created_by_user_id field to exercises table
-- This allows tracking which user created custom exercises
-- NULL values indicate global/existing exercises

ALTER TABLE exercises 
ADD COLUMN created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Create index for faster queries on user-specific exercises
CREATE INDEX idx_exercises_created_by_user_id ON exercises(created_by_user_id);

-- Add comment explaining the field
COMMENT ON COLUMN exercises.created_by_user_id IS 'User ID who created this exercise. NULL for global exercises available to all users.';
