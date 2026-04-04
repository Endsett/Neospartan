/// Daily Readiness Model
class DailyReadiness {
  final DateTime date;
  final int readinessScore; // 1-100
  final String? notes;
  final List<String>? factors;
  final String userId;

  DailyReadiness({
    required this.date,
    required this.readinessScore,
    this.notes,
    this.factors,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'readiness_score': readinessScore,
      'notes': notes,
      'factors': factors,
      'user_id': userId,
    };
  }

  factory DailyReadiness.fromMap(Map<String, dynamic> map) {
    return DailyReadiness(
      date: DateTime.parse(map['date']),
      readinessScore: map['readiness_score'] ?? 0,
      notes: map['notes'],
      factors: map['factors'] != null ? List<String>.from(map['factors']) : null,
      userId: map['user_id'] ?? '',
    );
  }
}
