import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Biometric Types
enum BiometricType {
  hrv,
  sleepHours,
  sleepQuality,
  restingHR,
  steps,
  weight,
  bodyFat,
  bloodPressureSystolic,
  bloodPressureDiastolic,
  vo2Max,
}

/// Biometric Reading Model
class BiometricReading {
  final String? id;
  final String userId;
  final BiometricType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String? source; // "health_connect", "manual", "device"
  final Map<String, dynamic>? metadata;

  BiometricReading({
    this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.source,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'metadata': metadata,
    };
  }

  factory BiometricReading.fromMap(Map<String, dynamic> map) {
    return BiometricReading(
      id: map['id'],
      userId: map['user_id'] ?? '',
      type: BiometricType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BiometricType.restingHR,
      ),
      value: map['value']?.toDouble() ?? 0,
      unit: map['unit'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      source: map['source'],
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  BiometricReading copyWith({
    String? id,
    String? userId,
    BiometricType? type,
    double? value,
    String? unit,
    DateTime? timestamp,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return BiometricReading(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Repository for Biometric CRUD operations
class BiometricsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _biometricsCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('biometrics');
  }

  /// Save a biometric reading
  Future<bool> saveBiometric(BiometricReading reading) async {
    try {
      final docRef = _biometricsCollection(reading.userId).doc();
      final data = reading.copyWith(id: docRef.id).toMap();

      await docRef.set(data);
      developer.log(
        'Biometric saved: ${reading.type.name}',
        name: 'BiometricsRepository',
      );
      return true;
    } catch (e) {
      developer.log('Error saving biometric: $e', name: 'BiometricsRepository');
      return false;
    }
  }

  /// Save multiple biometric readings (batch)
  Future<bool> saveBiometricsBatch(List<BiometricReading> readings) async {
    if (readings.isEmpty) return true;

    try {
      final batch = _firestore.batch();
      final userId = readings.first.userId;
      final collection = _biometricsCollection(userId);

      for (final reading in readings) {
        final docRef = collection.doc();
        final data = reading.copyWith(id: docRef.id).toMap();
        batch.set(docRef, data);
      }

      await batch.commit();
      developer.log(
        'Biometrics batch saved: ${readings.length}',
        name: 'BiometricsRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error saving biometrics batch: $e',
        name: 'BiometricsRepository',
      );
      return false;
    }
  }

  /// Get latest biometric reading of a specific type
  Future<BiometricReading?> getLatestBiometric(
    String userId,
    BiometricType type,
  ) async {
    try {
      final snapshot = await _biometricsCollection(userId)
          .where('type', isEqualTo: type.name)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return BiometricReading.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      developer.log(
        'Error getting latest biometric: $e',
        name: 'BiometricsRepository',
      );
      return null;
    }
  }

  /// Get biometric readings for a date range
  Future<List<BiometricReading>> getBiometricsForRange(
    String userId,
    BiometricType type,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _biometricsCollection(userId)
          .where('type', isEqualTo: type.name)
          .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BiometricReading.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log(
        'Error getting biometrics for range: $e',
        name: 'BiometricsRepository',
      );
      return [];
    }
  }

  /// Get all biometric readings for a date
  Future<List<BiometricReading>> getBiometricsForDate(
    String userId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      final snapshot = await _biometricsCollection(userId)
          .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BiometricReading.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log(
        'Error getting biometrics for date: $e',
        name: 'BiometricsRepository',
      );
      return [];
    }
  }

  /// Stream of latest biometric of a type
  Stream<BiometricReading?> latestBiometricStream(
    String userId,
    BiometricType type,
  ) {
    return _biometricsCollection(userId)
        .where('type', isEqualTo: type.name)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return BiometricReading.fromMap(snapshot.docs.first.data());
          }
          return null;
        });
  }

  /// Stream of all biometrics for a date range
  Stream<List<BiometricReading>> biometricsStream(
    String userId,
    BiometricType type, {
    int daysBack = 30,
  }) {
    final start = DateTime.now().subtract(Duration(days: daysBack));

    return _biometricsCollection(userId)
        .where('type', isEqualTo: type.name)
        .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BiometricReading.fromMap(doc.data()))
              .toList();
        });
  }

  /// Delete a biometric reading
  Future<bool> deleteBiometric(String userId, String biometricId) async {
    try {
      await _biometricsCollection(userId).doc(biometricId).delete();
      developer.log(
        'Biometric deleted: $biometricId',
        name: 'BiometricsRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error deleting biometric: $e',
        name: 'BiometricsRepository',
      );
      return false;
    }
  }

  /// Get average value for a biometric type over a range
  Future<double> getAverageBiometric(
    String userId,
    BiometricType type,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final readings = await getBiometricsForRange(userId, type, start, end);
      if (readings.isEmpty) return 0;

      final sum = readings.fold<double>(0, (acc, r) => acc + r.value);
      return sum / readings.length;
    } catch (e) {
      developer.log(
        'Error getting average biometric: $e',
        name: 'BiometricsRepository',
      );
      return 0;
    }
  }

  /// Get trend (increasing/decreasing/stable) for a biometric
  Future<BiometricTrend> getBiometricTrend(
    String userId,
    BiometricType type,
    int days,
  ) async {
    try {
      final end = DateTime.now();
      final start = end.subtract(Duration(days: days));

      final readings = await getBiometricsForRange(userId, type, start, end);
      if (readings.length < 3) return BiometricTrend.insufficientData;

      // Split into first and second half
      final mid = readings.length ~/ 2;
      final firstHalf = readings.sublist(mid);
      final secondHalf = readings.sublist(0, mid);

      final firstAvg =
          firstHalf.fold<double>(0, (a, r) => a + r.value) / firstHalf.length;
      final secondAvg =
          secondHalf.fold<double>(0, (a, r) => a + r.value) / secondHalf.length;

      final diff = secondAvg - firstAvg;
      final threshold = firstAvg * 0.05; // 5% threshold

      if (diff > threshold) return BiometricTrend.increasing;
      if (diff < -threshold) return BiometricTrend.decreasing;
      return BiometricTrend.stable;
    } catch (e) {
      developer.log(
        'Error getting biometric trend: $e',
        name: 'BiometricsRepository',
      );
      return BiometricTrend.error;
    }
  }
}

enum BiometricTrend { increasing, decreasing, stable, insufficientData, error }
