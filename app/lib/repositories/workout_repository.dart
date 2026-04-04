import 'dart:developer' as developer;
import '../models/workout.dart';
import '../services/supabase_database_service.dart';

/// Repository for Workout CRUD operations using Supabase
class WorkoutRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save workout session
  Future<bool> saveWorkout(String userId, CompletedWorkout workout) async {
    try {
      // Save workout session
      final sessionId = await _database.saveWorkoutSession({
        'date': workout.date.toIso8601String(),
        'start_time': workout.startTime?.toIso8601String(),
        'end_time': workout.endTime?.toIso8601String(),
        'workout_type': workout.workoutType,
        'notes': workout.notes,
      });

      // Save workout sets
      if (workout.sets.isNotEmpty) {
        final setsData = workout.sets.map((set) => {
          'exercise_name': set.exerciseName,
          'set_number': set.setNumber,
          'reps_performed': set.repsPerformed,
          'actual_rpe': set.actualRPE,
          'load_used': set.loadUsed,
          'completed': set.completed,
          'notes': set.notes,
        }).toList();

        await _database.saveWorkoutSets(sessionId, setsData);
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
        
        final workout = CompletedWorkout(
          id: session['id'],
          date: DateTime.parse(session['date']),
          startTime: session['start_time'] != null 
              ? DateTime.parse(session['start_time']) 
              : null,
          endTime: session['end_time'] != null 
              ? DateTime.parse(session['end_time']) 
              : null,
          workoutType: session['workout_type'] ?? '',
          notes: session['notes'] ?? '',
          sets: sets.map((setData) => WorkoutSet(
            exerciseName: setData['exercise_name'] ?? '',
            setNumber: setData['set_number'] ?? 1,
            repsPerformed: setData['reps_performed'] ?? 0,
            actualRPE: setData['actual_rpe']?.toDouble() ?? 0.0,
            loadUsed: setData['load_used']?.toDouble() ?? 0.0,
            completed: setData['completed'] ?? false,
            notes: setData['notes'] ?? '',
          )).toList(),
        );
        
        workouts.add(workout);
      }

      return workouts;
    } catch (e) {
      developer.log('Error getting workout history: $e', name: 'WorkoutRepository');
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

      return CompletedWorkout(
        id: session['id'],
        date: DateTime.parse(session['date']),
        startTime: session['start_time'] != null 
            ? DateTime.parse(session['start_time']) 
            : null,
        endTime: session['end_time'] != null 
            ? DateTime.parse(session['end_time']) 
            : null,
        workoutType: session['workout_type'] ?? '',
        notes: session['notes'] ?? '',
        sets: sets.map((setData) => WorkoutSet(
          exerciseName: setData['exercise_name'] ?? '',
          setNumber: setData['set_number'] ?? 1,
          repsPerformed: setData['reps_performed'] ?? 0,
          actualRPE: setData['actual_rpe']?.toDouble() ?? 0.0,
          loadUsed: setData['load_used']?.toDouble() ?? 0.0,
          completed: setData['completed'] ?? false,
          notes: setData['notes'] ?? '',
        )).toList(),
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
        (sum, workout) => sum + workout.sets.length,
      );
      final totalVolume = workouts.fold<double>(
        0.0,
        (sum, workout) => sum + workout.totalVolume,
      );

      return {
        'totalWorkouts': totalWorkouts,
        'totalSets': totalSets,
        'totalVolume': totalVolume,
        'averageRPE': totalSets > 0
            ? workouts.fold<double>(
                0.0,
                (sum, workout) => sum + workout.averageRPE,
              ) / totalWorkouts
            : 0.0,
      };
    } catch (e) {
      developer.log('Error getting workout stats: $e', name: 'WorkoutRepository');
      return {};
    }
  }
}
