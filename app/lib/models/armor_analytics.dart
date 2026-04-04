import 'exercise.dart';

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
