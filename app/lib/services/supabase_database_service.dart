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

      if (currentUserId == null) {
        throw Exception('No authenticated user');
      }

      final payload = {...data, 'user_id': currentUserId};

      if (payload['start_time'] == null) {
        payload['start_time'] = DateTime.now().toIso8601String();
      }

      if (payload['date'] == null && payload['start_time'] != null) {
        final parsed = DateTime.tryParse(payload['start_time'].toString());
        if (parsed != null) {
          payload['date'] = _dateOnly(parsed);
        }
      } else if (payload['date'] != null) {
        final parsedDate = DateTime.tryParse(payload['date'].toString());
        if (parsedDate != null) {
          payload['date'] = _dateOnly(parsedDate);
        }
      }

      final response = payload['id'] != null
          ? await _supabase
                .from('workout_sessions')
                .upsert(payload, onConflict: 'id')
                .select('id')
                .single()
          : await _supabase
                .from('workout_sessions')
                .insert({
                  ...payload,
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

      dynamic query = _supabase
          .from('workout_sessions')
          .select()
          .eq('user_id', currentUserId!);

      if (startDate != null) {
        query = query.gte('date', _dateOnly(startDate));
      }
      if (endDate != null) {
        query = query.lte('date', _dateOnly(endDate));
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

  /// Save a single workout set (for real-time logging)
  Future<void> saveWorkoutSet(Map<String, dynamic> setData) async {
    try {
      debugPrint(
        'Saving workout set: ${setData['exercise_name']} Set ${setData['set_number']}',
      );

      await _supabase.from('workout_sets').insert({
        ...setData,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Workout set saved successfully');
    } catch (e) {
      debugPrint('Error saving workout set: $e');
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

      dynamic query = _supabase
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

      if (currentUserId == null) {
        throw Exception('No authenticated user');
      }

      final rawWeekStart = progressData['week_starting'];
      final weekStartDate = rawWeekStart is DateTime
          ? rawWeekStart
          : DateTime.tryParse(rawWeekStart?.toString() ?? '');

      await _supabase.from('weekly_progress').upsert({
        ...progressData,
        'user_id': currentUserId,
        'week_starting': _dateOnly(weekStartDate ?? DateTime.now()),
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,week_starting');

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
          .eq('week_starting', _dateOnly(weekStart))
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

<<<<<<< HEAD
  // ==================== Session Readiness Inputs ====================

  /// Save session readiness input
  Future<String> saveSessionReadinessInput(Map<String, dynamic> data) async {
    try {
      debugPrint('Saving session readiness input');

      final response = await _supabase
          .from('session_readiness_inputs')
          .upsert({
            ...data,
            'user_id': currentUserId,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,session_date')
          .select('id')
          .single();

      debugPrint('Session readiness input saved: ${response['id']}');
      return response['id'];
    } catch (e) {
      debugPrint('Error saving session readiness input: $e');
      rethrow;
    }
  }

  /// Get session readiness input for date
  Future<Map<String, dynamic>?> getSessionReadinessInput(DateTime date) async {
    try {
      debugPrint('Getting session readiness input for: $date');

      final response = await _supabase
          .from('session_readiness_inputs')
          .select()
          .eq('user_id', currentUserId!)
          .eq('session_date', date.toIso8601String().split('T')[0])
          .maybeSingle();

      debugPrint('Session readiness input retrieved: ${response != null}');
      return response;
    } catch (e) {
      debugPrint('Error getting session readiness input: $e');
      return null;
    }
  }

  /// Get recent session readiness inputs
  Future<List<Map<String, dynamic>>> getRecentSessionReadinessInputs({
    int days = 7,
  }) async {
    try {
      debugPrint('Getting recent session readiness inputs');

      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('session_readiness_inputs')
          .select()
          .eq('user_id', currentUserId!)
          .gte('session_date', startDate.toIso8601String().split('T')[0])
          .order('session_date', ascending: false);

      debugPrint('Retrieved ${response.length} session readiness inputs');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting recent session readiness inputs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutCalendarForWeek(
    DateTime weekStart,
  ) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final response = await _supabase
          .from('workout_calendar')
          .select()
          .eq('user_id', currentUserId!)
          .gte('date', _dateOnly(weekStart))
          .lte('date', _dateOnly(weekEnd));

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting workout calendar for week: $e');
      return [];
    }
  }

  // ==================== Weekly Directives ====================

  /// Save weekly directive
  Future<String> saveWeeklyDirective(Map<String, dynamic> data) async {
    try {
      debugPrint('Saving weekly directive');

      final response = await _supabase
          .from('weekly_directives')
          .upsert({
            ...data,
            'user_id': currentUserId,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,week_starting')
          .select('id')
          .single();

      debugPrint('Weekly directive saved: ${response['id']}');
      return response['id'];
    } catch (e) {
      debugPrint('Error saving weekly directive: $e');
      rethrow;
    }
  }

  Future<void> saveWorkoutCalendarEntry({
    required DateTime date,
    String? workoutName,
    bool isRestDay = false,
  }) async {
    try {
      await _supabase.from('workout_calendar').upsert({
        'user_id': currentUserId,
        'date': _dateOnly(date),
        'workout_name': workoutName,
        'is_rest': isRestDay,
      }, onConflict: 'user_id,date');
    } catch (e) {
      debugPrint('Error saving workout calendar entry: $e');
      rethrow;
    }
  }

  /// Get weekly directive for week
  Future<Map<String, dynamic>?> getWeeklyDirective(DateTime weekStart) async {
    try {
      debugPrint('Getting weekly directive for week: $weekStart');

      final response = await _supabase
          .from('weekly_directives')
          .select()
          .eq('user_id', currentUserId!)
          .eq('week_starting', weekStart.toIso8601String().split('T')[0])
          .maybeSingle();

      debugPrint('Weekly directive retrieved: ${response != null}');
      return response;
    } catch (e) {
      debugPrint('Error getting weekly directive: $e');
      return null;
    }
  }

  /// Get current weekly directive (for current week)
  Future<Map<String, dynamic>?> getCurrentWeeklyDirective() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return getWeeklyDirective(weekStart);
  }

  /// Get weekly directive history
  Future<List<Map<String, dynamic>>> getWeeklyDirectiveHistory({
    int limit = 12,
  }) async {
    try {
      debugPrint('Getting weekly directive history');

      final response = await _supabase
          .from('weekly_directives')
          .select()
          .eq('user_id', currentUserId!)
          .order('week_starting', ascending: false)
          .limit(limit);

      debugPrint('Retrieved ${response.length} weekly directives');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting weekly directive history: $e');
      return [];
    }
  }

  Future<void> deleteWorkoutCalendarEntry(DateTime date) async {
    try {
      await _supabase
          .from('workout_calendar')
          .delete()
          .eq('user_id', currentUserId!)
          .eq('date', _dateOnly(date));
    } catch (e) {
      debugPrint('Error deleting workout calendar entry: $e');
      rethrow;
    }
  }

  Future<void> saveAnalyticsEvent(
    String eventType,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _supabase.from('analytics_events').insert({
        'user_id': currentUserId,
        'event_type': eventType,
        'payload': payload,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving analytics event: $e');
    }
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
