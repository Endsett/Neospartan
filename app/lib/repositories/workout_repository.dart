import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_tracking.dart';

/// Repository for Workout CRUD operations
class WorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference helper
  CollectionReference<Map<String, dynamic>> _workoutsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('workouts');
  }

  /// Save a completed workout
  Future<bool> saveWorkout(String userId, CompletedWorkout workout) async {
    try {
      await _workoutsCollection(userId).doc(workout.id).set(workout.toMap());

      developer.log('Workout saved: ${workout.id}', name: 'WorkoutRepository');
      return true;
    } catch (e) {
      developer.log('Error saving workout: $e', name: 'WorkoutRepository');
      return false;
    }
  }

  /// Get a specific workout by ID
  Future<CompletedWorkout?> getWorkout(String userId, String workoutId) async {
    try {
      final doc = await _workoutsCollection(userId).doc(workoutId).get();

      if (doc.exists && doc.data() != null) {
        return CompletedWorkout.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      developer.log('Error getting workout: $e', name: 'WorkoutRepository');
      return null;
    }
  }

  /// Get workout history (paginated)
  Future<List<CompletedWorkout>> getWorkoutHistory(
    String userId, {
    int limit = 50,
    String? startAfterId,
  }) async {
    try {
      var query = _workoutsCollection(
        userId,
      ).orderBy('start_time', descending: true).limit(limit);

      if (startAfterId != null) {
        final startAfterDoc = await _workoutsCollection(
          userId,
        ).doc(startAfterId).get();
        if (startAfterDoc.exists) {
          query = query.startAfterDocument(startAfterDoc);
        }
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => CompletedWorkout.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log(
        'Error getting workout history: $e',
        name: 'WorkoutRepository',
      );
      return [];
    }
  }

  /// Get workouts for a date range
  Future<List<CompletedWorkout>> getWorkoutsForDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _workoutsCollection(userId)
          .where('start_time', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('start_time', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('start_time', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CompletedWorkout.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log(
        'Error getting workouts for range: $e',
        name: 'WorkoutRepository',
      );
      return [];
    }
  }

  /// Get workouts for a specific date
  Future<List<CompletedWorkout>> getWorkoutsForDate(
    String userId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getWorkoutsForDateRange(userId, start, end);
  }

  /// Update a workout
  Future<bool> updateWorkout(
    String userId,
    String workoutId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _workoutsCollection(userId).doc(workoutId).update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });

      developer.log('Workout updated: $workoutId', name: 'WorkoutRepository');
      return true;
    } catch (e) {
      developer.log('Error updating workout: $e', name: 'WorkoutRepository');
      return false;
    }
  }

  /// Delete a workout
  Future<bool> deleteWorkout(String userId, String workoutId) async {
    try {
      await _workoutsCollection(userId).doc(workoutId).delete();
      developer.log('Workout deleted: $workoutId', name: 'WorkoutRepository');
      return true;
    } catch (e) {
      developer.log('Error deleting workout: $e', name: 'WorkoutRepository');
      return false;
    }
  }

  /// Get workout count
  Future<int> getWorkoutCount(String userId) async {
    try {
      final snapshot = await _workoutsCollection(userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      developer.log(
        'Error getting workout count: $e',
        name: 'WorkoutRepository',
      );
      return 0;
    }
  }

  /// Stream of workout history for real-time updates
  Stream<List<CompletedWorkout>> workoutHistoryStream(
    String userId, {
    int limit = 20,
  }) {
    return _workoutsCollection(userId)
        .orderBy('start_time', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CompletedWorkout.fromMap(doc.data()))
              .toList();
        });
  }

  /// Stream of today's workout
  Stream<List<CompletedWorkout>> todayWorkoutsStream(String userId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    return _workoutsCollection(userId)
        .where('start_time', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('start_time', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('start_time', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CompletedWorkout.fromMap(doc.data()))
              .toList();
        });
  }

  /// Get total workout volume for a date range
  Future<double> getTotalVolumeForRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final workouts = await getWorkoutsForDateRange(userId, start, end);
      return workouts.fold<double>(0, (total, w) => total + w.totalVolume);
    } catch (e) {
      developer.log(
        'Error getting total volume: $e',
        name: 'WorkoutRepository',
      );
      return 0;
    }
  }

  /// Get exercise history (for tracking PRs and progress)
  Future<List<ExerciseHistoryEntry>> getExerciseHistory(
    String userId,
    String exerciseId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _workoutsCollection(userId)
          .where('exercises', arrayContains: {'exercise_id': exerciseId})
          .orderBy('start_time', descending: true)
          .limit(limit)
          .get();

      final history = <ExerciseHistoryEntry>[];

      for (final doc in snapshot.docs) {
        final workout = CompletedWorkout.fromMap(doc.data());
        for (final exercise in workout.exercises) {
          if (exercise.exerciseId == exerciseId) {
            history.add(
              ExerciseHistoryEntry(
                date: workout.startTime,
                sets: exercise.sets,
                maxWeight: exercise.sets.fold<double>(
                  0,
                  (max, s) => (s.loadUsed ?? 0) > max ? s.loadUsed ?? 0 : max,
                ),
                totalReps: exercise.sets.fold<int>(
                  0,
                  (total, s) => total + (s.repsPerformed ?? 0),
                ),
                avgRpe: exercise.sets.isEmpty
                    ? 0
                    : exercise.sets
                              .map((s) => s.actualRPE ?? 0)
                              .reduce((a, b) => a + b) /
                          exercise.sets.length,
              ),
            );
          }
        }
      }

      return history;
    } catch (e) {
      developer.log(
        'Error getting exercise history: $e',
        name: 'WorkoutRepository',
      );
      return [];
    }
  }
}

/// Helper class for exercise history tracking
class ExerciseHistoryEntry {
  final DateTime date;
  final List<SetPerformance> sets;
  final double maxWeight;
  final int totalReps;
  final double avgRpe;

  ExerciseHistoryEntry({
    required this.date,
    required this.sets,
    required this.maxWeight,
    required this.totalReps,
    required this.avgRpe,
  });
}
