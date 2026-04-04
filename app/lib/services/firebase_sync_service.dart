import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_tracking.dart';
import '../models/workout_protocol.dart';
import '../models/user_profile.dart';
import '../models/exercise.dart';
import '../services/ai_plan_service.dart';
import '../services/guest_storage_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Firebase Sync Service
/// Handles data persistence and synchronization with Firebase Firestore
/// User data: workout history, preferences, micro-cycle logs
/// Cache layer for offline functionality
class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  bool get isAuthenticated => _userId != null;

  /// Initialize Firebase Auth state listener
  void initialize() {
    _auth.authStateChanges().listen((user) {
      debugPrint('Firebase Auth state: ${user?.uid ?? 'signed out'}');
    });
  }

  /// Sign in anonymously to enable data storage
  Future<void> signInAnonymously() async {
    try {
      if (!isAuthenticated) {
        final credential = await _auth.signInAnonymously();
        debugPrint('Signed in anonymously: ${credential.user?.uid}');
      }
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
    }
  }

  /// Ensure user is authenticated (for data operations)
  Future<void> ensureAuthenticated() async {
    if (!isAuthenticated) {
      await signInAnonymously();
    }
  }

  // ============ WORKOUT HISTORY ============

  /// Save completed workout to Firestore
  Future<void> saveCompletedWorkout(CompletedWorkout workout) async {
    if (!isAuthenticated) {
      debugPrint('Cannot save workout: User not authenticated');
      return;
    }

    // Check if user is anonymous (guest mode)
    if (_auth.currentUser?.isAnonymous ?? false) {
      debugPrint('Saving workout locally for guest user');
      await GuestStorageService.saveWorkout(workout);
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .doc(workout.id)
          .set(workout.toMap());

      debugPrint('Workout saved: ${workout.id}');
    } catch (e) {
      debugPrint('Error saving workout: $e');
    }
  }

  /// Get workout history
  Future<List<CompletedWorkout>> getWorkoutHistory({int limit = 50}) async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .orderBy('start_time', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _workoutFromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching workout history: $e');
      return [];
    }
  }

  /// Get workouts for a specific date range (for micro-cycle)
  Future<List<CompletedWorkout>> getWorkoutsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .where('start_time', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('start_time', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('start_time', descending: true)
          .get();

      return snapshot.docs.map((doc) => _workoutFromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching workouts for range: $e');
      return [];
    }
  }

  // ============ DAILY LOGS ============

  /// Save or update daily log
  Future<void> saveDailyLog(DailyLog log) async {
    if (!isAuthenticated) return;

    try {
      final docId = log.date.toIso8601String().split('T')[0]; // YYYY-MM-DD
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('daily_logs')
          .doc(docId)
          .set(log.toMap());

      debugPrint('Daily log saved: $docId');
    } catch (e) {
      debugPrint('Error saving daily log: $e');
    }
  }

  /// Get daily logs for micro-cycle
  Future<List<DailyLog>> getDailyLogsForMicroCycle() async {
    if (!isAuthenticated) return [];

    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('daily_logs')
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => _dailyLogFromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching daily logs: $e');
      return [];
    }
  }

  /// Build micro-cycle from Firestore data
  Future<MicroCycle> buildMicroCycle() async {
    final logs = await getDailyLogsForMicroCycle();

    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));

    return MicroCycle(days: logs, startDate: start, endDate: end);
  }

  // ============ USER PREFERENCES ============

  /// Save user preferences
  Future<void> savePreferences(Map<String, dynamic> preferences) async {
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('preferences')
          .set(preferences, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>> getPreferences() async {
    if (!isAuthenticated) return {};

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('preferences')
          .get();

      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error fetching preferences: $e');
      return {};
    }
  }

  // ============ PHALANX IMPORTED PLANS ============

  /// Save imported workout plan
  Future<void> saveImportedPlan(
    String planId,
    Map<String, dynamic> plan,
  ) async {
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('imported_plans')
          .doc(planId)
          .set({...plan, 'imported_at': DateTime.now().toIso8601String()});
    } catch (e) {
      debugPrint('Error saving imported plan: $e');
    }
  }

  /// Get all imported plans
  Future<List<Map<String, dynamic>>> getImportedPlans() async {
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('imported_plans')
          .orderBy('imported_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching imported plans: $e');
      return [];
    }
  }

  /// Delete imported plan
  Future<void> deleteImportedPlan(String planId) async {
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('imported_plans')
          .doc(planId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting imported plan: $e');
    }
  }

  // ============ REAL-TIME SYNC ============

  /// Stream of workout history for real-time updates
  Stream<List<CompletedWorkout>> workoutHistoryStream({int limit = 50}) {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .orderBy('start_time', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _workoutFromMap(doc.data())).toList(),
        );
  }

  /// Stream of latest daily log
  Stream<DailyLog?> latestDailyLogStream() {
    if (!isAuthenticated) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('daily_logs')
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty
              ? _dailyLogFromMap(snapshot.docs.first.data())
              : null,
        );
  }

  // ============ PARSING HELPERS ============

  CompletedWorkout _workoutFromMap(Map<String, dynamic> map) {
    // Simplified parsing - would be expanded in production
    return CompletedWorkout(
      id: map['id'] ?? '',
      protocolTitle: map['protocol_title'] ?? '',
      exercises: [], // Parse from map['exercises']
      startTime: DateTime.parse(
        map['start_time'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: DateTime.parse(
        map['end_time'] ?? DateTime.now().toIso8601String(),
      ),
      totalDurationMinutes: map['total_duration_minutes'] ?? 0,
      readinessScoreAtStart: map['readiness_score_at_start'] ?? 70,
    );
  }

  DailyLog _dailyLogFromMap(Map<String, dynamic> map) {
    return DailyLog(
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      rpeEntries: (map['rpe_entries'] as List<dynamic>? ?? []).cast<double>(),
      sleepQuality: map['sleep_quality'] ?? 5,
      sleepHours: map['sleep_hours'] ?? 7,
      jointFatigue: (map['joint_fatigue'] as Map<String, dynamic>? ?? {})
          .cast<String, int>(),
      flowState: map['flow_state'] ?? 5,
      readinessScore: map['readiness_score'] ?? 70,
    );
  }

  // ============ USER PROFILE ============

  /// Save user profile to Firestore
  Future<void> saveUserProfile(UserProfile profile) async {
    if (!isAuthenticated) {
      debugPrint('Cannot save profile: User not authenticated');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('profile')
          .doc('main')
          .set(profile.toMap());

      debugPrint('User profile saved');
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  /// Get user profile by ID (for AuthProvider)
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('main')
          .get();

      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile for $userId: $e');
      return null;
    }
  }

  /// Get current user profile (legacy method)
  Future<UserProfile?> getCurrentUserProfile() async {
    if (!isAuthenticated) return null;
    return getUserProfile(_userId!);
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    final profile = await getCurrentUserProfile();
    return profile?.hasCompletedOnboarding ?? false;
  }

  // ============ AI TRAINING PLANS ============

  /// Save AI-generated weekly plan
  Future<void> saveWeeklyPlan(WeeklyPlan plan) async {
    if (!isAuthenticated) return;

    try {
      final weekId =
          '${plan.weekStarting.year}-${plan.weekStarting.month.toString().padLeft(2, '0')}-${plan.weekStarting.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('ai_training_plans')
          .doc(weekId)
          .set(plan.toMap());

      debugPrint('Weekly AI plan saved: $weekId');
    } catch (e) {
      debugPrint('Error saving weekly plan: $e');
    }
  }

  /// Get weekly plan for specific date
  Future<WeeklyPlan?> getWeeklyPlan(DateTime weekStart) async {
    if (!isAuthenticated) return null;

    try {
      final weekId =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('ai_training_plans')
          .doc(weekId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return WeeklyPlan(
          weekStarting: DateTime.parse(data['week_starting']),
          dailyWorkouts: (data['daily_workouts'] as List<dynamic>)
              .map((d) => _dailyWorkoutFromMap(d as Map<String, dynamic>))
              .toList(),
          weeklyNotes: data['weekly_notes'] ?? '',
          intensityRecommendation: data['intensity_recommendation'] ?? '',
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching weekly plan: $e');
      return null;
    }
  }

  /// Get current week's plan
  Future<WeeklyPlan?> getCurrentWeekPlan() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return getWeeklyPlan(weekStart);
  }

  /// Get scheduled workouts for a specific week
  Future<Map<String, dynamic>> getScheduledWorkoutsForWeek(
    DateTime weekStart,
  ) async {
    if (!isAuthenticated) return {};

    try {
      final plan = await getWeeklyPlan(weekStart);
      if (plan == null) return {};

      final scheduled = <String, dynamic>{};
      for (final workout in plan.dailyWorkouts) {
        final dateKey =
            '${workout.day.toLowerCase()}_${weekStart.month}_${weekStart.day}';
        scheduled[dateKey] = {
          'workout_name': workout.protocol.title,
          'workout_type': workout.workoutType,
          'focus': workout.focus,
        };
      }
      return scheduled;
    } catch (e) {
      debugPrint('Error getting scheduled workouts: $e');
      return {};
    }
  }

  // ============ PROGRESS TRACKING ============

  /// Save weekly progress data
  Future<void> saveWeeklyProgress(WeeklyProgress progress) async {
    if (!isAuthenticated) return;

    try {
      final weekId =
          '${progress.weekStarting.year}-${progress.weekStarting.month.toString().padLeft(2, '0')}-${progress.weekStarting.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weekly_progress')
          .doc(weekId)
          .set(progress.toMap());

      debugPrint('Weekly progress saved: $weekId');
    } catch (e) {
      debugPrint('Error saving weekly progress: $e');
    }
  }

  /// Get weekly progress for auto-adjustment
  Future<WeeklyProgress?> getWeeklyProgress(DateTime weekStart) async {
    if (!isAuthenticated) return null;

    try {
      final weekId =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weekly_progress')
          .doc(weekId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return WeeklyProgress(
          weekStarting: DateTime.parse(data['week_starting']),
          workoutsCompleted: data['workouts_completed'] ?? 0,
          totalPlannedWorkouts: data['total_planned_workouts'] ?? 0,
          averageRPE: data['average_rpe']?.toDouble() ?? 0,
          totalVolume: data['total_volume']?.toDouble() ?? 0,
          averageReadiness: data['average_readiness'] ?? 70,
          achievedGoals: data['achieved_goals'] ?? false,
          userFeedback: data['user_feedback'],
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching weekly progress: $e');
      return null;
    }
  }

  // ============ ADDITIONAL PARSERS ============

  DailyWorkout _dailyWorkoutFromMap(Map<String, dynamic> map) {
    return DailyWorkout(
      day: map['day'] ?? 'Monday',
      workoutType: map['workout_type'] ?? 'General',
      focus: map['focus'] ?? '',
      protocol: _protocolFromMap(map['protocol'] ?? {}),
    );
  }

  WorkoutProtocol _protocolFromMap(Map<String, dynamic> map) {
    final entries = (map['entries'] as List<dynamic>? ?? [])
        .map((e) => _protocolEntryFromMap(e as Map<String, dynamic>))
        .toList();

    return WorkoutProtocol(
      title: map['title'] ?? 'Workout',
      subtitle: map['subtitle'] ?? 'Training session',
      tier: ProtocolTier.values.firstWhere(
        (t) => t.toString() == 'ProtocolTier.${map['tier'] ?? 'ready'}',
        orElse: () => ProtocolTier.ready,
      ),
      entries: entries,
      estimatedDurationMinutes: map['estimated_duration_minutes'] ?? 45,
      mindsetPrompt: map['mindset_prompt'] ?? 'Train with discipline',
    );
  }

  ProtocolEntry _protocolEntryFromMap(Map<String, dynamic> map) {
    return ProtocolEntry(
      exercise: Exercise.library.firstWhere(
        (e) =>
            e.name.toLowerCase() == (map['exercise_name'] ?? '').toLowerCase(),
        orElse: () => Exercise.library.first,
      ),
      sets: map['sets'] ?? 3,
      reps: map['reps'] ?? 10,
      intensityRpe: map['rpe']?.toDouble() ?? 7.0,
      restSeconds: map['rest_seconds'] ?? 60,
    );
  }
}
