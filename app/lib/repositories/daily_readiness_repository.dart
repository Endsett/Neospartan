import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Daily Readiness Entry - Captures morning readiness assessment
class DailyReadiness {
  final String? id;
  final String userId;
  final DateTime date;
  final int overallReadiness; // 0-100 calculated score

  // Input metrics
  final int sleepQuality; // 1-10
  final double sleepHours;
  final int? hrv; // Raw HRV value
  final int? restingHR;
  final int energyLevel; // 1-10 self-reported
  final int sorenessLevel; // 1-10
  final int stressLevel; // 1-10

  // Joint-specific fatigue
  final Map<String, int> jointFatigue; // "knees": 5, "shoulders": 3, etc.

  // Calculated recommendations
  final String? recommendedTier; // elite, ready, fatigued, recovery
  final String? aiInsight; // DOM-RL generated insight

  // Mental state
  final int? motivationLevel; // 1-10
  final int? focusLevel; // 1-10

  // Notes
  final String? notes;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  DailyReadiness({
    this.id,
    required this.userId,
    required this.date,
    required this.overallReadiness,
    required this.sleepQuality,
    required this.sleepHours,
    this.hrv,
    this.restingHR,
    required this.energyLevel,
    required this.sorenessLevel,
    required this.stressLevel,
    this.jointFatigue = const {},
    this.recommendedTier,
    this.aiInsight,
    this.motivationLevel,
    this.focusLevel,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Calculate overall readiness based on inputs
  static int calculateReadiness({
    required int sleepQuality,
    required double sleepHours,
    int? hrv,
    int? restingHR,
    required int energyLevel,
    required int sorenessLevel,
    required int stressLevel,
    Map<String, int>? jointFatigue,
  }) {
    // Weighted scoring
    double score = 0;

    // Sleep (30%)
    double sleepScore = (sleepQuality * 10) * 0.15;
    double durationScore = (sleepHours / 8 * 100).clamp(0, 100) * 0.15;
    score += sleepScore + durationScore;

    // Recovery metrics (30%)
    if (hrv != null) {
      // HRV scoring (normalized 20-80 range)
      score += ((hrv - 20) / 60 * 100).clamp(0, 100) * 0.15;
    } else {
      score += 50 * 0.15; // Default if no HRV
    }

    if (restingHR != null) {
      // Lower RHR is better (40-100 range)
      score += (100 - (restingHR - 40) / 60 * 100).clamp(0, 100) * 0.15;
    } else {
      score += 50 * 0.15; // Default if no RHR
    }

    // Self-reported (40%)
    score += energyLevel * 10 * 0.15;
    score += (100 - sorenessLevel * 10) * 0.15; // Inverted
    score += (100 - stressLevel * 10) * 0.10; // Inverted

    // Joint fatigue penalty (up to -20 points)
    if (jointFatigue != null && jointFatigue.isNotEmpty) {
      double avgJointStress =
          jointFatigue.values.reduce((a, b) => a + b) / jointFatigue.length;
      score -= avgJointStress * 2;
    }

    return score.clamp(0, 100).round();
  }

  /// Get recommended training tier based on readiness
  String getRecommendedTier() {
    if (overallReadiness >= 85) return 'elite';
    if (overallReadiness >= 65) return 'ready';
    if (overallReadiness >= 45) return 'fatigued';
    return 'recovery';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'overall_readiness': overallReadiness,
      'sleep_quality': sleepQuality,
      'sleep_hours': sleepHours,
      'hrv': hrv,
      'resting_hr': restingHR,
      'energy_level': energyLevel,
      'soreness_level': sorenessLevel,
      'stress_level': stressLevel,
      'joint_fatigue': jointFatigue,
      'recommended_tier': recommendedTier ?? getRecommendedTier(),
      'ai_insight': aiInsight,
      'motivation_level': motivationLevel,
      'focus_level': focusLevel,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DailyReadiness.fromMap(Map<String, dynamic> map) {
    return DailyReadiness(
      id: map['id'],
      userId: map['user_id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      overallReadiness: map['overall_readiness'] ?? 70,
      sleepQuality: map['sleep_quality'] ?? 5,
      sleepHours: map['sleep_hours']?.toDouble() ?? 7.0,
      hrv: map['hrv'],
      restingHR: map['resting_hr'],
      energyLevel: map['energy_level'] ?? 5,
      sorenessLevel: map['soreness_level'] ?? 5,
      stressLevel: map['stress_level'] ?? 5,
      jointFatigue:
          (map['joint_fatigue'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      recommendedTier: map['recommended_tier'],
      aiInsight: map['ai_insight'],
      motivationLevel: map['motivation_level'],
      focusLevel: map['focus_level'],
      notes: map['notes'],
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  DailyReadiness copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? overallReadiness,
    int? sleepQuality,
    double? sleepHours,
    int? hrv,
    int? restingHR,
    int? energyLevel,
    int? sorenessLevel,
    int? stressLevel,
    Map<String, int>? jointFatigue,
    String? recommendedTier,
    String? aiInsight,
    int? motivationLevel,
    int? focusLevel,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyReadiness(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      overallReadiness: overallReadiness ?? this.overallReadiness,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      sleepHours: sleepHours ?? this.sleepHours,
      hrv: hrv ?? this.hrv,
      restingHR: restingHR ?? this.restingHR,
      energyLevel: energyLevel ?? this.energyLevel,
      sorenessLevel: sorenessLevel ?? this.sorenessLevel,
      stressLevel: stressLevel ?? this.stressLevel,
      jointFatigue: jointFatigue ?? this.jointFatigue,
      recommendedTier: recommendedTier ?? this.recommendedTier,
      aiInsight: aiInsight ?? this.aiInsight,
      motivationLevel: motivationLevel ?? this.motivationLevel,
      focusLevel: focusLevel ?? this.focusLevel,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Repository for Daily Readiness CRUD operations
class DailyReadinessRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _readinessCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_readiness');
  }

  /// Save or update daily readiness
  Future<bool> saveReadiness(DailyReadiness readiness) async {
    try {
      final docId =
          readiness.id ??
          '${readiness.date.year}-${readiness.date.month.toString().padLeft(2, '0')}-${readiness.date.day.toString().padLeft(2, '0')}';

      await _readinessCollection(readiness.userId)
          .doc(docId)
          .set(readiness.copyWith(id: docId).toMap(), SetOptions(merge: true));

      developer.log(
        'Daily readiness saved: $docId',
        name: 'DailyReadinessRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error saving daily readiness: $e',
        name: 'DailyReadinessRepository',
      );
      return false;
    }
  }

  /// Get today's readiness entry
  Future<DailyReadiness?> getTodayReadiness(String userId) async {
    return getReadinessForDate(userId, DateTime.now());
  }

  /// Get readiness for a specific date
  Future<DailyReadiness?> getReadinessForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final docId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final doc = await _readinessCollection(userId).doc(docId).get();

      if (doc.exists && doc.data() != null) {
        return DailyReadiness.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      developer.log(
        'Error getting daily readiness: $e',
        name: 'DailyReadinessRepository',
      );
      return null;
    }
  }

  /// Get readiness entries for a date range
  Future<List<DailyReadiness>> getReadinessForRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _readinessCollection(userId)
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DailyReadiness.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log(
        'Error getting readiness range: $e',
        name: 'DailyReadinessRepository',
      );
      return [];
    }
  }

  /// Get recent readiness entries
  Future<List<DailyReadiness>> getRecentReadiness(
    String userId, {
    int days = 7,
  }) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return getReadinessForRange(userId, start, end);
  }

  /// Check if readiness is logged for today
  Future<bool> hasLoggedReadinessToday(String userId) async {
    final today = await getTodayReadiness(userId);
    return today != null;
  }

  /// Stream of today's readiness
  Stream<DailyReadiness?> todayReadinessStream(String userId) {
    final docId = _getDateDocId(DateTime.now());

    return _readinessCollection(userId).doc(docId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return DailyReadiness.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  /// Stream of recent readiness entries
  Stream<List<DailyReadiness>> recentReadinessStream(
    String userId, {
    int days = 7,
  }) {
    final start = DateTime.now().subtract(Duration(days: days));

    return _readinessCollection(userId)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DailyReadiness.fromMap(doc.data()))
              .toList();
        });
  }

  /// Delete a readiness entry
  Future<bool> deleteReadiness(String userId, DateTime date) async {
    try {
      final docId = _getDateDocId(date);
      await _readinessCollection(userId).doc(docId).delete();
      developer.log(
        'Daily readiness deleted: $docId',
        name: 'DailyReadinessRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error deleting daily readiness: $e',
        name: 'DailyReadinessRepository',
      );
      return false;
    }
  }

  /// Get average readiness over a period
  Future<double> getAverageReadiness(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final entries = await getReadinessForRange(userId, start, end);
      if (entries.isEmpty) return 70.0; // Default

      final sum = entries.fold<double>(0, (acc, e) => acc + e.overallReadiness);
      return sum / entries.length;
    } catch (e) {
      developer.log(
        'Error getting average readiness: $e',
        name: 'DailyReadinessRepository',
      );
      return 70.0;
    }
  }

  /// Helper to generate document ID from date
  String _getDateDocId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
