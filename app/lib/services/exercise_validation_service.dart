import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../repositories/exercise_repository.dart';

/// Service for validating AI-generated exercises and managing exercise database sync
class ExerciseValidationService {
  final ExerciseRepository _exerciseRepo = ExerciseRepository();
  final _uuid = const Uuid();

  /// Validate a list of exercise names and resolve them to actual Exercise objects
  /// If an exercise doesn't exist, it will be created with AI-generated metadata
  Future<List<Exercise>> validateAndResolveExercises(
    List<String> exerciseNames, {
    List<ExerciseCategory>? preferredCategories,
  }) async {
    final resolvedExercises = <Exercise>[];

    for (final name in exerciseNames) {
      final exercise = await _resolveExercise(name, preferredCategories);
      if (exercise != null) {
        resolvedExercises.add(exercise);
      }
    }

    return resolvedExercises;
  }

  /// Resolve a single exercise name to an Exercise object
  Future<Exercise?> _resolveExercise(
    String name,
    List<ExerciseCategory>? preferredCategories,
  ) async {
    // First, try exact match
    final allExercises = await _exerciseRepo.getAllExercises();

    final exactMatch = allExercises.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Exercise(
        id: '',
        name: '',
        category: ExerciseCategory.strength,
        youtubeId: '',
        targetMetaphor: '',
        instructions: '',
      ),
    );

    if (exactMatch.name.isNotEmpty) {
      developer.log(
        'Exercise found (exact match): ${exactMatch.name}',
        name: 'ExerciseValidationService',
      );
      return exactMatch;
    }

    // Try fuzzy match (contains)
    final fuzzyMatch = allExercises.firstWhere(
      (e) =>
          e.name.toLowerCase().contains(name.toLowerCase()) ||
          name.toLowerCase().contains(e.name.toLowerCase()),
      orElse: () => Exercise(
        id: '',
        name: '',
        category: ExerciseCategory.strength,
        youtubeId: '',
        targetMetaphor: '',
        instructions: '',
      ),
    );

    if (fuzzyMatch.name.isNotEmpty) {
      developer.log(
        'Exercise found (fuzzy match): ${fuzzyMatch.name} for "$name"',
        name: 'ExerciseValidationService',
      );
      return fuzzyMatch;
    }

    // Exercise not found - create it
    developer.log(
      'Creating new exercise: $name',
      name: 'ExerciseValidationService',
    );
    return await _createNewExercise(name, preferredCategories);
  }

  /// Create a new exercise in the database with AI-generated attributes
  Future<Exercise?> _createNewExercise(
    String name,
    List<ExerciseCategory>? preferredCategories,
  ) async {
    try {
      // Infer category from name or use preferred
      final category = _inferCategory(name, preferredCategories);

      // Generate ID
      final id = 'ex_${_uuid.v4().substring(0, 8)}';

      // Create exercise with basic metadata
      final exercise = Exercise(
        id: id,
        name: name,
        category: category,
        youtubeId: '',
        targetMetaphor: _generateMetaphor(name),
        instructions: _generateBasicInstructions(name),
        intensityLevel: _inferIntensity(name),
        primaryMuscles: _inferMuscles(name),
        jointStress: const {},
        idealGoals: const [],
        minFitnessLevel: FitnessLevel.beginner,
        maxFitnessLevel: FitnessLevel.advanced,
        workoutTags: _generateTags(name, category),
      );

      // Save to Supabase
      final success = await _exerciseRepo.saveExercise(exercise);

      if (success) {
        developer.log(
          'New exercise created: ${exercise.name} (${exercise.id})',
          name: 'ExerciseValidationService',
        );
        return exercise;
      } else {
        developer.log(
          'Failed to save new exercise: $name',
          name: 'ExerciseValidationService',
        );
        return null;
      }
    } catch (e) {
      developer.log(
        'Error creating new exercise: $e',
        name: 'ExerciseValidationService',
      );
      return null;
    }
  }

  /// Find similar exercises based on name similarity
  Future<List<Exercise>> findSimilarExercises(
    String name, {
    int limit = 3,
  }) async {
    final allExercises = await _exerciseRepo.getAllExercises();
    final searchLower = name.toLowerCase();

    // Score exercises by similarity
    final scored = allExercises.map((e) {
      final nameLower = e.name.toLowerCase();
      int score = 0;

      // Exact match
      if (nameLower == searchLower) score += 100;
      // Contains
      if (nameLower.contains(searchLower)) score += 50;
      if (searchLower.contains(nameLower)) score += 40;
      // Word overlap
      final searchWords = searchLower.split(' ');
      final exerciseWords = nameLower.split(' ');
      for (final word in searchWords) {
        if (word.length > 2 && exerciseWords.any((ew) => ew.contains(word))) {
          score += 20;
        }
      }

      return (exercise: e, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored
        .where((s) => s.score > 0)
        .take(limit)
        .map((s) => s.exercise)
        .toList();
  }

  /// Infer exercise category from name
  ExerciseCategory _inferCategory(
    String name,
    List<ExerciseCategory>? preferred,
  ) {
    final lower = name.toLowerCase();

    if (preferred != null && preferred.isNotEmpty) {
      return preferred.first;
    }

    if (lower.contains('sprint') || lower.contains('run')) {
      return ExerciseCategory.sprint;
    }
    if (lower.contains('jump') ||
        lower.contains('plyo') ||
        lower.contains('box')) {
      return ExerciseCategory.plyometric;
    }
    if (lower.contains('hold') ||
        lower.contains('plank') ||
        lower.contains('static')) {
      return ExerciseCategory.isometric;
    }
    if (lower.contains('punch') ||
        lower.contains('kick') ||
        lower.contains('combat') ||
        lower.contains('strike') ||
        lower.contains('bag')) {
      return ExerciseCategory.combat;
    }
    if (lower.contains('stretch') ||
        lower.contains('mobility') ||
        lower.contains('flex')) {
      return ExerciseCategory.mobility;
    }

    return ExerciseCategory.strength;
  }

  /// Infer intensity level from exercise name
  int _inferIntensity(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('max') ||
        lower.contains('heavy') ||
        lower.contains('sprint')) {
      return 9;
    }
    if (lower.contains('power') || lower.contains('explosive')) return 8;
    if (lower.contains('strength') || lower.contains('compound')) return 7;
    if (lower.contains('hypertrophy') || lower.contains('bodybuilding')) {
      return 6;
    }
    if (lower.contains('conditioning') || lower.contains('circuit')) return 5;
    if (lower.contains('endurance') || lower.contains('moderate')) return 4;
    if (lower.contains('light') || lower.contains('recovery')) return 3;
    if (lower.contains('stretch') || lower.contains('mobility')) return 2;

    return 5; // Default moderate
  }

  /// Infer primary muscles from exercise name
  List<String> _inferMuscles(String name) {
    final lower = name.toLowerCase();
    final muscles = <String>[];

    if (lower.contains('squat') ||
        lower.contains('lunge') ||
        lower.contains('leg')) {
      muscles.addAll(['Quadriceps', 'Glutes', 'Hamstrings']);
    }
    if (lower.contains('deadlift') || lower.contains('hinge')) {
      muscles.addAll(['Hamstrings', 'Glutes', 'Lower Back']);
    }
    if (lower.contains('push') ||
        lower.contains('press') ||
        lower.contains('chest')) {
      muscles.addAll(['Chest', 'Shoulders', 'Triceps']);
    }
    if (lower.contains('pull') ||
        lower.contains('row') ||
        lower.contains('back')) {
      muscles.addAll(['Lats', 'Rhomboids', 'Biceps']);
    }
    if (lower.contains('curl')) muscles.add('Biceps');
    if (lower.contains('extension') && !lower.contains('back')) {
      muscles.add('Triceps');
    }
    if (lower.contains('raise')) muscles.add('Shoulders');
    if (lower.contains('core') ||
        lower.contains('ab') ||
        lower.contains('plank')) {
      muscles.addAll(['Core', 'Abdominals']);
    }
    if (lower.contains('calf')) muscles.add('Calves');

    return muscles.isEmpty ? ['Full Body'] : muscles;
  }

  /// Generate a metaphor based on exercise name
  String _generateMetaphor(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('squat')) return 'The Foundation of Power';
    if (lower.contains('deadlift')) return 'The Armor-Bearer\'s Lift';
    if (lower.contains('press')) return 'The Shield Push';
    if (lower.contains('pull')) return 'Drawing the Bow';
    if (lower.contains('lunge')) return 'The Warrior\'s Advance';
    if (lower.contains('plank')) return 'The Unbreakable Line';
    if (lower.contains('sprint')) return 'The Charge of Leonidas';
    if (lower.contains('burpee')) return 'Rise from the Dust';

    return 'Forge Your Strength';
  }

  /// Generate basic instructions for the exercise
  String _generateBasicInstructions(String name) {
    return 'Perform $name with proper form and controlled movement. Maintain core engagement throughout. Adjust intensity based on your fitness level.';
  }

  /// Generate workout tags based on name and category
  List<String> _generateTags(String name, ExerciseCategory category) {
    final tags = <String>[category.name];
    final lower = name.toLowerCase();

    if (lower.contains('compound')) tags.add('compound');
    if (lower.contains('isolation')) tags.add('isolation');
    if (lower.contains('bodyweight')) tags.add('bodyweight');
    if (lower.contains('dumbbell')) tags.add('dumbbell');
    if (lower.contains('barbell')) tags.add('barbell');
    if (lower.contains('kettlebell')) tags.add('kettlebell');
    if (lower.contains('cardio')) tags.add('cardio');
    if (lower.contains('hiit')) tags.add('hiit');

    return tags;
  }
}
