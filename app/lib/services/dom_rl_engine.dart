import 'package:flutter/foundation.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';
import '../models/exercise.dart';

/// DOM-RL (Dynamic Multi-Objective Reinforcement Learning) Engine
/// Runs locally on device using TensorFlow Lite for inference
/// Optimizes workout protocols based on user's physiological state
class DomRlEngine {
  static final DomRlEngine _instance = DomRlEngine._internal();
  factory DomRlEngine() => _instance;
  DomRlEngine._internal();


  bool _isInitialized = false;
  bool _useHeuristicFallback = true; // Use heuristic if TFLite not available

  // DOM-RL weights for multi-objective optimization (placeholder for model usage)
  static const double powerWeight = 0.4;
  static const double enduranceWeight = 0.3;
  static const double recoveryWeight = 0.3;

  Future<void> initialize() async {
    try {
      // Try to load TFLite model if available
      // In production, this would load a trained DOM-RL model
      // For now, we use heuristic-based optimization
      _isInitialized = true;
      debugPrint('DOM-RL Engine initialized (heuristic mode)');
    } catch (e) {
      debugPrint('DOM-RL TFLite initialization failed: $e');
      _useHeuristicFallback = true;
      _isInitialized = true;
    }
  }

  /// Calculate current state from micro-cycle data
  DomRlState calculateState(MicroCycle microCycle) {
    if (microCycle.days.isEmpty) {
      return DomRlState(
        readinessScore: 75,
        weeklyVolume: 0.0,
        fatigueAccumulation: {},
        powerOutputTrend: [],
        recoveryMetrics: [],
      );
    }

    // Calculate weekly volume (sum of RPE × sets across all days)
    double weeklyVolume = 0;
    for (final day in microCycle.days) {
      if (day.rpeEntries.isNotEmpty) {
        weeklyVolume += day.rpeEntries.reduce((a, b) => a + b);
      }
    }

    // Calculate fatigue accumulation per joint
    final Map<String, List<int>> jointStressHistory = {};
    for (final day in microCycle.days) {
      day.jointFatigue.forEach((joint, fatigue) {
        jointStressHistory.putIfAbsent(joint, () => []);
        jointStressHistory[joint]!.add(fatigue);
      });
    }

    final fatigueAccumulation = <String, double>{};
    jointStressHistory.forEach((joint, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      // Accumulation factor increases with more days of stress
      fatigueAccumulation[joint] = avg * (1 + values.length * 0.1);
    });

    // Extract trend data
    final powerOutputTrend = microCycle.days.map((d) => d.readinessScore.toDouble()).toList();
    final recoveryMetrics = microCycle.days.map((d) => ((10 - d.jointFatigue['knees']!) as num).toDouble()).toList();

    // Latest readiness score
    final latestReadiness = microCycle.days.last.readinessScore;

    return DomRlState(
      readinessScore: latestReadiness,
      weeklyVolume: weeklyVolume,
      fatigueAccumulation: fatigueAccumulation,
      powerOutputTrend: powerOutputTrend,
      recoveryMetrics: recoveryMetrics,
    );
  }

  /// Generate optimal action based on current state
  /// Uses either TFLite inference or heuristic fallback
  DomRlAction generateAction(DomRlState state) {
    if (_useHeuristicFallback || !_isInitialized) {
      return _generateHeuristicAction(state);
    }
    
    // TFLite inference would go here with loaded model
    return _generateHeuristicAction(state);
  }

  /// Heuristic-based action generation (fallback when TFLite unavailable)
  DomRlAction _generateHeuristicAction(DomRlState state) {
    final action = DomRlAction(
      volumeAdjustment: 0.0,
      intensityAdjustment: 0.0,
      exerciseSubstitutions: [],
      restAdjustment: 0,
    );

    final readiness = state.readinessScore;

    // Power vs Recovery balance based on readiness
    if (readiness >= 85) {
      // Elite readiness - push power
      action.volumeAdjustment = 0.2;
      action.intensityAdjustment = 0.15;
      action.restAdjustment = -10;
      action.focusArea = DomRlFocusArea.power;
    } else if (readiness >= 65) {
      // Good readiness - maintain with slight power focus
      action.volumeAdjustment = 0.0;
      action.intensityAdjustment = 0.05;
      action.restAdjustment = 0;
      action.focusArea = DomRlFocusArea.balanced;
    } else if (readiness >= 45) {
      // Moderate fatigue - reduce volume, maintain intensity
      action.volumeAdjustment = -0.2;
      action.intensityAdjustment = -0.1;
      action.restAdjustment = 15;
      action.focusArea = DomRlFocusArea.endurance;
    } else {
      // High fatigue - recovery focus
      action.volumeAdjustment = -0.5;
      action.intensityAdjustment = -0.4;
      action.restAdjustment = 30;
      action.focusArea = DomRlFocusArea.recovery;
    }

    // Check for joint stress and suggest substitutions
    state.fatigueAccumulation.forEach((joint, fatigue) {
      if (fatigue > 7) {
        // High joint stress - find substitutions
        if (joint == 'knees') {
          action.exerciseSubstitutions.add(ExerciseSubstitution(
            fromExerciseId: 'ex_002', // Thrusters
            toExerciseId: 'ex_005',   // Plank
            reason: 'High knee stress',
          ));
        } else if (joint == 'lower_back') {
          action.exerciseSubstitutions.add(ExerciseSubstitution(
            fromExerciseId: 'ex_010', // Deadlifts
            toExerciseId: 'ex_006', // Shadowbox
            reason: 'High lower back stress',
          ));
        } else if (joint == 'shoulders') {
          action.exerciseSubstitutions.add(ExerciseSubstitution(
            fromExerciseId: 'ex_002', // Thrusters
            toExerciseId: 'ex_001',   // Lunges
            reason: 'High shoulder stress',
          ));
        }
      }
    });

    return action;
  }

  /// Apply DOM-RL action to optimize a protocol
  WorkoutProtocol optimizeProtocol(WorkoutProtocol baseProtocol, DomRlAction action) {
    final optimizedEntries = <ProtocolEntry>[];

    for (final entry in baseProtocol.entries) {
      // Check for substitutions
      var newExercise = entry.exercise;
      for (final sub in action.exerciseSubstitutions) {
        if (entry.exercise.id == sub.fromExerciseId) {
          final substitute = Exercise.library.firstWhere(
            (e) => e.id == sub.toExerciseId,
            orElse: () => entry.exercise,
          );
          newExercise = substitute;
          break;
        }
      }

      // Apply volume adjustment
      final newSets = (entry.sets * (1 + action.volumeAdjustment)).clamp(1, 10).round();

      // Apply intensity adjustment to RPE
      final newRpe = (entry.intensityRpe + action.intensityAdjustment * 3).clamp(3.0, 10.0);

      // Apply rest adjustment
      final newRest = (entry.restSeconds + action.restAdjustment).clamp(15, 300);

      optimizedEntries.add(ProtocolEntry(
        exercise: newExercise,
        sets: newSets,
        reps: entry.reps,
        intensityRpe: double.parse(newRpe.toStringAsFixed(1)),
        restSeconds: newRest,
      ));
    }

    // Update title prefix based on focus
    final focusPrefix = {
      DomRlFocusArea.power: 'CHARGE: ',
      DomRlFocusArea.endurance: 'HOLD: ',
      DomRlFocusArea.recovery: 'RESTORE: ',
      DomRlFocusArea.balanced: '',
    }[action.focusArea] ?? '';

    // Calculate new duration estimate
    final durationAdjustment = 1 + action.volumeAdjustment * 0.5;
    final newDuration = (baseProtocol.estimatedDurationMinutes * durationAdjustment).round();

    return WorkoutProtocol(
      title: focusPrefix + baseProtocol.title,
      subtitle: 'AI-Optimized (${action.focusArea.name.toUpperCase()}) | ${baseProtocol.subtitle}',
      tier: baseProtocol.tier,
      entries: optimizedEntries,
      estimatedDurationMinutes: newDuration,
      mindsetPrompt: baseProtocol.mindsetPrompt,
    );
  }

  /// Run complete DOM-RL optimization pipeline
  /// Returns optimized protocol with state and action metadata
  DomRlResult optimize(MicroCycle microCycle, WorkoutProtocol baseProtocol) {
    final state = calculateState(microCycle);
    final action = generateAction(state);
    final optimized = optimizeProtocol(baseProtocol, action);

    return DomRlResult(
      originalProtocol: baseProtocol,
      optimizedProtocol: optimized,
      state: state,
      action: action,
    );
  }

  /// Real-time adaptation based on immediate performance feedback
  DomRlResult adaptInRealTime(DomRlState currentState, WorkoutProtocol performedProtocol) {
    final action = generateAction(currentState);
    final adjustments = <String>[];

    // Check for specific conditions
    if (currentState.powerOutputTrend.length >= 2) {
      final powerDeclining = currentState.powerOutputTrend.last < 
                             currentState.powerOutputTrend.first * 0.95;
      if (powerDeclining && currentState.readinessScore > 70) {
        adjustments.add('Power output declining but recovery stable. Adding plyometric activation.');
        action.focusArea = DomRlFocusArea.power;
        action.volumeAdjustment = (action.volumeAdjustment + 0.1).clamp(-0.5, 0.5);
      }
    }

    // High HRV but poor performance = CNS fatigue, not muscular
    if (currentState.readinessScore > 80) {
      final hasJointStress = currentState.fatigueAccumulation.values.any((f) => f > 6);
      if (hasJointStress) {
        adjustments.add('Mismatch: High HRV but joint stress elevated. Switching to non-impact.');
        action.focusArea = DomRlFocusArea.endurance;
      }
    }

    final adapted = optimizeProtocol(performedProtocol, action);

    return DomRlResult(
      originalProtocol: performedProtocol,
      optimizedProtocol: adapted,
      state: currentState,
      action: action,
      adaptations: adjustments,
    );
  }
}

/// DOM-RL State representation
class DomRlState {
  final int readinessScore;
  final double weeklyVolume;
  final Map<String, double> fatigueAccumulation;
  final List<double> powerOutputTrend;
  final List<double> recoveryMetrics;

  DomRlState({
    required this.readinessScore,
    required this.weeklyVolume,
    required this.fatigueAccumulation,
    required this.powerOutputTrend,
    required this.recoveryMetrics,
  });

  /// Convert to feature vector for TFLite inference
  List<double> toFeatureVector() {
    return [
      readinessScore / 100.0,
      (weeklyVolume / 500.0).clamp(0.0, 1.0),
      fatigueAccumulation.values.isEmpty 
          ? 0.0 
          : fatigueAccumulation.values.reduce((a, b) => a + b) / fatigueAccumulation.values.length / 10.0,
      powerOutputTrend.isEmpty ? 0.5 : powerOutputTrend.last / 100.0,
      recoveryMetrics.isEmpty ? 0.5 : recoveryMetrics.last / 10.0,
    ];
  }
}

/// DOM-RL Action (optimization decisions)
class DomRlAction {
  double volumeAdjustment; // -1.0 to 1.0
  double intensityAdjustment; // -1.0 to 1.0
  List<ExerciseSubstitution> exerciseSubstitutions;
  int restAdjustment; // seconds to add/subtract
  DomRlFocusArea focusArea;

  DomRlAction({
    required this.volumeAdjustment,
    required this.intensityAdjustment,
    required this.exerciseSubstitutions,
    required this.restAdjustment,
    this.focusArea = DomRlFocusArea.balanced,
  });
}

enum DomRlFocusArea {
  power,
  endurance,
  recovery,
  balanced,
}

/// Exercise substitution mapping
class ExerciseSubstitution {
  final String fromExerciseId;
  final String toExerciseId;
  final String reason;

  ExerciseSubstitution({
    required this.fromExerciseId,
    required this.toExerciseId,
    required this.reason,
  });
}

/// DOM-RL optimization result
class DomRlResult {
  final WorkoutProtocol originalProtocol;
  final WorkoutProtocol optimizedProtocol;
  final DomRlState state;
  final DomRlAction action;
  final List<String>? adaptations;

  DomRlResult({
    required this.originalProtocol,
    required this.optimizedProtocol,
    required this.state,
    required this.action,
    this.adaptations,
  });
}
