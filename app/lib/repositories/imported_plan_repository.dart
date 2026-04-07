import 'dart:developer' as developer;
import 'dart:convert';
import '../models/workout_protocol.dart';
import '../services/supabase_database_service.dart';

/// Imported Plan model
class ImportedPlan {
  final String? id;
  final String userId;
  final String planName;
  final String? description;
  final WorkoutProtocol protocol;
  final String? sportFocus;
  final bool isActive;
  final bool autopilotEnabled;
  final String source;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ImportedPlan({
    this.id,
    required this.userId,
    required this.planName,
    this.description,
    required this.protocol,
    this.sportFocus,
    this.isActive = false,
    this.autopilotEnabled = false,
    this.source = 'manual',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'plan_name': planName,
      'description': description,
      'protocol_json': jsonEncode(protocol.toMap()),
      'sport_focus': sportFocus,
      'is_active': isActive,
      'autopilot_enabled': autopilotEnabled,
      'source': source,
    };
  }

  factory ImportedPlan.fromMap(Map<String, dynamic> map) {
    return ImportedPlan(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      planName: map['plan_name'] ?? '',
      description: map['description'],
      protocol: WorkoutProtocol.fromMap(
        jsonDecode(map['protocol_json'] ?? '{}'),
      ),
      sportFocus: map['sport_focus'],
      isActive: map['is_active'] ?? false,
      autopilotEnabled: map['autopilot_enabled'] ?? false,
      source: map['source'] ?? 'manual',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }
}

/// Repository for Imported Plans using Supabase
class ImportedPlanRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save an imported plan
  Future<bool> savePlan(ImportedPlan plan) async {
    try {
      await _database.saveImportedPlan(plan.toMap());
      developer.log(
        'Imported plan saved: ${plan.planName}',
        name: 'ImportedPlanRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error saving imported plan: $e',
        name: 'ImportedPlanRepository',
      );
      return false;
    }
  }

  /// Get all plans for user
  Future<List<ImportedPlan>> getUserPlans(String userId) async {
    try {
      final data = await _database.getImportedPlansForUser(userId);
      return data.map((m) => ImportedPlan.fromMap(m)).toList();
    } catch (e) {
      developer.log(
        'Error getting imported plans: $e',
        name: 'ImportedPlanRepository',
      );
      return [];
    }
  }

  /// Get active plan
  Future<ImportedPlan?> getActivePlan(String userId) async {
    try {
      final plans = await getUserPlans(userId);
      for (final plan in plans) {
        if (plan.isActive) return plan;
      }
      return plans.isNotEmpty ? plans.first : null;
    } catch (e) {
      developer.log(
        'Error getting active plan: $e',
        name: 'ImportedPlanRepository',
      );
      return null;
    }
  }

  /// Set active plan
  Future<bool> setActivePlan(String userId, String planId) async {
    try {
      // First, deactivate all plans
      await _database.deactivateAllImportedPlans(userId);
      // Then activate the selected one
      await _database.activateImportedPlan(planId);
      developer.log('Active plan set: $planId', name: 'ImportedPlanRepository');
      return true;
    } catch (e) {
      developer.log(
        'Error setting active plan: $e',
        name: 'ImportedPlanRepository',
      );
      return false;
    }
  }

  /// Update plan autopilot setting
  Future<bool> updateAutopilot(String planId, bool enabled) async {
    try {
      await _database.updateImportedPlanAutopilot(planId, enabled);
      developer.log(
        'Autopilot updated: $planId = $enabled',
        name: 'ImportedPlanRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error updating autopilot: $e',
        name: 'ImportedPlanRepository',
      );
      return false;
    }
  }

  /// Delete a plan
  Future<bool> deletePlan(String planId) async {
    try {
      await _database.deleteImportedPlan(planId);
      developer.log(
        'Imported plan deleted: $planId',
        name: 'ImportedPlanRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error deleting imported plan: $e',
        name: 'ImportedPlanRepository',
      );
      return false;
    }
  }
}
