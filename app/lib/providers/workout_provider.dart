import 'package:flutter/material.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';
import '../services/state_persistence_service.dart';
import '../services/supabase_database_service.dart';

class WorkoutProvider with ChangeNotifier {
  final StatePersistenceService _persistence = StatePersistenceService();
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  WorkoutProtocol? _activeProtocol;
  int _currentEntryIndex = 0;
  bool _isWorkoutActive = false;
  DateTime? _startTime;
  int? _initialReadinessScore;
  String? _currentSessionId;

  // Set tracking data
  final Map<String, List<SetPerformance>> _exerciseSets = {};
  final List<CompletedExerciseEntry> _completedExercises = [];

  WorkoutProtocol? get activeProtocol => _activeProtocol;
  int get currentEntryIndex => _currentEntryIndex;
  bool get isWorkoutActive => _isWorkoutActive;
  DateTime? get activeProtocolStartTime => _startTime;
  int? get initialReadinessScore => _initialReadinessScore;
  List<CompletedExerciseEntry> get completedExercises => _completedExercises;

  ProtocolEntry? get currentEntry {
    if (_activeProtocol == null ||
        _currentEntryIndex >= _activeProtocol!.entries.length) {
      return null;
    }
    return _activeProtocol!.entries[_currentEntryIndex];
  }

  /// Start a workout protocol
  Future<void> startWorkout(
    WorkoutProtocol protocol,
    int readinessScore,
  ) async {
    _activeProtocol = protocol;
    _currentEntryIndex = 0;
    _isWorkoutActive = true;
    _startTime = DateTime.now();
    _initialReadinessScore = readinessScore;
    _exerciseSets.clear();
    _completedExercises.clear();

    // Persist workout state
    await _persistence.saveWorkoutState(
      protocol: protocol,
      currentEntryIndex: _currentEntryIndex,
      startTime: _startTime!,
      readinessScore: readinessScore,
    );

    // Create session in Supabase
    try {
      _currentSessionId = await _database.saveWorkoutSession({
        'date': _startTime!.toIso8601String(),
        'start_time': _startTime!.toIso8601String(),
        'workout_type': protocol.title,
        'notes': 'readiness:$readinessScore;status:in_progress',
      });
    } catch (e) {
      debugPrint('Error creating workout session: $e');
    }

    notifyListeners();
  }

  /// Complete current exercise and move to next
  Future<void> completeExercise(List<SetPerformance> sets) async {
    if (currentEntry == null) return;

    final exerciseName = currentEntry!.exercise.name;
    _exerciseSets[exerciseName] = sets;

    final completedEntry = CompletedExerciseEntry(
      exercise: currentEntry!.exercise,
      sets: sets,
      completedAt: DateTime.now(),
    );

    _completedExercises.add(completedEntry);

    // Save sets to Supabase in real-time
    if (_currentSessionId != null) {
      for (final set in sets) {
        try {
          await _database.saveWorkoutSet({
            'session_id': _currentSessionId,
            'exercise_name': exerciseName,
            'set_number': set.setNumber,
            'reps_performed': set.repsPerformed,
            'load_used': set.loadUsed,
            'actual_rpe': set.actualRPE,
            'completed': set.completed,
            'notes': set.notes,
            'logged_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Error saving set to Supabase: $e');
        }
      }
    }

    _currentEntryIndex++;

    // Update persisted state
    if (_activeProtocol != null &&
        _startTime != null &&
        _initialReadinessScore != null) {
      await _persistence.saveWorkoutState(
        protocol: _activeProtocol!,
        currentEntryIndex: _currentEntryIndex,
        startTime: _startTime!,
        readinessScore: _initialReadinessScore!,
      );
    }

    notifyListeners();
  }

  /// Skip current exercise
  void skipExercise() {
    if (currentEntry == null) return;

    _currentEntryIndex++;
    notifyListeners();
  }

  /// Finish workout
  Future<CompletedWorkout?> finishWorkout() async {
    if (!_isWorkoutActive || _activeProtocol == null || _startTime == null) {
      return null;
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!).inMinutes;

    final workout = CompletedWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      protocolTitle: _activeProtocol!.title,
      exercises: _completedExercises,
      startTime: _startTime!,
      endTime: endTime,
      totalDurationMinutes: duration,
      readinessScoreAtStart: _initialReadinessScore ?? 70,
    );

    // Update session status in Supabase
    if (_currentSessionId != null) {
      try {
        await _database.saveWorkoutSession({
          'id': _currentSessionId,
          'date': _startTime!.toIso8601String(),
          'start_time': _startTime!.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'workout_type': _activeProtocol!.title,
          'notes':
              'readiness:${_initialReadinessScore ?? 70};duration:$duration;status:completed',
        });
      } catch (e) {
        debugPrint('Error updating workout session: $e');
      }
    }

    try {
      final weekStart = endTime.subtract(Duration(days: endTime.weekday - 1));
      final existing = await _database.getWeeklyProgress(weekStart);

      final previousCompleted =
          (existing?['workouts_completed'] as num?)?.toInt() ?? 0;
      final previousPlanned =
          (existing?['total_planned_workouts'] as num?)?.toInt() ?? 0;
      final previousAverageRpe =
          (existing?['average_rpe'] as num?)?.toDouble() ?? 0;
      final previousTotalVolume =
          (existing?['total_volume'] as num?)?.toDouble() ?? 0;
      final previousAverageReadiness =
          (existing?['average_readiness'] as num?)?.toInt() ?? 0;

      final completedCount = previousCompleted + 1;

      await _database.saveWeeklyProgress({
        'week_starting': weekStart.toIso8601String(),
        'workouts_completed': completedCount,
        'total_planned_workouts': previousPlanned + 1,
        'average_rpe':
            ((previousAverageRpe * previousCompleted) + workout.averageRPE) /
            completedCount,
        'total_volume': previousTotalVolume + workout.totalVolume,
        'average_readiness':
            (((previousAverageReadiness * previousCompleted) +
                        (_initialReadinessScore ?? 70)) /
                    completedCount)
                .round(),
      });
      await _database.saveAnalyticsEvent('workout_completed', {
        'session_id': _currentSessionId,
        'duration_minutes': duration,
        'total_volume': workout.totalVolume,
        'exercise_count': workout.exercises.length,
      });
    } catch (e) {
      debugPrint('Error saving workout progress analytics: $e');
    }

    // Reset state
    _isWorkoutActive = false;
    _activeProtocol = null;
    _currentEntryIndex = 0;
    _startTime = null;
    _initialReadinessScore = null;
    _currentSessionId = null;

    // Clear persisted state
    await _persistence.clearWorkoutState();

    notifyListeners();
    return workout;
  }

  /// Get sets for a specific exercise
  List<SetPerformance> getSetsForExercise(String exerciseName) {
    return _exerciseSets[exerciseName] ?? [];
  }

  /// Update set performance for current exercise
  void updateSetPerformance(int setIndex, SetPerformance performance) {
    if (currentEntry == null) return;

    final exerciseName = currentEntry!.exercise.name;
    if (!_exerciseSets.containsKey(exerciseName)) {
      _exerciseSets[exerciseName] = List.generate(
        currentEntry!.sets,
        (index) => SetPerformance(
          setNumber: index + 1,
          repsPerformed: currentEntry!.reps,
          actualRPE: 7.0,
          loadUsed: 0.0,
        ),
      );
    }

    _exerciseSets[exerciseName]![setIndex] = performance;
    notifyListeners();
  }

  /// Get workout progress percentage
  double get progress {
    if (_activeProtocol == null || _activeProtocol!.entries.isEmpty) {
      return 0.0;
    }
    return _currentEntryIndex / _activeProtocol!.entries.length;
  }

  /// Check if workout is complete
  bool get isWorkoutComplete {
    return _activeProtocol != null &&
        _currentEntryIndex >= _activeProtocol!.entries.length;
  }

  /// Get remaining exercises count
  int get remainingExercises {
    if (_activeProtocol == null) return 0;
    return (_activeProtocol!.entries.length - _currentEntryIndex).clamp(
      0,
      _activeProtocol!.entries.length,
    );
  }

  /// Reset workout state
  void resetWorkout() {
    _isWorkoutActive = false;
    _activeProtocol = null;
    _currentEntryIndex = 0;
    _startTime = null;
    _initialReadinessScore = null;
    _exerciseSets.clear();
    _completedExercises.clear();
    notifyListeners();
  }

  /// Pause workout (for interruptions)
  void pauseWorkout() {
    _isWorkoutActive = false;
    notifyListeners();
  }

  /// Resume paused workout
  void resumeWorkout() {
    if (_activeProtocol != null && _startTime != null) {
      _isWorkoutActive = true;
      notifyListeners();
    }
  }

  /// Get workout summary
  Map<String, dynamic> getWorkoutSummary() {
    if (!_isWorkoutActive || _activeProtocol == null) {
      return {};
    }

    final totalSets = _exerciseSets.values.fold(
      0,
      (sum, sets) => sum + sets.length,
    );
    final completedSets = _exerciseSets.values.fold(
      0,
      (sum, sets) =>
          sum + sets.where((set) => (set.repsPerformed ?? 0) > 0).length,
    );
    final averageRpe =
        _exerciseSets.values
            .expand((sets) => sets)
            .where((set) => set.actualRPE != null && set.actualRPE! > 0)
            .fold<double>(0.0, (sum, set) => sum + set.actualRPE!) /
        (completedSets > 0 ? completedSets : 1);

    return {
      'protocolTitle': _activeProtocol!.title,
      'exercisesCompleted': _completedExercises.length,
      'totalExercises': _activeProtocol!.entries.length,
      'totalSets': totalSets,
      'completedSets': completedSets,
      'averageRpe': averageRpe.toStringAsFixed(1),
      'duration': _startTime != null
          ? DateTime.now().difference(_startTime!).inMinutes
          : 0,
    };
  }

  /// Move to next exercise
  void nextExercise() {
    if (_currentEntryIndex < (_activeProtocol?.entries.length ?? 0) - 1) {
      _currentEntryIndex++;
      notifyListeners();
    }
  }

  /// Cancel current workout
  void cancelWorkout() {
    _activeProtocol = null;
    _currentEntryIndex = 0;
    _isWorkoutActive = false;
    _startTime = null;
    _initialReadinessScore = null;
    _exerciseSets.clear();
    _completedExercises.clear();
    notifyListeners();
  }
}
