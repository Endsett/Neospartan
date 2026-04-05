import 'dart:developer' as developer;
import '../models/session_readiness_input.dart';
import '../services/supabase_database_service.dart';

/// Repository for Session Readiness Input CRUD operations using Supabase
class SessionReadinessRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save session readiness input
  Future<bool> saveSessionReadinessInput(
    String userId,
    SessionReadinessInput input, {
    int? baselineReadiness,
    int? adjustedReadiness,
  }) async {
    try {
      final data = {
        'session_date': DateTime.now().toIso8601String().split('T')[0],
        'soreness': input.soreness,
        'motivation': input.motivation,
        'sleep_quality': input.sleepQuality,
        'stress': input.stress,
        'readiness_composite_score': input.readinessCompositeScore,
        'baseline_readiness': baselineReadiness,
        'adjusted_readiness': adjustedReadiness,
        'applied_to_recommendation': true,
      };

      await _database.saveSessionReadinessInput(data);
      developer.log(
        'Session readiness input saved successfully',
        name: 'SessionReadinessRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error saving session readiness input: $e',
        name: 'SessionReadinessRepository',
      );
      return false;
    }
  }

  /// Get session readiness input for today
  Future<SessionReadinessInput?> getTodayReadinessInput() async {
    try {
      final today = DateTime.now();
      final data = await _database.getSessionReadinessInput(today);

      if (data == null) return null;

      return SessionReadinessInput.fromMap(data);
    } catch (e) {
      developer.log(
        'Error getting today readiness input: $e',
        name: 'SessionReadinessRepository',
      );
      return null;
    }
  }

  /// Get session readiness input for a specific date
  Future<SessionReadinessInput?> getReadinessInputForDate(DateTime date) async {
    try {
      final data = await _database.getSessionReadinessInput(date);

      if (data == null) return null;

      return SessionReadinessInput.fromMap(data);
    } catch (e) {
      developer.log(
        'Error getting readiness input for date: $e',
        name: 'SessionReadinessRepository',
      );
      return null;
    }
  }

  /// Get recent session readiness inputs
  Future<List<SessionReadinessInput>> getRecentReadinessInputs({
    int days = 7,
  }) async {
    try {
      final data = await _database.getRecentSessionReadinessInputs(days: days);

      return data
          .map((item) => SessionReadinessInput.fromMap(item))
          .toList();
    } catch (e) {
      developer.log(
        'Error getting recent readiness inputs: $e',
        name: 'SessionReadinessRepository',
      );
      return [];
    }
  }

  /// Check if user has submitted readiness input for today
  Future<bool> hasTodayReadinessInput() async {
    final today = DateTime.now();
    final data = await _database.getSessionReadinessInput(today);
    return data != null;
  }
}
