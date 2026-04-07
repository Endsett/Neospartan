import 'dart:developer' as developer;
import '../services/supabase_database_service.dart';
import '../services/dom_rl_engine_v2.dart';

/// Repository for Weekly Directive CRUD operations using Supabase
class WeeklyDirectiveRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save weekly directive
  Future<bool> saveWeeklyDirective(
    String userId,
    AdaptiveWeeklyPeriodizationDecision directive, {
    DateTime? weekStart,
  }) async {
    try {
      final effectiveWeekStart = weekStart ?? _getWeekStart();

      final data = {
        'week_starting': effectiveWeekStart.toIso8601String().split('T')[0],
        'directive': directive.directive.name,
        'volume_adjustment_percent': directive.volumeAdjustmentPercent,
        'intensity_adjustment_percent': directive.intensityAdjustmentPercent,
        'readiness_trend': directive.readinessTrend,
        'predicted_fatigue_score': directive.predictedFatigueScore,
        'summary': directive.summary,
        'reasons': directive.reasons,
        'applied_at': DateTime.now().toIso8601String(),
        // Expire at end of week (Sunday midnight)
        'expires_at': effectiveWeekStart
            .add(const Duration(days: 7))
            .toIso8601String(),
      };

      await _database.saveWeeklyDirective(data);
      developer.log(
        'Weekly directive saved successfully',
        name: 'WeeklyDirectiveRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error saving weekly directive: $e',
        name: 'WeeklyDirectiveRepository',
      );
      return false;
    }
  }

  /// Get weekly directive for current week
  Future<AdaptiveWeeklyPeriodizationDecision?>
  getCurrentWeeklyDirective() async {
    try {
      final data = await _database.getCurrentWeeklyDirective();

      if (data == null) return null;

      return _mapToDecision(data);
    } catch (e) {
      developer.log(
        'Error getting current weekly directive: $e',
        name: 'WeeklyDirectiveRepository',
      );
      return null;
    }
  }

  /// Get weekly directive for a specific week
  Future<AdaptiveWeeklyPeriodizationDecision?> getWeeklyDirectiveForWeek(
    DateTime weekStart,
  ) async {
    try {
      final data = await _database.getWeeklyDirective(weekStart);

      if (data == null) return null;

      return _mapToDecision(data);
    } catch (e) {
      developer.log(
        'Error getting weekly directive for week: $e',
        name: 'WeeklyDirectiveRepository',
      );
      return null;
    }
  }

  /// Get weekly directive history
  Future<List<AdaptiveWeeklyPeriodizationDecision>> getDirectiveHistory({
    int limit = 12,
  }) async {
    try {
      final data = await _database.getWeeklyDirectiveHistory(limit: limit);

      return data.map((item) => _mapToDecision(item)).toList();
    } catch (e) {
      developer.log(
        'Error getting directive history: $e',
        name: 'WeeklyDirectiveRepository',
      );
      return [];
    }
  }

  /// Check if there's an active directive for current week
  Future<bool> hasCurrentWeeklyDirective() async {
    final data = await _database.getCurrentWeeklyDirective();
    return data != null;
  }

  /// Get recent directives as raw data (for DOM-RL log)
  Future<List<Map<String, dynamic>>> getRecentDirectives(
    String userId, {
    int limit = 7,
  }) async {
    try {
      final data = await _database.getWeeklyDirectiveHistory(limit: limit);
      return data;
    } catch (e) {
      developer.log(
        'Error getting recent directives: $e',
        name: 'WeeklyDirectiveRepository',
      );
      return [];
    }
  }

  /// Helper: Get the start of current week (Monday)
  DateTime _getWeekStart() {
    final now = DateTime.now();
    // Weekday is 1-7 (Monday-Sunday), subtract to get to Monday
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  /// Helper: Map database row to AdaptiveWeeklyPeriodizationDecision
  AdaptiveWeeklyPeriodizationDecision _mapToDecision(
    Map<String, dynamic> data,
  ) {
    final directiveStr = data['directive'] as String;
    final directive = WeeklyDirective.values.firstWhere(
      (d) => d.name == directiveStr,
      orElse: () => WeeklyDirective.maintain,
    );

    final reasons =
        (data['reasons'] as List<dynamic>?)
            ?.map((r) => r.toString())
            .toList() ??
        [];

    return AdaptiveWeeklyPeriodizationDecision(
      directive: directive,
      volumeAdjustmentPercent: data['volume_adjustment_percent'] as int,
      intensityAdjustmentPercent: data['intensity_adjustment_percent'] as int,
      readinessTrend: (data['readiness_trend'] as num?)?.toDouble() ?? 0.0,
      predictedFatigueScore:
          (data['predicted_fatigue_score'] as num?)?.toDouble() ?? 50.0,
      summary: data['summary'] as String,
      reasons: reasons,
    );
  }
}
