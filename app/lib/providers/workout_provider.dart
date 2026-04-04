import 'package:flutter/material.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';

class WorkoutProvider with ChangeNotifier {
  WorkoutProtocol? _activeProtocol;
  int _currentEntryIndex = 0;
  bool _isWorkoutActive = false;
  DateTime? _startTime;
  int? _initialReadinessScore;

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
  void startWorkout(WorkoutProtocol protocol, int readinessScore) {
    _activeProtocol = protocol;
    _currentEntryIndex = 0;
    _isWorkoutActive = true;
    _startTime = DateTime.now();
    _initialReadinessScore = readinessScore;
    _exerciseSets.clear();
    _completedExercises.clear();
    notifyListeners();
  }

  /// Complete current exercise and move to next
  void completeExercise(List<SetPerformance> sets) {
    if (currentEntry == null) return;

    final exerciseName = currentEntry!.exercise.name;
    _exerciseSets[exerciseName] = sets;

    _completedExercises.add(
      CompletedExerciseEntry(
        exercise: currentEntry!.exercise,
        sets: sets,
        completedAt: DateTime.now(),
      ),
    );

    _currentEntryIndex++;
    notifyListeners();
  }

  /// Skip current exercise
  void skipExercise() {
    if (currentEntry == null) return;

    _currentEntryIndex++;
    notifyListeners();
  }

  /// Finish workout
  CompletedWorkout? finishWorkout() {
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

    // Reset state
    _isWorkoutActive = false;
    _activeProtocol = null;
    _currentEntryIndex = 0;
    _startTime = null;
    _initialReadinessScore = null;

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
