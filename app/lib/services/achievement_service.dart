import 'dart:developer' as developer;
import '../models/achievement.dart';
import '../services/firestore_service.dart';

/// Achievement Service
/// Handles checking, awarding, and tracking achievements
class AchievementService {
  final AchievementRepository _repository = AchievementRepository();
  final FirestoreService _firestoreService = FirestoreService();

  /// Check achievements after a workout completion
  Future<List<Achievement>> checkWorkoutAchievements(
    String userId,
    int totalWorkouts,
    int currentStreak,
    int totalWorkoutMinutes,
  ) async {
    final newlyUnlocked = <Achievement>[];

    try {
      // Check volume achievements
      final volumeChecks = [
        _checkFirstBlood(userId, totalWorkouts),
        _checkCenturion(userId, totalWorkouts),
        _checkTitan(userId, totalWorkouts),
        _checkMarathoner(userId, totalWorkoutMinutes),
      ];

      final results = await Future.wait(volumeChecks);
      newlyUnlocked.addAll(results.where((a) => a != null).cast<Achievement>());

      // Check streak achievements
      final streakChecks = [
        _checkTheStreak(userId, currentStreak),
        _checkIronWill(userId, currentStreak),
        _checkLegend(userId, currentStreak),
      ];

      final streakResults = await Future.wait(streakChecks);
      newlyUnlocked.addAll(
        streakResults.where((a) => a != null).cast<Achievement>(),
      );

      if (newlyUnlocked.isNotEmpty) {
        developer.log(
          'New achievements unlocked: ${newlyUnlocked.map((a) => a.id).join(', ')}',
          name: 'AchievementService',
        );
      }

      return newlyUnlocked;
    } catch (e) {
      developer.log(
        'Error checking workout achievements: $e',
        name: 'AchievementService',
      );
      return [];
    }
  }

  /// Check achievements based on strength milestones
  Future<List<Achievement>> checkStrengthAchievements(
    String userId, {
    required double oneRepMax,
    required String exerciseName,
    required int rpe10CountThisWeek,
  }) async {
    final newlyUnlocked = <Achievement>[];

    // Check beast mode (10 RPE 10 sets in a week)
    if (rpe10CountThisWeek >= 10) {
      final beastMode = await _awardIfNotUnlocked(
        userId,
        Achievement(
          id: 'beast_mode',
          title: 'Beast Mode',
          description: 'Complete 10 RPE 10 sets in one week',
          iconName: 'bolt',
          category: AchievementCategory.strength,
          targetValue: 10,
          tier: 2,
        ),
      );
      if (beastMode != null) newlyUnlocked.add(beastMode);
    }

    return newlyUnlocked;
  }

  /// Check progressive overload achievement
  Future<Achievement?> checkProgressiveOverload(
    String userId,
    String exerciseId,
    List<double> weightHistory,
  ) async {
    if (weightHistory.length < 4) return null;

    // Check if weight increased for 4 consecutive weeks
    bool progressiveOverload = true;
    for (int i = 1; i < 4; i++) {
      if (weightHistory[i] <= weightHistory[i - 1]) {
        progressiveOverload = false;
        break;
      }
    }

    if (progressiveOverload) {
      return _awardIfNotUnlocked(
        userId,
        Achievement(
          id: 'progressive_overload_$exerciseId',
          title: 'Progressive Overload',
          description: 'Increase weight for 4 weeks straight on $exerciseId',
          iconName: 'trending_up',
          category: AchievementCategory.strength,
          targetValue: 4,
          tier: 2,
        ),
      );
    }

    return null;
  }

  // ==================== INDIVIDUAL ACHIEVEMENT CHECKS ====================

  Future<Achievement?> _checkFirstBlood(
    String userId,
    int totalWorkouts,
  ) async {
    if (totalWorkouts < 1) return null;

    return _awardIfNotUnlocked(
      userId,
      Achievement(
        id: 'first_blood',
        title: 'First Blood',
        description: 'Complete your first workout',
        iconName: 'sports_martial_arts',
        category: AchievementCategory.volume,
        targetValue: 1,
        tier: 1,
      ),
    );
  }

  Future<Achievement?> _checkCenturion(String userId, int totalWorkouts) async {
    if (totalWorkouts < 100) return null;

    return _awardIfNotUnlocked(
      userId,
      Achievement(
        id: 'centurion',
        title: 'Centurion',
        description: 'Complete 100 workouts',
        iconName: 'shield',
        category: AchievementCategory.volume,
        targetValue: 100,
        tier: 2,
      ),
    );
  }

  Future<Achievement?> _checkTitan(String userId, int totalWorkouts) async {
    if (totalWorkouts < 1000) return null;

    return _awardIfNotUnlocked(
      userId,
      Achievement(
        id: 'titan',
        title: 'Titan',
        description: 'Complete 1000 workouts',
        iconName: 'emoji_events',
        category: AchievementCategory.volume,
        targetValue: 1000,
        tier: 3,
      ),
    );
  }

  Future<Achievement?> _checkMarathoner(String userId, int totalMinutes) async {
    if (totalMinutes < 1572) return null; // 26.2 hours

    return _awardIfNotUnlocked(
      userId,
      Achievement(
        id: 'marathoner',
        title: 'Marathoner',
        description: 'Train for 26.2 hours total',
        iconName: 'timer',
        category: AchievementCategory.volume,
        targetValue: 1572,
        tier: 2,
      ),
    );
  }

  Future<Achievement?> _checkTheStreak(String userId, int currentStreak) async {
    if (currentStreak < 7) return null;

    return _awardIfNotUnlocked(
      userId,
      Achievement(
        id: 'the_streak',
        title: 'The Streak',
        description: 'Maintain a 7-day workout streak',
        iconName: 'local_fire_department',
        category: AchievementCategory.consistency,
        targetValue: 7,
        tier: 1,
      ),
    );
  }

  Future<Achievement?> _checkIronWill(String userId, int longestStreak) async {
    if (longestStreak < 30) return null;

    return _awardIfNotUnlocked(
      userId,
      Achievement(
        id: 'iron_will',
        title: 'Iron Will',
        description: 'Maintain a 30-day workout streak',
        iconName: 'fitness_center',
        category: AchievementCategory.consistency,
        targetValue: 30,
        tier: 2,
      ),
    );
  }

  Future<Achievement?> _checkLegend(String userId, int longestStreak) async {
    if (longestStreak < 100) return null;

    return _awardIfNotUnlocked(
      userId,
      Achievement(
        id: 'legend',
        title: 'Legend',
        description: 'Maintain a 100-day workout streak',
        iconName: 'star',
        category: AchievementCategory.consistency,
        targetValue: 100,
        tier: 3,
      ),
    );
  }

  /// Award achievement if not already unlocked
  Future<Achievement?> _awardIfNotUnlocked(
    String userId,
    Achievement achievement,
  ) async {
    // Check if already unlocked
    final existing = await _repository.getUserAchievements(userId);
    final alreadyUnlocked = existing.any(
      (a) => a.id == achievement.id && a.isUnlocked,
    );

    if (alreadyUnlocked) return null;

    // Award the achievement
    final success = await _repository.awardAchievement(userId, achievement);
    if (success) {
      return achievement;
    }
    return null;
  }

  /// Get all achievements with user progress
  Future<List<Achievement>> getAllAchievementsWithProgress(
    String userId,
  ) async {
    final allAchievements = await _repository.getAllAchievements();
    final userProgress = await _repository.getUserAchievementProgress(userId);
    final unlocked = await _repository.getUserAchievements(userId);

    final merged = <Achievement>[];

    for (final achievement in allAchievements) {
      // Check if unlocked
      final unlockedAchievement = unlocked.firstWhere(
        (a) => a.id == achievement.id,
        orElse: () => achievement,
      );

      if (unlockedAchievement.isUnlocked) {
        merged.add(unlockedAchievement);
      } else {
        // Get progress
        final progress = userProgress[achievement.id];
        merged.add(
          achievement.copyWith(currentValue: progress?.currentValue ?? 0),
        );
      }
    }

    return merged;
  }

  /// Calculate total achievement points
  int calculateAchievementPoints(List<Achievement> achievements) {
    return achievements.fold<int>(0, (sum, a) {
      if (!a.isUnlocked) return sum;
      // Bronze = 10, Silver = 25, Gold = 50
      final points = a.tier == 1
          ? 10
          : a.tier == 2
          ? 25
          : 50;
      return sum + points;
    });
  }
}
