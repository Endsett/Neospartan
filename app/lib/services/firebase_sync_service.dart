import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_tracking.dart';

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

  // ============ WORKOUT HISTORY ============

  /// Save completed workout to Firestore
  Future<void> saveCompletedWorkout(CompletedWorkout workout) async {
    if (!isAuthenticated) {
      debugPrint('Cannot save workout: User not authenticated');
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

    return MicroCycle(
      days: logs,
      startDate: start,
      endDate: end,
    );
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
  Future<void> saveImportedPlan(String planId, Map<String, dynamic> plan) async {
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('imported_plans')
          .doc(planId)
          .set({
            ...plan,
            'imported_at': DateTime.now().toIso8601String(),
          });
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
        .map((snapshot) => 
            snapshot.docs.map((doc) => _workoutFromMap(doc.data())).toList());
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
        .map((snapshot) => 
            snapshot.docs.isNotEmpty 
                ? _dailyLogFromMap(snapshot.docs.first.data())
                : null);
  }

  // ============ PARSING HELPERS ============

  CompletedWorkout _workoutFromMap(Map<String, dynamic> map) {
    // Simplified parsing - would be expanded in production
    return CompletedWorkout(
      id: map['id'] ?? '',
      protocolTitle: map['protocol_title'] ?? '',
      exercises: [], // Parse from map['exercises']
      startTime: DateTime.parse(map['start_time'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(map['end_time'] ?? DateTime.now().toIso8601String()),
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
      jointFatigue: (map['joint_fatigue'] as Map<String, dynamic>? ?? {}).cast<String, int>(),
      flowState: map['flow_state'] ?? 5,
      readinessScore: map['readiness_score'] ?? 70,
    );
  }
}
