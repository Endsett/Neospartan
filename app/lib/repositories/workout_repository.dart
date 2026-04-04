import 'dart:developer' as developer;
import '../models/workout_tracking.dart';
import '../models/exercise.dart';
import '../services/supabase_database_service.dart';

/// Repository for Workout CRUD operations using Supabase
class WorkoutRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save workout session
  Future<bool> saveWorkout(String userId, CompletedWorkout workout) async {
    try {
      // Save workout session
      final sessionId = await _database.saveWorkoutSession({
        'date': workout.startTime.toIso8601String(),
        'start_time': workout.startTime.toIso8601String(),
        'end_time': workout.endTime.toIso8601String(),
        'protocol_title': workout.protocolTitle,
        'total_duration_minutes': workout.totalDurationMinutes,
        'readiness_score_at_start': workout.readinessScoreAtStart,
      });

      // Save workout sets
      if (workout.exercises.isNotEmpty) {
        final allSets = <Map<String, dynamic>>[];

        for (final exercise in workout.exercises) {
          for (final set in exercise.sets) {
            allSets.add({
              'exercise_name': exercise.exerciseName,
              'set_number': set.setNumber,
              'reps_performed': set.repsPerformed,
              'actual_rpe': set.actualRPE,
              'load_used': set.loadUsed,
              'completed': set.completed,
              'notes': set.notes,
            });
          }
        }

        await _database.saveWorkoutSets(sessionId, allSets);
      }

      developer.log('Workout saved successfully', name: 'WorkoutRepository');
      return true;
    } catch (e) {
      developer.log('Error saving workout: $e', name: 'WorkoutRepository');
      return false;
    }
  }

  /// Get workout history for a user
  Future<List<CompletedWorkout>> getWorkoutHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final sessions = await _database.getWorkoutSessions(
        startDate: startDate,
        endDate: endDate,
        limit: limit ?? 50,
      );

      final workouts = <CompletedWorkout>[];

      for (final session in sessions) {
        final sets = await _database.getWorkoutSets(session['id']);

        // Group sets by exercise
        final exerciseMap = <String, List<Map<String, dynamic>>>{};
        for (final set in sets) {
          final exerciseName = set['exercise_name'] ?? '';
          if (!exerciseMap.containsKey(exerciseName)) {
            exerciseMap[exerciseName] = [];
          }
          exerciseMap[exerciseName]!.add(set);
        }

        // Create CompletedExerciseEntry objects
        final exercises = exerciseMap.entries.map((entry) {
          return CompletedExerciseEntry(
            exercise: Exercise(
              id: entry.key,
              name: entry.key,
              category: ExerciseCategory.strength,
              youtubeId: '',
              targetMetaphor: '',
              instructions: '',
            ),
            sets: entry.value
                .map(
                  (setData) => SetPerformance(
                    setNumber: setData['set_number'] ?? 1,
                    repsPerformed: setData['reps_performed'] ?? 0,
                    actualRPE: setData['actual_rpe']?.toDouble(),
                    loadUsed: setData['load_used']?.toDouble(),
                    completed: setData['completed'] ?? false,
                    notes: setData['notes'] ?? '',
                  ),
                )
                .toList(),
            completedAt: DateTime.now(),
          );
        }).toList();

        final workout = CompletedWorkout(
          id: session['id'],
          protocolTitle: session['protocol_title'] ?? '',
          exercises: exercises,
          startTime: DateTime.parse(session['start_time']),
          endTime: DateTime.parse(session['end_time']),
          totalDurationMinutes: session['total_duration_minutes'] ?? 0,
          readinessScoreAtStart: session['readiness_score_at_start'] ?? 0,
        );

        workouts.add(workout);
      }

      return workouts;
    } catch (e) {
      developer.log(
        'Error getting workout history: $e',
        name: 'WorkoutRepository',
      );
      return [];
    }
  }

  /// Get a single workout by ID
  Future<CompletedWorkout?> getWorkoutById(String workoutId) async {
    try {
      final sessions = await _database.executeQuery(
        'workout_sessions',
        eq: {'id': workoutId},
        limit: 1,
      );

      if (sessions.isEmpty) return null;

      final session = sessions.first;
      final sets = await _database.getWorkoutSets(session['id']);

      // Group sets by exercise
      final exerciseMap = <String, List<Map<String, dynamic>>>{};
      for (final set in sets) {
        final exerciseName = set['exercise_name'] ?? '';
        if (!exerciseMap.containsKey(exerciseName)) {
          exerciseMap[exerciseName] = [];
        }
        exerciseMap[exerciseName]!.add(set);
      }

      // Create CompletedExerciseEntry objects
      final exercises = exerciseMap.entries.map((entry) {
        return CompletedExerciseEntry(
          exercise: Exercise(
            id: entry.key,
            name: entry.key,
            category: ExerciseCategory.strength,
            youtubeId: '',
            targetMetaphor: '',
            instructions: '',
          ),
          sets: entry.value
              .map(
                (setData) => SetPerformance(
                  setNumber: setData['set_number'] ?? 1,
                  repsPerformed: setData['reps_performed'] ?? 0,
                  actualRPE: setData['actual_rpe']?.toDouble(),
                  loadUsed: setData['load_used']?.toDouble(),
                  completed: setData['completed'] ?? false,
                  notes: setData['notes'] ?? '',
                ),
              )
              .toList(),
          completedAt: DateTime.now(),
        );
      }).toList();

      return CompletedWorkout(
        id: session['id'],
        protocolTitle: session['protocol_title'] ?? '',
        exercises: exercises,
        startTime: DateTime.parse(session['start_time']),
        endTime: DateTime.parse(session['end_time']),
        totalDurationMinutes: session['total_duration_minutes'] ?? 0,
        readinessScoreAtStart: session['readiness_score_at_start'] ?? 0,
      );
    } catch (e) {
      developer.log('Error getting workout: $e', name: 'WorkoutRepository');
      return null;
    }
  }

  /// Delete workout
  Future<bool> deleteWorkout(String workoutId) async {
    try {
      await _database.deleteRecord('workout_sessions', workoutId);
      developer.log('Workout deleted successfully', name: 'WorkoutRepository');
      return true;
    } catch (e) {
      developer.log('Error deleting workout: $e', name: 'WorkoutRepository');
      return false;
    }
  }

  /// Get workout stats for a user
  Future<Map<String, dynamic>> getWorkoutStats(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final workouts = await getWorkoutHistory(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      final totalWorkouts = workouts.length;
      final totalSets = workouts.fold<int>(
        0,
        (sum, workout) =>
            sum +
            workout.exercises.fold(
              0,
              (exerciseSum, exercise) => exerciseSum + exercise.sets.length,
            ),
      );
      final totalVolume = workouts.fold<double>(
        0.0,
        (sum, workout) => sum + workout.totalVolume,
      );

      return {
        'totalWorkouts': totalWorkouts,
        'totalSets': totalSets,
        'totalVolume': totalVolume,
        'averageRPE': totalWorkouts > 0
            ? workouts.fold<double>(
                    0.0,
                    (sum, workout) => sum + workout.averageRPE,
                  ) /
                  totalWorkouts
            : 0.0,
      };
    } catch (e) {
      developer.log(
        'Error getting workout stats: $e',
        name: 'WorkoutRepository',
      );
      return {};
    }
  }
}
