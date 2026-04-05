import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_tracking.dart';
import '../models/user_profile.dart';
import '../models/exercise.dart';

/// Service for storing and syncing AI-generated workout plans across all screens
/// Acts as the central source of truth for the user's training plan
class WorkoutPlanStorageService {
  static final WorkoutPlanStorageService _instance =
      WorkoutPlanStorageService._internal();
  factory WorkoutPlanStorageService() => _instance;
  WorkoutPlanStorageService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // Storage keys
  static const String _weeklyPlansKey = 'weekly_plans_v2';
  static const String _completedWorkoutsKey = 'completed_workouts_v2';
  static const String _activeWorkoutKey = 'active_workout_session';

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    developer.log('WorkoutPlanStorageService initialized', name: 'PlanStorage');
  }

  // ==================== Weekly Plan Management ====================

  /// Save a complete weekly training plan
  Future<void> saveWeeklyPlan({
    required DateTime weekStarting,
    required List<DailyWorkoutPlan> dailyWorkouts,
    required String weeklyNotes,
    required String intensityRecommendation,
    required UserProfile profile,
  }) async {
    await initialize();

    final planData = {
      'week_starting': weekStarting.toIso8601String(),
      'daily_workouts': dailyWorkouts.map((w) => w.toMap()).toList(),
      'weekly_notes': weeklyNotes,
      'intensity_recommendation': intensityRecommendation,
      'profile_id': profile.userId,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Get existing plans
    final plans = await getAllWeeklyPlans();

    // Remove existing plan for this week if exists
    plans.removeWhere((p) => _isSameWeek(p.weekStarting, weekStarting));

    // Add new plan
    plans.add(WeeklyPlanStorage.fromMap(planData));

    // Save back to storage
    await _prefs?.setString(
      _weeklyPlansKey,
      jsonEncode(plans.map((p) => p.toMap()).toList()),
    );

    developer.log(
      'Weekly plan saved for week starting ${weekStarting.toIso8601String()}',
      name: 'PlanStorage',
    );
  }

  /// Get all stored weekly plans
  Future<List<WeeklyPlanStorage>> getAllWeeklyPlans() async {
    await initialize();

    final json = _prefs?.getString(_weeklyPlansKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((m) => WeeklyPlanStorage.fromMap(m)).toList();
    } catch (e) {
      developer.log('Error loading weekly plans: $e', name: 'PlanStorage');
      return [];
    }
  }

  /// Get plan for specific week
  Future<WeeklyPlanStorage?> getWeeklyPlan(DateTime weekStarting) async {
    final plans = await getAllWeeklyPlans();

    try {
      return plans.firstWhere((p) => _isSameWeek(p.weekStarting, weekStarting));
    } catch (e) {
      return null;
    }
  }

  /// Get current week's plan
  Future<WeeklyPlanStorage?> getCurrentWeekPlan() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return getWeeklyPlan(weekStart);
  }

  // ==================== Daily Workout Management ====================

  /// Get today's workout from current plan
  Future<DailyWorkoutPlan?> getTodaysWorkout() async {
    final currentPlan = await getCurrentWeekPlan();
    if (currentPlan == null) return null;

    final now = DateTime.now();
    final todayName = _getDayName(now.weekday);

    try {
      return currentPlan.dailyWorkouts.firstWhere(
        (w) => w.day.toLowerCase() == todayName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get workout for specific date
  Future<DailyWorkoutPlan?> getWorkoutForDate(DateTime date) async {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final plan = await getWeeklyPlan(weekStart);

    if (plan == null) return null;

    final dayName = _getDayName(date.weekday);

    try {
      return plan.dailyWorkouts.firstWhere(
        (w) => w.day.toLowerCase() == dayName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // ==================== Active Workout Session ====================

  /// Start a new workout session
  Future<void> startWorkoutSession(
    DailyWorkoutPlan workout,
    int readinessScore,
  ) async {
    await initialize();

    final sessionData = {
      'workout': workout.toMap(),
      'readiness_score': readinessScore,
      'start_time': DateTime.now().toIso8601String(),
      'exercise_progress': workout.exercises
          .map(
            (e) => {
              'exercise_id': e.exercise.id,
              'sets_completed': 0,
              'current_weight': e.suggestedWeight ?? 0,
              'reps_performed': <int>[],
              'completed': false,
            },
          )
          .toList(),
    };

    await _prefs?.setString(_activeWorkoutKey, jsonEncode(sessionData));
    developer.log(
      'Workout session started: ${workout.workoutType}',
      name: 'PlanStorage',
    );
  }

  /// Get active workout session
  ActiveWorkoutSession? getActiveWorkoutSession() {
    final json = _prefs?.getString(_activeWorkoutKey);
    if (json == null) return null;

    try {
      return ActiveWorkoutSession.fromMap(jsonDecode(json));
    } catch (e) {
      developer.log('Error loading active workout: $e', name: 'PlanStorage');
      return null;
    }
  }

  /// Update exercise progress during workout
  Future<void> updateExerciseProgress(
    String exerciseId, {
    int? setsCompleted,
    double? weightUsed,
    List<int>? repsPerformed,
    bool? completed,
  }) async {
    final session = getActiveWorkoutSession();
    if (session == null) return;

    final progress = session.exerciseProgress;
    final exerciseIndex = progress.indexWhere(
      (e) => e['exercise_id'] == exerciseId,
    );

    if (exerciseIndex != -1) {
      if (setsCompleted != null) {
        progress[exerciseIndex]['sets_completed'] = setsCompleted;
      }
      if (weightUsed != null) {
        progress[exerciseIndex]['current_weight'] = weightUsed;
      }
      if (repsPerformed != null) {
        progress[exerciseIndex]['reps_performed'] = repsPerformed;
      }
      if (completed != null) {
        progress[exerciseIndex]['completed'] = completed;
      }

      await _prefs?.setString(_activeWorkoutKey, jsonEncode(session.toMap()));
    }
  }

  /// Complete workout session
  Future<CompletedWorkout?> completeWorkoutSession() async {
    final session = getActiveWorkoutSession();
    if (session == null) return null;

    final completedWorkout = CompletedWorkout(
      id: 'completed_${DateTime.now().millisecondsSinceEpoch}',
      protocolTitle: session.workout.workoutType,
      exercises: session.exerciseProgress.map((e) {
        final exercise = session.workout.exercises.firstWhere(
          (ex) => ex.exercise.id == e['exercise_id'],
        );
        return CompletedExerciseEntry(
          exercise: exercise.exercise,
          sets: (e['reps_performed'] as List<dynamic>? ?? [])
              .asMap()
              .entries
              .map((entry) {
                return SetPerformance(
                  setNumber: entry.key + 1,
                  repsPerformed: entry.value as int,
                  loadUsed: e['current_weight']?.toDouble() ?? 0,
                  completed: true,
                );
              })
              .toList(),
          completedAt: DateTime.now(),
        );
      }).toList(),
      startTime: DateTime.parse(session.startTime),
      endTime: DateTime.now(),
      totalDurationMinutes: DateTime.now()
          .difference(DateTime.parse(session.startTime))
          .inMinutes,
      readinessScoreAtStart: session.readinessScore,
    );

    // Save to completed workouts
    await _saveCompletedWorkout(completedWorkout);

    // Clear active session
    await _prefs?.remove(_activeWorkoutKey);

    developer.log(
      'Workout completed: ${completedWorkout.protocolTitle}',
      name: 'PlanStorage',
    );
    return completedWorkout;
  }

  /// Cancel active workout
  Future<void> cancelWorkoutSession() async {
    await _prefs?.remove(_activeWorkoutKey);
    developer.log('Workout cancelled', name: 'PlanStorage');
  }

  // ==================== Completed Workouts ====================

  Future<void> _saveCompletedWorkout(CompletedWorkout workout) async {
    final workouts = await getCompletedWorkouts();
    workouts.add(workout);

    await _prefs?.setString(
      _completedWorkoutsKey,
      jsonEncode(workouts.map((w) => w.toMap()).toList()),
    );
  }

  /// Get all completed workouts
  Future<List<CompletedWorkout>> getCompletedWorkouts() async {
    await initialize();

    final json = _prefs?.getString(_completedWorkoutsKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((w) => CompletedWorkout.fromMap(w)).toList();
    } catch (e) {
      developer.log(
        'Error loading completed workouts: $e',
        name: 'PlanStorage',
      );
      return [];
    }
  }

  /// Get completed workouts for specific week
  Future<List<CompletedWorkout>> getCompletedWorkoutsForWeek(
    DateTime weekStarting,
  ) async {
    final allWorkouts = await getCompletedWorkouts();
    return allWorkouts.where((w) {
      return _isSameWeek(w.startTime, weekStarting);
    }).toList();
  }

  // ==================== Helper Methods ====================

  bool _isSameWeek(DateTime a, DateTime b) {
    final aWeekStart = a.subtract(Duration(days: a.weekday - 1));
    final bWeekStart = b.subtract(Duration(days: b.weekday - 1));
    return aWeekStart.year == bWeekStart.year &&
        aWeekStart.month == bWeekStart.month &&
        aWeekStart.day == bWeekStart.day;
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  /// Clear all plan data (use with caution)
  Future<void> clearAllData() async {
    await _prefs?.remove(_weeklyPlansKey);
    await _prefs?.remove(_completedWorkoutsKey);
    await _prefs?.remove(_activeWorkoutKey);
    developer.log('All plan data cleared', name: 'PlanStorage');
  }

  /// Get plan statistics
  Future<Map<String, dynamic>> getPlanStats() async {
    final plans = await getAllWeeklyPlans();
    final completed = await getCompletedWorkouts();

    return {
      'total_plans': plans.length,
      'total_workouts_completed': completed.length,
      'total_volume_lifted': completed.fold<double>(0, (sum, w) {
        return sum +
            w.exercises.fold<double>(0, (exSum, e) {
              return exSum +
                  e.sets.fold<double>(0, (setSum, s) {
                    return setSum + (s.loadUsed ?? 0) * (s.repsPerformed ?? 0);
                  });
            });
      }),
      'average_workout_duration': completed.isEmpty
          ? 0
          : completed
                    .map((w) => w.totalDurationMinutes)
                    .reduce((a, b) => a + b) /
                completed.length,
    };
  }
}

// ==================== Data Models ====================

class WeeklyPlanStorage {
  final DateTime weekStarting;
  final List<DailyWorkoutPlan> dailyWorkouts;
  final String weeklyNotes;
  final String intensityRecommendation;
  final String profileId;
  final DateTime createdAt;

  WeeklyPlanStorage({
    required this.weekStarting,
    required this.dailyWorkouts,
    required this.weeklyNotes,
    required this.intensityRecommendation,
    required this.profileId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'week_starting': weekStarting.toIso8601String(),
      'daily_workouts': dailyWorkouts.map((w) => w.toMap()).toList(),
      'weekly_notes': weeklyNotes,
      'intensity_recommendation': intensityRecommendation,
      'profile_id': profileId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeeklyPlanStorage.fromMap(Map<String, dynamic> map) {
    return WeeklyPlanStorage(
      weekStarting: DateTime.parse(map['week_starting']),
      dailyWorkouts: (map['daily_workouts'] as List)
          .map((w) => DailyWorkoutPlan.fromMap(w))
          .toList(),
      weeklyNotes: map['weekly_notes'] ?? '',
      intensityRecommendation: map['intensity_recommendation'] ?? '',
      profileId: map['profile_id'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class DailyWorkoutPlan {
  final String day;
  final String workoutType;
  final String focus;
  final List<PlannedExercise> exercises;
  final int estimatedDurationMinutes;
  final String mindsetPrompt;
  final bool isRestDay;

  DailyWorkoutPlan({
    required this.day,
    required this.workoutType,
    required this.focus,
    required this.exercises,
    required this.estimatedDurationMinutes,
    required this.mindsetPrompt,
    this.isRestDay = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'workout_type': workoutType,
      'focus': focus,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'estimated_duration_minutes': estimatedDurationMinutes,
      'mindset_prompt': mindsetPrompt,
      'is_rest_day': isRestDay,
    };
  }

  factory DailyWorkoutPlan.fromMap(Map<String, dynamic> map) {
    return DailyWorkoutPlan(
      day: map['day'] ?? '',
      workoutType: map['workout_type'] ?? '',
      focus: map['focus'] ?? '',
      exercises: (map['exercises'] as List? ?? [])
          .map((e) => PlannedExercise.fromMap(e))
          .toList(),
      estimatedDurationMinutes: map['estimated_duration_minutes'] ?? 60,
      mindsetPrompt: map['mindset_prompt'] ?? '',
      isRestDay: map['is_rest_day'] ?? false,
    );
  }
}

class PlannedExercise {
  final Exercise exercise;
  final int sets;
  final int targetReps;
  final double targetRpe;
  final int restSeconds;
  final double? suggestedWeight;
  final String notes;

  PlannedExercise({
    required this.exercise,
    required this.sets,
    required this.targetReps,
    required this.targetRpe,
    required this.restSeconds,
    this.suggestedWeight,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'exercise': exercise.toStorageMap(),
      'sets': sets,
      'target_reps': targetReps,
      'target_rpe': targetRpe,
      'rest_seconds': restSeconds,
      'suggested_weight': suggestedWeight,
      'notes': notes,
    };
  }

  factory PlannedExercise.fromMap(Map<String, dynamic> map) {
    return PlannedExercise(
      exercise: _exerciseFromStorageMap(map['exercise']),
      sets: map['sets'] ?? 3,
      targetReps: map['target_reps'] ?? 10,
      targetRpe: (map['target_rpe'] ?? 7.0).toDouble(),
      restSeconds: map['rest_seconds'] ?? 90,
      suggestedWeight: map['suggested_weight']?.toDouble(),
      notes: map['notes'] ?? '',
    );
  }
}

class ActiveWorkoutSession {
  final DailyWorkoutPlan workout;
  final int readinessScore;
  final String startTime;
  final List<Map<String, dynamic>> exerciseProgress;

  ActiveWorkoutSession({
    required this.workout,
    required this.readinessScore,
    required this.startTime,
    required this.exerciseProgress,
  });

  Map<String, dynamic> toMap() {
    return {
      'workout': workout.toMap(),
      'readiness_score': readinessScore,
      'start_time': startTime,
      'exercise_progress': exerciseProgress,
    };
  }

  factory ActiveWorkoutSession.fromMap(Map<String, dynamic> map) {
    return ActiveWorkoutSession(
      workout: DailyWorkoutPlan.fromMap(map['workout']),
      readinessScore: map['readiness_score'] ?? 70,
      startTime: map['start_time'] ?? DateTime.now().toIso8601String(),
      exerciseProgress: (map['exercise_progress'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
  }
}

// Extension on Exercise for serialization
extension ExerciseSerialization on Exercise {
  Map<String, dynamic> toStorageMap() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'youtube_id': youtubeId,
      'target_metaphor': targetMetaphor,
      'instructions': instructions,
      'intensity_level': intensityLevel,
      'primary_muscles': primaryMuscles,
      'joint_stress': jointStress,
      'workout_tags': workoutTags,
    };
  }
}

// Helper function to deserialize Exercise
Exercise _exerciseFromStorageMap(Map<String, dynamic> map) {
  return Exercise(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    category: ExerciseCategory.values[map['category'] ?? 0],
    youtubeId: map['youtube_id'] ?? '',
    targetMetaphor: map['target_metaphor'] ?? '',
    instructions: map['instructions'] ?? '',
    intensityLevel: map['intensity_level'] ?? 5,
    primaryMuscles: (map['primary_muscles'] as List? ?? []).cast<String>(),
    jointStress: (map['joint_stress'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as int),
    ),
    workoutTags: (map['workout_tags'] as List? ?? []).cast<String>(),
  );
}
