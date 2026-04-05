import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/workout_tracking.dart';
import '../models/workout_protocol.dart';

/// Service for storing guest user data locally using SharedPreferences
/// All data is persisted locally and can be migrated to Supabase when user signs up
class GuestStorageService {
  static final GuestStorageService _instance = GuestStorageService._internal();
  factory GuestStorageService() => _instance;
  GuestStorageService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // Keys for local storage
  static const String _workoutsKey = 'guest_workouts';
  static const String _profileKey = 'guest_profile_v2';
  static const String _settingsKey = 'guest_settings';
  static const String _onboardingCompleteKey = 'guest_onboarding_complete';
  static const String _weeklyProgressKey = 'guest_weekly_progress';
  static const String _workoutCalendarKey = 'guest_workout_calendar';
  static const String _aiMemoriesKey = 'guest_ai_memories';
  static const String _readinessInputsKey = 'guest_readiness_inputs';
  static const String _weeklyDirectivesKey = 'guest_weekly_directives';
  static const String _dailyProtocolKey = 'guest_daily_protocol';
  static const String _isGuestModeKey = 'is_guest_mode';

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    developer.log('GuestStorageService initialized', name: 'GuestStorage');
  }

  // ==================== Guest Mode Status ====================

  /// Check if currently in guest mode
  bool get isGuestMode => _prefs?.getBool(_isGuestModeKey) ?? false;

  /// Set guest mode status
  Future<void> setGuestMode(bool value) async {
    await _prefs?.setBool(_isGuestModeKey, value);
    developer.log('Guest mode set to: $value', name: 'GuestStorage');
  }

  /// Enable guest mode
  Future<void> enableGuestMode() async {
    await setGuestMode(true);
  }

  /// Disable guest mode (when user signs up)
  Future<void> disableGuestMode() async {
    await setGuestMode(false);
  }

  // ==================== User Profile ====================

  /// Save guest user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await initialize();
      final json = jsonEncode(profile.toMap());
      await _prefs?.setString(_profileKey, json);
      developer.log('Guest profile saved', name: 'GuestStorage');
    } catch (e) {
      developer.log('Error saving guest profile: $e', name: 'GuestStorage');
    }
  }

  /// Get guest user profile
  UserProfile? getUserProfile() {
    try {
      final json = _prefs?.getString(_profileKey);
      if (json == null) return null;

      final map = jsonDecode(json) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    } catch (e) {
      developer.log('Error loading guest profile: $e', name: 'GuestStorage');
      return null;
    }
  }

  /// Check if guest has completed onboarding
  bool get hasCompletedOnboarding {
    final profile = getUserProfile();
    return profile?.hasCompletedOnboarding ??
        (_prefs?.getBool(_onboardingCompleteKey) ?? false);
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    await _prefs?.setBool(_onboardingCompleteKey, true);
    final profile = getUserProfile();
    if (profile != null) {
      final updated = UserProfile(
        userId: profile.userId,
        displayName: profile.displayName,
        photoUrl: profile.photoUrl,
        bodyComposition: profile.bodyComposition,
        fitnessLevel: profile.fitnessLevel,
        experienceLevel: profile.experienceLevel,
        trainingGoal: profile.trainingGoal,
        philosophicalBaseline: profile.philosophicalBaseline,
        trainingDaysPerWeek: profile.trainingDaysPerWeek,
        preferredWorkoutDuration: profile.preferredWorkoutDuration,
        injuriesOrLimitations: profile.injuriesOrLimitations,
        dateOfBirth: profile.dateOfBirth,
        createdAt: profile.createdAt,
        updatedAt: DateTime.now(),
        hasCompletedOnboarding: true,
      );
      await saveUserProfile(updated);
    }
  }

  // ==================== Daily Protocol ====================

  /// Save today's protocol
  Future<void> saveDailyProtocol(WorkoutProtocol protocol) async {
    try {
      await initialize();
      final key = _getTodayKey(_dailyProtocolKey);
      final json = jsonEncode(protocol.toMap());
      await _prefs?.setString(key, json);
      await _prefs?.setString('${key}_timestamp', DateTime.now().toIso8601String());
      developer.log('Daily protocol saved for guest', name: 'GuestStorage');
    } catch (e) {
      developer.log('Error saving daily protocol: $e', name: 'GuestStorage');
    }
  }

  /// Load today's protocol if it exists
  WorkoutProtocol? loadDailyProtocol() {
    try {
      final key = _getTodayKey(_dailyProtocolKey);
      final timestampStr = _prefs?.getString('${key}_timestamp');

      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      // Only return if it's from today
      if (!_isSameDay(timestamp, now)) return null;

      final json = _prefs?.getString(key);
      if (json == null) return null;

      final map = jsonDecode(json) as Map<String, dynamic>;
      return WorkoutProtocol.fromMap(map);
    } catch (e) {
      developer.log('Error loading daily protocol: $e', name: 'GuestStorage');
      return null;
    }
  }

  /// Check if protocol was generated today
  bool hasProtocolForToday() {
    return loadDailyProtocol() != null;
  }

  // ==================== Workouts ====================

  /// Save workout data locally
  Future<void> saveWorkout(CompletedWorkout workout) async {
    try {
      await initialize();
      final workouts = await getWorkouts();
      workouts.add(workout);

      final workoutsJson = workouts.map((w) => w.toMap()).toList();
      await _prefs?.setString(_workoutsKey, jsonEncode(workoutsJson));
      developer.log('Guest workout saved', name: 'GuestStorage');
    } catch (e) {
      developer.log('Error saving guest workout: $e', name: 'GuestStorage');
    }
  }

  /// Get all saved workouts
  Future<List<CompletedWorkout>> getWorkouts() async {
    try {
      final workoutsJson = _prefs?.getString(_workoutsKey);

      if (workoutsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(workoutsJson);
      return decoded.map((w) => CompletedWorkout.fromMap(w)).toList();
    } catch (e) {
      developer.log('Error getting guest workouts: $e', name: 'GuestStorage');
      return [];
    }
  }

  // ==================== Workout Calendar ====================

  /// Save workout calendar entry
  Future<void> saveWorkoutCalendarEntry(DateTime date, String? workoutName, {bool isRest = false}) async {
    try {
      await initialize();
      final key = '${_workoutCalendarKey}_${date.toIso8601String().split('T')[0]}';
      final data = {
        'date': date.toIso8601String(),
        'workout_name': workoutName,
        'is_rest': isRest,
      };
      await _prefs?.setString(key, jsonEncode(data));
      developer.log('Guest calendar entry saved', name: 'GuestStorage');
    } catch (e) {
      developer.log('Error saving calendar entry: $e', name: 'GuestStorage');
    }
  }

  /// Get workout calendar entry for date
  Map<String, dynamic>? getWorkoutCalendarEntry(DateTime date) {
    try {
      final key = '${_workoutCalendarKey}_${date.toIso8601String().split('T')[0]}';
      final json = _prefs?.getString(key);
      if (json == null) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get all calendar entries for a date range
  List<Map<String, dynamic>> getWorkoutCalendarForRange(DateTime start, DateTime end) {
    final results = <Map<String, dynamic>>[];
    var current = start;

    while (!current.isAfter(end)) {
      final entry = getWorkoutCalendarEntry(current);
      if (entry != null) {
        results.add(entry);
      }
      current = current.add(const Duration(days: 1));
    }

    return results;
  }

  // ==================== Weekly Progress ====================

  /// Save weekly progress
  Future<void> saveWeeklyProgress(Map<String, dynamic> progressData) async {
    try {
      await initialize();
      final weekStart = progressData['week_starting'] as String;
      final key = '${_weeklyProgressKey}_$weekStart';
      await _prefs?.setString(key, jsonEncode(progressData));
      developer.log('Guest weekly progress saved', name: 'GuestStorage');
    } catch (e) {
      developer.log('Error saving weekly progress: $e', name: 'GuestStorage');
    }
  }

  /// Get weekly progress for a week
  Map<String, dynamic>? getWeeklyProgress(DateTime weekStart) {
    try {
      final key = '${_weeklyProgressKey}_${weekStart.toIso8601String().split('T')[0]}';
      final json = _prefs?.getString(key);
      if (json == null) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ==================== AI Memories ====================

  /// Cache AI memory locally
  Future<void> cacheMemory(Map<String, dynamic> memory) async {
    try {
      await initialize();
      final memories = getCachedMemories();
      memories.add({
        ...memory,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _prefs?.setString(_aiMemoriesKey, jsonEncode(memories));
    } catch (e) {
      developer.log('Error caching memory: $e', name: 'GuestStorage');
    }
  }

  /// Get cached memories
  List<Map<String, dynamic>> getCachedMemories() {
    try {
      final json = _prefs?.getString(_aiMemoriesKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ==================== Readiness Inputs ====================

  /// Save session readiness input
  Future<void> saveSessionReadinessInput(Map<String, dynamic> data) async {
    try {
      await initialize();
      final date = data['session_date'] as String? ??
          DateTime.now().toIso8601String().split('T')[0];
      final key = '${_readinessInputsKey}_$date';
      await _prefs?.setString(key, jsonEncode(data));
      developer.log('Guest readiness input saved', name: 'GuestStorage');
    } catch (e) {
      developer.log('Error saving readiness input: $e', name: 'GuestStorage');
    }
  }

  /// Get session readiness input for date
  Map<String, dynamic>? getSessionReadinessInput(DateTime date) {
    try {
      final key = '${_readinessInputsKey}_${date.toIso8601String().split('T')[0]}';
      final json = _prefs?.getString(key);
      if (json == null) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ==================== Weekly Directives ====================

  /// Save weekly directive
  Future<void> saveWeeklyDirective(Map<String, dynamic> data) async {
    try {
      await initialize();
      final weekStart = data['week_starting'] as String;
      final key = '${_weeklyDirectivesKey}_$weekStart';
      await _prefs?.setString(key, jsonEncode(data));
    } catch (e) {
      developer.log('Error saving weekly directive: $e', name: 'GuestStorage');
    }
  }

  /// Get weekly directive for week
  Map<String, dynamic>? getWeeklyDirective(DateTime weekStart) {
    try {
      final key = '${_weeklyDirectivesKey}_${weekStart.toIso8601String().split('T')[0]}';
      final json = _prefs?.getString(key);
      if (json == null) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get current weekly directive
  Map<String, dynamic>? getCurrentWeeklyDirective() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return getWeeklyDirective(weekStart);
  }

  // ==================== Settings ====================

  /// Save setting
  Future<void> setSetting(String key, dynamic value) async {
    final fullKey = '${_settingsKey}_$key';
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

  /// Get setting
  dynamic getSetting(String key, dynamic defaultValue) {
    final fullKey = '${_settingsKey}_$key';
    return _prefs?.get(fullKey) ?? defaultValue;
  }

  // ==================== Data Migration ====================

  /// Get all guest data for migration to Supabase
  Future<Map<String, dynamic>> getAllDataForMigration() async {
    return {
      'profile': getUserProfile()?.toMap(),
      'workouts': (await getWorkouts()).map((w) => w.toMap()).toList(),
      'memories': getCachedMemories(),
      'onboardingComplete': hasCompletedOnboarding,
    };
  }

  /// Get data size in MB
  Future<double> getDataSize() async {
    try {
      var totalBytes = 0;

      final keysToCheck = [
        _profileKey,
        _workoutsKey,
        _aiMemoriesKey,
        _settingsKey,
      ];

      for (final key in keysToCheck) {
        final value = _prefs?.getString(key);
        if (value != null) {
          totalBytes += value.length;
        }
      }

      // Count dynamic keys
      final allKeys = _prefs?.getKeys() ?? {};
      for (final key in allKeys) {
        if (key.startsWith(_workoutCalendarKey) ||
            key.startsWith(_dailyProtocolKey) ||
            key.startsWith(_weeklyProgressKey) ||
            key.startsWith(_readinessInputsKey) ||
            key.startsWith(_weeklyDirectivesKey)) {
          final value = _prefs?.getString(key);
          if (value != null) {
            totalBytes += value.length;
          }
        }
      }

      return totalBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0.0;
    }
  }

  // ==================== Clear Data ====================

  /// Clear all guest data
  Future<void> clearAllData() async {
    try {
      final allKeys = _prefs?.getKeys() ?? {};
      final keysToRemove = allKeys.where((key) =>
          key.startsWith('guest_') ||
          key.startsWith(_dailyProtocolKey) ||
          key == _isGuestModeKey).toList();

      for (final key in keysToRemove) {
        await _prefs?.remove(key);
      }

      developer.log('All guest data cleared', name: 'GuestStorage');
    } catch (e) {
      developer.log('Error clearing guest data: $e', name: 'GuestStorage');
    }
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
}
