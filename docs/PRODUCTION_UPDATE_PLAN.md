# NeoSpartan AI - Major Production Update Plan
## Version 2.0: Firebase Auth, Firestore Integration & Enhanced Features

---

## Executive Summary

This document outlines a comprehensive 6-phase production update for the NeoSpartan AI fitness application. The update introduces:
- **Firebase Authentication** with Google Sign-in and Email/Password
- **Complete Firestore Data Persistence** with security rules
- **Enhanced DOM-RL AI Engine** with improved recommendations
- **New Social & Gamification Features**
- **Production-Ready Infrastructure**

---

## Phase 1: Firebase Authentication Implementation

### 1.1 Authentication Service
**File:** `lib/services/auth_service.dart`

**Features:**
- Google Sign-in via `firebase_auth` and `google_sign_in`
- Email/Password authentication (Sign up, Sign in, Password reset)
- Anonymous authentication for onboarding preview
- Auth state persistence across app restarts
- Secure token management

**Implementation Details:**
```dart
class AuthService {
  // Google Sign-in flow
  Future<UserCredential> signInWithGoogle();
  
  // Email/Password flow
  Future<UserCredential> signUpWithEmail(String email, String password, String displayName);
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  
  // Anonymous for preview mode
  Future<UserCredential> signInAnonymously();
  
  // Link anonymous to permanent account
  Future<UserCredential> linkAnonymousToGoogle();
  Future<UserCredential> linkAnonymousToEmail(String email, String password);
  
  // Sign out
  Future<void> signOut();
  
  // Auth state stream
  Stream<User?> get authStateChanges;
}
```

### 1.2 Auth Provider
**File:** `lib/providers/auth_provider.dart`

**Features:**
- Reactive auth state management with Provider
- User profile loading on auth change
- Auth error handling and messaging
- Loading states for auth operations

### 1.3 Login & Signup Screens
**Files:** 
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/signup_screen.dart`
- `lib/screens/auth/forgot_password_screen.dart`

**Design Requirements:**
- Spartan-themed UI (dark theme with bronze accents)
- Google Sign-in button with proper branding
- Email/password forms with validation
- Password strength indicator
- Smooth transitions between auth states

**Screenshots Required:**
- Login screen with Google and Email options
- Signup screen with email verification
- Password reset confirmation

### 1.4 Auth Wrapper
**File:** `lib/screens/auth/auth_wrapper.dart`

**Features:**
- Routes unauthenticated users to Login
- Routes authenticated users to Onboarding (if new) or Home
- Handles deep links for email verification

---

## Phase 2: Firestore Data Layer

### 2.1 Enhanced User Profile
**Collection:** `users/{userId}`

**Schema Extensions:**
```dart
class UserProfile {
  String id;                    // Firebase Auth UID
  String email;
  String displayName;
  String? photoURL;
  String? philosophicalBaseline; // "Marcus Aurelius", "Seneca", "Epictetus"
  ExperienceLevel experienceLevel; // Novice, Hoplite, Spartan, Legend
  int lastReadinessScore;
  
  // New fields
  DateTime? dateOfBirth;
  String? gender;
  double? height;
  double? weight;
  List<String> fitnessGoals;   // "power", "endurance", "mobility", "combat"
  List<String> equipment;        // "kettlebell", "dumbbells", "barbell", "bodyweight"
  List<String> injuryHistory;
  
  // Stats
  int totalWorkoutsCompleted;
  int totalWorkoutMinutes;
  int currentStreak;
  int longestStreak;
  DateTime? lastWorkoutDate;
  
  // Preferences
  bool enablePushNotifications;
  bool enableWeeklyEmails;
  String preferredWorkoutTime; // "morning", "afternoon", "evening"
  
  // Timestamps
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 2.2 Workouts Collection
**Collection:** `workouts/{workoutId}`

**Schema:**
```dart
class WorkoutSession {
  String id;
  String userId;
  String type;                 // "Stadion", "Phalanx", "Agoge-Generated"
  DateTime date;
  int totalVolume;
  double averageRPE;
  int durationMinutes;
  int caloriesBurned;
  
  // Protocol info
  String protocolTitle;
  String protocolSubtitle;
  String protocolTier;         // elite, ready, fatigued, recovery
  
  // Exercises performed
  List<ExerciseSet> exercises;
  
  // Mental state
  int flowStateRating;         // 1-10
  int mentalEngagement;        // 1-10
  int disciplineRating;        // 1-10
  
  // Physical state
  int postWorkoutReadiness;
  String? notes;
  
  // Source
  bool wasDomRlOptimized;
  
  // Timestamps
  DateTime createdAt;
  DateTime updatedAt;
}

class ExerciseSet {
  String exerciseId;
  String name;
  String category;
  List<SetData> sets;
}

class SetData {
  int reps;
  double? weight;
  double rpe;
  bool completed;
  int? restSeconds;
  String? notes;
}
```

### 2.3 Biometrics Collection
**Collection:** `biometrics/{biometricId}`

**Schema:**
```dart
class BiometricReading {
  String id;
  String userId;
  BiometricType type;
  double value;
  String unit;
  DateTime timestamp;
  String? source;              // "health_connect", "manual", "device"
  Map<String, dynamic>? metadata;
}

enum BiometricType {
  hrv,                // Heart Rate Variability
  sleepHours,
  sleepQuality,       // 1-10
  restingHR,
  steps,
  weight,
  bodyFat,
  bloodPressure,
  vo2Max,
}
```

### 2.4 Daily Readiness Collection
**Collection:** `daily_readiness/{readinessId}`

**Schema:**
```dart
class DailyReadiness {
  String id;
  String userId;
  DateTime date;
  int overallReadiness;          // 0-100 calculated score
  
  // Inputs
  int sleepQuality;              // 1-10
  double sleepHours;
  int hrv;                       // Raw HRV value
  int restingHR;
  int energyLevel;               // 1-10 self-reported
  int sorenessLevel;             // 1-10
  int stressLevel;               // 1-10
  
  // Joint-specific fatigue
  Map<String, int> jointFatigue; // "knees": 5, "shoulders": 3, etc.
  
  // Calculated recommendations
  String recommendedTier;        // elite, ready, fatigued, recovery
  String? aiInsight;             // DOM-RL generated insight
  
  DateTime createdAt;
}
```

### 2.5 Firestore Service
**File:** `lib/services/firestore_service.dart`

**Features:**
- CRUD operations for all collections
- Batch writes for atomic operations
- Real-time listeners for live updates
- Offline persistence enabled
- Query optimization with indexes
- Data migration utilities

### 2.6 Repository Pattern
**Files:**
- `lib/repositories/user_repository.dart`
- `lib/repositories/workout_repository.dart`
- `lib/repositories/biometrics_repository.dart`

**Features:**
- Clean API for data access
- Caching layer for performance
- Error handling and retry logic
- Data synchronization between local and remote

---

## Phase 3: Enhanced Existing Features

### 3.1 DOM-RL Engine 2.0
**File:** `lib/services/dom_rl_engine.dart`

**Enhancements:**
- **Historical Pattern Learning**: Analyze last 30 days to predict optimal training loads
- **Periodization Support**: Implement mesocycle/macrocycle planning
- **Fatigue Prediction**: Use HRV trends to predict overreaching 2-3 days in advance
- **Progressive Overload Tracking**: Automatically suggest weight/rep increases
- **Deload Detection**: Smart detection of when deload is needed

**New Endpoints (Backend):**
```python
@app.post("/dom-rl/predict-fatigue")
def predict_future_fatigue(micro_cycle: MicroCycle, days_ahead: int = 3):
    """Predict fatigue levels for next N days based on current trajectory"""

@app.post("/dom-rl/generate-mesocycle")
def generate_mesocycle(
    user_profile: UserProfile, 
    goal: str,  # "power", "endurance", "recomposition"
    weeks: int = 4
):
    """Generate full mesocycle (4-week training block) with periodization"""

@app.post("/dom-rl/analyze-progress")
def analyze_progress(workout_history: List[WorkoutSession]):
    """Analyze training history for progress indicators and plateaus"""
```

### 3.2 Set Tracker Enhancements
**File:** `lib/widgets/set_tracker_card.dart`

**New Features:**
- **Rest Timer**: Built-in countdown between sets with audio cue
- **Form Check**: Quick form rating (1-5 stars) per set
- **Tempo Tracking**: Optional eccentric/concentric tempo logging
- **Auto-suggest**: Suggest next set weight based on previous performance
- **Set PR Notifications**: Highlight when user hits rep PR

### 3.3 Weekly Schedule Improvements
**File:** `lib/screens/weekly_schedule_screen.dart`

**Enhancements:**
- **Drag-and-Drop Rescheduling**: Move workouts between days
- **Conflict Detection**: Warn if scheduling too many high-intensity days
- **Calendar Sync**: Export workouts to phone calendar
- **Streak Visualization**: Show weekly streak on calendar
- **Planned vs Actual**: Compare scheduled vs completed workouts

### 3.4 Analytics Dashboard 2.0
**File:** `lib/screens/analytics_dashboard.dart`

**New Widgets:**
- **Volume Trend Chart**: 90-day training volume with trend line
- **Readiness Heatmap**: Calendar view of readiness scores
- **Joint Stress Radar Chart**: Visual joint stress distribution
- **Exercise Progress Graph**: Track strength progress per exercise
- **Recovery Metrics Correlation**: HRV vs Performance scatter plot
- **Consistency Score**: Percentage of planned workouts completed

### 3.5 Armor Analytics Enhancements
**File:** `lib/services/armor_analytics_service.dart`

**New Features:**
- **Predictive Injury Risk**: ML-based injury risk score
- **Movement Pattern Analysis**: Identify compensations
- **Mobility Recommendations**: Suggest specific mobility work based on stress
- **Recovery Protocol Generator**: Auto-generate recovery sessions

### 3.6 Stoic Integration Deepening
**File:** `lib/screens/stoic_screen.dart`

**New Features:**
- **Daily Stoic Journal**: Quick reflection prompts post-workout
- **Philosophy-Based Training**: Seneca vs Marcus Aurelius training styles
- **Quote Database Expansion**: 50+ quotes with context
- **Meditation Timer**: Simple breath work for pre/post workout
- **Virtue Tracking**: Track Courage, Temperance, Justice, Wisdom

---

## Phase 4: New Features

### 4.1 Achievements & Gamification System
**Collection:** `achievements/{achievementId}`
**User Subcollection:** `users/{userId}/unlocked_achievements`

**Achievement Categories:**

**Volume Achievements:**
- "First Blood" - Complete first workout
- "Centurion" - Complete 100 workouts
- "Marathoner" - 26.2 hours of training
- "Titan" - 1000 total workouts

**Consistency Achievements:**
- "The Streak" - 7-day streak
- "Iron Will" - 30-day streak
- "Legend" - 100-day streak

**Strength Achievements:**
- "Heavy Lifter" - Lift 10,000 lbs total volume
- "Beast Mode" - Complete 10 RPE 10 sets in one week
- "Progressive Overload" - Increase weight for 4 weeks straight

**Stoic Achievements:**
- "Student of Seneca" - Log 10 stoic reflections
- "Discipline" - Complete 20 scheduled workouts without skipping
- "Memento Mori" - Complete a workout while traveling

**Implementation:**
```dart
class AchievementService {
  Stream<List<Achievement>> get userAchievementsStream;
  Future<List<Achievement>> checkAndUnlockAchievements(String userId);
  Future<void> trackProgress(String achievementId, int progress);
}
```

### 4.2 Social Features (Lite)
**Collection:** `friendships/{friendshipId}`

**Features:**
- **Friend Discovery**: Find friends by username/email
- **Activity Feed**: See friends' completed workouts (privacy-respecting)
- **Challenges**: Weekly team challenges (e.g., "Most Consistent")
- **Leaderboards**: Rankings for volume, consistency, PRs
- **Privacy Controls**: Share all, workouts only, or nothing

**Privacy-First Design:**
- Opt-in only - no auto-sharing
- Granular control per workout type
- No exact weights/reps shared publicly, only relative effort

### 4.3 Nutrition & Fuel Tracking
**Collection:** `fuel_logs/{fuelLogId}`

**Schema:**
```dart
class FuelLog {
  String id;
  String userId;
  DateTime date;
  MealType type;                 // breakfast, lunch, dinner, snack, pre_workout, post_workout
  List<FuelEntry> items;
  int totalCalories;
  double totalProtein;
  double totalCarbs;
  double totalFat;
  double? waterLiters;
  
  // Workout correlation
  String? associatedWorkoutId;
  int? workoutPerformanceRating;
}

class FuelEntry {
  String name;
  double quantity;
  String unit;
  int calories;
  double protein;
  double carbs;
  double fat;
  String? brand;
  String? barcode;
}
```

**Features:**
- Quick-add common foods
- Barcode scanning (future enhancement)
- Workout correlation (how food affected performance)
- Simple macros tracking
- Water intake logging

### 4.4 Advanced Workout Modes

**HIIT Timer Mode:**
- Tabata protocol (20s work, 10s rest)
- Custom interval creation
- Audio cues for transitions

**EMOM (Every Minute On the Minute):**
- Auto-timer for EMOM workouts
- Set completion tracking per minute
- Drop-off rate calculation

**Circuit Mode:**
- Multi-station circuit tracking
- Round completion tracking
- Lap timing

### 4.5 Equipment & Gym Management
**Collection:** `user_equipment/{equipmentId}`

**Features:**
- Log available equipment at home/gym
- DOM-RL filters exercises by available equipment
- Equipment PR tracking ("Heaviest kettlebell swing")
- Maintenance reminders (replace shoes every 500 miles)

---

## Phase 5: Production Readiness

### 5.1 Firebase Security Rules
**File:** `firebase/firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isValidUserProfile() {
      return request.resource.data.keys().hasAll(['displayName', 'createdAt']) &&
             request.resource.data.displayName is string &&
             request.resource.data.displayName.size() >= 2;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId) && isValidUserProfile();
      allow update: if isOwner(userId) && 
        request.resource.data.updatedAt == request.time;
    }
    
    // Workouts collection
    match /workouts/{workoutId} {
      allow read: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(resource.data.userId)).data.privacySettings.shareWorkouts == true);
      allow create: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
      allow update, delete: if isOwner(resource.data.userId);
    }
    
    // Biometrics collection
    match /biometrics/{biometricId} {
      allow read, write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Achievements (global read, user-specific write)
    match /achievements/{achievementId} {
      allow read: if isAuthenticated();
      allow write: if false; // Only admin/cloud functions
    }
    
    // User achievements subcollection
    match /users/{userId}/unlocked_achievements/{achievementId} {
      allow read: if isOwner(userId);
      allow write: if false; // Only cloud functions can award
    }
  }
}
```

### 5.2 Firebase App Check
**Configuration:**
- Enable App Check for iOS (DeviceCheck)
- Enable App Check for Android (Play Integrity)
- Enable App Check for Web (reCAPTCHA Enterprise)

**Implementation:**
```dart
// In main.dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.deviceCheck,
);
```

### 5.3 Firebase Indexes
**File:** `firebase/firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "workouts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "biometrics",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "daily_readiness",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ]
}
```

### 5.4 Error Handling & Monitoring

**Crashlytics Integration:**
```dart
// In main.dart
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

**Structured Logging:**
```dart
class AppLogger {
  static void logError(String context, dynamic error, StackTrace? stack);
  static void logEvent(String event, Map<String, dynamic> params);
  static void logPerformance(String operation, int milliseconds);
}
```

**Offline Mode:**
- Graceful degradation when offline
- Queue operations for sync when back online
- Visual indicators for offline state

### 5.5 Performance Optimization

**Image Optimization:**
- Compress exercise images
- Lazy loading for exercise library
- CDN integration for static assets

**Query Optimization:**
- Pagination for workout history (20 per page)
- Debounced search in exercise library
- Cached DOM-RL recommendations (refresh every 4 hours)

**Startup Performance:**
- Lazy load non-critical services
- Splash screen with loading progress
- Pre-cache critical data

### 5.6 Firebase Configuration Files

**Android:**
- `android/app/google-services.json` (downloaded from Firebase Console)
- `android/build.gradle` - Add Google Services plugin
- `android/app/build.gradle` - Apply plugin, add dependencies

**iOS:**
- `ios/Runner/GoogleService-Info.plist` (downloaded from Firebase Console)
- `ios/Podfile` - Firebase dependencies

**Web:**
- `web/index.html` - Firebase SDK configuration

### 5.7 CI/CD Pipeline Setup

**GitHub Actions Workflow:**
```yaml
name: Build & Deploy

on:
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
  
  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - run: flutter build appbundle --release
  
  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --release --no-codesign
```

---

## Phase 6: Backend Production Deployment

### 6.1 Deployment Options

**Option A: Railway (Recommended for FastAPI)**
- Native Python support
- Automatic HTTPS
- Environment variable management
- Easy scaling

**Option B: Render**
- Free tier available
- Simple deployment from GitHub
- Automatic deploys on push

**Option C: Google Cloud Run**
- Serverless scaling
- Integration with Firebase
- Pay-per-use pricing

### 6.2 Backend Configuration

**Environment Variables:**
```bash
# Production .env
ENV=production
FIREBASE_PROJECT_ID=neospartan-prod
FIREBASE_SERVICE_ACCOUNT_KEY=...  # JSON string or path
API_KEY=secure_random_key
CORS_ORIGINS=https://neospartan.app,https://app.neospartan.ai
RATE_LIMIT=100/minute
```

**Security Headers:**
```python
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://neospartan.app"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

app.add_middleware(TrustedHostMiddleware, allowed_hosts=["api.neospartan.ai"])
```

### 6.3 API Rate Limiting
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/dom-rl/optimize")
@limiter.limit("10/minute")
def optimize_with_domrl(...):
    ...
```

### 6.4 Health Checks & Monitoring
```python
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "version": "2.0.0",
        "timestamp": datetime.now(),
        "firebase_connected": check_firebase_connection()
    }
```

---

## Implementation Timeline

### Week 1-2: Phase 1 - Authentication
- Day 1-3: Auth Service implementation
- Day 4-5: Login/Signup UI
- Day 6-8: Auth Provider and state management
- Day 9-10: Testing and integration

### Week 3-4: Phase 2 - Firestore Integration
- Day 1-3: User Profile repository
- Day 4-6: Workouts repository with CRUD
- Day 7-8: Biometrics repository
- Day 9-10: Daily Readiness collection
- Day 11-14: Sync logic and offline support

### Week 5-6: Phase 3 - Feature Enhancements
- Day 1-4: DOM-RL 2.0 improvements
- Day 5-7: Set Tracker enhancements
- Day 8-10: Analytics Dashboard 2.0
- Day 11-14: Armor Analytics & Stoic features

### Week 7-8: Phase 4 - New Features
- Day 1-5: Achievements system
- Day 6-8: Social features (lite)
- Day 9-12: Nutrition tracking
- Day 13-14: Advanced workout modes

### Week 9-10: Phase 5 - Production Readiness
- Day 1-3: Security rules & App Check
- Day 4-5: Error handling & Crashlytics
- Day 6-7: Performance optimization
- Day 8-10: CI/CD pipeline

### Week 11: Phase 6 - Backend Deployment
- Day 1-3: Backend production setup
- Day 4-5: API security & rate limiting
- Day 6-7: Monitoring & health checks

### Week 12: Testing & Launch Prep
- Day 1-5: End-to-end testing
- Day 6-7: Beta testing with select users
- Day 8-10: Final polish and launch

---

## File Structure Changes

```
lib/
├── main.dart
├── theme.dart
├── models/
│   ├── exercise.dart
│   ├── user_profile.dart (ENHANCED)
│   ├── workout_tracking.dart (ENHANCED)
│   ├── armor_analytics.dart
│   ├── fuel_entry.dart
│   ├── fuel_log.dart
│   ├── workout_protocol.dart
│   ├── daily_readiness.dart (NEW)
│   ├── achievement.dart (NEW)
│   └── biometric_reading.dart (NEW)
├── screens/
│   ├── auth/ (NEW FOLDER)
│   │   ├── login_screen.dart (NEW)
│   │   ├── signup_screen.dart (NEW)
│   │   ├── forgot_password_screen.dart (NEW)
│   │   └── auth_wrapper.dart (NEW)
│   ├── agoge_screen.dart (ENHANCED)
│   ├── analytics_dashboard.dart (ENHANCED)
│   ├── flow_state_screen.dart
│   ├── garrison_screen.dart (ENHANCED)
│   ├── onboarding_screen.dart (ENHANCED)
│   ├── phalanx_screen.dart
│   ├── pre_battle_primer_screen.dart
│   ├── stadion_screen.dart
│   ├── stoic_screen.dart (ENHANCED)
│   ├── weekly_schedule_screen.dart (ENHANCED)
│   ├── workout_session_screen.dart (ENHANCED)
│   └── nutrition/ (NEW FOLDER)
│       ├── fuel_log_screen.dart (NEW)
│       └── add_meal_screen.dart (NEW)
├── services/
│   ├── auth_service.dart (NEW)
│   ├── firestore_service.dart (NEW)
│   ├── firebase_sync_service.dart (ENHANCED)
│   ├── dom_rl_engine.dart (ENHANCED)
│   ├── backend_api_service.dart (ENHANCED)
│   ├── agoge_service.dart
│   ├── ai_plan_service.dart
│   ├── armor_analytics_service.dart (ENHANCED)
│   ├── ephor_scrutiny_service.dart
│   ├── health_service.dart (ENHANCED)
│   ├── tactical_retreat_service.dart
│   ├── phalanx_ingestion_service.dart
│   ├── laconic_parser_service.dart
│   └── achievement_service.dart (NEW)
├── repositories/ (NEW FOLDER)
│   ├── user_repository.dart (NEW)
│   ├── workout_repository.dart (NEW)
│   └── biometrics_repository.dart (NEW)
├── providers/
│   ├── auth_provider.dart (NEW)
│   ├── workout_provider.dart (ENHANCED)
│   └── ingestion_provider.dart
├── widgets/
│   ├── set_tracker_card.dart (ENHANCED)
│   └── weekly_calendar.dart (ENHANCED)
└── utils/
    ├── app_logger.dart (NEW)
    ├── constants.dart (NEW)
    └── validators.dart (NEW)

firebase/
├── firestore.rules (NEW)
├── firestore.indexes.json (NEW)
└── storage.rules (NEW)

backend/
├── main.py (ENHANCED)
├── requirements.txt (ENHANCED)
├── Dockerfile (NEW)
├── railway.toml (NEW - if using Railway)
└── .env.example (NEW)
```

---

## Dependencies to Add

```yaml
# pubspec.yaml additions
dependencies:
  # Firebase (existing, verify versions)
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  firebase_crashlytics: ^3.4.9
  firebase_app_check: ^0.2.1
  firebase_analytics: ^10.8.0
  
  # Google Sign In
  google_sign_in: ^6.2.1
  
  # Social Features
  share_plus: ^7.2.2
  
  # Charts & Visualization
  fl_chart: ^0.66.0
  
  # Notifications
  flutter_local_notifications: ^16.3.2
  
  # State Management (already have provider)
  # provider: ^6.1.1
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.3.3
  equatable: ^2.0.5
  dartz: ^0.10.1  # Functional programming
  
  # Connectivity
  connectivity_plus: ^5.0.2
  
  # Image handling
  cached_network_image: ^3.3.1
  
  # Security
  crypto: ^3.0.3
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  mockito: ^5.4.4
  build_runner: ^2.4.8
```

---

## Testing Strategy

### Unit Tests
- Auth Service methods
- Repository CRUD operations
- DOM-RL calculation logic
- Achievement tracking logic

### Widget Tests
- Login/Signup form validation
- Set Tracker interactions
- Weekly calendar navigation
- Analytics chart rendering

### Integration Tests
- End-to-end workout flow
- Offline mode behavior
- Auth state transitions
- Firestore sync operations

### Security Tests
- Firestore rules validation
- API authentication
- Rate limiting verification

---

## Production Checklist

- [ ] Firebase project created (separate from dev)
- [ ] iOS App Store Connect setup
- [ ] Google Play Console setup
- [ ] Firebase Security Rules deployed
- [ ] Firebase Indexes deployed
- [ ] App Check enforced
- [ ] Backend deployed with SSL
- [ ] Custom domain configured
- [ ] Privacy Policy drafted
- [ ] Terms of Service drafted
- [ ] Analytics events configured
- [ ] Crashlytics monitoring active
- [ ] Beta testing completed
- [ ] App store screenshots prepared
- [ ] App store descriptions written
- [ ] Support email configured

---

## Estimated Effort

| Phase | Days | Complexity |
|-------|------|------------|
| Phase 1: Authentication | 10 | Medium |
| Phase 2: Firestore | 14 | High |
| Phase 3: Enhancements | 14 | Medium-High |
| Phase 4: New Features | 14 | Medium |
| Phase 5: Production | 10 | Medium |
| Phase 6: Backend | 7 | Medium |
| Testing & Polish | 10 | Medium |
| **Total** | **~79 days** | **~12 weeks** |

---

## Success Metrics

**Technical:**
- 99.9% Firebase uptime
- <2s app startup time
- <500ms Firestore query times
- Zero security vulnerabilities

**User Experience:**
- 4.5+ app store rating
- <5% crash rate
- 70%+ user retention (7-day)
- 40%+ daily active users

**Growth:**
- 10,000+ downloads in first month
- 50%+ Google Sign-in adoption
- 30%+ daily workout completion rate

---

*Document Version: 1.0*
*Created for NeoSpartan AI v2.0 Production Update*
