-- Row Level Security policies for exercises table
-- Users can only see global exercises (created_by_user_id IS NULL) 
-- or their own custom exercises

-- First, enable RLS if not already enabled
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

-- Policy for reading exercises
-- Users can read all global exercises and their own custom exercises
CREATE POLICY "Users can view global and own exercises" ON exercises
    FOR SELECT USING (
        created_by_user_id IS NULL OR 
        created_by_user_id = auth.uid()
    );

-- Policy for inserting exercises
-- Users can insert new exercises (will be tagged with their ID)
CREATE POLICY "Users can create exercises" ON exercises
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL
    );

-- Policy for updating exercises
-- Users can only update their own custom exercises
-- Global exercises (created_by_user_id IS NULL) cannot be updated by regular users
CREATE POLICY "Users can update own exercises" ON exercises
    FOR UPDATE USING (
        created_by_user_id = auth.uid()
    );

-- Policy for deleting exercises
-- Users can only delete their own custom exercises
-- Global exercises cannot be deleted by regular users
CREATE POLICY "Users can delete own exercises" ON exercises
    FOR DELETE USING (
        created_by_user_id = auth.uid()
    );

-- Add a function to limit custom exercises per user (optional)
CREATE OR REPLACE FUNCTION check_user_exercise_limit()
RETURNS TRIGGER AS $$
DECLARE
    exercise_count INTEGER;
BEGIN
    -- Count user's custom exercises
    SELECT COUNT(*) INTO exercise_count
    FROM exercises
    WHERE created_by_user_id = NEW.created_by_user_id;
    
    -- Allow maximum 50 custom exercises per user
    IF exercise_count >= 50 THEN
        RAISE EXCEPTION 'User has reached maximum custom exercise limit (50)';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce exercise limit
CREATE TRIGGER enforce_exercise_limit
    BEFORE INSERT ON exercises
    FOR EACH ROW
    WHEN (NEW.created_by_user_id IS NOT NULL)
    EXECUTE FUNCTION check_user_exercise_limit();
