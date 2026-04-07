import 'dart:developer' as developer;
import '../models/achievement.dart';
import '../services/supabase_database_service.dart';

/// Repository for Achievement data using Supabase
class AchievementRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Get all achievements for a user
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final data = await _database.getUserAchievements(userId);
      return data.map((m) => Achievement.fromMap(m)).toList();
    } catch (e) {
      developer.log(
        'Error getting user achievements: $e',
        name: 'AchievementRepository',
      );
      return [];
    }
  }

  /// Get unlocked achievements
  Future<List<Achievement>> getUnlockedAchievements(String userId) async {
    try {
      final data = await _database.getUnlockedAchievements(userId);
      return data.map((m) => Achievement.fromMap(m)).toList();
    } catch (e) {
      developer.log(
        'Error getting unlocked achievements: $e',
        name: 'AchievementRepository',
      );
      return [];
    }
  }

  /// Save or update an achievement
  Future<bool> saveAchievement(String userId, Achievement achievement) async {
    try {
      await _database.saveAchievement(userId, achievement.toMap());
      developer.log(
        'Achievement saved: ${achievement.id}',
        name: 'AchievementRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error saving achievement: $e',
        name: 'AchievementRepository',
      );
      return false;
    }
  }

  /// Update achievement progress
  Future<bool> updateAchievementProgress(
    String userId,
    String achievementId,
    int currentValue,
  ) async {
    try {
      await _database.updateAchievementProgress(
        userId,
        achievementId,
        currentValue,
      );
      developer.log(
        'Achievement progress updated: $achievementId',
        name: 'AchievementRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error updating achievement progress: $e',
        name: 'AchievementRepository',
      );
      return false;
    }
  }

  /// Unlock an achievement
  Future<bool> unlockAchievement(String userId, String achievementId) async {
    try {
      await _database.unlockAchievement(userId, achievementId);
      developer.log(
        'Achievement unlocked: $achievementId',
        name: 'AchievementRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error unlocking achievement: $e',
        name: 'AchievementRepository',
      );
      return false;
    }
  }

  /// Check if achievement exists for user
  Future<bool> achievementExists(String userId, String achievementId) async {
    try {
      return await _database.achievementExists(userId, achievementId);
    } catch (e) {
      developer.log(
        'Error checking achievement existence: $e',
        name: 'AchievementRepository',
      );
      return false;
    }
  }
}
