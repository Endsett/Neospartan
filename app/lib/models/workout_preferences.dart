import 'exercise.dart';

/// Training focus types for workout customization
enum TrainingFocus {
  strength,
  conditioning,
  mixed,
  technique,
  hypertrophy,
  power,
  endurance,
}

/// User preferences for AI workout plan generation
class WorkoutPreferences {
  final String? id;
  final String userId;
  final int targetIntensity; // 1-10 scale
  final int targetDurationMinutes; // 20-90 minutes
  final List<ExerciseCategory> preferredCategories;
  final TrainingFocus trainingFocus;
  final int preferredExerciseCount; // 3-8 exercises
  final int setsPerExercise; // 2-6 sets
  final bool includeCardio;
  final bool includeMobility;
  final String? specificFocus; // e.g., "upper body", "explosive power"
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutPreferences({
    this.id,
    required this.userId,
    this.targetIntensity = 7,
    this.targetDurationMinutes = 45,
    this.preferredCategories = const [],
    this.trainingFocus = TrainingFocus.mixed,
    this.preferredExerciseCount = 5,
    this.setsPerExercise = 3,
    this.includeCardio = false,
    this.includeMobility = true,
    this.specificFocus,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Default preferences for new users
  factory WorkoutPreferences.defaultPrefs(String userId) {
    final now = DateTime.now();
    return WorkoutPreferences(
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Serialize to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'target_intensity': targetIntensity,
      'target_duration_minutes': targetDurationMinutes,
      'preferred_categories': preferredCategories.map((c) => c.name).toList(),
      'training_focus': trainingFocus.name,
      'preferred_exercise_count': preferredExerciseCount,
      'sets_per_exercise': setsPerExercise,
      'include_cardio': includeCardio,
      'include_mobility': includeMobility,
      'specific_focus': specificFocus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Deserialize from Map
  factory WorkoutPreferences.fromMap(Map<String, dynamic> map) {
    return WorkoutPreferences(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      targetIntensity: map['target_intensity'] as int? ?? 7,
      targetDurationMinutes: map['target_duration_minutes'] as int? ?? 45,
      preferredCategories: (map['preferred_categories'] as List<dynamic>?)
              ?.map((c) => ExerciseCategory.values.firstWhere(
                    (e) => e.name == c,
                    orElse: () => ExerciseCategory.strength,
                  ))
              .toList() ??
          [],
      trainingFocus: TrainingFocus.values.firstWhere(
        (t) => t.name == map['training_focus'],
        orElse: () => TrainingFocus.mixed,
      ),
      preferredExerciseCount: map['preferred_exercise_count'] as int? ?? 5,
      setsPerExercise: map['sets_per_exercise'] as int? ?? 3,
      includeCardio: map['include_cardio'] as bool? ?? false,
      includeMobility: map['include_mobility'] as bool? ?? true,
      specificFocus: map['specific_focus'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Create a copy with updated fields
  WorkoutPreferences copyWith({
    String? id,
    String? userId,
    int? targetIntensity,
    int? targetDurationMinutes,
    List<ExerciseCategory>? preferredCategories,
    TrainingFocus? trainingFocus,
    int? preferredExerciseCount,
    int? setsPerExercise,
    bool? includeCardio,
    bool? includeMobility,
    String? specificFocus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetIntensity: targetIntensity ?? this.targetIntensity,
      targetDurationMinutes: targetDurationMinutes ?? this.targetDurationMinutes,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      trainingFocus: trainingFocus ?? this.trainingFocus,
      preferredExerciseCount: preferredExerciseCount ?? this.preferredExerciseCount,
      setsPerExercise: setsPerExercise ?? this.setsPerExercise,
      includeCardio: includeCardio ?? this.includeCardio,
      includeMobility: includeMobility ?? this.includeMobility,
      specificFocus: specificFocus ?? this.specificFocus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get human-readable training focus label
  String get trainingFocusLabel {
    switch (trainingFocus) {
      case TrainingFocus.strength:
        return 'Strength';
      case TrainingFocus.conditioning:
        return 'Conditioning';
      case TrainingFocus.mixed:
        return 'Mixed Training';
      case TrainingFocus.technique:
        return 'Technique';
      case TrainingFocus.hypertrophy:
        return 'Muscle Building';
      case TrainingFocus.power:
        return 'Power';
      case TrainingFocus.endurance:
        return 'Endurance';
    }
  }

  /// Get intensity label
  String get intensityLabel {
    if (targetIntensity <= 2) return 'Recovery';
    if (targetIntensity <= 4) return 'Light';
    if (targetIntensity <= 6) return 'Moderate';
    if (targetIntensity <= 8) return 'Hard';
    return 'Maximum';
  }

  /// Get estimated total sets
  int get estimatedTotalSets => preferredExerciseCount * setsPerExercise;

  /// Get estimated time per exercise (including rest)
  int get estimatedTimePerExercise {
    // Rough estimate: 30s per set + rest based on intensity
    final restPerSet = targetIntensity > 7 ? 90 : (targetIntensity > 5 ? 60 : 45);
    return (30 + restPerSet) * setsPerExercise;
  }

  /// Validate preferences
  bool get isValid {
    return targetIntensity >= 1 && 
           targetIntensity <= 10 &&
           targetDurationMinutes >= 20 && 
           targetDurationMinutes <= 90 &&
           preferredExerciseCount >= 3 && 
           preferredExerciseCount <= 8 &&
           setsPerExercise >= 2 && 
           setsPerExercise <= 6;
  }
}
