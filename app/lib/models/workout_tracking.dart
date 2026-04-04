/// Joint stress tracking for Armor Analytics
class JointStressEntry {
  final String joint;
  final int stressLevel; // 1-10
  final DateTime timestamp;

  const JointStressEntry({
    required this.joint,
    required this.stressLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'joint': joint,
      'stress_level': stressLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Individual set performance tracking
class SetPerformance {
  final int setNumber;
  final int? repsPerformed;
  final double? actualRPE;
  final double? loadUsed; // weight in kg/lbs
  final bool completed;
  final String? notes;

  const SetPerformance({
    required this.setNumber,
    this.repsPerformed,
    this.actualRPE,
    this.loadUsed,
    this.completed = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'set_number': setNumber,
      'reps_performed': repsPerformed,
      'actual_rpe': actualRPE,
      'load_used': loadUsed,
      'completed': completed,
      'notes': notes,
    };
  }
}

/// Completed exercise entry with full tracking
class CompletedExerciseEntry {
  final String exerciseId;
  final String exerciseName;
  final List<SetPerformance> sets;
  final DateTime startTime;
  final DateTime? endTime;
  final int targetSets;
  final int targetReps;
  final double targetRPE;

  const CompletedExerciseEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.startTime,
    this.endTime,
    required this.targetSets,
    required this.targetReps,
    required this.targetRPE,
  });

  double get completionRate => sets.where((s) => s.completed).length / targetSets;
  double get averageRPE => sets.where((s) => s.actualRPE != null).map((s) => s.actualRPE!).reduce((a, b) => a + b) / sets.where((s) => s.actualRPE != null).length;

  Map<String, dynamic> toMap() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'sets': sets.map((s) => s.toMap()).toList(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_rpe': targetRPE,
    };
  }
}

/// Post-workout flow state assessment
class FlowStateAssessment {
  final int mentalEngagement; // 1-10
  final int focusClarity; // 1-10 (fewer intrusions = higher)
  final int formDiscipline; // 1-10
  final int overallFlow; // 1-10
  final String? notes;
  final DateTime timestamp;

  const FlowStateAssessment({
    required this.mentalEngagement,
    required this.focusClarity,
    required this.formDiscipline,
    required this.overallFlow,
    this.notes,
    required this.timestamp,
  });

  double get averageScore => (mentalEngagement + focusClarity + formDiscipline + overallFlow) / 4;

  Map<String, dynamic> toMap() {
    return {
      'mental_engagement': mentalEngagement,
      'focus_clarity': focusClarity,
      'form_discipline': formDiscipline,
      'overall_flow': overallFlow,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Complete workout log with all tracking data
class CompletedWorkout {
  final String id;
  final String protocolTitle;
  final List<CompletedExerciseEntry> exercises;
  final DateTime startTime;
  final DateTime endTime;
  final int totalDurationMinutes;
  final int readinessScoreAtStart;
  final FlowStateAssessment? flowAssessment;
  final List<JointStressEntry> jointStressEntries;

  const CompletedWorkout({
    required this.id,
    required this.protocolTitle,
    required this.exercises,
    required this.startTime,
    required this.endTime,
    required this.totalDurationMinutes,
    required this.readinessScoreAtStart,
    this.flowAssessment,
    this.jointStressEntries = const [],
  });

  double get averageCompletionRate => exercises.map((e) => e.completionRate).reduce((a, b) => a + b) / exercises.length;
  double get averageRPE => exercises.map((e) => e.averageRPE).reduce((a, b) => a + b) / exercises.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'protocol_title': protocolTitle,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_duration_minutes': totalDurationMinutes,
      'readiness_score_at_start': readinessScoreAtStart,
      'flow_assessment': flowAssessment?.toMap(),
      'joint_stress_entries': jointStressEntries.map((j) => j.toMap()).toList(),
    };
  }
}

/// Daily workout and recovery log
class DailyLog {
  final DateTime date;
  final List<double> rpeEntries;
  final int sleepQuality; // 1-10
  final int sleepHours;
  final Map<String, int> jointFatigue; // joint -> fatigue 1-10
  final int flowState; // 1-10
  final int readinessScore;
  final CompletedWorkout? workout;

  const DailyLog({
    required this.date,
    this.rpeEntries = const [],
    this.sleepQuality = 5,
    this.sleepHours = 7,
    this.jointFatigue = const {},
    this.flowState = 5,
    this.readinessScore = 70,
    this.workout,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'rpe_entries': rpeEntries,
      'sleep_quality': sleepQuality,
      'sleep_hours': sleepHours,
      'joint_fatigue': jointFatigue,
      'flow_state': flowState,
      'readiness_score': readinessScore,
    };
  }
}

/// 7-day micro-cycle for Ephor Scrutiny
class MicroCycle {
  final List<DailyLog> days;
  final DateTime startDate;
  final DateTime endDate;

  const MicroCycle({
    required this.days,
    required this.startDate,
    required this.endDate,
  });

  double get averageReadiness => days.isEmpty ? 70 : days.map((d) => d.readinessScore).reduce((a, b) => a + b) / days.length;
  double get averageSleepQuality => days.isEmpty ? 7 : days.map((d) => d.sleepQuality).reduce((a, b) => a + b) / days.length;

  Map<String, dynamic> toMap() {
    return {
      'days': days.map((d) => d.toMap()).toList(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}

/// Armor Analytics result
class ArmorAnalyticsResult {
  final Map<String, List<int>> jointLoadHistory;
  final List<JointRiskFlag> riskFlags;
  final List<String> safeMovements;
  final String summary;

  const ArmorAnalyticsResult({
    required this.jointLoadHistory,
    required this.riskFlags,
    required this.safeMovements,
    required this.summary,
  });
}

class JointRiskFlag {
  final String joint;
  final String riskLevel; // LOW, ELEVATED, HIGH, CRITICAL
  final String message;
  final String recommendation;

  const JointRiskFlag({
    required this.joint,
    required this.riskLevel,
    required this.message,
    required this.recommendation,
  });
}
