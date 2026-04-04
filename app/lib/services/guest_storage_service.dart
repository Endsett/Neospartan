import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_tracking.dart';

/// Service for storing guest user data locally
class GuestStorageService {
  static const String _workoutsKey = 'guest_workouts';
  static const String _profileKey = 'guest_profile';
  static const String _settingsKey = 'guest_settings';

  /// Save workout data locally
  static Future<void> saveWorkout(CompletedWorkout workout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workouts = await getWorkouts();
      workouts.add(workout);

      final workoutsJson = workouts.map((w) => w.toMap()).toList();
      await prefs.setString(_workoutsKey, jsonEncode(workoutsJson));
    } catch (e) {
      developer.log('Error saving workout locally: $e');
    }
  }

  /// Get all saved workouts
  static Future<List<CompletedWorkout>> getWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutsJson = prefs.getString(_workoutsKey);

      if (workoutsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(workoutsJson);
      return decoded.map((w) => CompletedWorkout.fromMap(w)).toList();
    } catch (e) {
      developer.log('Error getting workouts: $e');
      return [];
    }
  }

  /// Clear all guest data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_workoutsKey);
      await prefs.remove(_profileKey);
      await prefs.remove(_settingsKey);
    } catch (e) {
      developer.log('Error clearing guest data: $e');
    }
  }

  /// Get data size in MB
  static Future<double> getDataSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workouts = prefs.getString(_workoutsKey) ?? '';
      final profile = prefs.getString(_profileKey) ?? '';
      final settings = prefs.getString(_settingsKey) ?? '';

      final totalBytes = workouts.length + profile.length + settings.length;
      return totalBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0.0;
    }
  }
}
