import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';

/// Ephor Scrutiny - Weekly Micro-Cycle Review
/// Analyzes past 7 days of training data and auto-generates next week's protocol
/// Runs locally on device
class EphorScrutinyService {
  static final EphorScrutinyService _instance = EphorScrutinyService._internal();
  factory EphorScrutinyService() => _instance;
  EphorScrutinyService._internal();

  /// Minimum days of data required for meaningful analysis
  static const int _minDaysRequired = 3;

  /// Run weekly Ephor Scrutiny analysis
  /// Returns detailed analysis with next week's recommendations
  EphorAnalysis analyzeMicroCycle(MicroCycle microCycle) {
    if (microCycle.days.length < _minDaysRequired) {
      return EphorAnalysis(
        recommendation: EphorRecommendation.insufficientData,
        protocolTier: ProtocolTier.ready,
        message: 'At least $_minDaysRequired days of data required for Ephor analysis.',
        metrics: EphorMetrics.empty(),
        trainingPrinciples: const [
          'Continue logging daily workouts for personalized recommendations',
        ],
      );
    }

    // Calculate metrics
    final readinessScores = microCycle.days.map((d) => d.readinessScore).toList();
    final avgReadiness = readinessScores.reduce((a, b) => a + b) / readinessScores.length;
    final readinessVolatility = _calculateVolatility(readinessScores);

    final sleepScores = microCycle.days.map((d) => d.sleepQuality).toList();
    final avgSleep = sleepScores.reduce((a, b) => a + b) / sleepScores.length;

    final sleepHours = microCycle.days.map((d) => d.sleepHours).toList();
    final avgSleepHours = sleepHours.reduce((a, b) => a + b) / sleepHours.length;

    // Joint stress analysis
    final jointStressReport = <String, JointStressAnalysis>{};
    final allJoints = <String>{};
    for (final day in microCycle.days) {
      allJoints.addAll(day.jointFatigue.keys);
    }

    for (final joint in allJoints) {
      final values = microCycle.days
          .map((d) => d.jointFatigue[joint] ?? 0)
          .where((v) => v > 0)
          .toList();

      if (values.isNotEmpty) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        final max = values.reduce((a, b) => a > b ? a : b);
        final trend = values.last > values.first ? StressTrend.increasing 
                     : values.last < values.first ? StressTrend.decreasing 
                     : StressTrend.stable;

        jointStressReport[joint] = JointStressAnalysis(
          average: avg,
          max: max,
          trend: trend,
        );
      }
    }

    // Determine recommendation
    EphorRecommendation recommendation;
    ProtocolTier protocolTier;
    String message;

    if (avgReadiness < 50 && avgSleep < 5) {
      recommendation = EphorRecommendation.deloadRecovery;
      protocolTier = ProtocolTier.recovery;
      message = 'Central nervous system shows signs of overreaching. Mandatory deload week enforced.';
    } else if (avgReadiness < 65 || avgSleepHours < 6) {
      recommendation = EphorRecommendation.maintenance;
      protocolTier = ProtocolTier.fatigued;
      message = 'Fatigue accumulation detected. Reduce volume 30%, maintain intensity. Prioritize sleep.';
    } else if (avgReadiness > 85 && avgSleep > 7 && avgSleepHours > 7.5) {
      recommendation = EphorRecommendation.progressiveOverload;
      protocolTier = ProtocolTier.elite;
      message = 'Excellent recovery metrics. Progressive overload authorized. Test new RPE thresholds.';
    } else if (readinessVolatility > 15) {
      recommendation = EphorRecommendation.stabilize;
      protocolTier = ProtocolTier.ready;
      message = 'High readiness volatility detected. Stabilize routine before progressing.';
    } else {
      recommendation = EphorRecommendation.steadyState;
      protocolTier = ProtocolTier.ready;
      message = 'Stable metrics. Continue current progression. Maintain consistency.';
    }

    // Generate training principles
    final principles = <String>[
      if (jointStressReport.values.any((j) => j.average > 6))
        'Prioritize movements with lowest joint stress scores',
      if (avgSleepHours < 7)
        'Sleep optimization is critical - aim for 8+ hours',
      if (avgReadiness > 80)
        'High readiness - incorporate explosive plyometric work',
      'Target weekly volume: ${(microCycle.days.length * 50 * _getVolumeMultiplier(protocolTier)).round()} RPE-minutes',
    ];

    return EphorAnalysis(
      recommendation: recommendation,
      protocolTier: protocolTier,
      message: message,
      metrics: EphorMetrics(
        avgReadiness: avgReadiness,
        readinessVolatility: readinessVolatility,
        avgSleepQuality: avgSleep,
        avgSleepHours: avgSleepHours,
        jointStressReport: jointStressReport,
        totalTrainingDays: microCycle.days.where((d) => d.rpeEntries.isNotEmpty).length,
      ),
      trainingPrinciples: principles,
    );
  }

  /// Calculate coefficient of variation (volatility)
  double _calculateVolatility(List<int> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2).toDouble()).toList();
    final variance = squaredDiffs.reduce((a, b) => a + b) / squaredDiffs.length;
    final stdDev = sqrt(variance);
    
    return (stdDev / mean) * 100; // Coefficient of variation as percentage
  }

  double _getVolumeMultiplier(ProtocolTier tier) {
    switch (tier) {
      case ProtocolTier.elite:
        return 1.15;
      case ProtocolTier.ready:
        return 1.0;
      case ProtocolTier.fatigued:
        return 0.7;
      case ProtocolTier.recovery:
        return 0.4;
    }
  }

  /// Generate next week's protocol based on analysis
  NextWeekPlan generateNextWeekPlan(EphorAnalysis analysis) {
    final days = <PlannedDay>[];
    
    // Generate 7 days of planned workouts
    for (int i = 0; i < 7; i++) {
      final isRestDay = i == 3 || i == 6; // Wed and Sun as rest
      
      PlannedDay day;
      if (isRestDay) {
        day = PlannedDay(
          dayOfWeek: i,
          isRestDay: true,
          focus: 'Active Recovery',
          recommendedRPE: 3,
          estimatedDuration: 20,
        );
      } else {
        final focus = _determineDailyFocus(i, analysis.protocolTier);
        day = PlannedDay(
          dayOfWeek: i,
          isRestDay: false,
          focus: focus,
          recommendedRPE: _getTargetRPE(analysis.protocolTier),
          estimatedDuration: _getTargetDuration(analysis.protocolTier),
        );
      }
      
      days.add(day);
    }

    return NextWeekPlan(
      analysis: analysis,
      plannedDays: days,
      weekStarting: DateTime.now().add(Duration(days: 7 - DateTime.now().weekday + 1)),
    );
  }

  String _determineDailyFocus(int dayIndex, ProtocolTier tier) {
    final focuses = tier == ProtocolTier.elite
        ? ['Power/Explosive', 'Strength', 'Combat Conditioning', 'Rest', 'Power/Strength', 'Sprint/Plyo', 'Recovery']
        : tier == ProtocolTier.fatigued
            ? ['Maintenance', 'Mobility/Skill', 'Light Conditioning', 'Rest', 'Maintenance', 'Active Recovery', 'Rest']
            : tier == ProtocolTier.recovery
                ? ['Mobility', 'Light Movement', 'Recovery', 'Rest', 'Mobility', 'Recovery', 'Rest']
                : ['Strength', 'Combat Conditioning', 'Power', 'Rest', 'Strength', 'Sprint/Conditioning', 'Active Recovery'];
    
    return focuses[dayIndex % focuses.length];
  }

  double _getTargetRPE(ProtocolTier tier) {
    switch (tier) {
      case ProtocolTier.elite:
        return 8.5;
      case ProtocolTier.ready:
        return 7.5;
      case ProtocolTier.fatigued:
        return 6.0;
      case ProtocolTier.recovery:
        return 4.0;
    }
  }

  int _getTargetDuration(ProtocolTier tier) {
    switch (tier) {
      case ProtocolTier.elite:
        return 60;
      case ProtocolTier.ready:
        return 50;
      case ProtocolTier.fatigued:
        return 35;
      case ProtocolTier.recovery:
        return 25;
    }
  }
}

/// Ephor analysis result
class EphorAnalysis {
  final EphorRecommendation recommendation;
  final ProtocolTier protocolTier;
  final String message;
  final EphorMetrics metrics;
  final List<String> trainingPrinciples;

  EphorAnalysis({
    required this.recommendation,
    required this.protocolTier,
    required this.message,
    required this.metrics,
    required this.trainingPrinciples,
  });
}

enum EphorRecommendation {
  insufficientData,
  deloadRecovery,
  maintenance,
  progressiveOverload,
  steadyState,
  stabilize,
}

/// Ephor metrics from analysis
class EphorMetrics {
  final double avgReadiness;
  final double readinessVolatility;
  final double avgSleepQuality;
  final double avgSleepHours;
  final Map<String, JointStressAnalysis> jointStressReport;
  final int totalTrainingDays;

  EphorMetrics({
    required this.avgReadiness,
    required this.readinessVolatility,
    required this.avgSleepQuality,
    required this.avgSleepHours,
    required this.jointStressReport,
    required this.totalTrainingDays,
  });

  factory EphorMetrics.empty() {
    return EphorMetrics(
      avgReadiness: 0,
      readinessVolatility: 0,
      avgSleepQuality: 0,
      avgSleepHours: 0,
      jointStressReport: const {},
      totalTrainingDays: 0,
    );
  }
}

/// Joint stress analysis
class JointStressAnalysis {
  final double average;
  final int max;
  final StressTrend trend;

  JointStressAnalysis({
    required this.average,
    required this.max,
    required this.trend,
  });
}

enum StressTrend {
  increasing,
  decreasing,
  stable,
}

/// Next week's training plan
class NextWeekPlan {
  final EphorAnalysis analysis;
  final List<PlannedDay> plannedDays;
  final DateTime weekStarting;

  NextWeekPlan({
    required this.analysis,
    required this.plannedDays,
    required this.weekStarting,
  });
}

/// Individual planned day
class PlannedDay {
  final int dayOfWeek; // 0-6 (Mon-Sun)
  final bool isRestDay;
  final String focus;
  final double recommendedRPE;
  final int estimatedDuration;

  PlannedDay({
    required this.dayOfWeek,
    required this.isRestDay,
    required this.focus,
    required this.recommendedRPE,
    required this.estimatedDuration,
  });

  String get dayName {
    final names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[dayOfWeek];
  }
}
