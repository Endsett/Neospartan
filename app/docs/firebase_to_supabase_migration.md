# Firebase to Supabase Migration Plan

## Overview
Complete migration from Firebase to Supabase for the Neospartan Flutter app.

## Migration Strategy
**Incremental Migration Approach:**
1. Phase 1: Setup Supabase and migrate authentication
2. Phase 2: Migrate database (Firestore → Supabase)
3. Phase 3: Update all services and repositories
4. Phase 4: Remove Firebase dependencies (except Analytics/Crashlytics)

## Phase 1: Supabase Setup & Authentication

### 1.1 Create Supabase Project
- Go to https://supabase.com
- Create new project
- Note project URL and anon key
- Set up authentication providers (email, Google)

### 1.2 Install Dependencies
```yaml
dependencies:
  supabase_flutter: ^2.0.0
  # Remove: firebase_auth, cloud_firestore
  # Keep: firebase_analytics, firebase_crashlytics
```

### 1.3 Create Supabase Config
```dart
// lib/config/supabase_config.dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 1.4 Update Authentication
- Replace Firebase Auth with Supabase Auth
- Update AuthGate to use Supabase auth state
- Migrate user profiles to Supabase auth.users

## Phase 2: Database Migration

### 2.1 Database Schema
Create tables in Supabase SQL Editor:

```sql
-- User Profiles
CREATE TABLE user_profiles (
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  has_completed_onboarding BOOLEAN DEFAULT false
);

-- Workout Sessions
CREATE TABLE workout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  date DATE,
  start_time TIMESTAMP WITH TIME ZONE,
  end_time TIMESTAMP WITH TIME ZONE,
  workout_type TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout Sets
CREATE TABLE workout_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES workout_sessions(id),
  exercise_name TEXT,
  set_number INTEGER,
  reps_performed INTEGER,
  actual_rpe REAL,
  load_used REAL,
  completed BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI Memories
CREATE TABLE ai_memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
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

-- Weekly Progress
CREATE TABLE weekly_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
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

-- Enable RLS (Row Level Security)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
-- Add similar policies for all tables
```

### 2.2 Data Migration Script
Create a script to migrate existing data from Firebase to Supabase.

## Phase 3: Service Updates

### 3.1 Update Services
- **FirebaseSyncService** → **SupabaseSyncService**
- **UserProfileRepository** → Use Supabase client
- **WorkoutRepository** → Use Supabase queries
- **AIMemoryService** → Use Supabase storage

### 3.2 Update Models
- Ensure all models have toMap() and fromMap() methods
- Update for Supabase UUID primary keys

## Phase 4: Cleanup

### 4.1 Remove Firebase Dependencies
```yaml
dependencies:
  # Remove these:
  # firebase_auth: ^4.19.0
  # cloud_firestore: ^4.17.0
  # firebase_core: ^2.31.0
  
  # Keep these:
  firebase_analytics: ^10.10.0
  firebase_crashlytics: ^3.5.0
```

### 4.2 Update Imports
- Replace all Firebase imports with Supabase
- Update authentication flow
- Update error handling

## Implementation Steps

### Day 1: Setup & Auth
1. Create Supabase project
2. Update pubspec.yaml
3. Create Supabase config
4. Implement Supabase auth
5. Update AuthGate

### Day 2: Database & Repositories
1. Create database schema
2. Migrate existing data
3. Update all repository classes
4. Test CRUD operations

### Day 3: Services & Testing
1. Update all services
2. Fix authentication flow
3. Test all features
4. Handle edge cases

### Day 4: Cleanup & Polish
1. Remove Firebase dependencies
2. Fix any remaining issues
3. Optimize queries
4. Final testing

## Key Differences

### Authentication
- Firebase: `FirebaseAuth.instance.currentUser`
- Supabase: `Supabase.instance.client.auth.currentUser`

### Database Queries
- Firebase: `FirebaseFirestore.instance.collection('users').doc(id)`
- Supabase: `Supabase.instance.client.from('user_profiles').select()`

### Real-time Updates
- Firebase: `snapshots()`
- Supabase: `.stream()` or `realtime()`

## Migration Checklist

- [ ] Create Supabase project
- [ ] Get URL and anon key
- [ ] Create database schema
- [ ] Migrate authentication
- [ ] Migrate user data
- [ ] Update all repositories
- [ ] Update all services
- [ ] Test authentication
- [ ] Test CRUD operations
- [ ] Test real-time features
- [ ] Remove Firebase dependencies
- [ ] Update documentation

## Risks & Mitigations

1. **Data Loss**: Backup Firebase data before migration
2. **Downtime**: Use incremental migration
3. **User Impact**: Maintain backward compatibility during transition
4. **Complex Queries**: Rewrite complex Firestore queries for PostgreSQL

## Post-Migration

1. Monitor performance
2. Set up Supabase logs monitoring
3. Consider Supabase Edge Functions for serverless logic
4. Update deployment configuration
