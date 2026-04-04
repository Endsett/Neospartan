import 'exercise.dart';

enum ProtocolTier {
  elite,
  ready,
  fatigued,
  recovery,
}

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
}

class ProtocolEntry {
  final Exercise exercise;
  final int sets;
  final int reps;
  final double intensityRPE;
  final int restSeconds;

  const ProtocolEntry({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.intensityRPE,
    required this.restSeconds,
  });
}
