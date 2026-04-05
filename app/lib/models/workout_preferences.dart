/// Workout generation preferences for AI tailoring
library workout_preferences;

import '../models/sport_category.dart' hide ExerciseCategory;
import '../models/equipment_type.dart';
import '../models/user_profile.dart';
import '../models/workout_tracking.dart';

class WorkoutPreferences {
  /// Primary sport focus for this workout
  final SportCategory? sportFocus;

  /// Training focus for the session
  final TrainingFocus? trainingFocus;

  /// Available time for the workout
  final Duration availableTime;

  /// Equipment available to the user
  final List<EquipmentType> availableEquipment;

  /// Injuries or limitations to avoid
  final List<String> injuriesToAvoid;

  /// Current training phase
  final TrainingPhase phase;

  /// Desired intensity level (1-10), null for AI-determined
  final int? desiredIntensity;

  /// Include sport-specific drills
  final bool includeSportSpecificDrills;

  /// Workout type preference
  final WorkoutType workoutType;

  /// Include partner drills
  final bool? hasPartner;

  const WorkoutPreferences({
    this.sportFocus,
    this.trainingFocus,
    this.availableTime = const Duration(minutes: 60),
    this.availableEquipment = const [],
    this.injuriesToAvoid = const [],
    this.phase = TrainingPhase.generalPreparation,
    this.desiredIntensity,
    this.includeSportSpecificDrills = true,
    this.workoutType = WorkoutType.fullWorkout,
    this.hasPartner,
  });

  /// Create from user profile defaults
  factory WorkoutPreferences.fromUserProfile(UserProfile profile) {
    return WorkoutPreferences(
      sportFocus: _mapTrainingGoalToSport(profile.trainingGoal),
      availableTime: Duration(minutes: profile.preferredWorkoutDuration ?? 60),
      availableEquipment: [], // Would come from profile settings
      phase: TrainingPhase.generalPreparation,
      includeSportSpecificDrills: true,
    );
  }

  static SportCategory? _mapTrainingGoalToSport(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.mma:
        return SportCategory.mma;
      case TrainingGoal.boxing:
        return SportCategory.boxing;
      case TrainingGoal.muayThai:
        return SportCategory.muayThai;
      case TrainingGoal.wrestling:
        return SportCategory.wrestling;
      case TrainingGoal.bjj:
        return SportCategory.bjj;
      case TrainingGoal.generalCombat:
        return SportCategory.generalCombat;
      case TrainingGoal.strength:
        return SportCategory.fightStrength;
      case TrainingGoal.conditioning:
        return SportCategory.fightConditioning;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'sport_focus': sportFocus?.name,
      'training_focus': trainingFocus?.name,
      'available_time_minutes': availableTime.inMinutes,
      'available_equipment': availableEquipment.map((e) => e.name).toList(),
      'injuries_to_avoid': injuriesToAvoid,
      'phase': phase.name,
      'desired_intensity': desiredIntensity,
      'include_sport_specific': includeSportSpecificDrills,
      'workout_type': workoutType.name,
      'has_partner': hasPartner,
    };
  }
}

/// Training phases for periodization
enum TrainingPhase {
  offSeason,
  generalPreparation,
  sportSpecificPreparation,
  preCompetition,
  competition,
  transition,
}

/// Workout type options
enum WorkoutType {
  fullWorkout,
  techniqueOnly,
  strengthOnly,
  conditioningOnly,
  recovery,
  sparringPrep,
  quickSession,
}

/// Performance context for adaptive workout generation
class PerformanceContext {
  /// Recent completed workouts (last 7 days)
  final List<CompletedWorkout> last7Days;

  /// Daily logs for recovery data
  final List<DailyLog> recentRecoveryData;

  /// Muscle group recovery percentages
  final Map<String, double> muscleGroupRecovery;

  /// Movement patterns used recently
  final List<String> recentMovementPatterns;

  /// Predicted readiness score
  final double predictedReadiness;

  /// Current micro-cycle progress
  final double microCycleProgress;

  /// Days since last rest day
  final int daysSinceRest;

  /// Training load trend (increasing, decreasing, stable)
  final LoadTrend loadTrend;

  /// Average RPE from recent sessions
  final double averageRPE;

  /// Any flags from recent performance
  final List<String> performanceFlags;

  const PerformanceContext({
    this.last7Days = const [],
    this.recentRecoveryData = const [],
    this.muscleGroupRecovery = const {},
    this.recentMovementPatterns = const [],
    this.predictedReadiness = 70.0,
    this.microCycleProgress = 0.0,
    this.daysSinceRest = 2,
    this.loadTrend = LoadTrend.stable,
    this.averageRPE = 7.0,
    this.performanceFlags = const [],
  });

  /// Build from workout history
  factory PerformanceContext.fromHistory({
    required List<CompletedWorkout> recentWorkouts,
    required List<DailyLog> dailyLogs,
    UserProfile? profile,
  }) {
    // Calculate muscle group recovery
    final muscleRecovery = _calculateMuscleRecovery(recentWorkouts);

    // Get recent movement patterns
    final recentPatterns = _extractMovementPatterns(recentWorkouts);

    // Calculate predicted readiness
    final readiness = _calculateReadiness(dailyLogs, recentWorkouts);

    // Determine load trend
    final trend = _determineLoadTrend(recentWorkouts);

    // Calculate average RPE
    final avgRPE = _calculateAverageRPE(recentWorkouts);

    // Check for flags
    final flags = _checkPerformanceFlags(dailyLogs, recentWorkouts);

    return PerformanceContext(
      last7Days: recentWorkouts.take(7).toList(),
      recentRecoveryData: dailyLogs.take(7).toList(),
      muscleGroupRecovery: muscleRecovery,
      recentMovementPatterns: recentPatterns,
      predictedReadiness: readiness,
      microCycleProgress: _calculateMicroCycleProgress(recentWorkouts),
      daysSinceRest: _calculateDaysSinceRest(dailyLogs),
      loadTrend: trend,
      averageRPE: avgRPE,
      performanceFlags: flags,
    );
  }

  static Map<String, double> _calculateMuscleRecovery(
    List<CompletedWorkout> workouts,
  ) {
    final recovery = <String, double>{};

    // Default all muscles to 100% recovery
    final allMuscles = [
      'chest',
      'back',
      'shoulders',
      'biceps',
      'triceps',
      'quads',
      'hamstrings',
      'glutes',
      'calves',
      'core',
    ];

    for (final muscle in allMuscles) {
      recovery[muscle] = 100.0;
    }

    // Reduce recovery based on recent work
    final now = DateTime.now();
    for (final workout in workouts.take(3)) {
      final hoursAgo = now.difference(workout.endTime).inHours;
      final recoveryFactor = (hoursAgo / 48).clamp(0.0, 1.0);

      for (final exercise in workout.exercises) {
        for (final muscle in exercise.exercise.primaryMuscles) {
          final currentRecovery = recovery[muscle] ?? 100.0;
          final workoutStress = exercise.sets.fold<int>(
            0,
            (sum, set) => sum + (set.repsPerformed ?? 0),
          );
          final stressFactor =
              (workoutStress / 100) * (1 - recoveryFactor) * 20;
          recovery[muscle] = (currentRecovery - stressFactor).clamp(
            20.0,
            100.0,
          );
        }
      }
    }

    return recovery;
  }

  static List<String> _extractMovementPatterns(
    List<CompletedWorkout> workouts,
  ) {
    final patterns = <String>{};
    for (final workout in workouts.take(7)) {
      for (final entry in workout.exercises) {
        // Would need to add movement patterns to Exercise model
        // For now, derive from exercise category
        patterns.add(entry.exercise.category.name);
      }
    }
    return patterns.toList();
  }

  static double _calculateReadiness(
    List<DailyLog> dailyLogs,
    List<CompletedWorkout> workouts,
  ) {
    if (dailyLogs.isEmpty) return 70.0;

    final recentLog = dailyLogs.first;
    var readiness = recentLog.readinessScore.toDouble();

    // Adjust based on recent workout volume
    final recentVolume = workouts
        .take(2)
        .fold<double>(0, (sum, w) => sum + w.totalVolume);
    if (recentVolume > 10000) {
      readiness -= 10;
    }

    // Adjust based on sleep
    if (recentLog.sleepHours < 6) {
      readiness -= 15;
    } else if (recentLog.sleepHours > 8) {
      readiness += 5;
    }

    return readiness.clamp(20.0, 100.0);
  }

  static LoadTrend _determineLoadTrend(List<CompletedWorkout> workouts) {
    if (workouts.length < 3) return LoadTrend.stable;

    final recent =
        workouts.take(3).map((w) => w.totalVolume).reduce((a, b) => a + b) / 3;
    final previous =
        workouts
            .skip(3)
            .take(3)
            .map((w) => w.totalVolume)
            .reduce((a, b) => a + b) /
        3;

    if (recent > previous * 1.1) return LoadTrend.increasing;
    if (recent < previous * 0.9) return LoadTrend.decreasing;
    return LoadTrend.stable;
  }

  static double _calculateAverageRPE(List<CompletedWorkout> workouts) {
    if (workouts.isEmpty) return 7.0;

    final rpes = workouts
        .expand((w) => w.exercises)
        .expand((e) => e.sets)
        .where((s) => s.actualRPE != null)
        .map((s) => s.actualRPE!)
        .toList();

    if (rpes.isEmpty) return 7.0;
    return rpes.reduce((a, b) => a + b) / rpes.length;
  }

  static List<String> _checkPerformanceFlags(
    List<DailyLog> dailyLogs,
    List<CompletedWorkout> workouts,
  ) {
    final flags = <String>[];

    if (dailyLogs.isNotEmpty) {
      final recent = dailyLogs.first;

      if (recent.readinessScore < 50) {
        flags.add('low_readiness');
      }
      if (recent.sleepHours < 6) {
        flags.add('poor_sleep');
      }
      if (recent.jointFatigue.values.any((v) => v > 7)) {
        flags.add('high_joint_stress');
      }
    }

    if (workouts.isNotEmpty) {
      final recent = workouts.first;
      if (recent.averageRPE > 9) {
        flags.add('very_high_intensity');
      }
    }

    return flags;
  }

  static double _calculateMicroCycleProgress(List<CompletedWorkout> workouts) {
    // Simple calculation: count workouts in current week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekWorkouts = workouts
        .where((w) => w.startTime.isAfter(weekStart))
        .length;
    return (weekWorkouts / 5).clamp(0.0, 1.0);
  }

  static int _calculateDaysSinceRest(List<DailyLog> dailyLogs) {
    var days = 0;
    for (final log in dailyLogs) {
      // Check if this was a rest day (no workout logged)
      if (log.rpeEntries.isEmpty) {
        break;
      }
      days++;
    }
    return days;
  }

  /// Get under-recovered muscle groups
  List<String> get underRecoveredMuscles {
    return muscleGroupRecovery.entries
        .where((e) => e.value < 70.0)
        .map((e) => e.key)
        .toList();
  }

  /// Check if a specific muscle group is recovered
  bool isMuscleRecovered(String muscle) {
    return (muscleGroupRecovery[muscle] ?? 100.0) >= 80.0;
  }

  /// Get recommended workout intensity based on context
  int get recommendedIntensity {
    var baseIntensity = 7;

    // Adjust based on readiness
    if (predictedReadiness < 50) {
      baseIntensity -= 2;
    } else if (predictedReadiness > 85) {
      baseIntensity += 1;
    }

    // Adjust based on load trend
    if (loadTrend == LoadTrend.increasing) {
      baseIntensity -= 1;
    }

    // Adjust based on days since rest
    if (daysSinceRest > 4) {
      baseIntensity -= 1;
    }

    return baseIntensity.clamp(4, 9);
  }

  Map<String, dynamic> toMap() {
    return {
      'predicted_readiness': predictedReadiness,
      'muscle_group_recovery': muscleGroupRecovery,
      'recent_movement_patterns': recentMovementPatterns,
      'micro_cycle_progress': microCycleProgress,
      'days_since_rest': daysSinceRest,
      'load_trend': loadTrend.name,
      'average_rpe': averageRPE,
      'performance_flags': performanceFlags,
      'under_recovered_muscles': underRecoveredMuscles,
    };
  }
}

/// Load trend indicators
enum LoadTrend { increasing, decreasing, stable }

// Import statements at the top would be:
// import '../models/sport_category.dart' hide ExerciseCategory;
// import '../models/equipment_type.dart';
// import '../models/movement_pattern.dart';
// import '../models/user_profile.dart';
// import '../models/workout_tracking.dart';
// import '../models/exercise.dart';
