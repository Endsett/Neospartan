import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../repositories/exercise_repository.dart';

/// Provider for Exercise Library state management
class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _repository = ExerciseRepository();

  // State
  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  ExerciseCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Exercise> get exercises => _exercises;
  List<Exercise> get filteredExercises => _filteredExercises;
  ExerciseCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Categories for filter chips
  List<ExerciseCategory> get categories => ExerciseCategory.values;

  /// Load all exercises from database
  Future<void> loadExercises() async {
    _setLoading(true);
    _clearError();

    try {
      _exercises = await _repository.getAllExercises();
      _filteredExercises = List.from(_exercises);
      developer.log('Loaded ${_exercises.length} exercises', name: 'ExerciseProvider');
    } catch (e) {
      _setError('Failed to load exercises: $e');
      developer.log('Error loading exercises: $e', name: 'ExerciseProvider');
    } finally {
      _setLoading(false);
    }
  }

  /// Filter exercises by category
  void filterByCategory(ExerciseCategory? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Search exercises by name
  Future<void> search(String query) async {
    _searchQuery = query;
    _setLoading(true);

    try {
      if (query.isEmpty) {
        await loadExercises();
      } else {
        _filteredExercises = await _repository.searchExercises(query);
      }
    } catch (e) {
      _setError('Search failed: $e');
    } finally {
      _setLoading(false);
    }

    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _filteredExercises = List.from(_exercises);
    notifyListeners();
  }

  /// Get exercises suitable for user profile
  Future<void> loadExercisesForUser(
    UserProfile profile, {
    String? workoutType,
    int limit = 120,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _filteredExercises = await _repository.getExercisesForUserProfile(
        profile,
        workoutType: workoutType,
        limit: limit,
      );
      developer.log(
        'Loaded ${_filteredExercises.length} exercises for user',
        name: 'ExerciseProvider',
      );
    } catch (e) {
      _setError('Failed to load exercises: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Apply current filters to exercise list
  void _applyFilters() {
    var filtered = List<Exercise>.from(_exercises);

    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) =>
        e.name.toLowerCase().contains(query) ||
        e.instructions.toLowerCase().contains(query) ||
        e.targetMetaphor.toLowerCase().contains(query)
      ).toList();
    }

    _filteredExercises = filtered;
  }

  // State helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Get category display name
  String getCategoryName(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.plyometric:
        return 'Plyometric';
      case ExerciseCategory.isometric:
        return 'Isometric';
      case ExerciseCategory.combat:
        return 'Combat';
      case ExerciseCategory.strength:
        return 'Strength';
      case ExerciseCategory.mobility:
        return 'Mobility';
      case ExerciseCategory.sprint:
        return 'Sprint';
    }
  }

  /// Get category icon
  IconData getCategoryIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.plyometric:
        return Icons.trending_up;
      case ExerciseCategory.isometric:
        return Icons.access_time;
      case ExerciseCategory.combat:
        return Icons.sports_mma;
      case ExerciseCategory.strength:
        return Icons.fitness_center;
      case ExerciseCategory.mobility:
        return Icons.self_improvement;
      case ExerciseCategory.sprint:
        return Icons.speed;
    }
  }

  /// Get category color
  Color getCategoryColor(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.plyometric:
        return Colors.orange;
      case ExerciseCategory.isometric:
        return Colors.blue;
      case ExerciseCategory.combat:
        return Colors.red;
      case ExerciseCategory.strength:
        return Colors.purple;
      case ExerciseCategory.mobility:
        return Colors.green;
      case ExerciseCategory.sprint:
        return Colors.teal;
    }
  }

  /// Get intensity stars display
  String getIntensityStars(int level) {
    return '★' * level + '☆' * (10 - level);
  }
}
