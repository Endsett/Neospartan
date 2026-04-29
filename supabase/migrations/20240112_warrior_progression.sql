-- Warrior Progression System Tables
-- NeoSpartan Warrior Forge Database Schema

-- ============================================
-- 1. WARRIOR PROFILES
-- Stores user progression data: rank, XP, streaks
-- ============================================
CREATE TABLE IF NOT EXISTS warrior_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Rank & Progression
    rank_level INTEGER NOT NULL DEFAULT 1,
    total_xp INTEGER NOT NULL DEFAULT 0,
    
    -- Streak Tracking
    current_streak INTEGER NOT NULL DEFAULT 0,
    longest_streak INTEGER NOT NULL DEFAULT 0,
    last_workout_date DATE,
    
    -- Stats
    total_workouts INTEGER NOT NULL DEFAULT 0,
    rank_achieved_date TIMESTAMPTZ,
    
    -- Skill Tree Progress (JSONB for flexibility)
    skill_progress JSONB DEFAULT '{}',
    
    -- Titles & Customization
    current_title TEXT,
    unlocked_titles TEXT[] DEFAULT '{}',
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Constraints
    CONSTRAINT valid_rank CHECK (rank_level >= 1 AND rank_level <= 10),
    CONSTRAINT valid_xp CHECK (total_xp >= 0),
    CONSTRAINT valid_streaks CHECK (current_streak >= 0 AND longest_streak >= 0),
    
    -- Unique constraint: one profile per user
    UNIQUE(user_id)
);

-- Indexes for warrior_profiles
CREATE INDEX idx_warrior_profiles_user_id ON warrior_profiles(user_id);
CREATE INDEX idx_warrior_profiles_rank ON warrior_profiles(rank_level);
CREATE INDEX idx_warrior_profiles_xp ON warrior_profiles(total_xp DESC);

-- ============================================
-- 2. ACHIEVEMENTS
-- Master list of all available achievements
-- ============================================
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Achievement Details
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_name TEXT NOT NULL DEFAULT 'star',
    
    -- Category & Tier
    category TEXT NOT NULL CHECK (category IN ('combat', 'skill', 'discipline', 'special')),
    tier INTEGER NOT NULL DEFAULT 1 CHECK (tier IN (1, 2, 3)), -- Bronze, Silver, Gold
    
    -- Requirements
    target_value INTEGER NOT NULL,
    requirement_type TEXT NOT NULL, -- e.g., 'workouts_completed', 'streak_days', 'xp_earned'
    
    -- Rewards
    xp_reward INTEGER DEFAULT 0,
    
    -- Metadata
    is_secret BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Unique constraint: prevent duplicate achievements
    UNIQUE(title, category, tier)
);

-- Indexes for achievements
CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_tier ON achievements(tier);

-- ============================================
-- 3. USER ACHIEVEMENTS (Junction Table)
-- Tracks which achievements each user has unlocked
-- ============================================
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
    
    -- Progress tracking
    current_value INTEGER DEFAULT 0,
    progress_percent INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN (SELECT target_value FROM achievements WHERE id = achievement_id) > 0 
            THEN LEAST(100, (current_value * 100 / (SELECT target_value FROM achievements WHERE id = achievement_id)))
            ELSE 0
        END
    ) STORED,
    
    -- Status
    is_unlocked BOOLEAN DEFAULT false,
    unlocked_at TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Unique constraint: one entry per user-achievement pair
    UNIQUE(user_id, achievement_id)
);

-- Indexes for user_achievements
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX idx_user_achievements_unlocked ON user_achievements(user_id, is_unlocked);

-- ============================================
-- 4. BATTLE CHRONICLE
-- Workout history with warrior-themed narrative
-- ============================================
CREATE TABLE IF NOT EXISTS battle_chronicle (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Trial Details
    trial_name TEXT NOT NULL,
    difficulty TEXT NOT NULL CHECK (difficulty IN ('recruit', 'soldier', 'veteran', 'elite', 'legendary')),
    
    -- Performance
    completion_rate DECIMAL(4,3) CHECK (completion_rate >= 0 AND completion_rate <= 1),
    duration_minutes INTEGER,
    
    -- Warrior-themed metrics
    casualties INTEGER, -- Calories burned
    spoils JSONB DEFAULT '{}', -- XP earned, bonuses, etc.
    wounds TEXT[] DEFAULT '{}', -- Muscle groups worked
    
    -- Narrative
    battle_cry TEXT,
    stoic_reflection TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now(),
    workout_date DATE DEFAULT CURRENT_DATE
);

-- Indexes for battle_chronicle
CREATE INDEX idx_battle_chronicle_user_id ON battle_chronicle(user_id);
CREATE INDEX idx_battle_chronicle_date ON battle_chronicle(workout_date DESC);
CREATE INDEX idx_battle_chronicle_created ON battle_chronicle(created_at DESC);

-- ============================================
-- 5. SKILL TREE PROGRESS
-- Detailed tracking per skill discipline
-- ============================================
CREATE TABLE IF NOT EXISTS skill_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Skill Identification
    skill_id TEXT NOT NULL CHECK (skill_id IN ('phalanx', 'pankration', 'dromos', 'agoge', 'tactics')),
    
    -- Progress
    level INTEGER NOT NULL DEFAULT 0,
    xp INTEGER NOT NULL DEFAULT 0,
    workouts_completed INTEGER DEFAULT 0,
    
    -- Tracking
    last_workout_date DATE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Unique constraint: one entry per user-skill pair
    UNIQUE(user_id, skill_id)
);

-- Indexes for skill_progress
CREATE INDEX idx_skill_progress_user_id ON skill_progress(user_id);
CREATE INDEX idx_skill_progress_skill_id ON skill_progress(skill_id);

-- ============================================
-- 6. DAILY OATHS
-- User commitments and daily declarations
-- ============================================
CREATE TABLE IF NOT EXISTS daily_oaths (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Oath Details
    oath_text TEXT NOT NULL,
    oath_type TEXT NOT NULL DEFAULT 'daily' CHECK (oath_type IN ('daily', 'weekly', 'campaign')),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_fulfilled BOOLEAN DEFAULT false,
    fulfilled_at TIMESTAMPTZ,
    
    -- Time Tracking
    oath_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expires_at TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Constraints
    UNIQUE(user_id, oath_date, oath_type)
);

-- Indexes for daily_oaths
CREATE INDEX idx_daily_oaths_user_id ON daily_oaths(user_id);
CREATE INDEX idx_daily_oaths_date ON daily_oaths(oath_date DESC);
CREATE INDEX idx_daily_oaths_active ON daily_oaths(user_id, is_active);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE warrior_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE battle_chronicle ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_oaths ENABLE ROW LEVEL SECURITY;

-- Warrior Profiles: Users can only see/edit their own
CREATE POLICY "Users can view own warrior profile"
    ON warrior_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own warrior profile"
    ON warrior_profiles FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own warrior profile"
    ON warrior_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Achievements: Everyone can view all achievements
CREATE POLICY "Anyone can view achievements"
    ON achievements FOR SELECT
    USING (true);

-- User Achievements: Users can only see/edit their own
CREATE POLICY "Users can view own achievements"
    ON user_achievements FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own achievements"
    ON user_achievements FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements"
    ON user_achievements FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Battle Chronicle: Users can only see/edit their own
CREATE POLICY "Users can view own chronicle"
    ON battle_chronicle FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own chronicle entries"
    ON battle_chronicle FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Skill Progress: Users can only see/edit their own
CREATE POLICY "Users can view own skill progress"
    ON skill_progress FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own skill progress"
    ON skill_progress FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own skill progress"
    ON skill_progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Daily Oaths: Users can only see/edit their own
CREATE POLICY "Users can view own oaths"
    ON daily_oaths FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own oaths"
    ON daily_oaths FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own oaths"
    ON daily_oaths FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_warrior_profiles_updated_at
    BEFORE UPDATE ON warrior_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_achievements_updated_at
    BEFORE UPDATE ON user_achievements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_skill_progress_updated_at
    BEFORE UPDATE ON skill_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SEED DATA: DEFAULT ACHIEVEMENTS
-- ============================================

INSERT INTO achievements (title, description, icon_name, category, tier, target_value, requirement_type, xp_reward, is_secret) VALUES
    -- Combat Medals (Tier 1: Bronze)
    ('First Blood', 'Complete your first workout', 'blood', 'combat', 1, 1, 'workouts_completed', 50, false),
    ('Shield Wall', 'Complete a 7-day streak', 'shield', 'combat', 1, 7, 'streak_days', 100, false),
    ('Last Stand', 'Complete a workout while marked as fatigued', 'medical_services', 'combat', 1, 1, 'fatigued_workouts', 75, false),
    
    -- Combat Medals (Tier 2: Silver)
    ('Veteran', 'Complete 50 workouts', 'military_tech', 'combat', 2, 50, 'workouts_completed', 200, false),
    ('Unbreakable', 'Complete a 30-day streak', 'local_fire_department', 'combat', 2, 30, 'streak_days', 300, false),
    
    -- Combat Medals (Tier 3: Gold)
    ('Centurion', 'Complete 100 workouts', 'workspace_premium', 'combat', 3, 100, 'workouts_completed', 500, false),
    ('Iron Will', 'Complete a 100-day streak', 'emoji_events', 'combat', 3, 100, 'streak_days', 1000, false),
    
    -- Skill Badges
    ('Iron Grip', 'Deadlift 2x bodyweight', 'fitness_center', 'skill', 2, 1, 'deadlift_pr', 150, false),
    ('Marathon Runner', 'Run 100km total', 'directions_run', 'skill', 2, 100000, 'distance_meters', 200, false),
    ('Phalanx Master', 'Complete 100 strength workouts', 'sports_martial_arts', 'skill', 3, 100, 'strength_workouts', 400, false),
    
    -- Discipline Badges
    ('Early Bird', 'Complete 10 workouts before 6am', 'wb_sunny', 'discipline', 1, 10, 'early_workouts', 100, false),
    ('Never Miss Monday', 'Complete 4 consecutive Monday workouts', 'calendar_today', 'discipline', 1, 4, 'monday_streak', 75, false),
    ('Perfect Week', 'Complete all scheduled workouts in a week', 'check_circle', 'discipline', 2, 1, 'perfect_weeks', 200, false),
    
    -- Secret Achievements
    ('Spartan Dawn', 'Complete a workout at 5am', 'wb_twilight', 'special', 2, 1, 'dawn_workouts', true),
    ('Blood & Sweat', 'Complete an outdoor workout in the rain', 'water_drop', 'special', 2, 1, 'rain_workouts', true),
    ('Never Retreat', 'Complete a workout despite low readiness', 'sports_martial_arts', 'special', 2, 1, 'perseverance', true)
ON CONFLICT (title, category, tier) DO NOTHING;

-- ============================================
-- FUNCTIONS FOR RANK PROGRESSION
-- ============================================

-- Function to calculate rank from XP
CREATE OR REPLACE FUNCTION calculate_rank_from_xp(xp_amount INTEGER)
RETURNS INTEGER AS $$
DECLARE
    rank_levels INTEGER[] := ARRAY[0, 500, 1500, 3000, 5000, 8000, 12000, 20000, 35000, 60000];
    current_rank INTEGER := 1;
BEGIN
    FOR i IN 2..10 LOOP
        IF xp_amount >= rank_levels[i] THEN
            current_rank := i;
        ELSE
            EXIT;
        END IF;
    END LOOP;
    RETURN current_rank;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-update rank when XP changes
CREATE OR REPLACE FUNCTION update_warrior_rank()
RETURNS TRIGGER AS $$
BEGIN
    NEW.rank_level := calculate_rank_from_xp(NEW.total_xp);
    IF NEW.rank_level > OLD.rank_level THEN
        NEW.rank_achieved_date := now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply rank update trigger
CREATE TRIGGER auto_update_warrior_rank
    BEFORE UPDATE OF total_xp ON warrior_profiles
    FOR EACH ROW EXECUTE FUNCTION update_warrior_rank();

-- ============================================
-- VIEWS FOR LEADERBOARDS
-- ============================================

-- Rank leaderboard view
CREATE OR REPLACE VIEW rank_leaderboard AS
SELECT 
    wp.user_id,
    wp.rank_level,
    wp.total_xp,
    wp.current_streak,
    wp.total_workouts,
    RANK() OVER (ORDER BY wp.total_xp DESC) as global_rank
FROM warrior_profiles wp
WHERE wp.total_xp > 0;

-- Streak leaderboard view
CREATE OR REPLACE VIEW streak_leaderboard AS
SELECT 
    wp.user_id,
    wp.current_streak,
    wp.longest_streak,
    wp.total_workouts,
    RANK() OVER (ORDER BY wp.current_streak DESC, wp.total_xp DESC) as rank
FROM warrior_profiles wp
WHERE wp.current_streak > 0;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE warrior_profiles IS 'Stores warrior progression data: rank, XP, streaks, and skill progress';
COMMENT ON TABLE achievements IS 'Master list of all available achievements in the system';
COMMENT ON TABLE user_achievements IS 'Tracks which achievements each user has unlocked and their progress';
COMMENT ON TABLE battle_chronicle IS 'Workout history with warrior-themed narrative and metrics';
COMMENT ON TABLE skill_progress IS 'Detailed tracking per skill discipline (Phalanx, Pankration, etc.)';
COMMENT ON TABLE daily_oaths IS 'User commitments and daily declarations';
