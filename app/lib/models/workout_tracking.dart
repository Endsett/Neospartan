// No unused analytics import here
import 'exercise.dart';
import 'sport_category.dart' hide ExerciseCategory;
import '../data/combat_exercise_library.dart' show CombatExercise;

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

/// Completed exercise entry in a workout
class CompletedExerciseEntry {
  final Exercise exercise;
  final List<SetPerformance> sets;
  final DateTime completedAt;
  final Map<String, dynamic>?
  progressiveOverloadData; // New field for tracking progress
  final List<String>?
  substitutionOptions; // New field for alternative exercises

  const CompletedExerciseEntry({
    required this.exercise,
    required this.sets,
    required this.completedAt,
    this.progressiveOverloadData,
    this.substitutionOptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'exercise_name': exercise.name,
      'sets': sets.map((s) => s.toMap()).toList(),
      'completed_at': completedAt.toIso8601String(),
      'progressive_overload_data': progressiveOverloadData,
      'substitution_options': substitutionOptions,
    };
  }

  // Compatibility getters for existing code
  String get exerciseName => exercise.name;

  double get completionRate {
    if (sets.isEmpty) return 0.0;
    final completedSets = sets.where((s) => s.completed).length;
    return completedSets / sets.length;
  }

  int get targetSets => sets.length;

  String get exerciseId => exercise.id;

  double get targetRPE {
    if (sets.isEmpty) return 7.0;
    // Return the most common target RPE from the sets
    final rpeCounts = <double, int>{};
    for (final set in sets) {
      final rpe = set.actualRPE ?? 7.0;
      rpeCounts[rpe] = (rpeCounts[rpe] ?? 0) + 1;
    }
    if (rpeCounts.isEmpty) return 7.0;
    return rpeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Completed workout session
class CompletedWorkout {
  final String id;
  final String protocolTitle;
  final List<CompletedExerciseEntry> exercises;
  final DateTime startTime;
  final DateTime endTime;
  final int totalDurationMinutes;
  final int readinessScoreAtStart;

  const CompletedWorkout({
    required this.id,
    required this.protocolTitle,
    required this.exercises,
    required this.startTime,
    required this.endTime,
    required this.totalDurationMinutes,
    required this.readinessScoreAtStart,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'protocol_title': protocolTitle,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_duration_minutes': totalDurationMinutes,
      'readiness_score_at_start': readinessScoreAtStart,
    };
  }

  double get averageRPE {
    if (exercises.isEmpty) return 0.0;

    final allRPEs = exercises
        .expand((e) => e.sets)
        .where((s) => s.actualRPE != null)
        .map((s) => s.actualRPE!)
        .toList();

    if (allRPEs.isEmpty) return 0.0;
    return allRPEs.reduce((a, b) => a + b) / allRPEs.length;
  }

  int get totalSets {
    return exercises.fold(0, (sum, e) => sum + e.sets.length);
  }

  int get totalReps {
    return exercises.fold(
      0,
      (sum, e) =>
          sum + e.sets.fold(0, (setSum, s) => setSum + (s.repsPerformed ?? 0)),
    );
  }

  factory CompletedWorkout.fromMap(Map<String, dynamic> map) {
    return CompletedWorkout(
      id: map['id'] ?? '',
      protocolTitle: map['protocol_title'] ?? '',
      exercises:
          (map['exercises'] as List<dynamic>?)
              ?.map(
                (e) => CompletedExerciseEntry(
                  exercise: Exercise.library.firstWhere(
                    (ex) => ex.name == e['exercise_name'],
                    orElse: () => Exercise.library.first,
                  ),
                  sets: (e['sets'] as List<dynamic>)
                      .map(
                        (s) => SetPerformance(
                          setNumber: s['set_number'],
                          repsPerformed: s['reps_performed'],
                          actualRPE: s['actual_rpe']?.toDouble(),
                          loadUsed: s['load_used']?.toDouble(),
                          completed: s['completed'] ?? false,
                          notes: s['notes'],
                        ),
                      )
                      .toList(),
                  completedAt: DateTime.parse(e['completed_at']),
                ),
              )
              .toList() ??
          [],
      startTime: DateTime.parse(
        map['start_time'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: DateTime.parse(
        map['end_time'] ?? DateTime.now().toIso8601String(),
      ),
      totalDurationMinutes: map['total_duration_minutes'] ?? 0,
      readinessScoreAtStart: map['readiness_score_at_start'] ?? 70,
    );
  }

  double get totalVolume {
    return exercises.fold(0.0, (sum, exercise) {
      return sum +
          exercise.sets.fold(0.0, (setSum, set) {
            return setSum + (set.loadUsed ?? 0.0) * (set.repsPerformed ?? 0);
          });
    });
  }

  // Compatibility getter for existing code
  List<JointStressEntry> get jointStressEntries => [];
}

/// Daily log for micro-cycle tracking
class DailyLog {
  final DateTime date;
  final List<double> rpeEntries; // RPE for each workout/exercise
  final int sleepQuality; // 1-10 scale
  final double sleepHours;
  final Map<String, int> jointFatigue; // Joint -> fatigue level (1-10)
  final int flowState; // 1-10 scale
  final int readinessScore; // Overall readiness (1-100)

  const DailyLog({
    required this.date,
    required this.rpeEntries,
    required this.sleepQuality,
    required this.sleepHours,
    required this.jointFatigue,
    required this.flowState,
    required this.readinessScore,
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

  double get averageRPE {
    if (rpeEntries.isEmpty) return 0.0;
    return rpeEntries.reduce((a, b) => a + b) / rpeEntries.length;
  }
}

/// Micro-cycle (7-day training block)
class MicroCycle {
  final List<DailyLog> days;
  final DateTime startDate;
  final DateTime endDate;

  const MicroCycle({
    required this.days,
    required this.startDate,
    required this.endDate,
  });

  double get averageReadiness {
    if (days.isEmpty) return 0.0;
    return days.fold(0.0, (sum, d) => sum + d.readinessScore) / days.length;
  }

  double get averageSleepQuality {
    if (days.isEmpty) return 0.0;
    return days.fold(0.0, (sum, d) => sum + d.sleepQuality) / days.length;
  }

  Map<String, double> get averageJointFatigue {
    final allJoints = <String>{};
    for (final day in days) {
      allJoints.addAll(day.jointFatigue.keys);
    }

    final averages = <String, double>{};
    for (final joint in allJoints) {
      final values = days
          .map((d) => d.jointFatigue[joint] ?? 0)
          .where((v) => v > 0)
          .toList();

      if (values.isNotEmpty) {
        averages[joint] = values.reduce((a, b) => a + b) / values.length;
      }
    }

    return averages;
  }

  List<double> get rpeTrend {
    return days.expand((d) => d.rpeEntries).toList();
  }
}

/// Daily workout plan/schedule entry
class DailyWorkout {
  final String id;
  final DateTime date;
  final List<CombatExercise> exercises;
  final int intensityLevel; // 1-10
  final int durationSeconds;
  final bool completed;
  final List<SportCategory> sports;
  final List<String> skillFocus;

  const DailyWorkout({
    required this.id,
    required this.date,
    required this.exercises,
    required this.intensityLevel,
    required this.durationSeconds,
    this.completed = false,
    this.sports = const [],
    this.skillFocus = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toLegacyExercise().toMap()).toList(),
      'intensity_level': intensityLevel,
      'duration_seconds': durationSeconds,
      'completed': completed,
      'sports': sports.map((s) => s.name).toList(),
      'skill_focus': skillFocus,
    };
  }

  factory DailyWorkout.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'];
    final parsedDate = dateStr != null
        ? DateTime.tryParse(dateStr) ?? DateTime.now()
        : DateTime.now();

    return DailyWorkout(
      id: map['id']?.toString() ?? '',
      date: parsedDate,
      exercises:
          (map['exercises'] as List<dynamic>?)
              ?.map(
                (e) => CombatExercise(
                  id: e['id'] ?? '',
                  name: e['name'] ?? '',
                  category: ExerciseCategory.values.firstWhere(
                    (c) => c.name == e['category'],
                    orElse: () => ExerciseCategory.strength,
                  ),
                  youtubeId: e['youtube_id'] ?? '',
                  targetMetaphor: e['target_metaphor'] ?? '',
                  instructions: e['instructions'] ?? '',
                  intensityLevel: e['intensity_level'] ?? 5,
                  primaryMuscles:
                      (e['primary_muscles'] as List<dynamic>?)
                          ?.cast<String>() ??
                      [],
                  jointStress: {},
                ),
              )
              .toList() ??
          [],
      intensityLevel: map['intensity_level'] ?? 5,
      durationSeconds: map['duration_seconds'] ?? 0,
      completed: map['completed'] ?? false,
      sports:
          (map['sports'] as List<dynamic>?)
              ?.map(
                (s) => SportCategory.values.firstWhere(
                  (v) => v.name == s,
                  orElse: () => SportCategory.generalCombat,
                ),
              )
              .toList() ??
          [],
      skillFocus:
          (map['skill_focus'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
    );
  }
}
