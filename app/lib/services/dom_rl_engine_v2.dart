import 'dart:developer' as developer;
import '../models/user_profile.dart';
import '../models/workout_tracking.dart';
import '../models/daily_readiness.dart';
import '../models/biometrics.dart';
import '../repositories/workout_repository.dart';
import '../repositories/biometrics_repository.dart';
import '../repositories/daily_readiness_repository.dart';
import 'dom_rl_engine.dart';

/// DOM-RL 2.0 Enhanced Engine
/// Advanced AI features including:
/// - Fatigue prediction
/// - Periodization support (mesocycles/macrocycles)
/// - Progressive overload tracking
/// - Deload detection
/// - Recovery optimization
class DomRlEngineV2 {
  static final DomRlEngineV2 _instance = DomRlEngineV2._internal();
  factory DomRlEngineV2() => _instance;
  DomRlEngineV2._internal();

  final DomRlEngine _baseEngine = DomRlEngine();
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  final BiometricsRepository _biometricsRepository = BiometricsRepository();
  final DailyReadinessRepository _readinessRepository =
      DailyReadinessRepository();

  Future<void> initialize() async {
    await _baseEngine.initialize();
    developer.log('DOM-RL 2.0 Engine initialized', name: 'DomRlEngineV2');
  }

  // ==================== FATIGUE PREDICTION ====================

  /// Predict fatigue levels for the next N days based on current trajectory
  /// Uses trend analysis from HRV, training load, and recovery metrics
  Future<List<FatiguePrediction>> predictFatigue(
    String userId,
    int daysAhead, {
    DateTime? fromDate,
  }) async {
    try {
      final startDate = fromDate ?? DateTime.now();

      // Get historical data
      final workouts = await _workoutRepository.getWorkoutsForDateRange(
        userId,
        startDate.subtract(const Duration(days: 14)),
        startDate,
      );
      final readiness = await _readinessRepository.getRecentReadiness(
        userId,
        days: 7,
      );
      final hrvReadings = await _biometricsRepository.getBiometricsForRange(
        userId,
        startDate.subtract(const Duration(days: 7)),
        startDate,
      );

      final predictions = <FatiguePrediction>[];

      for (int i = 1; i <= daysAhead; i++) {
        final date = startDate.add(Duration(days: i));

        // Calculate predicted fatigue score (0-100, higher = more fatigued)
        double fatigueScore = await _calculatePredictedFatigue(
          date,
          workouts,
          readiness,
          hrvReadings,
          i,
        );

        predictions.add(
          FatiguePrediction(
            date: date,
            predictedFatigueScore: fatigueScore,
            recommendedTier: _fatigueToTier(fatigueScore),
            confidence: _calculateConfidence(i, daysAhead),
            contributingFactors: _identifyFatigueFactors(
              fatigueScore,
              workouts,
              readiness,
            ),
          ),
        );
      }

      return predictions;
    } catch (e) {
      developer.log(
        'Error predicting fatigue: $e',
        name: 'DomRlEngineV2',
        error: e,
      );
      return [];
    }
  }

  Future<double> _calculatePredictedFatigue(
    DateTime date,
    List<CompletedWorkout> recentWorkouts,
    List<DailyReadiness> recentReadiness,
    List<Biometrics> hrvReadings,
    int daysOut,
  ) async {
    // Base fatigue from recent training load
    double baseFatigue = 50.0;

    // Recent training volume impact (decays over time)
    final recentVolume = recentWorkouts
        .where(
          (w) => w.startTime.isAfter(date.subtract(const Duration(days: 7))),
        )
        .fold<int>(0, (sum, w) => sum + w.totalDurationMinutes);

    baseFatigue += (recentVolume / 300) * 10; // 5 hours/week adds ~10 points

    // HRV trend impact
    if (hrvReadings.length >= 3) {
      final hrvTrend = _calculateTrend(
        hrvReadings.map((r) => r.value).toList(),
      );
      if (hrvTrend < -0.1) {
        baseFatigue += 15; // Declining HRV = increasing fatigue
      } else if (hrvTrend > 0.1) {
        baseFatigue -= 10; // Improving HRV = recovering well
      }
    }

    // Recent readiness trend
    if (recentReadiness.isNotEmpty) {
      final avgReadiness =
          recentReadiness
              .map((r) => r.overallReadiness)
              .reduce((a, b) => a + b) /
          recentReadiness.length;
      baseFatigue += (100 - avgReadiness) * 0.3;
    }

    // Recovery projection (fatigue naturally decreases with rest)
    final projectedRecovery = daysOut * 5; // 5 points recovery per day
    baseFatigue -= projectedRecovery;

    return baseFatigue.clamp(0, 100);
  }

  String _fatigueToTier(double fatigueScore) {
    if (fatigueScore < 30) return 'elite';
    if (fatigueScore < 50) return 'ready';
    if (fatigueScore < 70) return 'fatigued';
    return 'recovery';
  }

  double _calculateConfidence(int daysOut, int maxDays) {
    // Confidence decreases as we predict further out
    return (1 - (daysOut / maxDays) * 0.3).clamp(0.5, 1.0);
  }

  List<String> _identifyFatigueFactors(
    double fatigueScore,
    List<CompletedWorkout> workouts,
    List<DailyReadiness> readiness,
  ) {
    final factors = <String>[];

    if (workouts.length > 5) {
      factors.add('High training frequency');
    }

    final highIntensityWorkouts = workouts.where((w) {
      final avgRPE =
          w.exercises.fold<double>(0, (sum, e) {
            if (e.sets.isEmpty) return sum;
            return sum +
                e.sets.map((s) => s.actualRPE ?? 7).reduce((a, b) => a + b) /
                    e.sets.length;
          }) /
          (w.exercises.isEmpty ? 1 : w.exercises.length);
      return avgRPE > 8;
    }).length;

    if (highIntensityWorkouts >= 3) {
      factors.add('Multiple high-intensity sessions');
    }

    if (readiness.isNotEmpty) {
      final poorSleep = readiness
          .where((r) => (r.sleepQuality ?? 0) < 5)
          .length;
      if (poorSleep >= 2) {
        factors.add('Inadequate sleep quality');
      }
    }

    if (fatigueScore > 70) {
      factors.add('Accumulated fatigue');
    }

    return factors;
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0;

    final first = values.first;
    final last = values.last;
    return (last - first) / first;
  }

  // ==================== PERIODIZATION ====================

  /// Generate a mesocycle (4-week training block) with periodization
  Future<MesocyclePlan> generateMesocycle({
    required String userId,
    required TrainingGoal goal,
    required ExperienceLevel experienceLevel,
    int weeks = 4,
    int trainingDaysPerWeek = 4,
  }) async {
    try {
      // Get user's recent data for personalization
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      final recentWorkouts = await _workoutRepository.getWorkoutsForDateRange(
        userId,
        startDate,
        endDate,
      );
      final avgVolume = recentWorkouts.isEmpty
          ? 0.0
          : (recentWorkouts.fold<int>(
                      0,
                      (sum, w) => sum + w.totalDurationMinutes,
                    ) /
                    recentWorkouts.length)
                .toDouble();

      final weeklyPlans = <WeeklyPlan>[];

      for (int week = 1; week <= weeks; week++) {
        final weeklyPlan = _generateWeeklyPlan(
          week: week,
          totalWeeks: weeks,
          goal: goal,
          experienceLevel: experienceLevel,
          trainingDaysPerWeek: trainingDaysPerWeek,
          baseVolume: avgVolume,
        );
        weeklyPlans.add(weeklyPlan);
      }

      return MesocyclePlan(
        userId: userId,
        weeks: weeklyPlans,
        goal: goal,
        experienceLevel: experienceLevel,
        startDate: DateTime.now(),
      );
    } catch (e) {
      developer.log(
        'Error generating mesocycle: $e',
        name: 'DomRlEngineV2',
        error: e,
      );
      return MesocyclePlan.empty();
    }
  }

  WeeklyPlan _generateWeeklyPlan({
    required int week,
    required int totalWeeks,
    required TrainingGoal goal,
    required ExperienceLevel experienceLevel,
    required int trainingDaysPerWeek,
    required double baseVolume,
  }) {
    // Periodization: volume increases, then tapers in final week
    double volumeMultiplier;
    if (week < totalWeeks - 1) {
      // Accumulation weeks: gradual increase
      volumeMultiplier = 1.0 + (week * 0.1);
    } else {
      // Deload week: reduce volume
      volumeMultiplier = 0.6;
    }

    // Adjust intensity based on goal and experience
    final baseIntensity = _getBaseIntensityForGoal(goal);
    final experienceModifier = _getExperienceModifier(experienceLevel);

    return WeeklyPlan(
      weekNumber: week,
      trainingDays: trainingDaysPerWeek,
      targetVolume: (baseVolume * volumeMultiplier).round(),
      targetIntensity: (baseIntensity * experienceModifier).clamp(6.0, 9.5),
      focus: _getFocusForWeek(week, totalWeeks, goal),
      notes: _generateWeekNotes(week, totalWeeks, volumeMultiplier),
    );
  }

  double _getBaseIntensityForGoal(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.mma:
      case TrainingGoal.boxing:
      case TrainingGoal.muayThai:
        return 8.0; // Combat sports need high intensity
      case TrainingGoal.strength:
        return 7.5;
      case TrainingGoal.conditioning:
        return 8.5;
      default:
        return 7.0;
    }
  }

  double _getExperienceModifier(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.novice:
        return 0.9; // Slightly lower intensity
      case ExperienceLevel.hoplite:
        return 1.0;
      case ExperienceLevel.spartan:
        return 1.05;
      case ExperienceLevel.legend:
        return 1.1;
    }
  }

  String _getFocusForWeek(int week, int totalWeeks, TrainingGoal goal) {
    if (week == totalWeeks) return 'Recovery/Deload';
    if (week <= 2) return 'Volume/Technique';
    if (goal == TrainingGoal.strength) return 'Strength/Power';
    return 'Intensity/Conditioning';
  }

  String _generateWeekNotes(int week, int totalWeeks, double volumeMultiplier) {
    if (week == totalWeeks) {
      return 'Deload week: Reduce volume by 40%, focus on technique and recovery';
    }
    final percentage = ((volumeMultiplier - 1) * 100).round();
    return 'Week $week: ${percentage > 0 ? '+$percentage' : percentage}% volume adjustment';
  }

  // ==================== PROGRESSIVE OVERLOAD ====================

  /// Analyze exercise progress and suggest next progression
  Future<ProgressionRecommendation> suggestProgression(
    String userId,
    String exerciseId,
    String exerciseName,
  ) async {
    try {
      final history = await _workoutRepository.getExerciseHistory(
        userId,
        exerciseId,
        limit: 10,
      );

      if (history.length < 3) {
        return ProgressionRecommendation(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          recommendation: ProgressionType.maintain,
          reason: 'Insufficient data for progression analysis',
          suggestedChange: null,
        );
      }

      // Analyze trend
      final recent = history.sublist(
        0,
        history.length > 5 ? 5 : history.length,
      );
      final older = history.sublist(history.length > 5 ? 5 : 0);

      final recentMaxWeight = recent
          .map((h) => h.maxWeight)
          .reduce((a, b) => a > b ? a : b);
      final olderMaxWeight = older
          .map((h) => h.maxWeight)
          .reduce((a, b) => a > b ? a : b);

      final recentAvgReps =
          recent
              .map((h) => h.totalReps / h.sets.length)
              .reduce((a, b) => a + b) /
          recent.length;
      final olderAvgReps =
          older
              .map((h) => h.totalReps / h.sets.length)
              .reduce((a, b) => a + b) /
          older.length;

      // Determine if ready for progression
      ProgressionType recommendation;
      String? suggestedChange;
      String reason;

      if (recentMaxWeight > olderMaxWeight * 1.05) {
        // Weight has increased
        if (recentAvgReps >= olderAvgReps * 0.95) {
          recommendation = ProgressionType.increaseWeight;
          suggestedChange = 'Add 2.5-5 lbs to working sets';
          reason = 'Successfully handling current weight with good reps';
        } else {
          recommendation = ProgressionType.maintain;
          reason =
              'Weight increased but reps decreased - consolidate at current level';
        }
      } else if (recentAvgReps > olderAvgReps * 1.1) {
        // Reps have increased significantly
        recommendation = ProgressionType.increaseWeight;
        suggestedChange = 'Add 2.5-5 lbs, expect 1-2 fewer reps';
        reason = 'Reps consistently above target - ready for more load';
      } else if (recentAvgReps < olderAvgReps * 0.9) {
        // Reps declining
        recommendation = ProgressionType.reduceLoad;
        suggestedChange = 'Reduce weight by 5-10% for 1 week';
        reason = 'Reps declining - possible fatigue or overreaching';
      } else {
        recommendation = ProgressionType.maintain;
        reason = 'Stable performance - continue current progression';
      }

      return ProgressionRecommendation(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recommendation: recommendation,
        reason: reason,
        suggestedChange: suggestedChange,
        currentMaxWeight: recentMaxWeight,
        currentAvgReps: recentAvgReps,
        trendData: history.map((h) => h.maxWeight).toList(),
      );
    } catch (e) {
      developer.log(
        'Error suggesting progression: $e',
        name: 'DomRlEngineV2',
        error: e,
      );
      return ProgressionRecommendation(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        recommendation: ProgressionType.maintain,
        reason: 'Error analyzing progression',
      );
    }
  }

  // ==================== DELOAD DETECTION ====================

  /// Detect if user needs a deload based on multiple fatigue indicators
  Future<DeloadRecommendation> checkDeloadNeeded(String userId) async {
    try {
      final now = DateTime.now();
      final last7Days = now.subtract(const Duration(days: 7));
      final last14Days = now.subtract(const Duration(days: 14));

      // Gather data
      final workouts = await _workoutRepository.getWorkoutsForDateRange(
        userId,
        last14Days,
        now,
      );
      final readiness = await _readinessRepository.getRecentReadiness(
        userId,
        days: 7,
      );
      final hrvReadings = await _biometricsRepository.getBiometricsForRange(
        userId,
        last7Days,
        now,
      );

      final indicators = <DeloadIndicator>[];

      // Check 1: Declining HRV
      if (hrvReadings.length >= 3) {
        final hrvTrend = _calculateTrend(
          hrvReadings.map((r) => r.hrv ?? 0).toList(),
        );
        if (hrvTrend < -0.15) {
          indicators.add(
            DeloadIndicator(
              type: DeloadIndicatorType.hrvDecline,
              severity: hrvTrend < -0.25
                  ? DeloadSeverity.high
                  : DeloadSeverity.moderate,
              message: 'HRV declining - sympathetic dominance detected',
            ),
          );
        }
      }

      // Check 2: Declining readiness scores
      if (readiness.length >= 3) {
        final readinessTrend = _calculateTrend(
          readiness.map((r) => r.overallReadiness.toDouble()).toList(),
        );
        if (readinessTrend < -0.1) {
          indicators.add(
            DeloadIndicator(
              type: DeloadIndicatorType.readinessDecline,
              severity: readinessTrend < -0.2
                  ? DeloadSeverity.high
                  : DeloadSeverity.moderate,
              message: 'Readiness scores trending down',
            ),
          );
        }
      }

      // Check 3: High training volume
      final weekVolume = workouts
          .where((w) => w.startTime.isAfter(last7Days))
          .fold<int>(0, (sum, w) => sum + w.totalDurationMinutes);
      if (weekVolume > 400) {
        indicators.add(
          DeloadIndicator(
            type: DeloadIndicatorType.highVolume,
            severity: weekVolume > 500
                ? DeloadSeverity.high
                : DeloadSeverity.moderate,
            message: 'High weekly training volume (${weekVolume ~/ 60}+ hours)',
          ),
        );
      }

      // Check 4: No rest days
      final workoutDays = workouts
          .map(
            (w) =>
                DateTime(w.startTime.year, w.startTime.month, w.startTime.day),
          )
          .toSet();
      if (workoutDays.length >= 6) {
        indicators.add(
          DeloadIndicator(
            type: DeloadIndicatorType.insufficientRest,
            severity: workoutDays.length >= 7
                ? DeloadSeverity.high
                : DeloadSeverity.moderate,
            message: 'Insufficient rest days this week',
          ),
        );
      }

      // Determine overall recommendation
      final highSeverityCount = indicators
          .where((i) => i.severity == DeloadSeverity.high)
          .length;
      final moderateSeverityCount = indicators
          .where((i) => i.severity == DeloadSeverity.moderate)
          .length;

      DeloadRecommendationType recommendation;
      String guidance;

      if (highSeverityCount >= 2 ||
          (highSeverityCount >= 1 && moderateSeverityCount >= 2)) {
        recommendation = DeloadRecommendationType.mandatory;
        guidance =
            'Mandatory deload recommended. Reduce volume by 50-60% for 3-5 days. Focus on recovery, sleep, and light movement.';
      } else if (moderateSeverityCount >= 2 || highSeverityCount >= 1) {
        recommendation = DeloadRecommendationType.recommended;
        guidance =
            'Deload recommended within the next 3 days. Consider a light recovery session or full rest day.';
      } else {
        recommendation = DeloadRecommendationType.notNeeded;
        guidance = 'No deload needed. Continue current training progression.';
      }

      return DeloadRecommendation(
        recommendation: recommendation,
        indicators: indicators,
        guidance: guidance,
        suggestedDurationDays:
            recommendation == DeloadRecommendationType.mandatory ? 5 : 3,
      );
    } catch (e) {
      developer.log(
        'Error checking deload: $e',
        name: 'DomRlEngineV2',
        error: e,
      );
      return DeloadRecommendation.notNeeded();
    }
  }
}

// ==================== DATA CLASSES ====================

class FatiguePrediction {
  final DateTime date;
  final double predictedFatigueScore;
  final String recommendedTier;
  final double confidence;
  final List<String> contributingFactors;

  FatiguePrediction({
    required this.date,
    required this.predictedFatigueScore,
    required this.recommendedTier,
    required this.confidence,
    required this.contributingFactors,
  });

  bool get isHighFatigue => predictedFatigueScore > 70;
  bool get isLowFatigue => predictedFatigueScore < 30;
}

class MesocyclePlan {
  final String userId;
  final List<WeeklyPlan> weeks;
  final TrainingGoal goal;
  final ExperienceLevel experienceLevel;
  final DateTime startDate;

  MesocyclePlan({
    required this.userId,
    required this.weeks,
    required this.goal,
    required this.experienceLevel,
    required this.startDate,
  });

  factory MesocyclePlan.empty() {
    return MesocyclePlan(
      userId: '',
      weeks: [],
      goal: TrainingGoal.generalCombat,
      experienceLevel: ExperienceLevel.novice,
      startDate: DateTime.now(),
    );
  }
}

class WeeklyPlan {
  final int weekNumber;
  final int trainingDays;
  final int targetVolume;
  final double targetIntensity;
  final String focus;
  final String notes;

  WeeklyPlan({
    required this.weekNumber,
    required this.trainingDays,
    required this.targetVolume,
    required this.targetIntensity,
    required this.focus,
    required this.notes,
  });
}

class ProgressionRecommendation {
  final String exerciseId;
  final String exerciseName;
  final ProgressionType recommendation;
  final String reason;
  final String? suggestedChange;
  final double? currentMaxWeight;
  final double? currentAvgReps;
  final List<double>? trendData;

  ProgressionRecommendation({
    required this.exerciseId,
    required this.exerciseName,
    required this.recommendation,
    required this.reason,
    this.suggestedChange,
    this.currentMaxWeight,
    this.currentAvgReps,
    this.trendData,
  });

  bool get shouldIncrease =>
      recommendation == ProgressionType.increaseWeight ||
      recommendation == ProgressionType.increaseReps;
  bool get shouldDecrease => recommendation == ProgressionType.reduceLoad;
}

enum ProgressionType {
  increaseWeight,
  increaseReps,
  maintain,
  reduceLoad,
  deload,
}

class DeloadRecommendation {
  final DeloadRecommendationType recommendation;
  final List<DeloadIndicator> indicators;
  final String guidance;
  final int suggestedDurationDays;

  DeloadRecommendation({
    required this.recommendation,
    required this.indicators,
    required this.guidance,
    required this.suggestedDurationDays,
  });

  factory DeloadRecommendation.notNeeded() {
    return DeloadRecommendation(
      recommendation: DeloadRecommendationType.notNeeded,
      indicators: [],
      guidance: 'No deload needed. Continue current training.',
      suggestedDurationDays: 0,
    );
  }

  bool get isMandatory => recommendation == DeloadRecommendationType.mandatory;
  bool get isRecommended =>
      recommendation == DeloadRecommendationType.recommended;
}

class DeloadIndicator {
  final DeloadIndicatorType type;
  final DeloadSeverity severity;
  final String message;

  DeloadIndicator({
    required this.type,
    required this.severity,
    required this.message,
  });
}

enum DeloadIndicatorType {
  hrvDecline,
  readinessDecline,
  highVolume,
  insufficientRest,
  performanceDecline,
  jointStress,
}

enum DeloadSeverity { low, moderate, high, critical }

enum DeloadRecommendationType { notNeeded, recommended, mandatory }
