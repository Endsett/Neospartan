import 'dart:developer' as developer;
import '../models/daily_readiness.dart';
import '../services/supabase_database_service.dart';

/// Repository for Daily Readiness data using Supabase
class DailyReadinessRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save daily readiness
  Future<bool> saveDailyReadiness(DailyReadiness readiness) async {
    try {
      await _database.saveDailyReadiness(readiness);
      developer.log('Daily readiness saved', name: 'DailyReadinessRepository');
      return true;
    } catch (e) {
      developer.log(
        'Error saving daily readiness: $e',
        name: 'DailyReadinessRepository',
      );
      return false;
    }
  }

  /// Get recent readiness scores
  Future<List<DailyReadiness>> getRecentReadiness(
    String userId, {
    int days = 7,
  }) async {
    try {
      final data = await _database.getRecentReadiness(userId, days: days);
      return data.map((m) => DailyReadiness.fromMap(m)).toList();
    } catch (e) {
      developer.log(
        'Error getting recent readiness: $e',
        name: 'DailyReadinessRepository',
      );
      return [];
    }
  }

  /// Get daily readiness history
  Future<List<DailyReadiness>> getReadinessHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final data = await _database.getReadinessHistory(userId, limit: limit);
      return data.map((m) => DailyReadiness.fromMap(m)).toList();
    } catch (e) {
      developer.log(
        'Error getting readiness history: $e',
        name: 'DailyReadinessRepository',
      );
      return [];
    }
  }

  /// Get readiness for specific date
  Future<DailyReadiness?> getReadinessForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final data = await _database.getReadinessForDate(userId, date);
      if (data != null) {
        return DailyReadiness.fromMap(data);
      }
      return null;
    } catch (e) {
      developer.log(
        'Error getting readiness for date: $e',
        name: 'DailyReadinessRepository',
      );
      return null;
    }
  }

  /// Get latest readiness score
  Future<int?> getLatestReadinessScore(String userId) async {
    try {
      final readiness = await getReadinessForDate(userId, DateTime.now());
      return readiness?.readinessScore;
    } catch (e) {
      developer.log(
        'Error getting latest readiness score: $e',
        name: 'DailyReadinessRepository',
      );
      return null;
    }
  }
}
