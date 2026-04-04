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
    if (_activeProtocol == null || _currentEntryIndex >= _activeProtocol!.entries.length) {
      return null;
    }
    return _activeProtocol!.entries[_currentEntryIndex];
  }

  void startWorkout(WorkoutProtocol protocol, {int? readinessScore}) {
    _activeProtocol = protocol;
    _currentEntryIndex = 0;
    _isWorkoutActive = true;
    _startTime = DateTime.now();
    _initialReadinessScore = readinessScore;
    _exerciseSets.clear();
    _completedExercises.clear();
    notifyListeners();
  }

  /// Log a completed set for the current exercise
  void logSet(SetPerformance performance) {
    final current = currentEntry;
    if (current == null) return;
    
    final exerciseId = current.exercise.id;
    if (!_exerciseSets.containsKey(exerciseId)) {
      _exerciseSets[exerciseId] = [];
    }
    _exerciseSets[exerciseId]!.add(performance);
    notifyListeners();
  }

  /// Get sets logged for current exercise
  List<SetPerformance> getCurrentExerciseSets() {
    final current = currentEntry;
    if (current == null) return [];
    return _exerciseSets[current.exercise.id] ?? [];
  }

  /// Complete current exercise and move to next
  void completeCurrentExercise() {
    final current = currentEntry;
    if (current == null) return;
    
    final exerciseId = current.exercise.id;
    final sets = _exerciseSets[exerciseId] ?? [];
    
    if (sets.isNotEmpty) {
      _completedExercises.add(CompletedExerciseEntry(
        exerciseId: exerciseId,
        exerciseName: current.exercise.name,
        sets: sets,
        startTime: DateTime.now().subtract(Duration(minutes: sets.length * 3)), // Estimate
        endTime: DateTime.now(),
        targetSets: current.sets,
        targetReps: current.reps,
        targetRPE: current.intensityRpe,
      ));
    }
    
    nextExercise();
  }

  void nextExercise() {
    if (_activeProtocol != null && _currentEntryIndex < _activeProtocol!.entries.length - 1) {
      _currentEntryIndex++;
      notifyListeners();
    } else {
      finishWorkout();
    }
  }

  void finishWorkout() {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      debugPrint("Workout finished in ${duration.inMinutes} minutes.");
    }
    _isWorkoutActive = false;
    _activeProtocol = null;
    _currentEntryIndex = 0;
    notifyListeners();
  }

  void cancelWorkout() {
    _isWorkoutActive = false;
    _activeProtocol = null;
    _currentEntryIndex = 0;
    _exerciseSets.clear();
    _completedExercises.clear();
    notifyListeners();
  }
}
