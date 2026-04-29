/// Analytics Metrics Models
/// Comprehensive data structures for warrior performance analytics

/// Time-series data point for charts
class TimeSeriesPoint {
  final DateTime date;
  final double value;
  final String? label;

  TimeSeriesPoint({
    required this.date,
    required this.value,
    this.label,
  });
}

/// Volume metrics over time
class VolumeMetrics {
  final List<TimeSeriesPoint> dailyVolumes;
  final List<TimeSeriesPoint> weeklyVolumes;
  final double totalVolume;
  final double averageDailyVolume;
  final double bestWeekVolume;
  final double trendSlope; // Positive = improving

  VolumeMetrics({
    required this.dailyVolumes,
    required this.weeklyVolumes,
    required this.totalVolume,
    required this.averageDailyVolume,
    required this.bestWeekVolume,
    required this.trendSlope,
  });
}

/// Strength progression for a specific exercise
class ExerciseProgression {
  final String exerciseName;
  final String exerciseId;
  final List<TimeSeriesPoint> estimatedOneRM;
  final List<TimeSeriesPoint> maxLoad;
  final List<TimeSeriesPoint> totalVolume;
  final double currentOneRM;
  final double? personalRecord;
  final DateTime? prDate;
  final double progressionRate; // kg or lbs per week
  final bool isPlateauing;
  final int workoutsCount;

  ExerciseProgression({
    required this.exerciseName,
    required this.exerciseId,
    required this.estimatedOneRM,
    required this.maxLoad,
    required this.totalVolume,
    required this.currentOneRM,
    this.personalRecord,
    this.prDate,
    required this.progressionRate,
    required this.isPlateauing,
    required this.workoutsCount,
  });

  /// Calculate 1RM using Epley formula: weight * (1 + reps/30)
  static double estimateOneRM(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }
}

/// Workout consistency metrics
class ConsistencyMetrics {
  final int currentStreak;
  final int longestStreak;
  final double weeklyCompletionRate;
  final List<TimeSeriesPoint> weeklyRates;
  final List<DateTime> workoutDates;
  final int totalWorkouts;
  final int missedWorkouts;
  final double adherencePercentage;

  ConsistencyMetrics({
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyCompletionRate,
    required this.weeklyRates,
    required this.workoutDates,
    required this.totalWorkouts,
    required this.missedWorkouts,
    required this.adherencePercentage,
  });
}

/// Heatmap data for workout calendar
class WorkoutHeatmapData {
  final DateTime date;
  final int intensity; // 0-4 scale (0 = rest, 4 = high intensity)
  final double? volume;
  final int? duration;
  final bool isWorkoutDay;

  WorkoutHeatmapData({
    required this.date,
    required this.intensity,
    this.volume,
    this.duration,
    required this.isWorkoutDay,
  });
}

/// Recovery and readiness correlation
class RecoveryMetrics {
  final List<TimeSeriesPoint> readinessTrend;
  final List<TimeSeriesPoint> sleepQualityTrend;
  final List<TimeSeriesPoint> sleepHoursTrend;
  final double avgReadiness;
  final double avgSleepQuality;
  final double avgSleepHours;
  final double readinessSleepCorrelation;
  final List<String> overtrainingWarnings;

  RecoveryMetrics({
    required this.readinessTrend,
    required this.sleepQualityTrend,
    required this.sleepHoursTrend,
    required this.avgReadiness,
    required this.avgSleepQuality,
    required this.avgSleepHours,
    required this.readinessSleepCorrelation,
    required this.overtrainingWarnings,
  });
}

/// Exercise frequency distribution
class ExerciseFrequency {
  final String exerciseName;
  final String category;
  final int frequency;
  final double percentage;
  final double totalVolume;

  ExerciseFrequency({
    required this.exerciseName,
    required this.category,
    required this.frequency,
    required this.percentage,
    required this.totalVolume,
  });
}

/// Period comparison data
class PeriodComparison {
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime previousPeriodStart;
  final DateTime previousPeriodEnd;
  final double currentVolume;
  final double previousVolume;
  final double volumeChangePercent;
  final int currentWorkouts;
  final int previousWorkouts;
  final double workoutChangePercent;
  final double currentAvgDuration;
  final double previousAvgDuration;
  final double durationChangePercent;
  final double currentAvgRPE;
  final double previousAvgRPE;
  final double rpeChangePercent;

  PeriodComparison({
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.previousPeriodStart,
    required this.previousPeriodEnd,
    required this.currentVolume,
    required this.previousVolume,
    required this.volumeChangePercent,
    required this.currentWorkouts,
    required this.previousWorkouts,
    required this.workoutChangePercent,
    required this.currentAvgDuration,
    required this.previousAvgDuration,
    required this.durationChangePercent,
    required this.currentAvgRPE,
    required this.previousAvgRPE,
    required this.rpeChangePercent,
  });

  bool get isImproving => volumeChangePercent > 0 || workoutChangePercent > 0;
}

/// Comprehensive analytics snapshot
class WarriorAnalyticsSnapshot {
  final VolumeMetrics volumeMetrics;
  final ConsistencyMetrics consistencyMetrics;
  final RecoveryMetrics recoveryMetrics;
  final List<ExerciseProgression> exerciseProgressions;
  final List<ExerciseFrequency> exerciseFrequency;
  final PeriodComparison? periodComparison;
  final DateTime generatedAt;
  final DateTime dataStartDate;
  final DateTime dataEndDate;

  WarriorAnalyticsSnapshot({
    required this.volumeMetrics,
    required this.consistencyMetrics,
    required this.recoveryMetrics,
    required this.exerciseProgressions,
    required this.exerciseFrequency,
    this.periodComparison,
    required this.generatedAt,
    required this.dataStartDate,
    required this.dataEndDate,
  });

  /// Get top progressing exercises
  List<ExerciseProgression> get topProgressingExercises {
    final sorted = List<ExerciseProgression>.from(exerciseProgressions)
      ..sort((a, b) => b.progressionRate.compareTo(a.progressionRate));
    return sorted.where((e) => e.progressionRate > 0).take(3).toList();
  }

  /// Get plateauing exercises
  List<ExerciseProgression> get plateauingExercises {
    return exerciseProgressions.where((e) => e.isPlateauing).toList();
  }

  /// Get insights summary
  List<String> get insights {
    final insights = <String>[];

    // Volume trend
    if (volumeMetrics.trendSlope > 0.1) {
      insights.add('Volume trending up - strong progression!');
    } else if (volumeMetrics.trendSlope < -0.1) {
      insights.add('Volume declining - consider deload or rest.');
    }

    // Consistency
    if (consistencyMetrics.currentStreak >= 7) {
      insights.add('${consistencyMetrics.currentStreak}-day streak - discipline of a true warrior!');
    }

    // Recovery
    if (recoveryMetrics.avgReadiness < 60) {
      insights.add('Readiness scores low - prioritize recovery and sleep.');
    }

    // Plateaus
    if (plateauingExercises.isNotEmpty) {
      final names = plateauingExercises.take(2).map((e) => e.exerciseName).join(', ');
      insights.add('Progress plateau detected in $names - time to vary training.');
    }

    return insights;
  }
}
