import '../models/exercise.dart';
import '../models/workout_protocol.dart';

class AgogeService {
  static final AgogeService _instance = AgogeService._internal();
  factory AgogeService() => _instance;
  AgogeService._internal();

  WorkoutProtocol generateProtocol(int readinessScore) {
    if (readinessScore >= 85) {
      return _buildEliteProtocol();
    } else if (readinessScore >= 60) {
      return _buildReadyProtocol();
    } else if (readinessScore >= 40) {
      return _buildFatiguedProtocol();
    } else {
      return _buildRecoveryProtocol();
    }
  }

  WorkoutProtocol _buildEliteProtocol() {
    return WorkoutProtocol(
      title: "THE SPARTAN CHARGE",
      subtitle: "MAXIMUM INTENSITY ACTIVATED",
      tier: ProtocolTier.elite,
      estimatedDurationMinutes: 60,
      mindsetPrompt: "Leonidas would not hesitate. Push the limits of your endurance.",
      entries: [
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == "ex_004"), // Sprints
          sets: 5,
          reps: 0,
          intensityRpe: 10,
          restSeconds: 90,
        ),
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == "ex_006"), // Thrusters
          sets: 4,
          reps: 12,
          intensityRpe: 9,
          restSeconds: 60,
        ),
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == "ex_005"), // Deadlifts
          sets: 5,
          reps: 5,
          intensityRpe: 9,
          restSeconds: 120,
        ),
      ],
    );
  }

  WorkoutProtocol _buildReadyProtocol() {
    return WorkoutProtocol(
      title: "THE PHALANX",
      subtitle: "STRUCTURED STRENGTH",
      tier: ProtocolTier.ready,
      estimatedDurationMinutes: 45,
      mindsetPrompt: "Consistency is the foundation of the phalanx. Maintain form.",
      entries: [
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == "ex_001"), // Lunges
          sets: 4,
          reps: 12,
          intensityRpe: 8,
          restSeconds: 60,
        ),
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == "ex_002"), // Push-ups
          sets: 4,
          reps: 20,
          intensityRpe: 7,
          restSeconds: 45,
        ),
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == "ex_003"), // Plank
          sets: 3,
          reps: 0,
          intensityRpe: 6,
          restSeconds: 30,
        ),
      ],
    );
  }

  WorkoutProtocol _buildFatiguedProtocol() {
    return WorkoutProtocol(
      title: "THE GARRISON",
      subtitle: "MAINTENANCE & READINESS",
      tier: ProtocolTier.fatigued,
      estimatedDurationMinutes: 30,
      mindsetPrompt: "A warrior knows when to hold the line and conserve strength.",
      entries: [
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == "ex_003"), // Plank
          sets: 3,
          reps: 0,
          intensityRpe: 5,
          restSeconds: 60,
        ),
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == "ex_001"), // Lunges
          sets: 2,
          reps: 10,
          intensityRpe: 6,
          restSeconds: 90,
        ),
      ],
    );
  }

  WorkoutProtocol _buildRecoveryProtocol() {
    return WorkoutProtocol(
      title: "STOIC RESTORATION",
      subtitle: "MIND OVER MUSCLE",
      tier: ProtocolTier.recovery,
      estimatedDurationMinutes: 20,
      mindsetPrompt: "Victory is won in recovery. Master the stillness.",
      entries: [
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.id == "ex_003"), // Plank
          sets: 2,
          reps: 0,
          intensityRpe: 3,
          restSeconds: 120,
        ),
      ],
    );
  }
}
