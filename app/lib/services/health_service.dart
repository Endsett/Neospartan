import 'package:health/health.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  bool _isSimulated = false;

  bool get isSimulated => _isSimulated;

  void toggleSimulation(bool value) {
    _isSimulated = value;
  }

  Future<bool> requestPermissions() async {
    if (_isSimulated) return true;

    final types = [
      HealthDataType.HEART_RATE_VARIABILITY_SDNN,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.RESTING_HEART_RATE,
    ];

    bool? hasPermissions = await _health.hasPermissions(types);
    if (hasPermissions != true) {
      return await _health.requestAuthorization(types);
    }
    return true;
  }

  Future<Map<String, dynamic>> fetchReadinessData() async {
    if (_isSimulated) {
      return _generateSimulatedData();
    }

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final types = [
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.RESTING_HEART_RATE,
      ];

      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: types,
      );

      double hrv = 0;
      double sleepHours = 0;
      double rhr = 0;

      for (var p in healthData) {
        if (p.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN) {
          hrv = (p.value as NumericHealthValue).numericValue.toDouble();
        } else if (p.type == HealthDataType.SLEEP_ASLEEP) {
          sleepHours += (p.value as NumericHealthValue).numericValue.toDouble() / 60;
        } else if (p.type == HealthDataType.RESTING_HEART_RATE) {
          rhr = (p.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      // If data is missing, fallback to simulation or handle accordingly
      if (hrv == 0) hrv = 65.0; // Mock default
      if (sleepHours == 0) sleepHours = 7.5;
      if (rhr == 0) rhr = 55.0;

      return {
        'hrv': hrv,
        'sleep': sleepHours,
        'rhr': rhr,
        'score': _calculateReadiness(hrv, sleepHours, rhr),
      };
    } catch (e) {
      debugPrint("Error fetching health data: $e");
      return _generateSimulatedData();
    }
  }

  Map<String, dynamic> _generateSimulatedData() {
    final random = Random();
    double hrv = 55 + random.nextDouble() * 20;
    double sleep = 6 + random.nextDouble() * 3;
    double rhr = 48 + random.nextDouble() * 12;
    
    return {
      'hrv': hrv,
      'sleep': sleep,
      'rhr': rhr,
      'score': _calculateReadiness(hrv, sleep, rhr),
    };
  }

  int _calculateReadiness(double hrv, double sleep, double rhr) {
    // Basic Spartan heuristic
    // Higher HRV is better, more sleep is better (up to 8h), lower RHR is better
    double hrvFactor = (hrv / 100).clamp(0.0, 1.0);
    double sleepFactor = (sleep / 8.0).clamp(0.0, 1.0);
    double rhrFactor = (1.0 - (rhr - 40) / 40).clamp(0.0, 1.0);

    double score = (hrvFactor * 0.4 + sleepFactor * 0.4 + rhrFactor * 0.2) * 100;
    return score.toInt();
  }
}
