import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/analytics_metrics.dart';

/// Analytics Query Service
/// Handles complex aggregation queries for warrior performance analytics
class AnalyticsQueryService {
  static final AnalyticsQueryService _instance =
      AnalyticsQueryService._internal();
  factory AnalyticsQueryService() => _instance;
  AnalyticsQueryService._internal();

  final SupabaseClient _supabase = SupabaseConfig.client;
  String? get currentUserId => SupabaseConfig.userId;

  // ==================== Volume Analytics ====================

  /// Get volume metrics over a date range
  Future<VolumeMetrics> getVolumeMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get all workout sessions with sets in the date range
      final sessions = await _getSessionsWithSets(startDate, endDate);

      // Calculate daily volumes
      final dailyVolumes = <TimeSeriesPoint>[];
      final dailyMap = <String, double>{};

      for (final session in sessions) {
        final date = DateTime.parse(
          session['date']?.toString() ?? session['start_time'],
        );
        final dateKey = _dateOnlyString(date);
        final sets = session['sets'] as List<dynamic>? ?? [];

        double dayVolume = 0;
        for (final set in sets) {
          final load = (set['load_used'] as num?)?.toDouble() ?? 0;
          final reps = (set['reps_performed'] as num?)?.toInt() ?? 0;
          dayVolume += load * reps;
        }

        dailyMap[dateKey] = (dailyMap[dateKey] ?? 0) + dayVolume;
      }

      // Fill in all dates (including rest days with 0 volume)
      for (
        var d = startDate;
        d.isBefore(endDate.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))
      ) {
        final dateKey = _dateOnlyString(d);
        dailyVolumes.add(
          TimeSeriesPoint(date: d, value: dailyMap[dateKey] ?? 0),
        );
      }

      // Calculate weekly volumes
      final weeklyVolumes = _aggregateToWeekly(dailyVolumes);

      // Calculate trend slope
      final trendSlope = _calculateTrendSlope(dailyVolumes);

      final totalVolume = dailyVolumes.fold<double>(
        0,
        (sum, p) => sum + p.value,
      );
      final workoutDays = dailyVolumes.where((p) => p.value > 0).length;
      final averageDailyVolume = workoutDays > 0
          ? totalVolume / workoutDays
          : 0.0;
      final bestWeekVolume = weeklyVolumes.isNotEmpty
          ? weeklyVolumes.map((p) => p.value).reduce(math.max).toDouble()
          : 0.0;

      return VolumeMetrics(
        dailyVolumes: dailyVolumes,
        weeklyVolumes: weeklyVolumes,
        totalVolume: totalVolume,
        averageDailyVolume: averageDailyVolume,
        bestWeekVolume: bestWeekVolume,
        trendSlope: trendSlope,
      );
    } catch (e) {
      debugPrint('Error getting volume metrics: $e');
      return VolumeMetrics(
        dailyVolumes: [],
        weeklyVolumes: [],
        totalVolume: 0,
        averageDailyVolume: 0,
        bestWeekVolume: 0,
        trendSlope: 0,
      );
    }
  }

  // ==================== Exercise Progression ====================

  /// Get progression data for all exercises
  Future<List<ExerciseProgression>> getExerciseProgressions({
    required DateTime startDate,
    required DateTime endDate,
    int minWorkouts = 3,
  }) async {
    try {
      final sessions = await _getSessionsWithSets(startDate, endDate);

      // Group sets by exercise
      final exerciseData = <String, List<Map<String, dynamic>>>{};

      for (final session in sessions) {
        final date = DateTime.parse(
          session['date']?.toString() ?? session['start_time'],
        );
        final sets = session['sets'] as List<dynamic>? ?? [];

        for (final set in sets) {
          final exerciseName = set['exercise_name']?.toString() ?? 'Unknown';
          exerciseData.putIfAbsent(exerciseName, () => []);
          exerciseData[exerciseName]!.add({
            ...set as Map<String, dynamic>,
            'date': date,
          });
        }
      }

      final progressions = <ExerciseProgression>[];

      for (final entry in exerciseData.entries) {
        if (entry.value.length < minWorkouts) continue;

        final progression = await _calculateExerciseProgression(
          entry.key,
          entry.value,
        );
        progressions.add(progression);
      }

      return progressions;
    } catch (e) {
      debugPrint('Error getting exercise progressions: $e');
      return [];
    }
  }

  // ==================== Consistency Analytics ====================

  /// Get consistency metrics including streaks
  Future<ConsistencyMetrics> getConsistencyMetrics({
    required DateTime startDate,
    required DateTime endDate,
    int targetWorkoutsPerWeek = 4,
  }) async {
    try {
      // Get all workout dates
      final response = await _supabase
          .from('workout_sessions')
          .select('date')
          .eq('user_id', currentUserId!)
          .gte('date', _dateOnlyString(startDate))
          .lte('date', _dateOnlyString(endDate))
          .order('date', ascending: true);

      final workoutDates = (response as List<dynamic>)
          .map((r) => DateTime.parse(r['date'].toString()))
          .toList();

      // Calculate streaks
      final allDates = <DateTime>[];
      for (
        var d = startDate;
        d.isBefore(endDate.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))
      ) {
        allDates.add(d);
      }

      final workoutDateSet = workoutDates.map(_dateOnlyString).toSet();

      // Current streak (from today backwards)
      int currentStreak = 0;
      var checkDate = DateTime.now();
      while (workoutDateSet.contains(_dateOnlyString(checkDate))) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      // Longest streak
      int longestStreak = 0;
      int currentRun = 0;
      for (final date in allDates) {
        if (workoutDateSet.contains(_dateOnlyString(date))) {
          currentRun++;
          longestStreak = math.max(longestStreak, currentRun);
        } else {
          currentRun = 0;
        }
      }

      // Weekly completion rates
      final weeklyRates = <TimeSeriesPoint>[];
      var weekStart = startDate;
      while (weekStart.isBefore(endDate)) {
        final weekEnd = weekStart.add(const Duration(days: 6));
        final daysInWeek = workoutDates
            .where(
              (d) =>
                  d.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                  d.isBefore(weekEnd.add(const Duration(days: 1))),
            )
            .length;
        final rate = daysInWeek / targetWorkoutsPerWeek;
        weeklyRates.add(
          TimeSeriesPoint(
            date: weekStart,
            value: rate.clamp(0, 1),
            label: '$daysInWeek/$targetWorkoutsPerWeek',
          ),
        );
        weekStart = weekStart.add(const Duration(days: 7));
      }

      final totalWorkouts = workoutDates.length;
      final totalDays = endDate.difference(startDate).inDays + 1;
      final expectedWorkouts = (totalDays / 7) * targetWorkoutsPerWeek;
      final missedWorkouts = math.max(
        0,
        expectedWorkouts.round() - totalWorkouts,
      );
      final adherencePercentage = expectedWorkouts > 0
          ? ((totalWorkouts / expectedWorkouts * 100).clamp(0, 100) as num)
                .toDouble()
          : 0.0;

      // Current week rate
      final currentWeekStart = _getWeekStart(DateTime.now());
      final currentWeekWorkouts = workoutDates
          .where(
            (d) =>
                d.isAfter(currentWeekStart.subtract(const Duration(days: 1))),
          )
          .length;
      final weeklyCompletionRate =
          ((currentWeekWorkouts / targetWorkoutsPerWeek).clamp(0, 1) as num)
              .toDouble();

      return ConsistencyMetrics(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        weeklyCompletionRate: weeklyCompletionRate,
        weeklyRates: weeklyRates,
        workoutDates: workoutDates,
        totalWorkouts: totalWorkouts,
        missedWorkouts: missedWorkouts,
        adherencePercentage: adherencePercentage,
      );
    } catch (e) {
      debugPrint('Error getting consistency metrics: $e');
      return ConsistencyMetrics(
        currentStreak: 0,
        longestStreak: 0,
        weeklyCompletionRate: 0,
        weeklyRates: [],
        workoutDates: [],
        totalWorkouts: 0,
        missedWorkouts: 0,
        adherencePercentage: 0,
      );
    }
  }

  // ==================== Recovery Analytics ====================

  /// Get recovery and readiness metrics
  Future<RecoveryMetrics> getRecoveryMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get daily readiness data
      final response = await _supabase
          .from('daily_readiness')
          .select()
          .eq('user_id', currentUserId!)
          .gte('date', _dateOnlyString(startDate))
          .lte('date', _dateOnlyString(endDate))
          .order('date', ascending: true);

      final readinessTrend = <TimeSeriesPoint>[];
      final sleepQualityTrend = <TimeSeriesPoint>[];
      final sleepHoursTrend = <TimeSeriesPoint>[];

      double totalReadiness = 0;
      double totalSleepQuality = 0;
      double totalSleepHours = 0;

      for (final record in response) {
        final date = DateTime.parse(record['date'].toString());
        final readiness = (record['readiness_score'] as num?)?.toDouble();
        final sleepQuality = (record['sleep_quality'] as num?)?.toDouble();
        final sleepHours = (record['sleep_hours'] as num?)?.toDouble();

        if (readiness != null) {
          readinessTrend.add(TimeSeriesPoint(date: date, value: readiness));
          totalReadiness += readiness;
        }
        if (sleepQuality != null) {
          sleepQualityTrend.add(
            TimeSeriesPoint(date: date, value: sleepQuality),
          );
          totalSleepQuality += sleepQuality;
        }
        if (sleepHours != null) {
          sleepHoursTrend.add(TimeSeriesPoint(date: date, value: sleepHours));
          totalSleepHours += sleepHours;
        }
      }

      final avgReadiness = readinessTrend.isNotEmpty
          ? totalReadiness / readinessTrend.length
          : 0.0;
      final avgSleepQuality = sleepQualityTrend.isNotEmpty
          ? totalSleepQuality / sleepQualityTrend.length
          : 0.0;
      final avgSleepHours = sleepHoursTrend.isNotEmpty
          ? totalSleepHours / sleepHoursTrend.length
          : 0.0;

      // Calculate correlation between sleep and readiness
      final correlation =
          readinessTrend.length == sleepQualityTrend.length &&
              readinessTrend.isNotEmpty
          ? _calculateCorrelation(
              readinessTrend.map((p) => (p.value as num).toDouble()).toList(),
              sleepQualityTrend
                  .map((p) => (p.value as num).toDouble())
                  .toList(),
            )
          : 0.0;

      // Check for overtraining warnings
      final warnings = <String>[];
      if (avgReadiness < 50) {
        warnings.add(
          'Consistently low readiness - consider extended rest period',
        );
      }
      if (correlation > 0.5 && avgSleepQuality < 5) {
        warnings.add(
          'Poor sleep correlating with low readiness - prioritize sleep hygiene',
        );
      }

      return RecoveryMetrics(
        readinessTrend: readinessTrend,
        sleepQualityTrend: sleepQualityTrend,
        sleepHoursTrend: sleepHoursTrend,
        avgReadiness: avgReadiness,
        avgSleepQuality: avgSleepQuality,
        avgSleepHours: avgSleepHours,
        readinessSleepCorrelation: correlation,
        overtrainingWarnings: warnings,
      );
    } catch (e) {
      debugPrint('Error getting recovery metrics: $e');
      return RecoveryMetrics(
        readinessTrend: [],
        sleepQualityTrend: [],
        sleepHoursTrend: [],
        avgReadiness: 0,
        avgSleepQuality: 0,
        avgSleepHours: 0,
        readinessSleepCorrelation: 0,
        overtrainingWarnings: [],
      );
    }
  }

  // ==================== Exercise Frequency ====================

  /// Get exercise frequency distribution
  Future<List<ExerciseFrequency>> getExerciseFrequency({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('workout_sets')
          .select('exercise_name, load_used, reps_performed')
          .eq('user_id', currentUserId!)
          .gte('created_at', startDate.toIso8601String())
          .lte(
            'created_at',
            endDate.add(const Duration(days: 1)).toIso8601String(),
          );

      final exerciseStats = <String, Map<String, dynamic>>{};

      for (final set in response) {
        final name = set['exercise_name']?.toString() ?? 'Unknown';
        exerciseStats.putIfAbsent(
          name,
          () => {'count': 0, 'volume': 0.0, 'category': _inferCategory(name)},
        );

        exerciseStats[name]!['count'] =
            ((exerciseStats[name]!['count'] as num?)?.toInt() ?? 0) + 1;

        final load = (set['load_used'] as num?)?.toDouble() ?? 0;
        final reps = (set['reps_performed'] as num?)?.toInt() ?? 0;
        exerciseStats[name]!['volume'] =
            ((exerciseStats[name]!['volume'] as num?)?.toDouble() ?? 0) +
            (load * reps);
      }

      final totalSets = exerciseStats.values.fold<int>(
        0,
        (sum, e) => sum + (e['count'] as num).toInt(),
      );

      final frequencies = exerciseStats.entries
          .map(
            (e) => ExerciseFrequency(
              exerciseName: e.key,
              category: e.value['category'] as String,
              frequency: (e.value['count'] as num).toInt(),
              percentage: totalSets > 0
                  ? ((e.value['count'] as num).toInt()) / totalSets * 100
                  : 0.0,
              totalVolume: (e.value['volume'] as num).toDouble(),
            ),
          )
          .toList();

      frequencies.sort((a, b) => b.frequency.compareTo(a.frequency));

      return frequencies;
    } catch (e) {
      debugPrint('Error getting exercise frequency: $e');
      return [];
    }
  }

  // ==================== Period Comparison ====================

  /// Compare current period vs previous period
  Future<PeriodComparison> comparePeriods({
    required DateTime currentStart,
    required DateTime currentEnd,
  }) async {
    final currentDuration = currentEnd.difference(currentStart);
    final previousStart = currentStart.subtract(currentDuration);
    final previousEnd = currentStart.subtract(const Duration(days: 1));

    final currentMetrics = await _getPeriodMetrics(currentStart, currentEnd);
    final previousMetrics = await _getPeriodMetrics(previousStart, previousEnd);

    return PeriodComparison(
      currentPeriodStart: currentStart,
      currentPeriodEnd: currentEnd,
      previousPeriodStart: previousStart,
      previousPeriodEnd: previousEnd,
      currentVolume: currentMetrics['volume'] ?? 0,
      previousVolume: previousMetrics['volume'] ?? 0,
      volumeChangePercent:
          previousMetrics['volume'] != null && previousMetrics['volume']! > 0
          ? ((currentMetrics['volume']! - previousMetrics['volume']!) /
                previousMetrics['volume']! *
                100)
          : 0.0,
      currentWorkouts: (currentMetrics['workouts'] ?? 0).toInt(),
      previousWorkouts: (previousMetrics['workouts'] ?? 0).toInt(),
      workoutChangePercent:
          previousMetrics['workouts'] != null &&
              previousMetrics['workouts']! > 0
          ? ((currentMetrics['workouts']! - previousMetrics['workouts']!) /
                previousMetrics['workouts']! *
                100)
          : 0.0,
      currentAvgDuration: currentMetrics['avgDuration'] ?? 0.0,
      previousAvgDuration: previousMetrics['avgDuration'] ?? 0.0,
      durationChangePercent:
          previousMetrics['avgDuration'] != null &&
              previousMetrics['avgDuration']! > 0
          ? ((currentMetrics['avgDuration']! -
                    previousMetrics['avgDuration']!) /
                previousMetrics['avgDuration']! *
                100)
          : 0.0,
      currentAvgRPE: currentMetrics['avgRPE'] ?? 0.0,
      previousAvgRPE: previousMetrics['avgRPE'] ?? 0.0,
      rpeChangePercent:
          previousMetrics['avgRPE'] != null && previousMetrics['avgRPE']! > 0
          ? ((currentMetrics['avgRPE']! - previousMetrics['avgRPE']!) /
                previousMetrics['avgRPE']! *
                100)
          : 0.0,
    );
  }

  // ==================== Comprehensive Snapshot ====================

  /// Get complete analytics snapshot
  Future<WarriorAnalyticsSnapshot> getAnalyticsSnapshot({
    DateTime? startDate,
    DateTime? endDate,
    bool includeComparison = true,
  }) async {
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 90));

    final volumeMetrics = await getVolumeMetrics(
      startDate: start,
      endDate: end,
    );
    final consistencyMetrics = await getConsistencyMetrics(
      startDate: start,
      endDate: end,
    );
    final recoveryMetrics = await getRecoveryMetrics(
      startDate: start,
      endDate: end,
    );
    final exerciseProgressions = await getExerciseProgressions(
      startDate: start,
      endDate: end,
    );
    final exerciseFrequency = await getExerciseFrequency(
      startDate: start,
      endDate: end,
    );

    PeriodComparison? comparison;
    if (includeComparison) {
      final currentStart = end.subtract(const Duration(days: 30));
      comparison = await comparePeriods(
        currentStart: currentStart,
        currentEnd: end,
      );
    }

    return WarriorAnalyticsSnapshot(
      volumeMetrics: volumeMetrics,
      consistencyMetrics: consistencyMetrics,
      recoveryMetrics: recoveryMetrics,
      exerciseProgressions: exerciseProgressions,
      exerciseFrequency: exerciseFrequency,
      periodComparison: comparison,
      generatedAt: DateTime.now(),
      dataStartDate: start,
      dataEndDate: end,
    );
  }

  // ==================== Helper Methods ====================

  Future<List<Map<String, dynamic>>> _getSessionsWithSets(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _supabase
        .from('workout_sessions')
        .select('*, workout_sets(*)')
        .eq('user_id', currentUserId!)
        .gte('date', _dateOnlyString(startDate))
        .lte('date', _dateOnlyString(endDate))
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, double>> _getPeriodMetrics(
    DateTime start,
    DateTime end,
  ) async {
    final sessions = await _getSessionsWithSets(start, end);

    double totalVolume = 0;
    int totalDuration = 0;
    double totalRPE = 0;
    int rpeCount = 0;

    for (final session in sessions) {
      final sets = session['workout_sets'] as List<dynamic>? ?? [];

      for (final set in sets) {
        final load = (set['load_used'] as num?)?.toDouble() ?? 0;
        final reps = (set['reps_performed'] as num?)?.toInt() ?? 0;
        final rpe = (set['actual_rpe'] as num?)?.toDouble();

        totalVolume += load * reps;
        if (rpe != null) {
          totalRPE += rpe;
          rpeCount++;
        }
      }

      final startTime = DateTime.tryParse(
        session['start_time']?.toString() ?? '',
      );
      final endTime = DateTime.tryParse(session['end_time']?.toString() ?? '');
      if (startTime != null && endTime != null) {
        totalDuration += endTime.difference(startTime).inMinutes;
      }
    }

    return {
      'volume': totalVolume,
      'workouts': sessions.length.toDouble(),
      'avgDuration': sessions.isNotEmpty ? totalDuration / sessions.length : 0,
      'avgRPE': rpeCount > 0 ? totalRPE / rpeCount : 0,
    };
  }

  Future<ExerciseProgression> _calculateExerciseProgression(
    String exerciseName,
    List<Map<String, dynamic>> sets,
  ) async {
    // Group by workout date to find best set per session
    final workoutData = <DateTime, List<Map<String, dynamic>>>{};
    for (final set in sets) {
      final date = set['date'] as DateTime;
      workoutData.putIfAbsent(date, () => []);
      workoutData[date]!.add(set);
    }

    final estimatedOneRM = <TimeSeriesPoint>[];
    final maxLoad = <TimeSeriesPoint>[];
    final totalVolume = <TimeSeriesPoint>[];

    double personalRecord = 0;
    DateTime? prDate;
    double currentOneRM = 0;

    for (final entry in workoutData.entries) {
      final date = entry.key;
      final daySets = entry.value;

      // Find best set (highest estimated 1RM)
      double bestOneRM = 0;
      double bestLoad = 0;
      double dayVolume = 0;

      for (final set in daySets) {
        final load = (set['load_used'] as num?)?.toDouble() ?? 0;
        final reps = (set['reps_performed'] as num?)?.toInt() ?? 0;
        final oneRM = ExerciseProgression.estimateOneRM(load, reps);

        if (oneRM > bestOneRM) {
          bestOneRM = oneRM;
          bestLoad = load;
        }
        if (oneRM > personalRecord) {
          personalRecord = oneRM;
          prDate = date;
        }

        dayVolume += load * reps;
      }

      estimatedOneRM.add(TimeSeriesPoint(date: date, value: bestOneRM));
      maxLoad.add(TimeSeriesPoint(date: date, value: bestLoad));
      totalVolume.add(TimeSeriesPoint(date: date, value: dayVolume));

      if (date.isAfter(DateTime.now().subtract(const Duration(days: 14)))) {
        currentOneRM = bestOneRM;
      }
    }

    // Calculate progression rate
    double progressionRate = 0;
    bool isPlateauing = false;
    if (estimatedOneRM.length >= 4) {
      final firstHalf = estimatedOneRM
          .take(estimatedOneRM.length ~/ 2)
          .map((p) => p.value)
          .toList();
      final secondHalf = estimatedOneRM
          .skip(estimatedOneRM.length ~/ 2)
          .map((p) => p.value)
          .toList();

      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      final weeksDiff =
          estimatedOneRM.last.date
              .difference(estimatedOneRM.first.date)
              .inDays /
          7;
      if (weeksDiff > 0) {
        progressionRate = (secondAvg - firstAvg) / weeksDiff;
      }

      // Plateau: less than 1% improvement per month
      isPlateauing =
          progressionRate < (firstAvg * 0.01 / 4); // 1% per month threshold
    }

    return ExerciseProgression(
      exerciseName: exerciseName,
      exerciseId: exerciseName.toLowerCase().replaceAll(' ', '_'),
      estimatedOneRM: estimatedOneRM,
      maxLoad: maxLoad,
      totalVolume: totalVolume,
      currentOneRM: currentOneRM,
      personalRecord: personalRecord > 0 ? personalRecord : null,
      prDate: prDate,
      progressionRate: progressionRate,
      isPlateauing: isPlateauing,
      workoutsCount: workoutData.length,
    );
  }

  List<TimeSeriesPoint> _aggregateToWeekly(List<TimeSeriesPoint> daily) {
    if (daily.isEmpty) return [];

    final weekly = <TimeSeriesPoint>[];
    DateTime? weekStart;
    double weekSum = 0;

    for (final point in daily) {
      if (weekStart == null || point.date.difference(weekStart).inDays >= 7) {
        if (weekStart != null) {
          weekly.add(TimeSeriesPoint(date: weekStart, value: weekSum));
        }
        weekStart = point.date;
        weekSum = 0;
      }
      weekSum += point.value;
    }

    if (weekStart != null) {
      weekly.add(TimeSeriesPoint(date: weekStart, value: weekSum));
    }

    return weekly;
  }

  double _calculateTrendSlope(List<TimeSeriesPoint> data) {
    if (data.length < 2) return 0;

    // Simple linear regression
    final n = data.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = data[i].value;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0;

    return (n * sumXY - sumX * sumY) / denominator;
  }

  double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0;

    final n = x.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;

    for (var i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
    }

    final numerator = n * sumXY - sumX * sumY;
    final denominator = math.sqrt(
      (n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY),
    );

    if (denominator == 0) return 0;
    return numerator / denominator;
  }

  String _dateOnlyString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _inferCategory(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('squat') ||
        name.contains('leg') ||
        name.contains('lunge')) {
      return 'Legs';
    } else if (name.contains('bench') ||
        name.contains('press') ||
        name.contains('chest')) {
      return 'Push';
    } else if (name.contains('row') ||
        name.contains('pull') ||
        name.contains('lat')) {
      return 'Pull';
    } else if (name.contains('curl') || name.contains('arm')) {
      return 'Arms';
    } else if (name.contains('deadlift') || name.contains('back')) {
      return 'Back';
    } else if (name.contains('core') || name.contains('ab')) {
      return 'Core';
    }
    return 'Other';
  }
}
