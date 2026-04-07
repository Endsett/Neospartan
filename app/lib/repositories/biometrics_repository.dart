import 'dart:developer' as developer;
import '../models/biometrics.dart';
import '../services/supabase_database_service.dart';

/// Repository for Biometrics data using Supabase
class BiometricsRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save biometrics data
  Future<bool> saveBiometrics(String userId, Biometrics biometrics) async {
    try {
      await _database.saveBiometrics(userId, biometrics);
      developer.log(
        'Biometrics saved successfully',
        name: 'BiometricsRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error saving biometrics: $e',
        name: 'BiometricsRepository',
      );
      return false;
    }
  }

  /// Get biometrics for date range
  Future<List<Biometrics>> getBiometricsForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _database.getBiometricsForRange(
        userId,
        startDate,
        endDate,
      );
      return data.map((m) => Biometrics.fromMap(m)).toList();
    } catch (e) {
      developer.log(
        'Error getting biometrics for range: $e',
        name: 'BiometricsRepository',
      );
      return [];
    }
  }

  /// Get biometrics history
  Future<List<Biometrics>> getBiometricsHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final data = await _database.getBiometricsHistory(userId, limit: limit);
      return data.map((m) => Biometrics.fromMap(m)).toList();
    } catch (e) {
      developer.log(
        'Error getting biometrics history: $e',
        name: 'BiometricsRepository',
      );
      return [];
    }
  }

  /// Get latest biometrics entry
  Future<Biometrics?> getLatestBiometrics(String userId) async {
    try {
      final data = await _database.getLatestBiometrics(userId);
      if (data != null) {
        return Biometrics.fromMap(data);
      }
      return null;
    } catch (e) {
      developer.log(
        'Error getting latest biometrics: $e',
        name: 'BiometricsRepository',
      );
      return null;
    }
  }

  /// Get biometrics for specific date
  Future<Biometrics?> getBiometricsForDate(String userId, DateTime date) async {
    try {
      final data = await _database.getBiometricsForDate(userId, date);
      if (data != null) {
        return Biometrics.fromMap(data);
      }
      return null;
    } catch (e) {
      developer.log(
        'Error getting biometrics for date: $e',
        name: 'BiometricsRepository',
      );
      return null;
    }
  }
}
