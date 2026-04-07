import 'dart:developer' as developer;
import '../services/supabase_database_service.dart';

/// Fuel Log Entry model
class FuelLogEntry {
  final String? id;
  final String userId;
  final String itemName;
  final double protein;
  final double carbs;
  final double fat;
  final int calories;
  final double quantity;
  final String unit;
  final DateTime date;
  final DateTime timestamp;
  final DateTime? createdAt;

  FuelLogEntry({
    this.id,
    required this.userId,
    required this.itemName,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.calories = 0,
    this.quantity = 1,
    this.unit = 'g',
    required this.date,
    DateTime? timestamp,
    this.createdAt,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'item_name': itemName,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories': calories,
      'quantity': quantity,
      'unit': unit,
      'date': _dateOnly(date),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FuelLogEntry.fromMap(Map<String, dynamic> map) {
    return FuelLogEntry(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      itemName: map['item_name'] ?? '',
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
      unit: map['unit'] ?? 'g',
      date: DateTime.parse(map['date'] ?? map['timestamp']),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get macro totals as map
  Map<String, double> get macros => {
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'calories': calories.toDouble(),
  };
}

/// Daily nutrition totals
class DailyNutrition {
  final DateTime date;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int totalCalories;
  final int entryCount;

  DailyNutrition({
    required this.date,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalCalories = 0,
    this.entryCount = 0,
  });
}

/// Repository for Fuel/Nutrition logs using Supabase
class FuelLogRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save a fuel log entry
  Future<bool> saveEntry(FuelLogEntry entry) async {
    try {
      await _database.saveFuelLogEntry(entry.toMap());
      developer.log('Fuel log entry saved: ${entry.itemName}', name: 'FuelLogRepository');
      return true;
    } catch (e) {
      developer.log('Error saving fuel log entry: $e', name: 'FuelLogRepository');
      return false;
    }
  }

  /// Get entries for a specific date
  Future<List<FuelLogEntry>> getEntriesForDate(String userId, DateTime date) async {
    try {
      final data = await _database.getFuelLogsForDate(userId, date);
      return data.map((m) => FuelLogEntry.fromMap(m)).toList();
    } catch (e) {
      developer.log('Error getting fuel logs for date: $e', name: 'FuelLogRepository');
      return [];
    }
  }

  /// Get entries for date range
  Future<List<FuelLogEntry>> getEntriesForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _database.getFuelLogsForRange(userId, startDate, endDate);
      return data.map((m) => FuelLogEntry.fromMap(m)).toList();
    } catch (e) {
      developer.log('Error getting fuel logs for range: $e', name: 'FuelLogRepository');
      return [];
    }
  }

  /// Get daily nutrition totals
  Future<DailyNutrition> getDailyNutrition(String userId, DateTime date) async {
    try {
      final entries = await getEntriesForDate(userId, date);
      return DailyNutrition(
        date: date,
        totalProtein: entries.fold(0, (sum, e) => sum + e.protein),
        totalCarbs: entries.fold(0, (sum, e) => sum + e.carbs),
        totalFat: entries.fold(0, (sum, e) => sum + e.fat),
        totalCalories: entries.fold(0, (sum, e) => sum + e.calories),
        entryCount: entries.length,
      );
    } catch (e) {
      developer.log('Error getting daily nutrition: $e', name: 'FuelLogRepository');
      return DailyNutrition(date: date);
    }
  }

  /// Delete an entry
  Future<bool> deleteEntry(String entryId) async {
    try {
      await _database.deleteFuelLogEntry(entryId);
      developer.log('Fuel log entry deleted', name: 'FuelLogRepository');
      return true;
    } catch (e) {
      developer.log('Error deleting fuel log entry: $e', name: 'FuelLogRepository');
      return false;
    }
  }

  /// Get recent entries (for history view)
  Future<List<FuelLogEntry>> getRecentEntries(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final data = await _database.getRecentFuelLogs(userId, limit: limit);
      return data.map((m) => FuelLogEntry.fromMap(m)).toList();
    } catch (e) {
      developer.log('Error getting recent fuel logs: $e', name: 'FuelLogRepository');
      return [];
    }
  }
}
