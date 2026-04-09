import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/biometrics.dart';
import '../models/daily_readiness.dart';

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

  /// Save partial/abandoned workout session with completion percentage
  Future<void> savePartialWorkoutSession({
    required String sessionId,
    required DateTime startTime,
    required String workoutType,
    required int exercisesCompleted,
    required int totalExercises,
    required double completionPercentage,
    required int readinessScore,
    int? durationMinutes,
  }) async {
    try {
      debugPrint(
        'Saving partial workout session: $completionPercentage% complete',
      );

      if (currentUserId == null) {
        throw Exception('No authenticated user');
      }

      final endTime = DateTime.now();
      final actualDuration =
          durationMinutes ?? endTime.difference(startTime).inMinutes;

      await _supabase.from('workout_sessions').upsert({
        'id': sessionId,
        'user_id': currentUserId,
        'date': _dateOnly(startTime),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'workout_type': workoutType,
        'status': 'abandoned',
        'completion_percentage': completionPercentage,
        'exercises_completed': exercisesCompleted,
        'total_exercises': totalExercises,
        'notes':
            'readiness:$readinessScore;duration:$actualDuration;status:abandoned;completed:$exercisesCompleted/$totalExercises',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      debugPrint('Partial workout session saved successfully');
    } catch (e) {
      debugPrint('Error saving partial workout session: $e');
      rethrow;
    }
  }

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

      // Remove user_id if present - workout_sets table only requires session_id
      final payload = Map<String, dynamic>.from(setData);
      payload.remove('user_id');

      await _supabase.from('workout_sets').insert({
        ...payload,
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

  // ==================== Performance Analytics for AI ====================

  /// Fetch a structured summary of recent workout performance for AI prompt context.
  /// Returns per-exercise stats, volume trends, RPE trends, and weekly progress.
  Future<Map<String, dynamic>> getRecentPerformanceSummary({
    int sessionLimit = 10,
    int weeklyProgressWeeks = 4,
  }) async {
    try {
      if (currentUserId == null) {
        return {'empty': true, 'reason': 'no_user'};
      }

      // 1. Fetch recent completed sessions
      final sessions = await getWorkoutSessions(limit: sessionLimit);
      if (sessions.isEmpty) {
        return {'empty': true, 'reason': 'no_sessions'};
      }

      // 2. Fetch sets for each session
      final allSets = <Map<String, dynamic>>[];
      for (final session in sessions) {
        final sessionId = session['id']?.toString();
        if (sessionId == null || sessionId.isEmpty) continue;
        final sets = await getWorkoutSets(sessionId);
        for (final s in sets) {
          s['session_date'] = session['date'];
          s['workout_type'] = session['workout_type'];
        }
        allSets.addAll(sets);
      }

      // 3. Build per-exercise aggregates
      final exerciseStats = <String, Map<String, dynamic>>{};
      for (final s in allSets) {
        final name = s['exercise_name']?.toString() ?? 'Unknown';
        final stats = exerciseStats.putIfAbsent(
          name,
          () => ({
            'count': 0,
            'total_reps': 0,
            'total_volume': 0.0,
            'max_load': 0.0,
            'rpe_sum': 0.0,
            'rpe_count': 0,
            'dates': <String>[],
          }),
        );
        stats['count'] = (stats['count'] as int) + 1;
        final reps = (s['reps_performed'] as num?)?.toInt() ?? 0;
        final load = (s['load_used'] as num?)?.toDouble() ?? 0.0;
        final rpe = (s['actual_rpe'] as num?)?.toDouble() ?? 0.0;
        stats['total_reps'] = (stats['total_reps'] as int) + reps;
        stats['total_volume'] =
            (stats['total_volume'] as double) + (load * reps);
        if (load > (stats['max_load'] as double)) {
          stats['max_load'] = load;
        }
        if (rpe > 0) {
          stats['rpe_sum'] = (stats['rpe_sum'] as double) + rpe;
          stats['rpe_count'] = (stats['rpe_count'] as int) + 1;
        }
        final date = s['session_date']?.toString() ?? '';
        if (date.isNotEmpty &&
            !(stats['dates'] as List<String>).contains(date)) {
          (stats['dates'] as List<String>).add(date);
        }
      }

      // Compute averages
      final exerciseSummaries = <Map<String, dynamic>>[];
      for (final entry in exerciseStats.entries) {
        final stats = entry.value;
        final avgRpe = (stats['rpe_count'] as int) > 0
            ? (stats['rpe_sum'] as double) / (stats['rpe_count'] as int)
            : 0.0;
        exerciseSummaries.add({
          'exercise': entry.key,
          'sets_logged': stats['count'],
          'total_reps': stats['total_reps'],
          'total_volume': (stats['total_volume'] as double).toStringAsFixed(1),
          'max_load': stats['max_load'],
          'avg_rpe': double.parse(avgRpe.toStringAsFixed(1)),
          'sessions_appeared': (stats['dates'] as List<String>).length,
        });
      }

      // Sort by frequency
      exerciseSummaries.sort(
        (a, b) => (b['sets_logged'] as int).compareTo(a['sets_logged'] as int),
      );

      // 4. Fetch recent weekly progress
      final weeklyData = <Map<String, dynamic>>[];
      final now = DateTime.now();
      for (int i = 0; i < weeklyProgressWeeks; i++) {
        final weekStart = now.subtract(
          Duration(days: now.weekday - 1 + (i * 7)),
        );
        final progress = await getWeeklyProgress(weekStart);
        if (progress != null) {
          weeklyData.add(progress);
        }
      }

      // 5. Compute session-level trends
      double totalSessionRpe = 0;
      int sessionRpeCount = 0;
      for (final session in sessions) {
        final notes = session['notes']?.toString() ?? '';
        final rpeMatch = RegExp(r'averageRpe:([\d.]+)').firstMatch(notes);
        if (rpeMatch != null) {
          totalSessionRpe += double.tryParse(rpeMatch.group(1)!) ?? 0;
          sessionRpeCount++;
        }
      }

      return {
        'empty': false,
        'sessions_analyzed': sessions.length,
        'total_sets_analyzed': allSets.length,
        'exercise_summaries': exerciseSummaries.take(15).toList(),
        'weekly_progress': weeklyData
            .map(
              (w) => {
                'week': w['week_starting'],
                'workouts_completed': w['workouts_completed'],
                'average_rpe': w['average_rpe'],
                'total_volume': w['total_volume'],
                'average_readiness': w['average_readiness'],
              },
            )
            .toList(),
        'overall_avg_rpe': sessionRpeCount > 0
            ? double.parse(
                (totalSessionRpe / sessionRpeCount).toStringAsFixed(1),
              )
            : null,
        'most_recent_session_date': sessions.first['date'],
      };
    } catch (e) {
      debugPrint('Error building performance summary: $e');
      return {'empty': true, 'reason': 'error', 'error': e.toString()};
    }
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ==================== Biometrics ====================

  /// Save biometrics data
  Future<void> saveBiometrics(String userId, Biometrics biometrics) async {
    try {
      debugPrint('Saving biometrics for user: $userId');
      await _supabase.from('biometrics').upsert({
        'user_id': userId,
        'date': _dateOnly(biometrics.date),
        'weight': biometrics.weight,
        'body_fat': biometrics.bodyFat,
        'muscle_mass': biometrics.muscleMass,
        'waist_circumference': biometrics.waistCircumference,
        'chest_circumference': biometrics.chestCircumference,
        'arm_circumference': biometrics.armCircumference,
        'thigh_circumference': biometrics.thighCircumference,
        'hrv': biometrics.hrv,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');
      debugPrint('Biometrics saved successfully');
    } catch (e) {
      debugPrint('Error saving biometrics: $e');
      rethrow;
    }
  }

  /// Get biometrics for date range
  Future<List<Map<String, dynamic>>> getBiometricsForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('biometrics')
          .select()
          .eq('user_id', userId)
          .gte('date', _dateOnly(startDate))
          .lte('date', _dateOnly(endDate))
          .order('date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting biometrics for range: $e');
      return [];
    }
  }

  /// Get biometrics history
  Future<List<Map<String, dynamic>>> getBiometricsHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final response = await _supabase
          .from('biometrics')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting biometrics history: $e');
      return [];
    }
  }

  /// Get latest biometrics entry
  Future<Map<String, dynamic>?> getLatestBiometrics(String userId) async {
    try {
      final response = await _supabase
          .from('biometrics')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error getting latest biometrics: $e');
      return null;
    }
  }

  /// Get biometrics for specific date
  Future<Map<String, dynamic>?> getBiometricsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final response = await _supabase
          .from('biometrics')
          .select()
          .eq('user_id', userId)
          .eq('date', _dateOnly(date))
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error getting biometrics for date: $e');
      return null;
    }
  }

  // ==================== Daily Readiness ====================

  /// Save daily readiness
  Future<void> saveDailyReadiness(DailyReadiness readiness) async {
    try {
      debugPrint('Saving daily readiness for user: ${readiness.userId}');
      await _supabase.from('daily_readiness').upsert({
        'user_id': readiness.userId,
        'date': _dateOnly(readiness.date),
        'readiness_score': readiness.readinessScore,
        'notes': readiness.notes,
        'factors': readiness.factors,
        'sleep_quality': readiness.sleepQuality,
        'recovery_score': readiness.recoveryScore,
        'soreness': readiness.soreness,
        'motivation': readiness.motivation,
        'stress': readiness.stress,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date');
      debugPrint('Daily readiness saved successfully');
    } catch (e) {
      debugPrint('Error saving daily readiness: $e');
      rethrow;
    }
  }

  /// Get recent readiness scores
  Future<List<Map<String, dynamic>>> getRecentReadiness(
    String userId, {
    int days = 7,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      final response = await _supabase
          .from('daily_readiness')
          .select()
          .eq('user_id', userId)
          .gte('date', _dateOnly(startDate))
          .lte('date', _dateOnly(endDate))
          .order('date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting recent readiness: $e');
      return [];
    }
  }

  /// Get readiness history
  Future<List<Map<String, dynamic>>> getReadinessHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final response = await _supabase
          .from('daily_readiness')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting readiness history: $e');
      return [];
    }
  }

  /// Get readiness for specific date
  Future<Map<String, dynamic>?> getReadinessForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final response = await _supabase
          .from('daily_readiness')
          .select()
          .eq('user_id', userId)
          .eq('date', _dateOnly(date))
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error getting readiness for date: $e');
      return null;
    }
  }

  // ==================== Achievements ====================

  /// Get all achievements for user
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .order('tier', ascending: true)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      return [];
    }
  }

  /// Get unlocked achievements
  Future<List<Map<String, dynamic>>> getUnlockedAchievements(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .eq('is_unlocked', true)
          .order('unlocked_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting unlocked achievements: $e');
      return [];
    }
  }

  /// Save or update achievement
  Future<void> saveAchievement(
    String userId,
    Map<String, dynamic> achievement,
  ) async {
    try {
      await _supabase.from('achievements').upsert({
        'user_id': userId,
        'achievement_id': achievement['achievement_id'],
        'title': achievement['title'],
        'description': achievement['description'],
        'icon_name': achievement['icon_name'] ?? 'star',
        'category': achievement['category'],
        'tier': achievement['tier'] ?? 1,
        'target_value': achievement['target_value'],
        'current_value': achievement['current_value'] ?? 0,
        'is_unlocked': achievement['is_unlocked'] ?? false,
        'unlocked_at': achievement['unlocked_at'],
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,achievement_id');
      debugPrint('Achievement saved successfully');
    } catch (e) {
      debugPrint('Error saving achievement: $e');
      rethrow;
    }
  }

  /// Update achievement progress
  Future<void> updateAchievementProgress(
    String userId,
    String achievementId,
    int currentValue,
  ) async {
    try {
      await _supabase
          .from('achievements')
          .update({
            'current_value': currentValue,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('achievement_id', achievementId);
      debugPrint('Achievement progress updated');
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
      rethrow;
    }
  }

  /// Unlock achievement
  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      await _supabase
          .from('achievements')
          .update({
            'is_unlocked': true,
            'unlocked_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('achievement_id', achievementId);
      debugPrint('Achievement unlocked');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
      rethrow;
    }
  }

  /// Check if achievement exists
  Future<bool> achievementExists(String userId, String achievementId) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select('id')
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking achievement existence: $e');
      return false;
    }
  }

  // ==================== Stoic Entries ====================

  /// Save stoic entry
  Future<void> saveStoicEntry(Map<String, dynamic> entry) async {
    try {
      await _supabase.from('stoic_entries').insert(entry);
      debugPrint('Stoic entry saved');
    } catch (e) {
      debugPrint('Error saving stoic entry: $e');
      rethrow;
    }
  }

  /// Get stoic entries by type
  Future<List<Map<String, dynamic>>> getStoicEntriesByType(
    String userId,
    String type, {
    int limit = 30,
  }) async {
    try {
      final response = await _supabase
          .from('stoic_entries')
          .select()
          .eq('user_id', userId)
          .eq('entry_type', type)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting stoic entries: $e');
      return [];
    }
  }

  /// Get stoic entries for date range
  Future<List<Map<String, dynamic>>> getStoicEntriesForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('stoic_entries')
          .select()
          .eq('user_id', userId)
          .gte('session_date', _dateOnly(startDate))
          .lte('session_date', _dateOnly(endDate))
          .order('session_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting stoic entries for range: $e');
      return [];
    }
  }

  /// Delete stoic entry
  Future<void> deleteStoicEntry(String entryId) async {
    try {
      await _supabase.from('stoic_entries').delete().eq('id', entryId);
      debugPrint('Stoic entry deleted');
    } catch (e) {
      debugPrint('Error deleting stoic entry: $e');
      rethrow;
    }
  }

  // ==================== Fuel Logs ====================

  /// Save fuel log entry
  Future<void> saveFuelLogEntry(Map<String, dynamic> entry) async {
    try {
      await _supabase.from('fuel_logs').insert(entry);
      debugPrint('Fuel log entry saved');
    } catch (e) {
      debugPrint('Error saving fuel log entry: $e');
      rethrow;
    }
  }

  /// Get fuel logs for date
  Future<List<Map<String, dynamic>>> getFuelLogsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final response = await _supabase
          .from('fuel_logs')
          .select()
          .eq('user_id', userId)
          .eq('date', _dateOnly(date))
          .order('timestamp', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting fuel logs for date: $e');
      return [];
    }
  }

  /// Get fuel logs for range
  Future<List<Map<String, dynamic>>> getFuelLogsForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('fuel_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', _dateOnly(startDate))
          .lte('date', _dateOnly(endDate))
          .order('date', ascending: true)
          .order('timestamp', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting fuel logs for range: $e');
      return [];
    }
  }

  /// Delete fuel log entry
  Future<void> deleteFuelLogEntry(String entryId) async {
    try {
      await _supabase.from('fuel_logs').delete().eq('id', entryId);
      debugPrint('Fuel log entry deleted');
    } catch (e) {
      debugPrint('Error deleting fuel log entry: $e');
      rethrow;
    }
  }

  /// Get recent fuel logs
  Future<List<Map<String, dynamic>>> getRecentFuelLogs(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('fuel_logs')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting recent fuel logs: $e');
      return [];
    }
  }

  // ==================== Imported Plans ====================

  /// Save imported plan
  Future<void> saveImportedPlan(Map<String, dynamic> plan) async {
    try {
      await _supabase.from('imported_plans').upsert({
        'id': plan['id'],
        'user_id': plan['user_id'],
        'plan_name': plan['plan_name'],
        'description': plan['description'],
        'protocol_json': plan['protocol_json'],
        'sport_focus': plan['sport_focus'],
        'is_active': plan['is_active'] ?? false,
        'autopilot_enabled': plan['autopilot_enabled'] ?? false,
        'source': plan['source'] ?? 'manual',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      debugPrint('Imported plan saved');
    } catch (e) {
      debugPrint('Error saving imported plan: $e');
      rethrow;
    }
  }

  /// Get imported plans for user
  Future<List<Map<String, dynamic>>> getImportedPlansForUser(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('imported_plans')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting imported plans: $e');
      return [];
    }
  }

  /// Deactivate all imported plans for user
  Future<void> deactivateAllImportedPlans(String userId) async {
    try {
      await _supabase
          .from('imported_plans')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      debugPrint('All imported plans deactivated');
    } catch (e) {
      debugPrint('Error deactivating imported plans: $e');
      rethrow;
    }
  }

  /// Activate a specific imported plan
  Future<void> activateImportedPlan(String planId) async {
    try {
      await _supabase
          .from('imported_plans')
          .update({
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', planId);
      debugPrint('Imported plan activated: $planId');
    } catch (e) {
      debugPrint('Error activating imported plan: $e');
      rethrow;
    }
  }

  /// Update imported plan autopilot setting
  Future<void> updateImportedPlanAutopilot(String planId, bool enabled) async {
    try {
      await _supabase
          .from('imported_plans')
          .update({
            'autopilot_enabled': enabled,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', planId);
      debugPrint('Imported plan autopilot updated: $planId = $enabled');
    } catch (e) {
      debugPrint('Error updating imported plan autopilot: $e');
      rethrow;
    }
  }

  /// Delete imported plan
  Future<void> deleteImportedPlan(String planId) async {
    try {
      await _supabase.from('imported_plans').delete().eq('id', planId);
      debugPrint('Imported plan deleted: $planId');
    } catch (e) {
      debugPrint('Error deleting imported plan: $e');
      rethrow;
    }
  }

  // ==================== Analytics Events ====================

  /// Get analytics events with optional filtering
  Future<List<Map<String, dynamic>>> getAnalyticsEvents({
    required String userId,
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('analytics_events')
          .select()
          .eq('user_id', userId);

      if (eventType != null) {
        query = query.eq('event_type', eventType);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting analytics events: $e');
      return [];
    }
  }

  // ==================== AI Memory ====================

  /// Get memory statistics
  Future<Map<String, dynamic>> getMemoryStats(String userId) async {
    try {
      // Count total memories
      final totalResult = await _supabase
          .from('ai_memories')
          .select('id')
          .eq('user_id', userId);
      final totalMemories = totalResult.length;

      // Count by type
      final typeResult = await _supabase
          .from('ai_memories')
          .select('type')
          .eq('user_id', userId);
      final byType = <String, int>{};
      for (final row in typeResult) {
        final type = row['type'] as String;
        byType[type] = (byType[type] ?? 0) + 1;
      }

      // Count by priority
      final priorityResult = await _supabase
          .from('ai_memories')
          .select('priority')
          .eq('user_id', userId);
      final byPriority = <String, int>{};
      for (final row in priorityResult) {
        final priority = row['priority'] as String;
        byPriority[priority] = (byPriority[priority] ?? 0) + 1;
      }

      return {
        'totalMemories': totalMemories,
        'byType': byType,
        'byPriority': byPriority,
      };
    } catch (e) {
      debugPrint('Error getting memory stats: $e');
      return {'totalMemories': 0, 'byType': {}, 'byPriority': {}};
    }
  }

  /// Record memory access
  Future<void> recordMemoryAccess(String userId, String memoryId) async {
    try {
      await _supabase
          .from('ai_memories')
          .update({
            'access_count': _supabase.rpc(
              'increment',
              params: {'row_id': memoryId},
            ),
            'last_accessed': DateTime.now().toIso8601String(),
          })
          .eq('id', memoryId)
          .eq('user_id', userId);
      debugPrint('Memory access recorded: $memoryId');
    } catch (e) {
      // Fallback: simple increment without RPC
      try {
        final current = await _supabase
            .from('ai_memories')
            .select('access_count')
            .eq('id', memoryId)
            .eq('user_id', userId)
            .single();
        final newCount = (current['access_count'] as int? ?? 0) + 1;
        await _supabase
            .from('ai_memories')
            .update({
              'access_count': newCount,
              'last_accessed': DateTime.now().toIso8601String(),
            })
            .eq('id', memoryId);
      } catch (e2) {
        debugPrint('Error recording memory access: $e2');
      }
    }
  }

  // ==================== Flow State Assessments ====================

  /// Save flow state assessment
  Future<void> saveFlowStateAssessment(Map<String, dynamic> data) async {
    try {
      await _supabase.from('flow_state_assessments').insert(data);
      debugPrint('Flow state assessment saved successfully');
    } catch (e) {
      debugPrint('Error saving flow state assessment: $e');
      rethrow;
    }
  }

  /// Get flow state assessments for user
  Future<List<Map<String, dynamic>>> getFlowStateAssessments(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final response = await _supabase
          .from('flow_state_assessments')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting flow state assessments: $e');
      return [];
    }
  }

  /// Update workout session with flow score
  Future<void> updateWorkoutSessionWithFlow(
    String sessionId,
    int flowScore,
  ) async {
    try {
      await _supabase
          .from('workout_sessions')
          .update({
            'flow_score': flowScore,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
      debugPrint('Workout session updated with flow score: $flowScore');
    } catch (e) {
      debugPrint('Error updating workout session with flow: $e');
      rethrow;
    }
  }

  /// Get previous session data for a specific exercise
  Future<Map<String, dynamic>?> getPreviousExerciseSession(
    String exerciseName,
  ) async {
    try {
      debugPrint('Getting previous session for exercise: $exerciseName');

      // Get recent completed sessions
      final sessions = await getWorkoutSessions(limit: 10);

      for (final session in sessions) {
        final sessionId = session['id']?.toString();
        if (sessionId == null) continue;

        // Get sets for this session
        final sets = await getWorkoutSets(sessionId);

        // Find sets for this specific exercise
        final exerciseSets = sets
            .where(
              (set) =>
                  set['exercise_name']?.toString().toLowerCase() ==
                  exerciseName.toLowerCase(),
            )
            .toList();

        if (exerciseSets.isNotEmpty) {
          // Calculate best set (by weight x reps)
          final bestSet = exerciseSets.reduce((a, b) {
            final volumeA =
                (a['load_used'] as num? ?? 0) *
                (a['reps_performed'] as num? ?? 0);
            final volumeB =
                (b['load_used'] as num? ?? 0) *
                (b['reps_performed'] as num? ?? 0);
            return volumeA > volumeB ? a : b;
          });

          // Calculate average RPE if available
          final rpeValues = exerciseSets
              .map((s) => s['actual_rpe'] as num?)
              .where((rpe) => rpe != null)
              .toList();
          final avgRPE = rpeValues.isNotEmpty
              ? rpeValues.reduce((a, b) => a! + b!)! / rpeValues.length
              : null;

          return {
            'date': _formatDateRelative(session['date']),
            'weight': bestSet['load_used'] as double? ?? 0.0,
            'reps': bestSet['reps_performed'] as int? ?? 0,
            'rpe': avgRPE?.toDouble(),
            'sessionId': sessionId,
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting previous exercise session: $e');
      return null;
    }
  }

  /// Format date relative to now (e.g., "2 days ago")
  String _formatDateRelative(String? dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      if (difference.inDays < 30)
        return '${(difference.inDays / 7).floor()} weeks ago';
      return '${(difference.inDays / 30).floor()} months ago';
    } catch (e) {
      return dateStr;
    }
  }
}
