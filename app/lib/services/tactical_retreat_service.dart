import 'package:flutter/foundation.dart';
import '../models/workout_protocol.dart';
import '../models/exercise.dart';
import '../models/workout_tracking.dart';

/// Tactical Retreat System
/// Enforces recovery protocols when readiness drops below critical thresholds
/// Overrides heavy lifting when overtraining detected
class TacticalRetreatService {
  static final TacticalRetreatService _instance = TacticalRetreatService._internal();
  factory TacticalRetreatService() => _instance;
  TacticalRetreatService._internal();

  /// Critical readiness threshold - below this triggers retreat
  static const int _criticalReadinessThreshold = 35;
  
  /// Critical joint stress threshold
  static const int _criticalJointStress = 8;

  /// Check if tactical retreat should be enforced
  TacticalRetreatCheck checkRetreatStatus({
    required int currentReadiness,
    required Map<String, int> jointStress,
    List<JointRiskFlag>? armorAnalysis,
  }) {
    final reasons = <String>[];
    var shouldRetreat = false;

    // Check readiness threshold
    if (currentReadiness < _criticalReadinessThreshold) {
      shouldRetreat = true;
      reasons.add('Readiness $currentReadiness below critical threshold $_criticalReadinessThreshold');
    }

    // Check joint stress
    final criticalJoints = jointStress.entries
        .where((e) => e.value >= _criticalJointStress)
        .map((e) => e.key)
        .toList();
    
    if (criticalJoints.isNotEmpty) {
      shouldRetreat = true;
      reasons.add('Critical joint stress detected: ${criticalJoints.join(', ')}');
    }

    // Check armor analytics if provided
    if (armorAnalysis != null) {
      final criticalFlags = armorAnalysis.where((r) => r.riskLevel == JointRiskLevel.critical).toList();
      if (criticalFlags.isNotEmpty) {
        shouldRetreat = true;
        reasons.add('${criticalFlags.length} critical injury risk flags from Armor Analytics');
      }
    }

    // Build recovery protocol if retreat triggered
    WorkoutProtocol? enforcedProtocol;
    if (shouldRetreat) {
      enforcedProtocol = _buildRecoveryProtocol();
    }

    return TacticalRetreatCheck(
      shouldRetreat: shouldRetreat,
      reasons: reasons,
      enforcedProtocol: enforcedProtocol,
      retreatDuration: shouldRetreat ? '24-48 hours' : null,
      recommendations: shouldRetreat ? const [
        'PRIORITY 1: Sleep 8+ hours tonight',
        'Hydration: 3L minimum daily',
        'Light movement only - walking, gentle stretching',
        'No training until readiness > 50',
        'Consider cold therapy for joint inflammation',
      ] : [],
    );
  }

  /// Build mandatory recovery protocol
  WorkoutProtocol _buildRecoveryProtocol() {
    return WorkoutProtocol(
      title: 'TACTICAL RETREAT: MANDATORY RECOVERY',
      subtitle: 'Your body demands restoration. Honor it. This is strategy, not weakness.',
      tier: ProtocolTier.recovery,
      entries: [
        // Hip mobility
        ProtocolEntry(
          exercise: Exercise.library.firstWhere(
            (e) => e.id == 'ex_019',
            orElse: () => Exercise.library.firstWhere((e) => e.category == ExerciseCategory.mobility),
          ),
          sets: 3,
          reps: 0,
          intensityRpe: 3,
          restSeconds: 60,
        ),
        // Thoracic bridge
        ProtocolEntry(
          exercise: Exercise.library.firstWhere(
            (e) => e.id == 'ex_020',
            orElse: () => Exercise.library.firstWhere((e) => e.category == ExerciseCategory.mobility),
          ),
          sets: 3,
          reps: 0,
          intensityRpe: 3,
          restSeconds: 60,
        ),
        // Light plank
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == 'ex_005'),
          sets: 2,
          reps: 0,
          intensityRpe: 4,
          restSeconds: 90,
        ),
        // Shadow boxing for light movement
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == 'ex_006'),
          sets: 3,
          reps: 0,
          intensityRpe: 3,
          restSeconds: 60,
        ),
      ],
      estimatedDurationMinutes: 25,
      mindsetPrompt: 'The wise warrior knows when to rest. This is not weakness. This is strategy. Recovery is where victory is forged.',
    );
  }

  /// Get preemptive warning before workout starts
  RetreatWarning? getPreemptiveWarning({
    required int currentReadiness,
    required Map<String, int> jointStress,
  }) {
    final warnings = <String>[];
    var warningLevel = RetreatWarningLevel.none;

    // Approaching critical readiness
    if (currentReadiness >= _criticalReadinessThreshold && currentReadiness < 50) {
      warnings.add('Readiness approaching critical threshold. Consider reducing volume.');
      warningLevel = RetreatWarningLevel.caution;
    }

    // Elevated joint stress
    final elevatedJoints = jointStress.entries
        .where((e) => e.value >= 6 && e.value < _criticalJointStress)
        .map((e) => e.key)
        .toList();
    
    if (elevatedJoints.isNotEmpty) {
      warnings.add('Elevated stress in: ${elevatedJoints.join(', ')}. Substitute movements recommended.');
      warningLevel = warningLevel == RetreatWarningLevel.caution 
          ? RetreatWarningLevel.warning 
          : RetreatWarningLevel.caution;
    }

    // High readiness but joint stress mismatch
    if (currentReadiness > 75 && jointStress.values.any((s) => s > 6)) {
      warnings.add('Readiness high but joint stress detected. CNS fatigue possible. Prioritize non-impact movements.');
      warningLevel = RetreatWarningLevel.warning;
    }

    if (warnings.isEmpty) return null;

    return RetreatWarning(
      level: warningLevel,
      messages: warnings,
      recommendations: _getWarningRecommendations(warningLevel),
    );
  }

  List<String> _getWarningRecommendations(RetreatWarningLevel level) {
    switch (level) {
      case RetreatWarningLevel.none:
        return [];
      case RetreatWarningLevel.caution:
        return [
          'Reduce volume by 10-20%',
          'Add 15-30s rest between sets',
          'Monitor RPE closely - stop if exceeding 8',
        ];
      case RetreatWarningLevel.warning:
        return [
          'Reduce volume by 30% minimum',
          'Avoid max effort sets',
          'Prioritize technique over load',
          'Consider ending session early if quality degrades',
        ];
    }
  }

  /// Check if a specific exercise should be blocked
  bool shouldBlockExercise({
    required Exercise exercise,
    required Map<String, int> currentJointStress,
  }) {
    for (final entry in exercise.jointStress.entries) {
      final joint = entry.key;
      final stressLevel = entry.value;
      final currentStress = currentJointStress[joint] ?? 0;
      
      // Block if adding this would push joint into critical territory
      if (currentStress + stressLevel > _criticalJointStress) {
        return true;
      }
    }
    return false;
  }

  /// Get safe alternatives for a blocked exercise
  List<Exercise> getSafeAlternatives({
    required Exercise original,
    required Map<String, int> currentJointStress,
  }) {
    return Exercise.library.where((e) {
      // Similar category preferred
      if (e.category != original.category) return false;
      
      // Check if this alternative would also be blocked
      for (final entry in e.jointStress.entries) {
        final currentStress = currentJointStress[entry.key] ?? 0;
        if (currentStress + entry.value > _criticalJointStress - 1) {
          return false;
        }
      }
      
      return true;
    }).toList()
      ..sort((a, b) {
        // Sort by total joint stress (lower first)
        final aStress = a.jointStress.values.fold(0, (sum, v) => sum + v);
        final bStress = b.jointStress.values.fold(0, (sum, v) => sum + v);
        return aStress.compareTo(bStress);
      });
  }
}

/// Tactical retreat check result
class TacticalRetreatCheck {
  final bool shouldRetreat;
  final List<String> reasons;
  final WorkoutProtocol? enforcedProtocol;
  final String? retreatDuration;
  final List<String> recommendations;

  TacticalRetreatCheck({
    required this.shouldRetreat,
    required this.reasons,
    this.enforcedProtocol,
    this.retreatDuration,
    required this.recommendations,
  });
}

/// Preemptive retreat warning
class RetreatWarning {
  final RetreatWarningLevel level;
  final List<String> messages;
  final List<String> recommendations;

  RetreatWarning({
    required this.level,
    required this.messages,
    required this.recommendations,
  });

  bool get shouldShow => level != RetreatWarningLevel.none;
}

enum RetreatWarningLevel {
  none,
  caution,
  warning,
}

// Re-export for compatibility
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
