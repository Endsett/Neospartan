import 'dart:convert';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/workout_exercise.dart';
import '../models/workout_plan_enhanced.dart';
import '../models/exercise.dart' as exercise_model;
import '../models/sport_category.dart';
import '../data/combat_exercise_library.dart';
import 'exercise_library_service.dart';
import 'workout_plan_storage_service.dart';

/// Enhanced workout generator with JSON output and progressive overload
class EnhancedWorkoutGenerator {
  static final EnhancedWorkoutGenerator _instance =
      EnhancedWorkoutGenerator._internal();
  factory EnhancedWorkoutGenerator() => _instance;
  EnhancedWorkoutGenerator._internal();

  /// Generate a complete weekly workout plan in JSON format
  Future<EnhancedWeeklyPlan> generateWeeklyPlan({
    required UserProfile profile,
    required DateTime weekStarting,
    Map<String, dynamic>? previousWeekPerformance,
    Map<String, dynamic>? aiAdjustments,
  }) async {
    developer.log(
      'Generating weekly plan for ${profile.userId}',
      name: 'WorkoutGenerator',
    );

    try {
      // Get user's workout preferences
      final workoutDays = profile.trainingDaysPerWeek ?? 4;
      final workoutDuration = profile.preferredWorkoutDuration ?? 60;

      // Generate daily workouts
      final dailyWorkouts = <EnhancedDailyWorkoutPlan>[];
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      for (int i = 0; i < days.length; i++) {
        final day = days[i];
        final isRestDay = i >= workoutDays || (i + 1) % 7 == 0; // Sunday rest

        if (isRestDay) {
          dailyWorkouts.add(
            EnhancedDailyWorkoutPlan(
              id: 'rest_${day.toLowerCase()}',
              day: day,
              workoutType: 'Rest Day',
              focus: 'Recovery',
              exercises: [],
              estimatedDurationMinutes: 0,
              mindsetPrompt: 'Rest and recover for tomorrow\'s training',
              isRestDay: true,
              intensity: WorkoutIntensity.moderate,
              aiGenerationContext: {'day_type': 'rest'},
              aiConfidenceScore: 1.0,
              generatedAt: DateTime.now(),
            ),
          );
        } else {
          final workout = await generateDailyWorkout(
            profile: profile,
            day: day,
            workoutNumber: i + 1,
            totalWorkouts: workoutDays,
            duration: workoutDuration,
            previousPerformance: previousWeekPerformance,
            aiAdjustments: aiAdjustments,
          );
          dailyWorkouts.add(workout);
        }
      }

      // Generate weekly insights
      final weeklyInsights = await _generateWeeklyInsights(
        profile,
        dailyWorkouts,
        previousWeekPerformance,
      );

      final weeklyPlan = EnhancedWeeklyPlan(
        id: 'weekly_${DateTime.now().millisecondsSinceEpoch}',
        weekStarting: weekStarting,
        dailyWorkouts: dailyWorkouts,
        weeklyNotes: _generateWeeklyNotes(
          dailyWorkouts,
          WorkoutIntensity.moderate,
        ),
        intensityRecommendation: _getIntensityRecommendation(
          WorkoutIntensity.moderate,
        ),
        profileId: profile.userId,
        createdAt: DateTime.now(),
        weeklyGoals: _extractWeeklyGoals(dailyWorkouts),
        focusAreas: _extractFocusAreas(dailyWorkouts),
        overallIntensity: _calculateOverallIntensity(dailyWorkouts),
        weeklyProgressionNotes: _generateProgressionNotes(aiAdjustments),
        aiWeeklyInsights: weeklyInsights,
      );

      // Store in Supabase
      await _storeWeeklyPlan(weeklyPlan);

      return weeklyPlan;
    } catch (e) {
      developer.log(
        'Error generating weekly plan: $e',
        name: 'WorkoutGenerator',
        level: 1000,
      );
      rethrow;
    }
  }

  /// Generate a single daily workout
  Future<EnhancedDailyWorkoutPlan> generateDailyWorkout({
    required UserProfile profile,
    required String day,
    required int workoutNumber,
    required int totalWorkouts,
    int duration = 60,
    Map<String, dynamic>? previousPerformance,
    Map<String, dynamic>? aiAdjustments,
  }) async {
    // Determine workout focus based on day and user goals
    final focus = _determineWorkoutFocus(
      day,
      workoutNumber,
      totalWorkouts,
      profile.trainingGoal,
    );

    // Get previous performance for progressive overload
    final previousData = await _getPreviousPerformanceData(
      profile.userId,
      focus,
    );

    // Generate workout exercises
    final exercises = await generateWorkoutExercises(
      profile: profile,
      focus: focus,
      duration: duration,
      previousData: previousData,
      aiAdjustments: aiAdjustments,
    );

    // Generate warm-up and cool-down
    final warmupExercises = _generateWarmup(exercises, duration);
    final cooldownExercises = _generateCooldown(exercises, duration);

    // Calculate intensity
    final intensity = _calculateWorkoutIntensity(
      exercises,
      profile.fitnessLevel?.name ?? 'intermediate',
    );

    return EnhancedDailyWorkoutPlan(
      id: 'workout_${DateTime.now().millisecondsSinceEpoch}_$day',
      day: day,
      workoutType: _getWorkoutType(focus),
      focus: focus,
      exercises: exercises,
      estimatedDurationMinutes: duration,
      mindsetPrompt: _generateMindsetPrompt(focus, intensity),
      intensity: intensity,
      aiGenerationContext: {
        'user_level': profile.fitnessLevel,
        'focus': focus,
        'duration': duration,
        'has_previous_data': previousData.isNotEmpty,
      },
      aiConfidenceScore: _calculateConfidenceScore(exercises, previousData),
      generatedAt: DateTime.now(),
      warmupExercises: warmupExercises,
      cooldownExercises: cooldownExercises,
      requiredEquipment: _extractRequiredEquipment(exercises),
      optionalEquipment: _extractOptionalEquipment(exercises),
      canBeDoneWithBodyweight: _canBeDoneBodyweight(exercises),
      previousPerformance: previousData,
      progressiveOverloadNotes: _generateProgressiveOverloadNotes(
        exercises,
        previousData,
      ),
    );
  }

  /// Generate workout exercises with progressive overload
  Future<List<WorkoutExercise>> generateWorkoutExercises({
    required UserProfile profile,
    required String focus,
    required int duration,
    required Map<String, dynamic> previousData,
    Map<String, dynamic>? aiAdjustments,
  }) async {
    // Get base exercises for the focus
    final baseExercises = await _getBaseExercisesForFocus(focus, profile);

    // Apply AI adjustments if available
    final adjustedIntensity = aiAdjustments?['intensityModifier'] ?? 1.0;
    final adjustedVolume = aiAdjustments?['volumeModifier'] ?? 1.0;

    // Generate workout exercises with progressive overload
    final exercises = <WorkoutExercise>[];
    int remainingDuration = duration - 10; // Account for warm-up/cool-down

    for (final baseExercise in baseExercises) {
      if (remainingDuration <= 0) break;

      // Get previous performance for this exercise
      final previousPerf = previousData[baseExercise.id];

      // Calculate progressive overload
      final overload = _calculateProgressiveOverload(
        baseExercise,
        previousPerf,
        adjustedIntensity,
        adjustedVolume,
      );

      // Determine exercise parameters
      final exerciseDuration = _estimateExerciseDuration(
        baseExercise,
        ProgressiveOverloadData(
          sets: overload.sets,
          reps: overload.reps,
          weight: overload.weight,
          rpe: overload.rpe,
          restSeconds: overload.restSeconds,
          weightIncrease: overload.weightIncrease,
          repIncrease: overload.repIncrease,
          isProgressiveOverload: overload.isProgressiveOverload,
          isTimed: overload.isTimed,
          seconds: overload.seconds,
          substitutionIds: overload.substitutionIds,
          substitutionNames: overload.substitutionNames,
          substitutionReason: overload.substitutionReason,
        ),
      );
      if (exerciseDuration > remainingDuration) {
        // Adjust sets to fit remaining time
        overload.sets = (remainingDuration / exerciseDuration * overload.sets)
            .round();
        if (overload.sets < 1) break;
      }

      // Create workout exercise
      final workoutExercise = WorkoutExercise.fromExercise(
        exercise_model.Exercise(
          id: baseExercise.id,
          name: baseExercise.name,
          category: baseExercise.category,
          youtubeId: baseExercise.youtubeId ?? '',
          targetMetaphor: baseExercise.targetMetaphor ?? '',
          instructions: baseExercise.instructions,
          intensityLevel: baseExercise.intensityLevel,
          primaryMuscles: [],
          jointStress: {},
          workoutTags: [],
        ),
        sets: overload.sets,
        targetReps: overload.reps,
        targetSeconds: overload.seconds,
        targetRpe: overload.rpe,
        restSeconds: overload.restSeconds,
        suggestedWeight: overload.weight,
        type: _mapExerciseType(baseExercise.category),
        previousWeight: previousPerf?['weight'],
        previousReps: previousPerf?['reps'],
        weightIncrease: overload.weightIncrease,
        repIncrease: overload.repIncrease,
        isProgressiveOverload: overload.isProgressiveOverload,
        substitutionExerciseIds: overload.substitutionIds,
        substitutionExerciseNames: overload.substitutionNames,
        substitutionReason: overload.substitutionReason,
        isTimedExercise: overload.isTimed,
        requiredEquipment: baseExercise.equipment.map((e) => e.name).toList(),
        alternativeEquipment: [],
      );

      exercises.add(workoutExercise);
      remainingDuration -= exerciseDuration;
    }

    return exercises;
  }

  /// Get today's workout from Supabase or generate if not exists
  Future<EnhancedDailyWorkoutPlan?> getTodaysWorkout(String userId) async {
    try {
      final today = DateTime.now();

      // Try to get from Supabase first
      final response = await Supabase.instance.client
          .from('generated_workouts')
          .select()
          .eq('user_id', userId)
          .eq('scheduled_date', today.toIso8601String().split('T')[0])
          .maybeSingle();

      if (response != null) {
        final protocol = response['protocol'] as Map<String, dynamic>;
        return EnhancedDailyWorkoutPlan.fromJson(protocol);
      }

      // If not found, check local storage
      final storageService = WorkoutPlanStorageService();
      final dailyWorkout = await storageService.getTodaysWorkout();
      if (dailyWorkout != null) {
        return EnhancedDailyWorkoutPlan.fromLegacy(dailyWorkout);
      }
      return null;
    } catch (e) {
      developer.log(
        'Error getting today\'s workout: $e',
        name: 'WorkoutGenerator',
      );
      return null;
    }
  }

  /// Store weekly plan in Supabase
  Future<void> _storeWeeklyPlan(EnhancedWeeklyPlan plan) async {
    try {
      await Supabase.instance.client.from('generated_workouts').insert({
        'user_id': plan.profileId,
        'workout_name': 'Weekly Plan - ${plan.weekStarting}',
        'description': plan.weeklyNotes,
        'sport_focus': 'mixed',
        'generated_at': plan.createdAt.toIso8601String(),
        'protocol': plan.toJson(),
        'exercises': plan.dailyWorkouts
            .expand((d) => d.exercises)
            .map((e) => e.toJson())
            .toList(),
        'total_duration_minutes': plan.totalWeeklyMinutes,
        'target_intensity': (plan.overallIntensity * 10).round(),
        'ai_reasoning': jsonEncode(plan.aiWeeklyInsights),
        'generation_context': {
          'weekly_goals': plan.weeklyGoals,
          'focus_areas': plan.focusAreas,
        },
        'ai_confidence_score': 0.85,
        'scheduled_date': plan.weekStarting.toIso8601String(),
        'completed': false,
      });
    } catch (e) {
      developer.log('Error storing weekly plan: $e', name: 'WorkoutGenerator');
    }
  }

  /// Helper methods
  WorkoutIntensity _mapFitnessLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return WorkoutIntensity.light;
      case 'intermediate':
        return WorkoutIntensity.moderate;
      case 'advanced':
        return WorkoutIntensity.hard;
      case 'elite':
        return WorkoutIntensity.maximum;
      default:
        return WorkoutIntensity.moderate;
    }
  }

  String _determineWorkoutFocus(
    String day,
    int workoutNumber,
    int totalWorkouts,
    TrainingGoal? goal,
  ) {
    // Simple rotation - can be made more sophisticated
    final focuses = ['Strength', 'Cardio', 'Flexibility', 'Power', 'Endurance'];
    final index = (workoutNumber - 1) % focuses.length;

    // Adjust based on user goal
    if (goal?.name.toLowerCase().contains('strength') == true) {
      return focuses[index] == 'Cardio' ? 'HIIT' : focuses[index];
    }

    return focuses[index];
  }

  Future<List<CombatExercise>> _getBaseExercisesForFocus(
    String focus,
    UserProfile profile,
  ) async {
    final fitnessLevelString = profile.fitnessLevel?.name ?? 'intermediate';
    switch (focus.toLowerCase()) {
      case 'strength':
        return ExerciseLibraryService.filterByCategory(
              ExerciseCategory.values[0],
            ) // strength
            .where(
              (e) => e.intensityLevel <= _getMaxIntensity(fitnessLevelString),
            )
            .take(6)
            .toList();
      case 'cardio':
      case 'hiit':
        return ExerciseLibraryService.filterByCategory(
              ExerciseCategory.values[1],
            ) // cardio
            .where(
              (e) => e.intensityLevel <= _getMaxIntensity(fitnessLevelString),
            )
            .take(5)
            .toList();
      case 'power':
        return ExerciseLibraryService.filterByCategory(
              ExerciseCategory.values[2],
            ) // plyometric
            .where(
              (e) => e.intensityLevel <= _getMaxIntensity(fitnessLevelString),
            )
            .take(5)
            .toList();
      default:
        return ExerciseLibraryService.getRandomWorkout(5);
    }
  }

  int _getMaxIntensity(String? fitnessLevel) {
    switch (fitnessLevel?.toLowerCase()) {
      case 'beginner':
        return 4;
      case 'intermediate':
        return 6;
      case 'advanced':
        return 8;
      case 'elite':
        return 10;
      default:
        return 5;
    }
  }

  ProgressiveOverloadData _calculateProgressiveOverload(
    CombatExercise exercise,
    Map<String, dynamic>? previousPerf,
    double intensityModifier,
    double volumeModifier,
  ) {
    int sets = 3;
    int reps = 10;
    double? weight;
    double rpe = 7.0;
    int restSeconds = 90;
    double? weightIncrease;
    int? repIncrease;
    bool isProgressiveOverload = false;

    // Apply volume modifier
    sets = (sets * volumeModifier).round();
    sets = sets.clamp(1, 5);

    // Use previous performance if available
    if (previousPerf != null) {
      final prevWeight = previousPerf['weight'] as double?;
      final prevReps = previousPerf['reps'] as int?;
      final prevRPE = previousPerf['rpe'] as double?;

      if (prevWeight != null) {
        weight = prevWeight;
        // Progressive overload: increase weight by 2.5-5kg or reps by 1-2
        if (prevRPE != null && prevRPE < 8.5) {
          weightIncrease = 2.5 * intensityModifier;
          weight = weight! + weightIncrease!;
          isProgressiveOverload = true;
        }
      }

      if (prevReps != null && weight == null) {
        reps = prevReps;
        if (prevRPE != null && prevRPE < 8.5) {
          repIncrease = 1;
          reps = reps + repIncrease!;
          isProgressiveOverload = true;
        }
      }
    }

    // Adjust based on exercise category
    if (exercise.category.index == 0) {
      // strength
      reps = reps.clamp(5, 12);
      restSeconds = 90;
    } else if (exercise.category.index == 1) {
      // cardio
      reps = 30; // For timed exercises
      restSeconds = 60;
    } else if (exercise.category.index == 2) {
      // plyometric
      reps = reps.clamp(3, 8);
      restSeconds = 120;
    }

    // Apply intensity modifier to RPE
    rpe = (7.0 * intensityModifier).clamp(6.0, 9.0);

    return ProgressiveOverloadData(
      sets: sets,
      reps: reps,
      weight: weight,
      rpe: rpe,
      restSeconds: restSeconds,
      weightIncrease: weightIncrease,
      repIncrease: repIncrease,
      isProgressiveOverload: isProgressiveOverload,
      isTimed: exercise.category.index == 1,
      seconds: exercise.category.index == 1 ? 30 : null,
      substitutionIds: [], // TODO: Implement substitution logic
      substitutionNames: [],
      substitutionReason: null,
    );
  }

  Future<Map<String, dynamic>> _getPreviousPerformanceData(
    String userId,
    String focus,
  ) async {
    try {
      // Get recent workouts with same focus
      final response = await Supabase.instance.client
          .from('exercise_performance_history')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(10);

      final Map<String, dynamic> data = {};
      for (final row in response) {
        data[row['exercise_id']] = {
          'reps': row['performance_rating'],
          'weight': row['perceived_difficulty'],
          'rpe': row['would_repeat'] ? 7.0 : 8.0,
        };
      }

      return data;
    } catch (e) {
      developer.log(
        'Error getting previous performance: $e',
        name: 'WorkoutGenerator',
      );
      return {};
    }
  }

  ExerciseType _mapExerciseType(dynamic category) {
    final categoryName = category.toString().toLowerCase();
    if (categoryName.contains('strength')) {
      return ExerciseType.strength;
    } else if (categoryName.contains('cardio')) {
      return ExerciseType.cardio;
    } else if (categoryName.contains('flexibility')) {
      return ExerciseType.flexibility;
    } else if (categoryName.contains('plyometric')) {
      return ExerciseType.plyometric;
    } else {
      return ExerciseType.strength;
    }
  }

  int _estimateExerciseDuration(
    CombatExercise exercise,
    ProgressiveOverloadData overload,
  ) {
    final exerciseTime = overload.isTimed
        ? (overload.seconds ?? 30) * overload.sets
        : (overload.reps * 3 + overload.restSeconds) * overload.sets;
    return exerciseTime + (overload.restSeconds * (overload.sets - 1));
  }

  // Additional helper methods would be implemented here...
  // For brevity, I'm including stubs for the remaining methods

  List<WorkoutExercise> _generateWarmup(
    List<WorkoutExercise> exercises,
    int duration,
  ) {
    // Generate appropriate warm-up exercises
    return [];
  }

  List<WorkoutExercise> _generateCooldown(
    List<WorkoutExercise> exercises,
    int duration,
  ) {
    // Generate appropriate cool-down exercises
    return [];
  }

  WorkoutIntensity _calculateWorkoutIntensity(
    List<WorkoutExercise> exercises,
    String? fitnessLevel,
  ) {
    return _mapFitnessLevel(fitnessLevel);
  }

  String _generateWeeklyNotes(
    List<EnhancedDailyWorkoutPlan> workouts,
    WorkoutIntensity intensity,
  ) {
    return 'This week focuses on building consistency with ${workouts.where((w) => !w.isRestDay).length} training days.';
  }

  String _getIntensityRecommendation(WorkoutIntensity intensity) {
    switch (intensity) {
      case WorkoutIntensity.recovery:
        return 'Focus on active recovery and mobility';
      case WorkoutIntensity.light:
        return 'Maintain light intensity to build consistency';
      case WorkoutIntensity.moderate:
        return 'Push yourself but maintain good form';
      case WorkoutIntensity.hard:
        return 'Challenge yourself with higher intensity';
      case WorkoutIntensity.maximum:
        return 'Maximum effort - listen to your body';
    }
  }

  Map<String, dynamic> _extractWeeklyGoals(
    List<EnhancedDailyWorkoutPlan> workouts,
  ) {
    return {'consistency': 'Attend all scheduled workouts'};
  }

  List<String> _extractFocusAreas(List<EnhancedDailyWorkoutPlan> workouts) {
    return workouts.expand((w) => [w.focus]).toSet().toList();
  }

  double _calculateOverallIntensity(List<EnhancedDailyWorkoutPlan> workouts) {
    final intensities = workouts
        .map((w) => w.intensity.index.toDouble())
        .toList();
    return intensities.isEmpty
        ? 0.7
        : intensities.reduce((a, b) => a + b) / intensities.length;
  }

  List<String> _generateProgressionNotes(Map<String, dynamic>? aiAdjustments) {
    if (aiAdjustments == null) return [];
    return ['Focus on progressive overload this week'];
  }

  Future<Map<String, dynamic>> _generateWeeklyInsights(
    UserProfile profile,
    List<EnhancedDailyWorkoutPlan> workouts,
    Map<String, dynamic>? previousWeekPerformance,
  ) async {
    return {
      'recommendation': 'Stay consistent with your training schedule',
      'focus_area': 'Form and technique',
    };
  }

  String _getWorkoutType(String focus) {
    return '$focus Training';
  }

  String _generateMindsetPrompt(String focus, WorkoutIntensity intensity) {
    return 'Focus on proper form and controlled movements';
  }

  double _calculateConfidenceScore(
    List<WorkoutExercise> exercises,
    Map<String, dynamic> previousData,
  ) {
    return previousData.isNotEmpty ? 0.9 : 0.7;
  }

  List<String> _extractRequiredEquipment(List<WorkoutExercise> exercises) {
    return exercises.expand((e) => e.requiredEquipment).toSet().toList();
  }

  List<String> _extractOptionalEquipment(List<WorkoutExercise> exercises) {
    final equipment = exercises
        .expand((e) => e.alternativeEquipment)
        .toSet()
        .toList();
    return equipment.map((e) => e.toString()).toList();
  }

  bool _canBeDoneBodyweight(List<WorkoutExercise> exercises) {
    return exercises.every(
      (e) =>
          e.requiredEquipment.contains('bodyweight') ||
          e.requiredEquipment.isEmpty,
    );
  }

  List<String> _generateProgressiveOverloadNotes(
    List<WorkoutExercise> exercises,
    Map<String, dynamic> previousData,
  ) {
    return ['Track your weights for progressive overload'];
  }
}

/// Data class for progressive overload calculations
class ProgressiveOverloadData {
  int sets;
  final int reps;
  final double? weight;
  final double rpe;
  final int restSeconds;
  final double? weightIncrease;
  final int? repIncrease;
  final bool isProgressiveOverload;
  final bool isTimed;
  final int? seconds;
  final List<String> substitutionIds;
  final List<String> substitutionNames;
  final String? substitutionReason;

  ProgressiveOverloadData({
    required this.sets,
    required this.reps,
    this.weight,
    required this.rpe,
    required this.restSeconds,
    this.weightIncrease,
    this.repIncrease,
    required this.isProgressiveOverload,
    required this.isTimed,
    this.seconds,
    this.substitutionIds = const [],
    this.substitutionNames = const [],
    this.substitutionReason,
  });
}

// Extension on EnhancedDailyWorkoutPlan for Supabase integration
extension EnhancedDailyWorkoutPlanSupabase on EnhancedDailyWorkoutPlan {
  static EnhancedDailyWorkoutPlan fromSupabaseRow(Map<String, dynamic> row) {
    final protocol = row['protocol'] as Map<String, dynamic>;
    return EnhancedDailyWorkoutPlan.fromJson(protocol);
  }
}
