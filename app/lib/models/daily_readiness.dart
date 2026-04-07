/// Daily Readiness Model
class DailyReadiness {
  final DateTime date;
  final int readinessScore; // 1-100
  final String? notes;
  final List<String>? factors;
  final String userId;
  final double? sleepQuality; // 0-1
  final double? recoveryScore; // 0-1
  final int? soreness; // 1-10
  final int? motivation; // 1-10
  final int? stress; // 1-10

  DailyReadiness({
    required this.date,
    required this.readinessScore,
    this.notes,
    this.factors,
    required this.userId,
    this.sleepQuality,
    this.recoveryScore,
    this.soreness,
    this.motivation,
    this.stress,
  });

  // Overall readiness combines readiness score with other factors
  double get overallReadiness {
    double base = readinessScore.toDouble();
    if (sleepQuality != null) {
      base = (base + sleepQuality! * 100) / 2;
    }
    if (recoveryScore != null) {
      base = (base + recoveryScore! * 100) / 2;
    }
    return base;
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'readiness_score': readinessScore,
      'notes': notes,
      'factors': factors,
      'user_id': userId,
      'sleep_quality': sleepQuality,
      'recovery_score': recoveryScore,
      'soreness': soreness,
      'motivation': motivation,
      'stress': stress,
    };
  }

  factory DailyReadiness.fromMap(Map<String, dynamic> map) {
    return DailyReadiness(
      date: DateTime.parse(map['date']),
      readinessScore: map['readiness_score'] ?? 0,
      notes: map['notes'],
      factors: map['factors'] != null
          ? List<String>.from(map['factors'])
          : null,
      userId: map['user_id'] ?? '',
      sleepQuality: map['sleep_quality']?.toDouble(),
      recoveryScore: map['recovery_score']?.toDouble(),
      soreness: map['soreness']?.toInt(),
      motivation: map['motivation']?.toInt(),
      stress: map['stress']?.toInt(),
    );
  }
}
