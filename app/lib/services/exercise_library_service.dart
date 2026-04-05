import '../data/combat_exercise_library.dart';
import '../models/equipment_type.dart';
import '../models/movement_pattern.dart';
import '../models/sport_category.dart';
import '../models/exercise.dart' hide ExerciseCategory;

/// Service for searching and filtering the exercise library
class ExerciseLibraryService {
  /// Get all exercises
  static List<CombatExercise> get allExercises =>
      CombatExerciseLibrary.exercises;

  /// Get exercise count
  static int get exerciseCount => CombatExerciseLibrary.exercises.length;

  /// Search exercises by name
  static List<CombatExercise> searchByName(String query) {
    if (query.isEmpty) return allExercises;
    final lowerQuery = query.toLowerCase();
    return allExercises
        .where((e) => e.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Filter by sport category
  static List<CombatExercise> filterBySport(SportCategory sport) {
    return allExercises.where((e) => e.sports.contains(sport)).toList();
  }

  /// Filter by equipment type
  static List<CombatExercise> filterByEquipment(EquipmentType equipment) {
    return allExercises.where((e) => e.equipment.contains(equipment)).toList();
  }

  /// Filter by movement pattern
  static List<CombatExercise> filterByMovementPattern(MovementPattern pattern) {
    return allExercises
        .where((e) => e.movementPatterns.contains(pattern))
        .toList();
  }

  /// Filter by exercise category
  static List<CombatExercise> filterByCategory(ExerciseCategory category) {
    return allExercises.where((e) => e.category == category).toList();
  }

  /// Filter by intensity level range
  static List<CombatExercise> filterByIntensity(int min, int max) {
    return allExercises
        .where((e) => e.intensityLevel >= min && e.intensityLevel <= max)
        .toList();
  }

  /// Filter by workout tags
  static List<CombatExercise> filterByTag(String tag) {
    final lowerTag = tag.toLowerCase();
    return allExercises
        .where(
          (e) => e.workoutTags.any((t) => t.toLowerCase().contains(lowerTag)),
        )
        .toList();
  }

  /// Filter by primary muscle group
  static List<CombatExercise> filterByMuscle(String muscle) {
    final lowerMuscle = muscle.toLowerCase();
    return allExercises
        .where(
          (e) => e.primaryMuscles.any(
            (m) => m.toLowerCase().contains(lowerMuscle),
          ),
        )
        .toList();
  }

  /// Filter bodyweight only exercises
  static List<CombatExercise> get bodyweightOnly =>
      filterByEquipment(EquipmentType.bodyweight);

  /// Filter partner required exercises
  static List<CombatExercise> get partnerRequired =>
      allExercises.where((e) => e.requiresPartner).toList();

  /// Filter sport-specific exercises
  static List<CombatExercise> get sportSpecific =>
      allExercises.where((e) => e.isSportSpecific).toList();

  /// Get exercises by skill focus
  static List<CombatExercise> filterBySkillFocus(String focus) {
    final lowerFocus = focus.toLowerCase();
    return allExercises
        .where(
          (e) => e.skillFocus.any((s) => s.toLowerCase().contains(lowerFocus)),
        )
        .toList();
  }

  /// Combined search with multiple filters
  static List<CombatExercise> advancedSearch({
    String? nameQuery,
    SportCategory? sport,
    EquipmentType? equipment,
    MovementPattern? pattern,
    ExerciseCategory? category,
    int? minIntensity,
    int? maxIntensity,
    String? tag,
    String? muscle,
    bool? requiresPartner,
    bool? isSportSpecific,
  }) {
    var results = allExercises;

    if (nameQuery != null && nameQuery.isNotEmpty) {
      final lowerQuery = nameQuery.toLowerCase();
      results = results
          .where((e) => e.name.toLowerCase().contains(lowerQuery))
          .toList();
    }

    if (sport != null) {
      results = results.where((e) => e.sports.contains(sport)).toList();
    }

    if (equipment != null) {
      results = results.where((e) => e.equipment.contains(equipment)).toList();
    }

    if (pattern != null) {
      results = results
          .where((e) => e.movementPatterns.contains(pattern))
          .toList();
    }

    if (category != null) {
      results = results.where((e) => e.category == category).toList();
    }

    if (minIntensity != null) {
      results = results.where((e) => e.intensityLevel >= minIntensity).toList();
    }

    if (maxIntensity != null) {
      results = results.where((e) => e.intensityLevel <= maxIntensity).toList();
    }

    if (tag != null && tag.isNotEmpty) {
      final lowerTag = tag.toLowerCase();
      results = results
          .where(
            (e) => e.workoutTags.any((t) => t.toLowerCase().contains(lowerTag)),
          )
          .toList();
    }

    if (muscle != null && muscle.isNotEmpty) {
      final lowerMuscle = muscle.toLowerCase();
      results = results
          .where(
            (e) => e.primaryMuscles.any(
              (m) => m.toLowerCase().contains(lowerMuscle),
            ),
          )
          .toList();
    }

    if (requiresPartner != null) {
      results = results
          .where((e) => e.requiresPartner == requiresPartner)
          .toList();
    }

    if (isSportSpecific != null) {
      results = results
          .where((e) => e.isSportSpecific == isSportSpecific)
          .toList();
    }

    return results;
  }

  /// Get random exercise
  static CombatExercise getRandom() {
    return (allExercises..shuffle()).first;
  }

  /// Get random exercises for a workout
  static List<CombatExercise> getRandomWorkout(
    int count, {
    SportCategory? sport,
  }) {
    var pool = sport != null ? filterBySport(sport) : allExercises;
    return (pool..shuffle()).take(count).toList();
  }

  /// Get exercises sorted by intensity
  static List<CombatExercise> get sortedByIntensity {
    return [...allExercises]
      ..sort((a, b) => b.intensityLevel.compareTo(a.intensityLevel));
  }

  /// Get exercises sorted by duration
  static List<CombatExercise> get sortedByDuration {
    return [...allExercises]..sort(
      (a, b) =>
          a.estimatedDurationSeconds.compareTo(b.estimatedDurationSeconds),
    );
  }

  /// Get all unique tags
  static Set<String> get allTags {
    return allExercises.expand((e) => e.workoutTags).toSet();
  }

  /// Get all unique muscles
  static Set<String> get allMuscles {
    return allExercises.expand((e) => e.primaryMuscles).toSet();
  }

  /// Get exercise by ID
  static CombatExercise? getById(String id) {
    return CombatExerciseLibrary.getById(id);
  }

  /// Get exercises by list of IDs
  static List<CombatExercise> getByIds(List<String> ids) {
    return ids
        .map((id) => getById(id))
        .where((e) => e != null)
        .cast<CombatExercise>()
        .toList();
  }
}
