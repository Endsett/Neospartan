import 'dart:developer' as developer;
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../services/supabase_database_service.dart';
import '../config/supabase_config.dart';

/// Repository for Exercise CRUD operations using Supabase
class ExerciseRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  static const String _tableName = 'exercises';

  /// Get all exercises from the database
  Future<List<Exercise>> getAllExercises() async {
    try {
      final data = await _database.executeQuery(_tableName, orderBy: 'name');
      return data.map((e) => Exercise.fromSupabase(e)).toList();
    } catch (e) {
      developer.log(
        'Error getting all exercises: $e',
        name: 'ExerciseRepository',
      );
      return [];
    }
  }

  /// Get exercises by category
  Future<List<Exercise>> getExercisesByCategory(
    ExerciseCategory category,
  ) async {
    try {
      final data = await _database.executeQuery(
        _tableName,
        eq: {'category': category.name},
        orderBy: 'name',
      );
      return data.map((e) => Exercise.fromSupabase(e)).toList();
    } catch (e) {
      developer.log(
        'Error getting exercises by category: $e',
        name: 'ExerciseRepository',
      );
      return [];
    }
  }

  /// Get exercise by ID
  Future<Exercise?> getExerciseById(String id) async {
    try {
      final data = await _database.executeQuery(_tableName, eq: {'id': id});
      if (data.isNotEmpty) {
        return Exercise.fromSupabase(data.first);
      }
      return null;
    } catch (e) {
      developer.log(
        'Error getting exercise by ID: $e',
        name: 'ExerciseRepository',
      );
      return null;
    }
  }

  /// Search exercises by name using ILIKE (case-insensitive)
  Future<List<Exercise>> searchExercises(String query) async {
    try {
      final supabase = SupabaseConfig.client;
      final response = await supabase
          .from(_tableName)
          .select()
          .ilike('name', '%$query%')
          .order('name');
      return List<Map<String, dynamic>>.from(
        response,
      ).map((e) => Exercise.fromSupabase(e)).toList();
    } catch (e) {
      developer.log(
        'Error searching exercises: $e',
        name: 'ExerciseRepository',
      );
      return [];
    }
  }

  /// Get exercises filtered by multiple criteria
  Future<List<Exercise>> getFilteredExercises({
    ExerciseCategory? category,
    int? minIntensity,
    int? maxIntensity,
    String? muscle,
    List<String>? tags,
  }) async {
    try {
      final allExercises = await getAllExercises();

      var exercises = allExercises;

      if (category != null) {
        exercises = exercises.where((e) => e.category == category).toList();
      }

      if (minIntensity != null) {
        exercises = exercises
            .where((e) => e.intensityLevel >= minIntensity)
            .toList();
      }

      if (maxIntensity != null) {
        exercises = exercises
            .where((e) => e.intensityLevel <= maxIntensity)
            .toList();
      }

      if (muscle != null && muscle.isNotEmpty) {
        final muscleLower = muscle.toLowerCase();
        exercises = exercises
            .where(
              (e) => e.primaryMuscles.any(
                (m) => m.toLowerCase().contains(muscleLower),
              ),
            )
            .toList();
      }

      if (tags != null && tags.isNotEmpty) {
        final tagSet = tags.map((t) => t.toLowerCase()).toSet();
        exercises = exercises
            .where(
              (e) => e.workoutTags.any(
                (tag) => tagSet.contains(tag.toLowerCase()),
              ),
            )
            .toList();
      }

      return exercises;
    } catch (e) {
      developer.log(
        'Error getting filtered exercises: $e',
        name: 'ExerciseRepository',
      );
      return [];
    }
  }

  /// Get exercises suitable for a user profile
  Future<List<Exercise>> getExercisesForUserProfile(
    UserProfile profile, {
    String? workoutType,
    int limit = 120,
  }) async {
    try {
      final allExercises = await getAllExercises();

      final normalizedWorkoutType = workoutType?.toLowerCase();
      final limitations =
          profile.injuriesOrLimitations?.map((e) => e.toLowerCase()).toList() ??
          const [];

      var filtered = allExercises.where((exercise) {
        final fitsGoal =
            exercise.idealGoals.isEmpty ||
            exercise.idealGoals.contains(profile.trainingGoal);
        final fitsLevel =
            profile.fitnessLevel.index >= exercise.minFitnessLevel.index &&
            profile.fitnessLevel.index <= exercise.maxFitnessLevel.index;
        final fitsWorkoutType =
            normalizedWorkoutType == null ||
            normalizedWorkoutType.isEmpty ||
            exercise.workoutTags.any(
              (tag) => normalizedWorkoutType.contains(tag.toLowerCase()),
            );

        final conflictsWithLimitation = limitations.any((limitation) {
          return exercise.primaryMuscles.any(
                (muscle) => muscle.toLowerCase().contains(limitation),
              ) ||
              exercise.jointStress.keys.any(
                (joint) => joint.toLowerCase().contains(limitation),
              ) ||
              exercise.instructions.toLowerCase().contains(limitation);
        });

        return fitsGoal &&
            fitsLevel &&
            fitsWorkoutType &&
            !conflictsWithLimitation;
      }).toList();

      if (filtered.isEmpty) {
        filtered = allExercises.take(limit).toList();
      }

      filtered.sort((a, b) => a.intensityLevel.compareTo(b.intensityLevel));
      return filtered.take(limit).toList();
    } catch (e) {
      developer.log(
        'Error getting exercises for user profile: $e',
        name: 'ExerciseRepository',
      );
      return [];
    }
  }

  /// Save or update exercise (admin only)
  Future<bool> saveExercise(Exercise exercise) async {
    try {
      final supabase = SupabaseConfig.client;
      await supabase.from(_tableName).upsert(exercise.toSupabase());
      developer.log(
        'Exercise saved: ${exercise.id}',
        name: 'ExerciseRepository',
      );
      return true;
    } catch (e) {
      developer.log('Error saving exercise: $e', name: 'ExerciseRepository');
      return false;
    }
  }

  /// Delete exercise (admin only)
  Future<bool> deleteExercise(String id) async {
    try {
      await _database.deleteRecord(_tableName, id);
      developer.log('Exercise deleted: $id', name: 'ExerciseRepository');
      return true;
    } catch (e) {
      developer.log('Error deleting exercise: $e', name: 'ExerciseRepository');
      return false;
    }
  }

  /// Get all available muscle groups
  Future<List<String>> getMuscleGroups() async {
    try {
      final exercises = await getAllExercises();
      final muscles = <String>{};
      for (final exercise in exercises) {
        muscles.addAll(exercise.primaryMuscles);
      }
      return muscles.toList()..sort();
    } catch (e) {
      developer.log(
        'Error getting muscle groups: $e',
        name: 'ExerciseRepository',
      );
      return [];
    }
  }

  /// Get all available workout tags
  Future<List<String>> getWorkoutTags() async {
    try {
      final exercises = await getAllExercises();
      final tags = <String>{};
      for (final exercise in exercises) {
        tags.addAll(exercise.workoutTags);
      }
      return tags.toList()..sort();
    } catch (e) {
      developer.log(
        'Error getting workout tags: $e',
        name: 'ExerciseRepository',
      );
      return [];
    }
  }

  /// Count total exercises
  Future<int> countExercises() async {
    try {
      final exercises = await getAllExercises();
      return exercises.length;
    } catch (e) {
      developer.log('Error counting exercises: $e', name: 'ExerciseRepository');
      return 0;
    }
  }
}
