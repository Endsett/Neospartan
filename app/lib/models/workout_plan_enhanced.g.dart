// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_plan_enhanced.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnhancedDailyWorkoutPlan _$EnhancedDailyWorkoutPlanFromJson(
  Map<String, dynamic> json,
) => EnhancedDailyWorkoutPlan(
  id: json['id'] as String,
  day: json['day'] as String,
  workoutType: json['workoutType'] as String,
  focus: json['focus'] as String,
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
      .toList(),
  estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num).toInt(),
  mindsetPrompt: json['mindsetPrompt'] as String,
  isRestDay: json['isRestDay'] as bool? ?? false,
  intensity: $enumDecode(_$WorkoutIntensityEnumMap, json['intensity']),
  workoutTags:
      (json['workoutTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  aiGenerationContext: json['aiGenerationContext'] as Map<String, dynamic>,
  aiConfidenceScore: (json['aiConfidenceScore'] as num).toDouble(),
  generatedAt: DateTime.parse(json['generatedAt'] as String),
  weeklyPlanId: json['weeklyPlanId'] as String?,
  warmupExercises:
      (json['warmupExercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  cooldownExercises:
      (json['cooldownExercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  warmupDurationMinutes: (json['warmupDurationMinutes'] as num?)?.toInt() ?? 5,
  cooldownDurationMinutes:
      (json['cooldownDurationMinutes'] as num?)?.toInt() ?? 5,
  requiredEquipment:
      (json['requiredEquipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  optionalEquipment:
      (json['optionalEquipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  canBeDoneWithBodyweight: json['canBeDoneWithBodyweight'] as bool? ?? false,
  previousPerformance:
      json['previousPerformance'] as Map<String, dynamic>? ?? const {},
  progressiveOverloadNotes:
      (json['progressiveOverloadNotes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$EnhancedDailyWorkoutPlanToJson(
  EnhancedDailyWorkoutPlan instance,
) => <String, dynamic>{
  'id': instance.id,
  'day': instance.day,
  'workoutType': instance.workoutType,
  'focus': instance.focus,
  'exercises': instance.exercises,
  'estimatedDurationMinutes': instance.estimatedDurationMinutes,
  'mindsetPrompt': instance.mindsetPrompt,
  'isRestDay': instance.isRestDay,
  'intensity': _$WorkoutIntensityEnumMap[instance.intensity]!,
  'workoutTags': instance.workoutTags,
  'aiGenerationContext': instance.aiGenerationContext,
  'aiConfidenceScore': instance.aiConfidenceScore,
  'generatedAt': instance.generatedAt.toIso8601String(),
  'weeklyPlanId': instance.weeklyPlanId,
  'warmupExercises': instance.warmupExercises,
  'cooldownExercises': instance.cooldownExercises,
  'warmupDurationMinutes': instance.warmupDurationMinutes,
  'cooldownDurationMinutes': instance.cooldownDurationMinutes,
  'requiredEquipment': instance.requiredEquipment,
  'optionalEquipment': instance.optionalEquipment,
  'canBeDoneWithBodyweight': instance.canBeDoneWithBodyweight,
  'previousPerformance': instance.previousPerformance,
  'progressiveOverloadNotes': instance.progressiveOverloadNotes,
};

const _$WorkoutIntensityEnumMap = {
  WorkoutIntensity.recovery: 'recovery',
  WorkoutIntensity.light: 'light',
  WorkoutIntensity.moderate: 'moderate',
  WorkoutIntensity.hard: 'hard',
  WorkoutIntensity.maximum: 'maximum',
};

EnhancedWeeklyPlan _$EnhancedWeeklyPlanFromJson(Map<String, dynamic> json) =>
    EnhancedWeeklyPlan(
      id: json['id'] as String,
      weekStarting: DateTime.parse(json['weekStarting'] as String),
      dailyWorkouts: (json['dailyWorkouts'] as List<dynamic>)
          .map(
            (e) => EnhancedDailyWorkoutPlan.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      weeklyNotes: json['weeklyNotes'] as String,
      intensityRecommendation: json['intensityRecommendation'] as String,
      profileId: json['profileId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      weeklyGoals: json['weeklyGoals'] as Map<String, dynamic>? ?? const {},
      focusAreas:
          (json['focusAreas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      overallIntensity: (json['overallIntensity'] as num?)?.toDouble() ?? 0.7,
      weeklyProgressionNotes:
          (json['weeklyProgressionNotes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      aiWeeklyInsights:
          json['aiWeeklyInsights'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$EnhancedWeeklyPlanToJson(EnhancedWeeklyPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weekStarting': instance.weekStarting.toIso8601String(),
      'dailyWorkouts': instance.dailyWorkouts,
      'weeklyNotes': instance.weeklyNotes,
      'intensityRecommendation': instance.intensityRecommendation,
      'profileId': instance.profileId,
      'createdAt': instance.createdAt.toIso8601String(),
      'weeklyGoals': instance.weeklyGoals,
      'focusAreas': instance.focusAreas,
      'overallIntensity': instance.overallIntensity,
      'weeklyProgressionNotes': instance.weeklyProgressionNotes,
      'aiWeeklyInsights': instance.aiWeeklyInsights,
    };
