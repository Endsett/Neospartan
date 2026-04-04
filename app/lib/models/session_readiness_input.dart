class SessionReadinessInput {
  final int soreness;
  final int motivation;
  final int sleepQuality;
  final int stress;

  const SessionReadinessInput({
    required this.soreness,
    required this.motivation,
    required this.sleepQuality,
    required this.stress,
  });

  double get readinessCompositeScore {
    final sorenessScore = 11 - soreness;
    final stressScore = 11 - stress;
    final total = sorenessScore + motivation + sleepQuality + stressScore;
    return (total / 40) * 100;
  }

  int applyToReadiness(int baselineReadiness) {
    final combined = (baselineReadiness * 0.6) + (readinessCompositeScore * 0.4);
    return combined.clamp(1, 100).round();
  }

  Map<String, dynamic> toMap() {
    return {
      'soreness': soreness,
      'motivation': motivation,
      'sleep_quality': sleepQuality,
      'stress': stress,
      'readiness_composite_score': readinessCompositeScore,
    };
  }

  factory SessionReadinessInput.fromMap(Map<String, dynamic> map) {
    return SessionReadinessInput(
      soreness: map['soreness'] ?? 5,
      motivation: map['motivation'] ?? 5,
      sleepQuality: map['sleep_quality'] ?? 5,
      stress: map['stress'] ?? 5,
    );
  }
}
