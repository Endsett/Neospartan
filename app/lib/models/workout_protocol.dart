import 'exercise.dart';

enum ProtocolTier { elite, ready, fatigued, recovery }

class WorkoutProtocol {
  final String title;
  final String subtitle;
  final ProtocolTier tier;
  final List<ProtocolEntry> entries;
  final int estimatedDurationMinutes;
  final String mindsetPrompt;

  const WorkoutProtocol({
    required this.title,
    required this.subtitle,
    required this.tier,
    required this.entries,
    required this.estimatedDurationMinutes,
    required this.mindsetPrompt,
  });

  /// Serialize to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'tier': tier.index,
      'entries': entries.map((e) => e.toMap()).toList(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'mindsetPrompt': mindsetPrompt,
    };
  }

  /// Deserialize from Map
  factory WorkoutProtocol.fromMap(Map<String, dynamic> map) {
    return WorkoutProtocol(
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      tier: ProtocolTier.values[map['tier'] as int],
      entries: (map['entries'] as List)
          .map((e) => ProtocolEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      estimatedDurationMinutes: map['estimatedDurationMinutes'] as int,
      mindsetPrompt: map['mindsetPrompt'] as String,
    );
  }
}

class ProtocolEntry {
  final Exercise exercise;
  final int sets;
  final int reps;
  final double intensityRpe;
  final int restSeconds;

  const ProtocolEntry({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.intensityRpe,
    required this.restSeconds,
  });

  /// Serialize to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'exercise': exercise.toMap(),
      'sets': sets,
      'reps': reps,
      'intensityRpe': intensityRpe,
      'restSeconds': restSeconds,
    };
  }

  /// Deserialize from Map
  factory ProtocolEntry.fromMap(Map<String, dynamic> map) {
    return ProtocolEntry(
      exercise: Exercise.fromMap(map['exercise'] as Map<String, dynamic>),
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      intensityRpe: (map['intensityRpe'] as num).toDouble(),
      restSeconds: map['restSeconds'] as int,
    );
  }
}
