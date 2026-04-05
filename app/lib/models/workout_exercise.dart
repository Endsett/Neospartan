import 'exercise.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workout_exercise.g.dart';

/// Enhanced exercise model for workout plans with progressive overload tracking
@JsonSerializable()
class WorkoutExercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final int sets;
  final int targetReps;
  final int? targetSeconds; // For timed exercises
  final double targetRpe;
  final int restSeconds;
  final double? suggestedWeight;
  final String notes;
  final ExerciseType type;
  
  // Progressive overload fields
  final double? previousWeight; // Weight used in last session
  final int? previousReps; // Reps completed in last session
  final double? weightIncrease; // Suggested weight increase
  final int? repIncrease; // Suggested rep increase
  final bool isProgressiveOverload; // Flag for progressive overload achievement
  
  // Exercise substitution options
  final List<String> substitutionExerciseIds;
  final List<String> substitutionExerciseNames;
  final String? substitutionReason; // Why substitution is suggested
  
  // Superset/circuit grouping
  final String? supersetGroupId;
  final int? supersetOrder;
  final bool isTimedExercise;
  
  // Equipment and requirements
  final List<String> requiredEquipment;
  final List<String> alternativeEquipment;
  final bool requiresPartner;
  
  // Exercise instructions and media
  final String instructions;
  final String? youtubeId;
  final String? targetMetaphor;

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.sets,
    required this.targetReps,
    this.targetSeconds,
    required this.targetRpe,
    required this.restSeconds,
    this.suggestedWeight,
    this.notes = '',
    required this.type,
    this.previousWeight,
    this.previousReps,
    this.weightIncrease,
    this.repIncrease,
    this.isProgressiveOverload = false,
    this.substitutionExerciseIds = const [],
    this.substitutionExerciseNames = const [],
    this.substitutionReason,
    this.supersetGroupId,
    this.supersetOrder,
    this.isTimedExercise = false,
    this.requiredEquipment = const [],
    this.alternativeEquipment = const [],
    this.requiresPartner = false,
    required this.instructions,
    this.youtubeId,
    this.targetMetaphor,
  });

  factory WorkoutExercise.fromExercise(Exercise exercise, {
    required int sets,
    required int targetReps,
    int? targetSeconds,
    required double targetRpe,
    required int restSeconds,
    double? suggestedWeight,
    String notes = '',
    ExerciseType type = ExerciseType.strength,
    double? previousWeight,
    int? previousReps,
    double? weightIncrease,
    int? repIncrease,
    bool isProgressiveOverload = false,
    List<String> substitutionExerciseIds = const [],
    List<String> substitutionExerciseNames = const [],
    String? substitutionReason,
    String? supersetGroupId,
    int? supersetOrder,
    bool isTimedExercise = false,
    List<String> requiredEquipment = const [],
    List<String> alternativeEquipment = const [],
  }) {
    return WorkoutExercise(
      id: exercise.id,
      name: exercise.name,
      category: exercise.category,
      sets: sets,
      targetReps: targetReps,
      targetSeconds: targetSeconds,
      targetRpe: targetRpe,
      restSeconds: restSeconds,
      suggestedWeight: suggestedWeight,
      notes: notes,
      type: type,
      previousWeight: previousWeight,
      previousReps: previousReps,
      weightIncrease: weightIncrease,
      repIncrease: repIncrease,
      isProgressiveOverload: isProgressiveOverload,
      substitutionExerciseIds: substitutionExerciseIds,
      substitutionExerciseNames: substitutionExerciseNames,
      substitutionReason: substitutionReason,
      supersetGroupId: supersetGroupId,
      supersetOrder: supersetOrder,
      isTimedExercise: isTimedExercise,
      requiredEquipment: requiredEquipment,
      alternativeEquipment: alternativeEquipment,
      requiresPartner: false,
      instructions: exercise.instructions,
      youtubeId: exercise.youtubeId,
      targetMetaphor: exercise.targetMetaphor,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$WorkoutExerciseToJson(this);

  /// Create from JSON
  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);

  /// Create a copy with updated values
  WorkoutExercise copyWith({
    String? id,
    String? name,
    ExerciseCategory? category,
    int? sets,
    int? targetReps,
    int? targetSeconds,
    double? targetRpe,
    int? restSeconds,
    double? suggestedWeight,
    String? notes,
    ExerciseType? type,
    double? previousWeight,
    int? previousReps,
    double? weightIncrease,
    int? repIncrease,
    bool? isProgressiveOverload,
    List<String>? substitutionExerciseIds,
    List<String>? substitutionExerciseNames,
    String? substitutionReason,
    String? supersetGroupId,
    int? supersetOrder,
    bool? isTimedExercise,
    List<String>? requiredEquipment,
    List<String>? alternativeEquipment,
    bool? requiresPartner,
    String? instructions,
    String? youtubeId,
    String? targetMetaphor,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      targetReps: targetReps ?? this.targetReps,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      targetRpe: targetRpe ?? this.targetRpe,
      restSeconds: restSeconds ?? this.restSeconds,
      suggestedWeight: suggestedWeight ?? this.suggestedWeight,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      previousWeight: previousWeight ?? this.previousWeight,
      previousReps: previousReps ?? this.previousReps,
      weightIncrease: weightIncrease ?? this.weightIncrease,
      repIncrease: repIncrease ?? this.repIncrease,
      isProgressiveOverload: isProgressiveOverload ?? this.isProgressiveOverload,
      substitutionExerciseIds: substitutionExerciseIds ?? this.substitutionExerciseIds,
      substitutionExerciseNames: substitutionExerciseNames ?? this.substitutionExerciseNames,
      substitutionReason: substitutionReason ?? this.substitutionReason,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
      supersetOrder: supersetOrder ?? this.supersetOrder,
      isTimedExercise: isTimedExercise ?? this.isTimedExercise,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      alternativeEquipment: alternativeEquipment ?? this.alternativeEquipment,
      requiresPartner: requiresPartner ?? this.requiresPartner,
      instructions: instructions ?? this.instructions,
      youtubeId: youtubeId ?? this.youtubeId,
      targetMetaphor: targetMetaphor ?? this.targetMetaphor,
    );
  }

  /// Get display text for the target (reps or seconds)
  String get targetDisplay {
    if (isTimedExercise && targetSeconds != null) {
      return '${targetSeconds}s';
    }
    return '$targetReps reps';
  }

  /// Get display text for the sets and target
  String get setsAndTargetDisplay => '$sets x $targetDisplay';

  /// Check if this exercise has progressive overload data
  bool get hasProgressiveOverloadData => 
      previousWeight != null || previousReps != null || 
      weightIncrease != null || repIncrease != null;

  /// Check if this exercise has substitution options
  bool get hasSubstitutions => substitutionExerciseIds.isNotEmpty;

  /// Check if this is part of a superset
  bool get isSuperset => supersetGroupId != null;

  /// Get estimated duration in seconds
  int get estimatedDurationSeconds {
    final exerciseTime = isTimedExercise 
        ? (targetSeconds ?? 30) * sets 
        : (targetReps * 3 + restSeconds) * sets; // Rough estimate
    return exerciseTime + (restSeconds * (sets - 1));
  }
}

/// Exercise type for different training modalities
enum ExerciseType {
  strength,
  cardio,
  flexibility,
  balance,
  plyometric,
  isometric,
  explosive,
  endurance,
}

/// Exercise progression status
enum ExerciseProgressionStatus {
  notStarted,
  inProgress,
  completed,
  failed,
  substituted,
}
