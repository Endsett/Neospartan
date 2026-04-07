import '../services/supabase_database_service.dart';

/// Repository for fuel/nutrition log operations
class FuelRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save a fuel log entry
  Future<bool> saveLog(Map<String, dynamic> data) async {
    try {
      await _database.saveFuelLogEntry(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get logs for a specific date
  Future<List<Map<String, dynamic>>> getLogsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      return await _database.getFuelLogsForDate(userId, date);
    } catch (e) {
      return [];
    }
  }

  /// Get recent fuel logs
  Future<List<Map<String, dynamic>>> getRecentLogs(
    String userId, {
    int limit = 50,
  }) async {
    try {
      return await _database.getRecentFuelLogs(userId, limit: limit);
    } catch (e) {
      return [];
    }
  }

  /// Delete a fuel log
  Future<bool> deleteLog(String logId) async {
    try {
      await _database.deleteFuelLogEntry(logId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
