import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_protocol.dart';

/// Service for persisting app state locally
/// Ensures protocols, memories, and progress survive app restarts
class StatePersistenceService {
  static final StatePersistenceService _instance = StatePersistenceService._internal();
  factory StatePersistenceService() => _instance;
  StatePersistenceService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== Daily Protocol ====================

  /// Save today's protocol
  Future<void> saveDailyProtocol(WorkoutProtocol protocol) async {
    final key = _getTodayKey('daily_protocol');
    final json = jsonEncode(protocol.toMap());
    await _prefs?.setString(key, json);
    await _prefs?.setString('${key}_timestamp', DateTime.now().toIso8601String());
  }

  /// Load today's protocol if it exists
  WorkoutProtocol? loadDailyProtocol() {
    final key = _getTodayKey('daily_protocol');
    final timestampStr = _prefs?.getString('${key}_timestamp');
    
    if (timestampStr == null) return null;
    
    final timestamp = DateTime.parse(timestampStr);
    final now = DateTime.now();
    
    // Only return if it's from today
    if (!_isSameDay(timestamp, now)) return null;
    
    final json = _prefs?.getString(key);
    if (json == null) return null;
    
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return WorkoutProtocol.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  /// Check if protocol was generated today
  bool hasProtocolForToday() {
    return loadDailyProtocol() != null;
  }

  /// Clear today's protocol
  Future<void> clearDailyProtocol() async {
    final key = _getTodayKey('daily_protocol');
    await _prefs?.remove(key);
    await _prefs?.remove('${key}_timestamp');
  }

  // ==================== Workout State ====================

  /// Save active workout state
  Future<void> saveWorkoutState({
    required WorkoutProtocol protocol,
    required int currentEntryIndex,
    required DateTime startTime,
    required int readinessScore,
  }) async {
    final data = {
      'protocol': protocol.toMap(),
      'currentEntryIndex': currentEntryIndex,
      'startTime': startTime.toIso8601String(),
      'readinessScore': readinessScore,
    };
    await _prefs?.setString('active_workout', jsonEncode(data));
    await _prefs?.setBool('has_active_workout', true);
  }

  /// Load active workout state
  Map<String, dynamic>? loadWorkoutState() {
    final hasActive = _prefs?.getBool('has_active_workout') ?? false;
    if (!hasActive) return null;

    final json = _prefs?.getString('active_workout');
    if (json == null) return null;

    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear workout state
  Future<void> clearWorkoutState() async {
    await _prefs?.remove('active_workout');
    await _prefs?.setBool('has_active_workout', false);
  }

  // ==================== AI Memories Cache ====================

  /// Cache AI memories locally
  Future<void> cacheMemories(List<Map<String, dynamic>> memories) async {
    await _prefs?.setString('cached_memories', jsonEncode(memories));
    await _prefs?.setString('memories_cached_at', DateTime.now().toIso8601String());
  }

  /// Load cached memories
  List<Map<String, dynamic>> loadCachedMemories() {
    final json = _prefs?.getString('cached_memories');
    if (json == null) return [];

    try {
      final list = jsonDecode(json) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ==================== User Preferences ====================

  /// Save user preference
  Future<void> setPreference(String key, dynamic value) async {
    final fullKey = 'pref_$key';
    if (value is String) {
      await _prefs?.setString(fullKey, value);
    } else if (value is int) {
      await _prefs?.setInt(fullKey, value);
    } else if (value is bool) {
      await _prefs?.setBool(fullKey, value);
    } else if (value is double) {
      await _prefs?.setDouble(fullKey, value);
    }
  }

  /// Get user preference
  dynamic getPreference(String key, dynamic defaultValue) {
    final fullKey = 'pref_$key';
    return _prefs?.get(fullKey) ?? defaultValue;
  }

  // ==================== Helper Methods ====================

  String _getTodayKey(String base) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    return '${base}_$dateStr';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Clear all cached data (for logout)
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
