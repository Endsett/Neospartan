-- Neospartan App Database Schema for Supabase
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User Profiles Table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  display_name TEXT,
  photo_url TEXT,
  body_compression JSONB,
  fitness_level TEXT,
  training_goal TEXT,
  training_days_per_week INTEGER,
  preferred_workout_duration INTEGER,
  injuries_or_limitations TEXT[],
  date_of_service DATE,
  has_completed_onboarding BOOLEAN DEFAULT false,
  experience_level TEXT,
  philosophical_baseline TEXT,
  date_of_birth DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout Sessions Table
CREATE TABLE IF NOT EXISTS workout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE,
  start_time TIMESTAMP WITH TIME ZONE,
  end_time TIMESTAMP WITH TIME ZONE,
  workout_type TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout Sets Table
CREATE TABLE IF NOT EXISTS workout_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id UUID REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_name TEXT,
  set_number INTEGER,
  reps_performed INTEGER,
  actual_rpe REAL,
  load_used REAL,
  completed BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI Memories Table
CREATE TABLE IF NOT EXISTS ai_memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT,
  priority TEXT,
  data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  tags TEXT[],
  summary TEXT,
  access_count INTEGER DEFAULT 0,
  last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Weekly Progress Table
CREATE TABLE IF NOT EXISTS weekly_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  week_starting DATE,
  workouts_completed INTEGER,
  total_planned_workouts INTEGER,
  average_rpe REAL,
  total_volume REAL,
  average_readiness INTEGER,
  achieved_goals BOOLEAN DEFAULT false,
  user_feedback TEXT,
  daily_readiness_scores REAL[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policies for User Profiles
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON user_profiles;
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can delete own profile" ON user_profiles FOR DELETE USING (auth.uid() = id);

-- RLS Policies for Workout Sessions
DROP POLICY IF EXISTS "Users can view own sessions" ON workout_sessions;
DROP POLICY IF EXISTS "Users can insert own sessions" ON workout_sessions;
DROP POLICY IF EXISTS "Users can update own sessions" ON workout_sessions;
DROP POLICY IF EXISTS "Users can delete own sessions" ON workout_sessions;
CREATE POLICY "Users can view own sessions" ON workout_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own sessions" ON workout_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sessions" ON workout_sessions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own sessions" ON workout_sessions FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for Workout Sets
DROP POLICY IF EXISTS "Users can view own sets" ON workout_sets;
DROP POLICY IF EXISTS "Users can insert own sets" ON workout_sets;
DROP POLICY IF EXISTS "Users can update own sets" ON workout_sets;
DROP POLICY IF EXISTS "Users can delete own sets" ON workout_sets;
CREATE POLICY "Users can view own sets" ON workout_sets FOR SELECT USING (
  auth.uid() = (SELECT user_id FROM workout_sessions WHERE id = session_id)
);
CREATE POLICY "Users can insert own sets" ON workout_sets FOR INSERT WITH CHECK (
  auth.uid() = (SELECT user_id FROM workout_sessions WHERE id = session_id)
);
CREATE POLICY "Users can update own sets" ON workout_sets FOR UPDATE USING (
  auth.uid() = (SELECT user_id FROM workout_sessions WHERE id = session_id)
);
CREATE POLICY "Users can delete own sets" ON workout_sets FOR DELETE USING (
  auth.uid() = (SELECT user_id FROM workout_sessions WHERE id = session_id)
);

-- RLS Policies for AI Memories
DROP POLICY IF EXISTS "Users can view own memories" ON ai_memories;
DROP POLICY IF EXISTS "Users can insert own memories" ON ai_memories;
DROP POLICY IF EXISTS "Users can update own memories" ON ai_memories;
DROP POLICY IF EXISTS "Users can delete own memories" ON ai_memories;
CREATE POLICY "Users can view own memories" ON ai_memories FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own memories" ON ai_memories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own memories" ON ai_memories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own memories" ON ai_memories FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for Weekly Progress
DROP POLICY IF EXISTS "Users can view own progress" ON weekly_progress;
DROP POLICY IF EXISTS "Users can insert own progress" ON weekly_progress;
DROP POLICY IF EXISTS "Users can update own progress" ON weekly_progress;
DROP POLICY IF EXISTS "Users can delete own progress" ON weekly_progress;
CREATE POLICY "Users can view own progress" ON weekly_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own progress" ON weekly_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON weekly_progress FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own progress" ON weekly_progress FOR DELETE USING (auth.uid() = user_id);

-- Create Indexes for Better Performance
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_date ON workout_sessions(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_workout_sets_session ON workout_sets(session_id);
CREATE INDEX IF NOT EXISTS idx_ai_memories_user_type ON ai_memories(user_id, type);
CREATE INDEX IF NOT EXISTS idx_ai_memories_created ON ai_memories(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_progress_user_week ON weekly_progress(user_id, week_starting DESC);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, display_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'display_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
