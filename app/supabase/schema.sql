-- Neospartan App Database Schema for Supabase
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User Profiles Table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  display_name TEXT,
  photo_url TEXT,
  body_composition JSONB,
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

-- Workout Calendar Table
CREATE TABLE IF NOT EXISTS workout_calendar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  workout_name TEXT,
  is_rest BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (user_id, date)
);

-- Analytics Events Table
CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  payload JSONB,
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
ALTER TABLE workout_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

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

-- RLS Policies for Workout Calendar
DROP POLICY IF EXISTS "Users can view own calendar" ON workout_calendar;
DROP POLICY IF EXISTS "Users can insert own calendar" ON workout_calendar;
DROP POLICY IF EXISTS "Users can update own calendar" ON workout_calendar;
DROP POLICY IF EXISTS "Users can delete own calendar" ON workout_calendar;
CREATE POLICY "Users can view own calendar" ON workout_calendar FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own calendar" ON workout_calendar FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own calendar" ON workout_calendar FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own calendar" ON workout_calendar FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for Analytics Events
DROP POLICY IF EXISTS "Users can view own analytics events" ON analytics_events;
DROP POLICY IF EXISTS "Users can insert own analytics events" ON analytics_events;
DROP POLICY IF EXISTS "Users can delete own analytics events" ON analytics_events;
CREATE POLICY "Users can view own analytics events" ON analytics_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own analytics events" ON analytics_events FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own analytics events" ON analytics_events FOR DELETE USING (auth.uid() = user_id);

-- Create Indexes for Better Performance
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_date ON workout_sessions(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_workout_sets_session ON workout_sets(session_id);
CREATE INDEX IF NOT EXISTS idx_ai_memories_user_type ON ai_memories(user_id, type);
CREATE INDEX IF NOT EXISTS idx_ai_memories_created ON ai_memories(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_progress_user_week ON weekly_progress(user_id, week_starting DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_weekly_progress_user_week_unique ON weekly_progress(user_id, week_starting);
CREATE INDEX IF NOT EXISTS idx_workout_calendar_user_date ON workout_calendar(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_created ON analytics_events(user_id, created_at DESC);

-- Session Readiness Inputs Table
CREATE TABLE IF NOT EXISTS session_readiness_inputs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  session_date DATE NOT NULL,
  readiness_score INTEGER,
  sleep_hours REAL,
  stress_level INTEGER,
  soreness_level INTEGER,
  energy_level INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (user_id, session_date)
);

-- Weekly Directives Table
CREATE TABLE IF NOT EXISTS weekly_directives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  week_starting DATE NOT NULL,
  focus TEXT,
  intensity_modifier REAL DEFAULT 1.0,
  volume_modifier REAL DEFAULT 1.0,
  special_instructions TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (user_id, week_starting)
);

-- Enable RLS on new tables
ALTER TABLE session_readiness_inputs ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_directives ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Session Readiness
DROP POLICY IF EXISTS "Users can view own readiness inputs" ON session_readiness_inputs;
DROP POLICY IF EXISTS "Users can insert own readiness inputs" ON session_readiness_inputs;
DROP POLICY IF EXISTS "Users can update own readiness inputs" ON session_readiness_inputs;
DROP POLICY IF EXISTS "Users can delete own readiness inputs" ON session_readiness_inputs;
CREATE POLICY "Users can view own readiness inputs" ON session_readiness_inputs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own readiness inputs" ON session_readiness_inputs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own readiness inputs" ON session_readiness_inputs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own readiness inputs" ON session_readiness_inputs FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for Weekly Directives
DROP POLICY IF EXISTS "Users can view own directives" ON weekly_directives;
DROP POLICY IF EXISTS "Users can insert own directives" ON weekly_directives;
DROP POLICY IF EXISTS "Users can update own directives" ON weekly_directives;
DROP POLICY IF EXISTS "Users can delete own directives" ON weekly_directives;
CREATE POLICY "Users can view own directives" ON weekly_directives FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own directives" ON weekly_directives FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own directives" ON weekly_directives FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own directives" ON weekly_directives FOR DELETE USING (auth.uid() = user_id);

-- Indexes for new tables
CREATE INDEX IF NOT EXISTS idx_session_readiness_user_date ON session_readiness_inputs(user_id, session_date DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_directives_user_week ON weekly_directives(user_id, week_starting DESC);

-- Generated Workouts Table (for AI-generated workouts)
CREATE TABLE IF NOT EXISTS generated_workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_name TEXT NOT NULL,
  description TEXT,
  sport_focus TEXT,
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  protocol JSONB,
  exercises JSONB,
  total_duration_minutes INTEGER,
  target_intensity INTEGER,
  ai_reasoning TEXT,
  generation_context JSONB,
  ai_confidence_score REAL,
  scheduled_date DATE,
  completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exercise Performance History (for AI learning)
CREATE TABLE IF NOT EXISTS exercise_performance_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id TEXT NOT NULL,
  exercise_name TEXT,
  completed_workout_id UUID REFERENCES generated_workouts(id) ON DELETE CASCADE,
  performance_rating INTEGER,
  perceived_difficulty INTEGER,
  would_repeat BOOLEAN,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout Templates Table
CREATE TABLE IF NOT EXISTS workout_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  primary_sport TEXT,
  training_focus TEXT,
  target_duration_minutes INTEGER,
  blocks JSONB,
  required_equipment TEXT[],
  optional_equipment TEXT[],
  min_fitness_level INTEGER,
  max_fitness_level INTEGER,
  recommended_weekly_frequency INTEGER DEFAULT 2,
  is_system_template BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on new tables
ALTER TABLE generated_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_performance_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Generated Workouts
DROP POLICY IF EXISTS "Users can view own generated workouts" ON generated_workouts;
DROP POLICY IF EXISTS "Users can insert own generated workouts" ON generated_workouts;
DROP POLICY IF EXISTS "Users can update own generated workouts" ON generated_workouts;
DROP POLICY IF EXISTS "Users can delete own generated workouts" ON generated_workouts;
CREATE POLICY "Users can view own generated workouts" ON generated_workouts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own generated workouts" ON generated_workouts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own generated workouts" ON generated_workouts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own generated workouts" ON generated_workouts FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for Exercise Performance History
DROP POLICY IF EXISTS "Users can view own exercise history" ON exercise_performance_history;
DROP POLICY IF EXISTS "Users can insert own exercise history" ON exercise_performance_history;
CREATE POLICY "Users can view own exercise history" ON exercise_performance_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own exercise history" ON exercise_performance_history FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for Workout Templates (readable by all, writable only by system)
DROP POLICY IF EXISTS "Users can view templates" ON workout_templates;
CREATE POLICY "Users can view templates" ON workout_templates FOR SELECT USING (true);

-- Indexes for new tables
CREATE INDEX IF NOT EXISTS idx_generated_workouts_user_date ON generated_workouts(user_id, scheduled_date DESC);
CREATE INDEX IF NOT EXISTS idx_generated_workouts_created ON generated_workouts(user_id, generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_exercise_perf_user_exercise ON exercise_performance_history(user_id, exercise_id);
CREATE INDEX IF NOT EXISTS idx_workout_templates_sport ON workout_templates(primary_sport);

-- Insert default workout templates
INSERT INTO workout_templates (id, name, description, primary_sport, training_focus, target_duration_minutes, blocks, required_equipment, recommended_weekly_frequency, is_system_template)
VALUES 
  (gen_random_uuid(), 'MMA Fight Conditioning', 'High-intensity conditioning session mimicking MMA fight pace', 'mma', 'powerEndurance', 60, 
   '[{"id": "warmup", "name": "Fight Prep Warmup", "type": "warmup", "duration": 600}, {"id": "striking", "name": "Striking Power", "type": "combatSpecific", "duration": 900}]'::jsonb,
   ARRAY[]::TEXT[], 2, true),
  (gen_random_uuid(), 'Boxing Power Development', 'Build knockout power through explosive training', 'boxing', 'explosivePower', 45,
   '[{"id": "activation", "name": "Neural Activation", "type": "activation", "duration": 480}]'::jsonb,
   ARRAY[]::TEXT[], 2, true)
ON CONFLICT DO NOTHING;

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
