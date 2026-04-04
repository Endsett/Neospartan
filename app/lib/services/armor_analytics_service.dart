import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/workout_tracking.dart';
import '../models/exercise.dart';

/// Armor Analytics - Joint and Muscle Load Analysis
/// Tracks cumulative load on joints/muscles and flags overuse risks
/// Runs locally on device
class ArmorAnalyticsService {
  static final ArmorAnalyticsService _instance = ArmorAnalyticsService._internal();
  factory ArmorAnalyticsService() => _instance;
  ArmorAnalyticsService._internal();

  /// High risk threshold for average joint stress
  static const double _highRiskThreshold = 6.5;
  
  /// Critical risk threshold for max joint stress
  static const double _criticalRiskThreshold = 8.0;
  
  /// Elevated risk trend threshold
  static const double _elevatedTrendThreshold = 2.0;

  /// Analyze micro-cycle for joint/muscle load patterns
  ArmorAnalyticsResult analyze(MicroCycle microCycle) {
    final jointLoadHistory = <String, List<int>>{};
    final muscleGroupVolume = <String, double>{};

    // Aggregate joint stress across days
    for (final day in microCycle.days) {
      day.jointFatigue.forEach((joint, fatigue) {
        jointLoadHistory.putIfAbsent(joint, () => []);
        jointLoadHistory[joint]!.add(fatigue);
      });
    }

    // Calculate risk flags
    final riskFlags = <JointRiskFlag>[];
    
    jointLoadHistory.forEach((joint, loads) {
      final avgLoad = loads.reduce((a, b) => a + b) / loads.length;
      final maxLoad = loads.reduce((a, b) => a > b ? a : b);
      final trend = loads.last - loads.first;

      // Check for high average stress
      if (avgLoad > _highRiskThreshold) {
        riskFlags.add(JointRiskFlag(
          joint: joint,
          riskLevel: JointRiskLevel.high,
          message: '$joint averaging ${avgLoad.toStringAsFixed(1)}/10 stress. Mandatory 48hr rest from loading.',
          recommendation: RiskRecommendation.substituteLowImpact,
        ));
      }
      // Check for critical peak stress
      else if (maxLoad > _criticalRiskThreshold) {
        riskFlags.add(JointRiskFlag(
          joint: joint,
          riskLevel: JointRiskLevel.critical,
          message: '$joint peaked at $maxLoad/10. Skip all $joint-loading movements for 72hrs.',
          recommendation: RiskRecommendation.fullRest,
        ));
      }
      // Check for increasing trend
      else if (trend > _elevatedTrendThreshold) {
        riskFlags.add(JointRiskFlag(
          joint: joint,
          riskLevel: JointRiskLevel.elevated,
          message: '$joint stress trending upward (+$trend). Reduce volume 20%.',
          recommendation: RiskRecommendation.volumeReduce,
        ));
      }
    });

    // Determine safe movements (exercises that don't stress flagged joints)
    final safeMovements = _determineSafeMovements(riskFlags);

    return ArmorAnalyticsResult(
      jointLoadHistory: jointLoadHistory,
      riskFlags: riskFlags,
      safeMovements: safeMovements,
      summary: riskFlags.isEmpty 
          ? 'All systems nominal' 
          : '${riskFlags.length} risk flags detected',
      muscleGroupVolume: muscleGroupVolume,
    );
  }

  /// Determine which exercises are safe given current risk flags
  List<Exercise> _determineSafeMovements(List<JointRiskFlag> riskFlags) {
    final criticalOrHighJoints = riskFlags
        .where((r) => r.riskLevel == JointRiskLevel.critical || r.riskLevel == JointRiskLevel.high)
        .map((r) => r.joint)
        .toSet();

    return Exercise.library.where((exercise) {
      // Check if exercise stresses any critical/high-risk joint
      for (final joint in criticalOrHighJoints) {
        if (exercise.jointStress.containsKey(joint) && exercise.jointStress[joint]! > 3) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Get real-time joint stress estimate during workout
  Map<String, int> estimateCurrentJointStress(
    List<CompletedExerciseEntry> completedExercises,
  ) {
    final stress = <String, int>{};

    for (final entry in completedExercises) {
      final exercise = Exercise.library.firstWhere(
        (e) => e.id == entry.exerciseId,
        orElse: () => Exercise.library.first,
      );

      // Calculate stress per joint based on sets × RPE
      exercise.jointStress.forEach((joint, baseStress) {
        final completedSets = entry.sets.where((s) => s.completed).length;
        final avgRPE = entry.sets.where((s) => s.actualRPE != null).isNotEmpty
            ? entry.sets.where((s) => s.actualRPE != null).map((s) => s.actualRPE!).reduce((a, b) => a + b) / 
              entry.sets.where((s) => s.actualRPE != null).length
            : entry.targetRPE;

        final sessionStress = (baseStress * completedSets * (avgRPE / 10)).round();
        
        stress[joint] = (stress[joint] ?? 0) + sessionStress;
      });
    }

    // Normalize to 1-10 scale
    return stress.map((joint, value) => MapEntry(joint, (value / 3).clamp(1, 10).round()));
  }

  /// Check if a specific exercise should be avoided
  bool shouldAvoidExercise(
    Exercise exercise,
    List<JointRiskFlag> currentRiskFlags,
  ) {
    for (final flag in currentRiskFlags) {
      if (flag.riskLevel == JointRiskLevel.critical || flag.riskLevel == JointRiskLevel.high) {
        if (exercise.jointStress.containsKey(flag.joint) && exercise.jointStress[flag.joint]! > 3) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get recommended substitutes for a risky exercise
  List<Exercise> getSubstitutes(
    Exercise original,
    List<JointRiskFlag> riskFlags,
  ) {
    final riskyJoints = riskFlags
        .where((r) => r.riskLevel != JointRiskLevel.low)
        .map((r) => r.joint)
        .toSet();

    return Exercise.library.where((e) {
      // Same category preferred
      if (e.category != original.category) return false;
      
      // Doesn't stress risky joints
      for (final joint in riskyJoints) {
        if (e.jointStress.containsKey(joint) && e.jointStress[joint]! > 4) {
          return false;
        }
      }
      
      return true;
    }).toList()
      ..sort((a, b) {
        // Prefer lower intensity alternatives when recovering
        final aTotalStress = a.jointStress.values.fold(0, (sum, v) => sum + v);
        final bTotalStress = b.jointStress.values.fold(0, (sum, v) => sum + v);
        return aTotalStress.compareTo(bTotalStress);
      });
  }

  /// Calculate cumulative load for a specific joint over time
  List<Map<String, dynamic>> calculateJointLoadTrend(
    String joint,
    MicroCycle microCycle,
  ) {
    final trend = <Map<String, dynamic>>[];
    
    for (final day in microCycle.days) {
      final stress = day.jointFatigue[joint] ?? 0;
      trend.add({
        'date': day.date.toIso8601String(),
        'stress': stress,
        'warning': stress > _highRiskThreshold,
      });
    }
    
    return trend;
  }
}

/// Armor Analytics result
class ArmorAnalyticsResult {
  final Map<String, List<int>> jointLoadHistory;
  final Map<String, double> muscleGroupVolume;
  final List<JointRiskFlag> riskFlags;
  final List<Exercise> safeMovements;
  final String summary;

  ArmorAnalyticsResult({
    required this.jointLoadHistory,
    required this.muscleGroupVolume,
    required this.riskFlags,
    required this.safeMovements,
    required this.summary,
  });

  /// Get highest risk level currently present
  JointRiskLevel get highestRisk {
    if (riskFlags.isEmpty) return JointRiskLevel.low;
    return riskFlags.map((r) => r.riskLevel).reduce((a, b) => 
      a.index > b.index ? a : b
    );
  }

  /// Check if any critical risks exist
  bool get hasCriticalRisk => riskFlags.any((r) => r.riskLevel == JointRiskLevel.critical);

  /// Check if training should be modified
  bool get shouldModifyTraining => riskFlags.any((r) => 
    r.riskLevel == JointRiskLevel.high || r.riskLevel == JointRiskLevel.critical
  );
}

/// Joint risk flag
class JointRiskFlag {
  final String joint;
  final JointRiskLevel riskLevel;
  final String message;
  final RiskRecommendation recommendation;

  JointRiskFlag({
    required this.joint,
    required this.riskLevel,
    required this.message,
    required this.recommendation,
  });
}

enum JointRiskLevel {
  low,
  elevated,
  high,
  critical,
}

enum RiskRecommendation {
  substituteLowImpact,
  fullRest,
  volumeReduce,
  monitor,
}
