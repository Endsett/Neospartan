// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutExercise _$WorkoutExerciseFromJson(Map<String, dynamic> json) =>
    WorkoutExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: $enumDecode(_$ExerciseCategoryEnumMap, json['category']),
      sets: (json['sets'] as num).toInt(),
      targetReps: (json['targetReps'] as num).toInt(),
      targetSeconds: (json['targetSeconds'] as num?)?.toInt(),
      targetRpe: (json['targetRpe'] as num).toDouble(),
      restSeconds: (json['restSeconds'] as num).toInt(),
      suggestedWeight: (json['suggestedWeight'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
      type: $enumDecode(_$ExerciseTypeEnumMap, json['type']),
      previousWeight: (json['previousWeight'] as num?)?.toDouble(),
      previousReps: (json['previousReps'] as num?)?.toInt(),
      weightIncrease: (json['weightIncrease'] as num?)?.toDouble(),
      repIncrease: (json['repIncrease'] as num?)?.toInt(),
      isProgressiveOverload: json['isProgressiveOverload'] as bool? ?? false,
      substitutionExerciseIds:
          (json['substitutionExerciseIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      substitutionExerciseNames:
          (json['substitutionExerciseNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      substitutionReason: json['substitutionReason'] as String?,
      supersetGroupId: json['supersetGroupId'] as String?,
      supersetOrder: (json['supersetOrder'] as num?)?.toInt(),
      isTimedExercise: json['isTimedExercise'] as bool? ?? false,
      requiredEquipment:
          (json['requiredEquipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      alternativeEquipment:
          (json['alternativeEquipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      requiresPartner: json['requiresPartner'] as bool? ?? false,
      instructions: json['instructions'] as String,
      youtubeId: json['youtubeId'] as String?,
      targetMetaphor: json['targetMetaphor'] as String?,
    );

Map<String, dynamic> _$WorkoutExerciseToJson(WorkoutExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': _$ExerciseCategoryEnumMap[instance.category]!,
      'sets': instance.sets,
      'targetReps': instance.targetReps,
      'targetSeconds': instance.targetSeconds,
      'targetRpe': instance.targetRpe,
      'restSeconds': instance.restSeconds,
      'suggestedWeight': instance.suggestedWeight,
      'notes': instance.notes,
      'type': _$ExerciseTypeEnumMap[instance.type]!,
      'previousWeight': instance.previousWeight,
      'previousReps': instance.previousReps,
      'weightIncrease': instance.weightIncrease,
      'repIncrease': instance.repIncrease,
      'isProgressiveOverload': instance.isProgressiveOverload,
      'substitutionExerciseIds': instance.substitutionExerciseIds,
      'substitutionExerciseNames': instance.substitutionExerciseNames,
      'substitutionReason': instance.substitutionReason,
      'supersetGroupId': instance.supersetGroupId,
      'supersetOrder': instance.supersetOrder,
      'isTimedExercise': instance.isTimedExercise,
      'requiredEquipment': instance.requiredEquipment,
      'alternativeEquipment': instance.alternativeEquipment,
      'requiresPartner': instance.requiresPartner,
      'instructions': instance.instructions,
      'youtubeId': instance.youtubeId,
      'targetMetaphor': instance.targetMetaphor,
    };

const _$ExerciseCategoryEnumMap = {
  ExerciseCategory.plyometric: 'plyometric',
  ExerciseCategory.isometric: 'isometric',
  ExerciseCategory.combat: 'combat',
  ExerciseCategory.strength: 'strength',
  ExerciseCategory.mobility: 'mobility',
  ExerciseCategory.sprint: 'sprint',
};

const _$ExerciseTypeEnumMap = {
  ExerciseType.strength: 'strength',
  ExerciseType.cardio: 'cardio',
  ExerciseType.flexibility: 'flexibility',
  ExerciseType.balance: 'balance',
  ExerciseType.plyometric: 'plyometric',
  ExerciseType.isometric: 'isometric',
  ExerciseType.explosive: 'explosive',
  ExerciseType.endurance: 'endurance',
};
