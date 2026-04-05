import 'workout_exercise.dart';
import '../services/workout_plan_storage_service.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workout_plan_enhanced.g.dart';

/// Enhanced daily workout plan with JSON serialization and advanced features
@JsonSerializable()
class EnhancedDailyWorkoutPlan {
  final String id;
  final String day;
  final String workoutType;
  final String focus;
  final List<WorkoutExercise> exercises;
  final int estimatedDurationMinutes;
  final String mindsetPrompt;
  final bool isRestDay;

  // Enhanced fields
  final WorkoutIntensity intensity;
  final List<String> workoutTags;
  final Map<String, dynamic> aiGenerationContext;
  final double aiConfidenceScore;
  final DateTime generatedAt;
  final String? weeklyPlanId;

  // Warm-up and cool-down
  final List<WorkoutExercise> warmupExercises;
  final List<WorkoutExercise> cooldownExercises;
  final int warmupDurationMinutes;
  final int cooldownDurationMinutes;

  // Equipment requirements
  final List<String> requiredEquipment;
  final List<String> optionalEquipment;
  final bool canBeDoneWithBodyweight;

  // Performance tracking
  final Map<String, dynamic> previousPerformance;
  final List<String> progressiveOverloadNotes;

  const EnhancedDailyWorkoutPlan({
    required this.id,
    required this.day,
    required this.workoutType,
    required this.focus,
    required this.exercises,
    required this.estimatedDurationMinutes,
    required this.mindsetPrompt,
    this.isRestDay = false,
    required this.intensity,
    this.workoutTags = const [],
    required this.aiGenerationContext,
    required this.aiConfidenceScore,
    required this.generatedAt,
    this.weeklyPlanId,
    this.warmupExercises = const [],
    this.cooldownExercises = const [],
    this.warmupDurationMinutes = 5,
    this.cooldownDurationMinutes = 5,
    this.requiredEquipment = const [],
    this.optionalEquipment = const [],
    this.canBeDoneWithBodyweight = false,
    this.previousPerformance = const {},
    this.progressiveOverloadNotes = const [],
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$EnhancedDailyWorkoutPlanToJson(this);

  /// Create from JSON
  factory EnhancedDailyWorkoutPlan.fromJson(Map<String, dynamic> json) =>
      _$EnhancedDailyWorkoutPlanFromJson(json);

  /// Convert from existing DailyWorkoutPlan
  factory EnhancedDailyWorkoutPlan.fromLegacy(DailyWorkoutPlan legacy) {
    return EnhancedDailyWorkoutPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      day: legacy.day,
      workoutType: legacy.workoutType,
      focus: legacy.focus,
      exercises: legacy.exercises
          .map(
            (e) => WorkoutExercise.fromExercise(
              e.exercise,
              sets: e.sets,
              targetReps: e.targetReps,
              targetRpe: e.targetRpe,
              restSeconds: e.restSeconds,
              suggestedWeight: e.suggestedWeight,
              notes: e.notes,
            ),
          )
          .toList(),
      estimatedDurationMinutes: legacy.estimatedDurationMinutes,
      mindsetPrompt: legacy.mindsetPrompt,
      isRestDay: legacy.isRestDay,
      intensity: WorkoutIntensity.moderate,
      aiGenerationContext: {},
      aiConfidenceScore: 0.8,
      generatedAt: DateTime.now(),
    );
  }

  /// Get total duration including warm-up and cool-down
  int get totalDurationMinutes =>
      warmupDurationMinutes +
      estimatedDurationMinutes +
      cooldownDurationMinutes;

  /// Check if workout has any equipment requirements
  bool get requiresEquipment =>
      requiredEquipment.isNotEmpty || optionalEquipment.isNotEmpty;

  /// Get all exercises including warm-up and cool-down
  List<WorkoutExercise> get allExercises => [
    ...warmupExercises,
    ...exercises,
    ...cooldownExercises,
  ];

  /// Get exercises grouped by superset
  Map<String?, List<WorkoutExercise>> get exercisesBySuperset {
    final Map<String?, List<WorkoutExercise>> grouped = {};

    for (final exercise in allExercises) {
      final key = exercise.supersetGroupId;
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(exercise);
    }

    return grouped;
  }

  /// Check if this workout has progressive overload opportunities
  bool get hasProgressiveOverload =>
      exercises.any((e) => e.hasProgressiveOverloadData) ||
      progressiveOverloadNotes.isNotEmpty;

  /// Create a copy with updated values
  EnhancedDailyWorkoutPlan copyWith({
    String? id,
    String? day,
    String? workoutType,
    String? focus,
    List<WorkoutExercise>? exercises,
    int? estimatedDurationMinutes,
    String? mindsetPrompt,
    bool? isRestDay,
    WorkoutIntensity? intensity,
    List<String>? workoutTags,
    Map<String, dynamic>? aiGenerationContext,
    double? aiConfidenceScore,
    DateTime? generatedAt,
    String? weeklyPlanId,
    List<WorkoutExercise>? warmupExercises,
    List<WorkoutExercise>? cooldownExercises,
    int? warmupDurationMinutes,
    int? cooldownDurationMinutes,
    List<String>? requiredEquipment,
    List<String>? optionalEquipment,
    bool? canBeDoneWithBodyweight,
    Map<String, dynamic>? previousPerformance,
    List<String>? progressiveOverloadNotes,
  }) {
    return EnhancedDailyWorkoutPlan(
      id: id ?? this.id,
      day: day ?? this.day,
      workoutType: workoutType ?? this.workoutType,
      focus: focus ?? this.focus,
      exercises: exercises ?? this.exercises,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      mindsetPrompt: mindsetPrompt ?? this.mindsetPrompt,
      isRestDay: isRestDay ?? this.isRestDay,
      intensity: intensity ?? this.intensity,
      workoutTags: workoutTags ?? this.workoutTags,
      aiGenerationContext: aiGenerationContext ?? this.aiGenerationContext,
      aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
      generatedAt: generatedAt ?? this.generatedAt,
      weeklyPlanId: weeklyPlanId ?? this.weeklyPlanId,
      warmupExercises: warmupExercises ?? this.warmupExercises,
      cooldownExercises: cooldownExercises ?? this.cooldownExercises,
      warmupDurationMinutes:
          warmupDurationMinutes ?? this.warmupDurationMinutes,
      cooldownDurationMinutes:
          cooldownDurationMinutes ?? this.cooldownDurationMinutes,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      optionalEquipment: optionalEquipment ?? this.optionalEquipment,
      canBeDoneWithBodyweight:
          canBeDoneWithBodyweight ?? this.canBeDoneWithBodyweight,
      previousPerformance: previousPerformance ?? this.previousPerformance,
      progressiveOverloadNotes:
          progressiveOverloadNotes ?? this.progressiveOverloadNotes,
    );
  }
}

/// Workout intensity levels
enum WorkoutIntensity { recovery, light, moderate, hard, maximum }

/// Weekly workout plan with enhanced features
@JsonSerializable()
class EnhancedWeeklyPlan {
  final String id;
  final DateTime weekStarting;
  final List<EnhancedDailyWorkoutPlan> dailyWorkouts;
  final String weeklyNotes;
  final String intensityRecommendation;
  final String profileId;
  final DateTime createdAt;

  // Enhanced fields
  final Map<String, dynamic> weeklyGoals;
  final List<String> focusAreas;
  final double overallIntensity;
  final List<String> weeklyProgressionNotes;
  final Map<String, dynamic> aiWeeklyInsights;

  const EnhancedWeeklyPlan({
    required this.id,
    required this.weekStarting,
    required this.dailyWorkouts,
    required this.weeklyNotes,
    required this.intensityRecommendation,
    required this.profileId,
    required this.createdAt,
    this.weeklyGoals = const {},
    this.focusAreas = const [],
    this.overallIntensity = 0.7,
    this.weeklyProgressionNotes = const [],
    this.aiWeeklyInsights = const {},
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$EnhancedWeeklyPlanToJson(this);

  /// Create from JSON
  factory EnhancedWeeklyPlan.fromJson(Map<String, dynamic> json) =>
      _$EnhancedWeeklyPlanFromJson(json);

  /// Get workout for specific day
  EnhancedDailyWorkoutPlan? getWorkoutForDay(String day) {
    try {
      return dailyWorkouts.firstWhere(
        (w) => w.day.toLowerCase() == day.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get total workout days for the week
  int get totalWorkoutDays => dailyWorkouts.where((w) => !w.isRestDay).length;

  /// Get total estimated workout time for the week
  int get totalWeeklyMinutes =>
      dailyWorkouts.fold(0, (sum, w) => sum + w.totalDurationMinutes);

  /// Create a copy with updated values
  EnhancedWeeklyPlan copyWith({
    String? id,
    DateTime? weekStarting,
    List<EnhancedDailyWorkoutPlan>? dailyWorkouts,
    String? weeklyNotes,
    String? intensityRecommendation,
    String? profileId,
    DateTime? createdAt,
    Map<String, dynamic>? weeklyGoals,
    List<String>? focusAreas,
    double? overallIntensity,
    List<String>? weeklyProgressionNotes,
    Map<String, dynamic>? aiWeeklyInsights,
  }) {
    return EnhancedWeeklyPlan(
      id: id ?? this.id,
      weekStarting: weekStarting ?? this.weekStarting,
      dailyWorkouts: dailyWorkouts ?? this.dailyWorkouts,
      weeklyNotes: weeklyNotes ?? this.weeklyNotes,
      intensityRecommendation:
          intensityRecommendation ?? this.intensityRecommendation,
      profileId: profileId ?? this.profileId,
      createdAt: createdAt ?? this.createdAt,
      weeklyGoals: weeklyGoals ?? this.weeklyGoals,
      focusAreas: focusAreas ?? this.focusAreas,
      overallIntensity: overallIntensity ?? this.overallIntensity,
      weeklyProgressionNotes:
          weeklyProgressionNotes ?? this.weeklyProgressionNotes,
      aiWeeklyInsights: aiWeeklyInsights ?? this.aiWeeklyInsights,
    );
  }
}
