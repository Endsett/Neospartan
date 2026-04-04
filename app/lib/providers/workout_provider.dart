import 'package:flutter/material.dart';
import '../models/workout_protocol.dart';

class WorkoutProvider with ChangeNotifier {
  WorkoutProtocol? _activeProtocol;
  int _currentEntryIndex = 0;
  bool _isWorkoutActive = false;
  DateTime? _startTime;
  int? _initialReadinessScore;

  WorkoutProtocol? get activeProtocol => _activeProtocol;
  int get currentEntryIndex => _currentEntryIndex;
  bool get isWorkoutActive => _isWorkoutActive;
  DateTime? get activeProtocolStartTime => _startTime;
  int? get initialReadinessScore => _initialReadinessScore;
  
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
    notifyListeners();
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
    notifyListeners();
  }
}
