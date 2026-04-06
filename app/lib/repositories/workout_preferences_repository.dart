import 'dart:developer' as developer;
import '../models/workout_preferences.dart';
import '../config/supabase_config.dart';

/// Repository for WorkoutPreferences CRUD operations using Supabase
class WorkoutPreferencesRepository {
  static const String _tableName = 'workout_preferences';

  /// Get preferences for a user
  Future<WorkoutPreferences?> getPreferences(String userId) async {
    try {
      final supabase = SupabaseConfig.client;
      final response = await supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        developer.log('Workout preferences found for user: $userId', 
            name: 'WorkoutPreferencesRepository');
        return WorkoutPreferences.fromMap(response);
      }

      return null;
    } catch (e) {
      developer.log(
        'Error getting workout preferences: $e',
        name: 'WorkoutPreferencesRepository',
      );
      return null;
    }
  }

  /// Save or update preferences
  Future<bool> savePreferences(WorkoutPreferences preferences) async {
    try {
      final supabase = SupabaseConfig.client;
      final now = DateTime.now();
      
      final data = preferences.copyWith(
        updatedAt: now,
      ).toMap();

      // Remove id if null to let Supabase generate it
      if (data['id'] == null) {
        data.remove('id');
      }

      await supabase.from(_tableName).upsert(
        data,
        onConflict: 'user_id',
      );

      developer.log(
        'Workout preferences saved for user: ${preferences.userId}',
        name: 'WorkoutPreferencesRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error saving workout preferences: $e',
        name: 'WorkoutPreferencesRepository',
      );
      return false;
    }
  }

  /// Create default preferences for a new user
  Future<WorkoutPreferences> createDefaultPreferences(String userId) async {
    final prefs = WorkoutPreferences.defaultPrefs(userId);
    await savePreferences(prefs);
    return prefs;
  }

  /// Get or create preferences for a user
  Future<WorkoutPreferences> getOrCreatePreferences(String userId) async {
    final existing = await getPreferences(userId);
    if (existing != null) {
      return existing;
    }
    return await createDefaultPreferences(userId);
  }

  /// Delete preferences for a user
  Future<bool> deletePreferences(String userId) async {
    try {
      final supabase = SupabaseConfig.client;
      await supabase
          .from(_tableName)
          .delete()
          .eq('user_id', userId);

      developer.log(
        'Workout preferences deleted for user: $userId',
        name: 'WorkoutPreferencesRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error deleting workout preferences: $e',
        name: 'WorkoutPreferencesRepository',
      );
      return false;
    }
  }
}
