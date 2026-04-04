import 'dart:developer' as developer;
import '../models/biometrics.dart';
import '../services/supabase_database_service.dart';

/// Repository for Biometrics data using Supabase
class BiometricsRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save biometrics data
  Future<bool> saveBiometrics(String userId, Biometrics biometrics) async {
    try {
      // Store in user_profiles body_compression field
      await _database.saveUserProfile(userId, {
        'body_compression': biometrics.toMap(),
      });
      
      developer.log('Biometrics saved successfully', name: 'BiometricsRepository');
      return true;
    } catch (e) {
      developer.log('Error saving biometrics: $e', name: 'BiometricsRepository');
      return false;
    }
  }

  /// Get biometrics history
  Future<List<Biometrics>> getBiometricsHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      // Fetch from user_profiles
      return [];
    } catch (e) {
      developer.log('Error getting biometrics history: $e', name: 'BiometricsRepository');
      return [];
    }
  }
}
