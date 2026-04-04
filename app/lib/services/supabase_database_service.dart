import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Database Service
/// Handles all database operations using Supabase PostgreSQL
class SupabaseDatabaseService {
  static final SupabaseDatabaseService _instance =
      SupabaseDatabaseService._internal();
  factory SupabaseDatabaseService() => _instance;
  SupabaseDatabaseService._internal();

  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get current user ID
  String? get currentUserId => SupabaseConfig.userId;

  /// Check if user is authenticated
  bool get isAuthenticated => SupabaseConfig.isAuthenticated;

  // ==================== User Profiles ====================

  /// Create or update user profile
  Future<void> saveUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      debugPrint('Saving user profile: $userId');

      await _supabase.from('user_profiles').upsert({
        'id': userId,
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('User profile saved successfully');
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      debugPrint('Getting user profile: $userId');

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('User profile retrieved: ${response != null}');
      return response;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // ==================== Workout Sessions ====================

  /// Save workout session
  Future<String> saveWorkoutSession(Map<String, dynamic> data) async {
    try {
      debugPrint('Saving workout session');

      final response = await _supabase
          .from('workout_sessions')
          .insert({
            ...data,
            'user_id': currentUserId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      debugPrint('Workout session saved: ${response['id']}');
      return response['id'];
    } catch (e) {
      debugPrint('Error saving workout session: $e');
      rethrow;
    }
  }

  /// Get workout sessions for a user
  Future<List<Map<String, dynamic>>> getWorkoutSessions({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      debugPrint('Getting workout sessions');

      var query = _supabase
          .from('workout_sessions')
          .select()
          .eq('user_id', currentUserId!);

      if (startDate != null) {
        query = query.filter('date', 'gte', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.filter('date', 'lte', endDate.toIso8601String());
      }

      query = query.order('date', ascending: false).limit(limit);

      final response = await query;
      debugPrint('Retrieved ${response.length} workout sessions');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting workout sessions: $e');
      return [];
    }
  }

  // ==================== Workout Sets ====================

  /// Save workout sets
  Future<void> saveWorkoutSets(
    String sessionId,
    List<Map<String, dynamic>> sets,
  ) async {
    try {
      debugPrint('Saving ${sets.length} workout sets for session: $sessionId');

      final setsWithSession = sets
          .map(
            (set) => {
              ...set,
              'session_id': sessionId,
              'created_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      await _supabase.from('workout_sets').insert(setsWithSession);
      debugPrint('Workout sets saved successfully');
    } catch (e) {
      debugPrint('Error saving workout sets: $e');
      rethrow;
    }
  }

  /// Get workout sets for a session
  Future<List<Map<String, dynamic>>> getWorkoutSets(String sessionId) async {
    try {
      debugPrint('Getting workout sets for session: $sessionId');

      final response = await _supabase
          .from('workout_sets')
          .select()
          .eq('session_id', sessionId)
          .order('set_number', ascending: true);

      debugPrint('Retrieved ${response.length} workout sets');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting workout sets: $e');
      return [];
    }
  }

  // ==================== AI Memories ====================

  /// Store AI memory
  Future<void> storeMemory(Map<String, dynamic> memoryData) async {
    try {
      debugPrint('Storing AI memory');

      await _supabase.from('ai_memories').insert({
        ...memoryData,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
        'last_accessed': DateTime.now().toIso8601String(),
      });

      debugPrint('AI memory stored successfully');
    } catch (e) {
      debugPrint('Error storing AI memory: $e');
      rethrow;
    }
  }

  /// Query AI memories
  Future<List<Map<String, dynamic>>> queryMemories({
    String? type,
    int limit = 50,
  }) async {
    try {
      debugPrint('Querying AI memories');

      var query = _supabase
          .from('ai_memories')
          .select()
          .eq('user_id', currentUserId!);

      if (type != null) {
        query = query.eq('type', type);
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;
      debugPrint('Retrieved ${response.length} AI memories');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error querying AI memories: $e');
      return [];
    }
  }

  // ==================== Weekly Progress ====================

  /// Save weekly progress
  Future<void> saveWeeklyProgress(Map<String, dynamic> progressData) async {
    try {
      debugPrint('Saving weekly progress');

      await _supabase.from('weekly_progress').upsert({
        ...progressData,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Weekly progress saved successfully');
    } catch (e) {
      debugPrint('Error saving weekly progress: $e');
      rethrow;
    }
  }

  /// Get weekly progress
  Future<Map<String, dynamic>?> getWeeklyProgress(DateTime weekStart) async {
    try {
      debugPrint('Getting weekly progress for week: $weekStart');

      final response = await _supabase
          .from('weekly_progress')
          .select()
          .eq('user_id', currentUserId!)
          .eq('week_starting', weekStart.toIso8601String())
          .maybeSingle();

      debugPrint('Weekly progress retrieved: ${response != null}');
      return response;
    } catch (e) {
      debugPrint('Error getting weekly progress: $e');
      return null;
    }
  }

  // ==================== Real-time Subscriptions ====================

  /// Subscribe to real-time updates for a table
  Stream<List<Map<String, dynamic>>> subscribeToTable(
    String tableName, {
    String? column,
    dynamic value,
  }) {
    debugPrint('Subscribing to table: $tableName');

    return _supabase
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  // ==================== Utility Methods ====================

  /// Execute custom query
  Future<List<Map<String, dynamic>>> executeQuery(
    String tableName, {
    List<String> select = const ['*'],
    Map<String, dynamic>? eq,
    Map<String, dynamic>? neq,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase.from(tableName).select(select.join(', '));

      if (eq != null) {
        for (final entry in eq.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      if (neq != null) {
        for (final entry in neq.entries) {
          query = query.neq(entry.key, entry.value);
        }
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error executing query: $e');
      return [];
    }
  }

  /// Delete record
  Future<void> deleteRecord(String tableName, String id) async {
    try {
      debugPrint('Deleting record from $tableName: $id');

      await _supabase.from(tableName).delete().eq('id', id);
      debugPrint('Record deleted successfully');
    } catch (e) {
      debugPrint('Error deleting record: $e');
      rethrow;
    }
  }
}
