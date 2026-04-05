import '../models/workout_tracking.dart';

/// Service for tracking and analyzing combat sports performance metrics
class PerformanceAnalyticsService {
  /// Track exercise completion and performance
  static Future<void> logExerciseCompletion({
    required String exerciseId,
    required String userId,
    required DateTime timestamp,
    required int durationSeconds,
    required int intensityAchieved,
    List<String>? notes,
    Map<String, dynamic>? metrics,
  }) async {
    // Implementation would store to database
    // This is a placeholder for the actual implementation
  }

  /// Get user's workout streak
  static int calculateStreak(List<DailyWorkout> workouts) {
    if (workouts.isEmpty) return 0;

    workouts.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime? lastDate;

    for (var workout in workouts) {
      if (workout.completed) {
        if (lastDate == null) {
          streak = 1;
          lastDate = workout.date;
        } else {
          final difference = lastDate.difference(workout.date).inDays;
          if (difference <= 1) {
            streak++;
            lastDate = workout.date;
          } else {
            break;
          }
        }
      }
    }

    return streak;
  }

  /// Calculate weekly training volume
  static Map<String, dynamic> calculateWeeklyVolume(
    List<DailyWorkout> workouts,
  ) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final weeklyWorkouts = workouts
        .where((w) => w.date.isAfter(weekStart) && w.completed)
        .toList();

    int totalDuration = 0;
    int totalExercises = 0;
    int highIntensityCount = 0;

    for (var workout in weeklyWorkouts) {
      totalDuration += workout.durationSeconds.toInt();
      totalExercises += workout.exercises.length;

      for (var exercise in workout.exercises) {
        if (exercise.intensityLevel >= 7) {
          highIntensityCount++;
        }
      }
    }

    return {
      'totalWorkouts': weeklyWorkouts.length,
      'totalDurationMinutes': totalDuration ~/ 60,
      'totalExercises': totalExercises,
      'highIntensityExercises': highIntensityCount,
      'averageIntensity': weeklyWorkouts.isEmpty
          ? 0
          : (weeklyWorkouts
                        .map((w) => w.intensityLevel)
                        .reduce((a, b) => a + b) /
                    weeklyWorkouts.length)
                .toInt(),
    };
  }

  /// Calculate skill progression over time
  static Map<String, double> calculateSkillProgression(
    List<DailyWorkout> workouts,
    String skillFocus,
  ) {
    final skillWorkouts = workouts
        .where((w) => w.exercises.any((e) => e.skillFocus.contains(skillFocus)))
        .toList();

    if (skillWorkouts.isEmpty) return {};

    skillWorkouts.sort((a, b) => a.date.compareTo(b.date));

    final progression = <String, double>{};
    for (int i = 0; i < skillWorkouts.length; i++) {
      final key = '${skillWorkouts[i].date.month}/${skillWorkouts[i].date.day}';
      progression[key] = skillWorkouts[i].intensityLevel.toDouble();
    }

    return progression;
  }

  /// Get sport-specific training breakdown
  static Map<String, int> getSportBreakdown(List<DailyWorkout> workouts) {
    final breakdown = <String, int>{};

    for (var workout in workouts) {
      if (!workout.completed) continue;

      for (var exercise in workout.exercises) {
        for (var sport in exercise.sports) {
          final key = sport.toString().split('.').last;
          breakdown[key] = (breakdown[key] ?? 0) + 1;
        }
      }
    }

    return breakdown;
  }

  /// Calculate recovery metrics
  static Map<String, dynamic> calculateRecoveryMetrics(
    List<DailyWorkout> workouts,
  ) {
    if (workouts.isEmpty) return {};

    final last7Days = workouts
        .where(
          (w) => w.date.isAfter(DateTime.now().subtract(Duration(days: 7))),
        )
        .toList();

    final highIntensityDays = last7Days
        .where((w) => w.intensityLevel >= 8)
        .length;

    final restDays = 7 - last7Days.where((w) => w.completed).length;

    return {
      'trainingDays': last7Days.length,
      'highIntensityDays': highIntensityDays,
      'restDays': restDays,
      'recommendedRest': highIntensityDays >= 4
          ? 'High - Take 2 rest days'
          : highIntensityDays >= 3
          ? 'Moderate - Take 1 rest day'
          : 'Low - Maintain current schedule',
    };
  }

  /// Get performance trends
  static List<Map<String, dynamic>> getPerformanceTrends(
    List<DailyWorkout> workouts,
    int weeks,
  ) {
    final trends = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 0; i < weeks; i++) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));

      final weekWorkouts = workouts
          .where(
            (w) =>
                w.date.isAfter(weekStart) &&
                w.date.isBefore(weekEnd) &&
                w.completed,
          )
          .toList();

      if (weekWorkouts.isNotEmpty) {
        final avgIntensity =
            weekWorkouts.map((w) => w.intensityLevel).reduce((a, b) => a + b) /
            weekWorkouts.length;

        final totalDuration = weekWorkouts.fold<int>(
          0,
          (sum, w) => sum + w.durationSeconds,
        );

        trends.add({
          'week': i + 1,
          'workouts': weekWorkouts.length,
          'avgIntensity': avgIntensity,
          'totalMinutes': totalDuration ~/ 60,
        });
      }
    }

    return trends;
  }

  /// Calculate personal records
  static Map<String, dynamic> calculatePersonalRecords(
    List<DailyWorkout> workouts,
  ) {
    if (workouts.isEmpty) return {};

    int longestWorkout = 0;
    int highestIntensity = 0;
    int mostExercises = 0;
    int currentStreak = 0;
    int longestStreak = 0;

    for (var workout in workouts) {
      if (!workout.completed) {
        currentStreak = 0;
        continue;
      }

      currentStreak++;
      longestStreak = currentStreak > longestStreak
          ? currentStreak
          : longestStreak;

      longestWorkout = workout.durationSeconds > longestWorkout
          ? workout.durationSeconds
          : longestWorkout;

      highestIntensity = workout.intensityLevel > highestIntensity
          ? workout.intensityLevel
          : highestIntensity;

      mostExercises = workout.exercises.length > mostExercises
          ? workout.exercises.length
          : mostExercises;
    }

    return {
      'longestWorkoutMinutes': longestWorkout ~/ 60,
      'highestIntensity': highestIntensity,
      'mostExercisesInWorkout': mostExercises,
      'longestStreak': longestStreak,
      'currentStreak': currentStreak,
    };
  }

  /// Generate workout recommendations based on analytics
  static List<String> generateRecommendations(List<DailyWorkout> workouts) {
    final recommendations = <String>[];
    final recovery = calculateRecoveryMetrics(workouts);
    final volume = calculateWeeklyVolume(workouts);

    // Recovery recommendations
    if (recovery['highIntensityDays'] as int >= 4) {
      recommendations.add(
        'High training load detected. Prioritize recovery this week.',
      );
    }

    if (recovery['restDays'] as int < 1) {
      recommendations.add('Consider adding a rest day for optimal recovery.');
    }

    // Volume recommendations
    if (volume['totalWorkouts'] as int < 3) {
      recommendations.add(
        'Aim for at least 3 workouts per week for consistent progress.',
      );
    }

    // Intensity recommendations
    final highIntensityRatio =
        (volume['highIntensityExercises'] as int) /
        (volume['totalExercises'] as int > 0
            ? volume['totalExercises'] as int
            : 1);

    if (highIntensityRatio > 0.7) {
      recommendations.add(
        'Many high-intensity workouts. Add some lower intensity sessions for recovery.',
      );
    }

    // Streak encouragement
    final prs = calculatePersonalRecords(workouts);
    if (prs['currentStreak'] as int >= 7) {
      recommendations.add(
        'Amazing ${prs['currentStreak']} day streak! Keep it up!',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add('Great job maintaining consistent training!');
    }

    return recommendations;
  }
}
