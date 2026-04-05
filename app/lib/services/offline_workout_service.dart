import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_tracking.dart';
import '../models/workout_plan_enhanced.dart';
import '../models/user_profile.dart';

/// Service for handling offline workout data storage and synchronization
class OfflineWorkoutService {
  static final OfflineWorkoutService _instance =
      OfflineWorkoutService._internal();
  factory OfflineWorkoutService() => _instance;
  OfflineWorkoutService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // Storage keys
  static const String _pendingWorkoutsKey = 'pending_workouts_v2';
  static const String _cachedWorkoutsKey = 'cached_workouts_v2';
  static const String _syncQueueKey = 'sync_queue_v2';
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    developer.log('OfflineWorkoutService initialized', name: 'OfflineWorkout');
  }

  /// Save workout data locally when offline
  Future<void> saveWorkoutOffline({
    required CompletedWorkout workout,
    required UserProfile profile,
    Map<String, dynamic>? workoutPlan,
  }) async {
    await initialize();

    final offlineWorkout = OfflineWorkoutData(
      id: workout.id,
      workout: workout,
      profileId: profile.userId,
      workoutPlan: workoutPlan,
      timestamp: DateTime.now(),
      synced: false,
    );

    // Add to pending workouts
    final pending = await getPendingWorkouts();
    pending.add(offlineWorkout);

    // Keep only last 50 pending workouts locally
    if (pending.length > 50) {
      pending.removeRange(0, pending.length - 50);
    }

    await _prefs?.setString(
      _pendingWorkoutsKey,
      jsonEncode(pending.map((w) => w.toMap()).toList()),
    );

    developer.log(
      'Workout saved offline: ${workout.id}',
      name: 'OfflineWorkout',
    );
  }

  /// Cache workout plan for offline access
  Future<void> cacheWorkoutPlan(EnhancedDailyWorkoutPlan plan) async {
    await initialize();

    final cached = await getCachedWorkouts();

    // Remove existing plan for same day if exists
    cached.removeWhere((p) => p.day == plan.day);

    // Add new plan
    cached.add(plan);

    // Keep only last 30 days of cached workouts
    if (cached.length > 30) {
      cached.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      cached.removeRange(30, cached.length);
    }

    await _prefs?.setString(
      _cachedWorkoutsKey,
      jsonEncode(cached.map((p) => p.toJson()).toList()),
    );

    developer.log('Workout plan cached: ${plan.day}', name: 'OfflineWorkout');
  }

  /// Get cached workout plan for today
  Future<EnhancedDailyWorkoutPlan?> getTodaysCachedWorkout() async {
    await initialize();

    final cached = await getCachedWorkouts();
    final today = DateTime.now().weekday;

    try {
      return cached.firstWhere((plan) {
        final planDay = _getWeekdayNumber(plan.day);
        return planDay == today;
      });
    } catch (e) {
      return null;
    }
  }

  /// Get all pending workouts
  Future<List<OfflineWorkoutData>> getPendingWorkouts() async {
    await initialize();

    final json = _prefs?.getString(_pendingWorkoutsKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((w) => OfflineWorkoutData.fromMap(w)).toList();
    } catch (e) {
      developer.log(
        'Error loading pending workouts: $e',
        name: 'OfflineWorkout',
      );
      return [];
    }
  }

  /// Get all cached workouts
  Future<List<EnhancedDailyWorkoutPlan>> getCachedWorkouts() async {
    await initialize();

    final json = _prefs?.getString(_cachedWorkoutsKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((p) => EnhancedDailyWorkoutPlan.fromJson(p)).toList();
    } catch (e) {
      developer.log(
        'Error loading cached workouts: $e',
        name: 'OfflineWorkout',
      );
      return [];
    }
  }

  /// Sync all pending data to Supabase
  Future<SyncResult> syncPendingData() async {
    await initialize();

    final pending = await getPendingWorkouts();
    if (pending.isEmpty) {
      return SyncResult(success: true, syncedCount: 0, errors: []);
    }

    int syncedCount = 0;
    final errors = <String>[];
    final remainingPending = <OfflineWorkoutData>[];

    for (final workoutData in pending) {
      try {
        // Sync to Supabase
        await _syncWorkoutToSupabase(workoutData);

        // Mark as synced
        syncedCount++;

        developer.log(
          'Workout synced successfully: ${workoutData.id}',
          name: 'OfflineWorkout',
        );
      } catch (e) {
        errors.add('Failed to sync ${workoutData.id}: $e');
        remainingPending.add(workoutData);

        developer.log(
          'Failed to sync workout ${workoutData.id}: $e',
          name: 'OfflineWorkout',
          level: 1000,
        );
      }
    }

    // Update pending list with only failed items
    await _prefs?.setString(
      _pendingWorkoutsKey,
      jsonEncode(remainingPending.map((w) => w.toMap()).toList()),
    );

    // Update last sync timestamp
    await _updateLastSyncTimestamp();

    return SyncResult(
      success: errors.isEmpty,
      syncedCount: syncedCount,
      errors: errors,
    );
  }

  /// Check if there are pending workouts to sync
  Future<bool> hasPendingWorkouts() async {
    final pending = await getPendingWorkouts();
    return pending.isNotEmpty;
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    await initialize();

    final timestamp = _prefs?.getString(_lastSyncKey);
    return timestamp != null ? DateTime.tryParse(timestamp) : null;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await initialize();

    await _prefs?.remove(_cachedWorkoutsKey);
    await _prefs?.remove(_syncQueueKey);

    developer.log('Cache cleared', name: 'OfflineWorkout');
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    await initialize();

    final pending = await getPendingWorkouts();
    final cached = await getCachedWorkouts();
    final lastSync = await getLastSyncTimestamp();

    return {
      'pendingWorkouts': pending.length,
      'cachedWorkouts': cached.length,
      'lastSync': lastSync?.toIso8601String(),
      'storageSize': await _calculateStorageSize(),
    };
  }

  Future<void> _syncWorkoutToSupabase(OfflineWorkoutData workoutData) async {
    // Save completed workout
    await Supabase.instance.client.from('workout_sessions').insert({
      'user_id': workoutData.profileId,
      'date': workoutData.workout.startTime.toIso8601String().split('T')[0],
      'start_time': workoutData.workout.startTime.toIso8601String(),
      'end_time': workoutData.workout.endTime.toIso8601String(),
      'workout_type': workoutData.workout.protocolTitle,
      'notes': 'Offline workout synced on ${DateTime.now().toIso8601String()}',
    });

    // Save workout sets
    for (final exercise in workoutData.workout.exercises) {
      for (final set in exercise.sets) {
        await Supabase.instance.client.from('workout_sets').insert({
          'user_id': workoutData.profileId,
          'exercise_name': exercise.exercise.name,
          'set_number': set.setNumber,
          'reps_performed': set.repsPerformed,
          'actual_rpe': set.actualRPE,
          'load_used': set.loadUsed,
          'completed': set.completed,
          'notes': set.notes,
        });
      }
    }

    // Store in exercise performance history
    for (final exercise in workoutData.workout.exercises) {
      await Supabase.instance.client
          .from('exercise_performance_history')
          .insert({
            'user_id': workoutData.profileId,
            'exercise_id': exercise.exercise.id,
            'exercise_name': exercise.exercise.name,
            'performance_rating': workoutData.workout.averageRPE.round(),
            'perceived_difficulty':
                workoutData.workout.totalVolume /
                workoutData.workout.exercises.length,
            'would_repeat': workoutData.workout.averageRPE < 8.0,
            'completed_at': workoutData.workout.endTime.toIso8601String(),
          });
    }
  }

  Future<void> _updateLastSyncTimestamp() async {
    await _prefs?.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  int _getWeekdayNumber(String dayName) {
    final days = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return days[dayName] ?? 1;
  }

  Future<int> _calculateStorageSize() async {
    final keys = [_pendingWorkoutsKey, _cachedWorkoutsKey, _syncQueueKey];
    int totalSize = 0;

    for (final key in keys) {
      final value = _prefs?.getString(key);
      if (value != null) {
        totalSize += value.length;
      }
    }

    return totalSize;
  }
}

/// Offline workout data container
class OfflineWorkoutData {
  final String id;
  final CompletedWorkout workout;
  final String profileId;
  final Map<String, dynamic>? workoutPlan;
  final DateTime timestamp;
  final bool synced;

  const OfflineWorkoutData({
    required this.id,
    required this.workout,
    required this.profileId,
    this.workoutPlan,
    required this.timestamp,
    required this.synced,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout': workout.toMap(),
      'profileId': profileId,
      'workoutPlan': workoutPlan,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
    };
  }

  factory OfflineWorkoutData.fromMap(Map<String, dynamic> map) {
    return OfflineWorkoutData(
      id: map['id'] ?? '',
      workout: CompletedWorkout.fromMap(map['workout']),
      profileId: map['profileId'] ?? '',
      workoutPlan: map['workoutPlan'],
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      synced: map['synced'] ?? false,
    );
  }
}

/// Sync result container
class SyncResult {
  final bool success;
  final int syncedCount;
  final List<String> errors;

  const SyncResult({
    required this.success,
    required this.syncedCount,
    required this.errors,
  });
}
