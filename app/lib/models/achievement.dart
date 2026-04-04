import 'dart:developer' as developer;
import '../services/supabase_database_service.dart';

/// Achievement Model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final AchievementCategory category;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int tier; // 1=Bronze, 2=Silver, 3=Gold

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.tier = 1,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
  int get progressPercent => (progress * 100).round();
  bool get isNearUnlock => !isUnlocked && progress >= 0.8;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'category': category.name,
      'target_value': targetValue,
      'current_value': currentValue,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'tier': tier,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      iconName: map['icon_name'] ?? 'star',
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => AchievementCategory.volume,
      ),
      targetValue: map['target_value'] ?? 1,
      currentValue: map['current_value'] ?? 0,
      isUnlocked: map['is_unlocked'] ?? false,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'])
          : null,
      tier: map['tier'] ?? 1,
    );
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    AchievementCategory? category,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? tier,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      tier: tier ?? this.tier,
    );
  }
}

enum AchievementCategory { volume, consistency, strength, stoic, special }

/// Achievement Repository
class AchievementRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Get all available achievements (global list)
  Future<List<Achievement>> getAllAchievements() async {
    try {
      // Return default achievements for now
      return _getDefaultAchievements();
    } catch (e) {
      developer.log(
        'Error getting achievements: $e',
        name: 'AchievementRepository',
      );
      return _getDefaultAchievements();
    }
  }

  /// Get user's unlocked achievements
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      // Fetch from user profile or separate achievements table
      return [];
    } catch (e) {
      developer.log(
        'Error getting user achievements: $e',
        name: 'AchievementRepository',
      );
      return [];
    }
  }

  /// Get user's achievement progress
  Future<Map<String, Achievement>> getUserAchievementProgress(
    String userId,
  ) async {
    try {
      // Fetch achievement progress from Supabase
      // For now, return empty map
      return {};
    } catch (e) {
      developer.log(
        'Error getting achievement progress: $e',
        name: 'AchievementRepository',
      );
      return {};
    }
  }

  /// Update achievement progress
  Future<bool> updateProgress(
    String userId,
    String achievementId,
    int progress,
  ) async {
    try {
      // Update achievement progress in Supabase
      // For now, just log the update
      developer.log(
        'Updating achievement progress: $achievementId = $progress',
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

  /// Award achievement to user (called by cloud function usually)
  Future<bool> awardAchievement(String userId, Achievement achievement) async {
    try {
      final now = DateTime.now();
      final awarded = achievement.copyWith(
        isUnlocked: true,
        unlockedAt: now,
        currentValue: achievement.targetValue,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('unlocked_achievements')
          .doc(achievement.id)
          .set(awarded.toMap());

      developer.log(
        'Achievement awarded: ${achievement.id}',
        name: 'AchievementRepository',
      );
      return true;
    } catch (e) {
      developer.log(
        'Error awarding achievement: $e',
        name: 'AchievementRepository',
      );
      return false;
    }
  }

  /// Stream of user's achievement progress for real-time updates
  Stream<Map<String, Achievement>> userAchievementProgressStream(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievement_progress')
        .snapshots()
        .map((snapshot) {
          final progress = <String, Achievement>{};
          for (final doc in snapshot.docs) {
            progress[doc.id] = Achievement.fromMap(doc.data());
          }
          return progress;
        });
  }

  /// Check and award achievements based on stats (client-side check)
  Future<List<Achievement>> checkAndAwardAchievements(
    String userId, {
    required int totalWorkouts,
    required int currentStreak,
    required int longestStreak,
    required double totalVolume,
  }) async {
    final newlyUnlocked = <Achievement>[];

    // Check volume achievements
    final volumeAchievements = _getVolumeAchievements();
    for (final achievement in volumeAchievements) {
      int progress = 0;
      switch (achievement.id) {
        case 'first_blood':
          progress = totalWorkouts >= 1 ? 1 : 0;
          break;
        case 'centurion':
          progress = totalWorkouts;
          break;
        case 'marathoner':
          progress = (totalVolume / 60).floor(); // hours
          break;
        case 'titan':
          progress = totalWorkouts;
          break;
      }

      if (progress >= achievement.targetValue && !achievement.isUnlocked) {
        await awardAchievement(userId, achievement);
        newlyUnlocked.add(achievement);
      } else {
        await updateProgress(userId, achievement.id, progress);
      }
    }

    // Check streak achievements
    final streakAchievements = _getStreakAchievements();
    for (final achievement in streakAchievements) {
      int progress = 0;
      switch (achievement.id) {
        case 'the_streak':
          progress = currentStreak;
          break;
        case 'iron_will':
          progress = longestStreak;
          break;
        case 'legend':
          progress = longestStreak;
          break;
      }

      if (progress >= achievement.targetValue && !achievement.isUnlocked) {
        await awardAchievement(userId, achievement);
        newlyUnlocked.add(achievement);
      } else {
        await updateProgress(userId, achievement.id, progress);
      }
    }

    return newlyUnlocked;
  }

  /// Default achievements list
  List<Achievement> _getDefaultAchievements() {
    return [
      ..._getVolumeAchievements(),
      ..._getStreakAchievements(),
      ..._getStrengthAchievements(),
      ..._getStoicAchievements(),
    ];
  }

  List<Achievement> _getVolumeAchievements() {
    return [
      Achievement(
        id: 'first_blood',
        title: 'First Blood',
        description: 'Complete your first workout',
        iconName: 'sports_martial arts',
        category: AchievementCategory.volume,
        targetValue: 1,
        tier: 1,
      ),
      Achievement(
        id: 'centurion',
        title: 'Centurion',
        description: 'Complete 100 workouts',
        iconName: 'shield',
        category: AchievementCategory.volume,
        targetValue: 100,
        tier: 2,
      ),
      Achievement(
        id: 'marathoner',
        title: 'Marathoner',
        description: 'Train for 26.2 hours total',
        iconName: 'timer',
        category: AchievementCategory.volume,
        targetValue: 1572, // minutes
        tier: 2,
      ),
      Achievement(
        id: 'titan',
        title: 'Titan',
        description: 'Complete 1000 workouts',
        iconName: 'emoji_events',
        category: AchievementCategory.volume,
        targetValue: 1000,
        tier: 3,
      ),
    ];
  }

  List<Achievement> _getStreakAchievements() {
    return [
      Achievement(
        id: 'the_streak',
        title: 'The Streak',
        description: 'Maintain a 7-day workout streak',
        iconName: 'local_fire_department',
        category: AchievementCategory.consistency,
        targetValue: 7,
        tier: 1,
      ),
      Achievement(
        id: 'iron_will',
        title: 'Iron Will',
        description: 'Maintain a 30-day workout streak',
        iconName: 'fitness_center',
        category: AchievementCategory.consistency,
        targetValue: 30,
        tier: 2,
      ),
      Achievement(
        id: 'legend',
        title: 'Legend',
        description: 'Maintain a 100-day workout streak',
        iconName: 'star',
        category: AchievementCategory.consistency,
        targetValue: 100,
        tier: 3,
      ),
    ];
  }

  List<Achievement> _getStrengthAchievements() {
    return [
      Achievement(
        id: 'heavy_lifter',
        title: 'Heavy Lifter',
        description: 'Lift 10,000 lbs total volume',
        iconName: 'weight',
        category: AchievementCategory.strength,
        targetValue: 10000,
        tier: 2,
      ),
      Achievement(
        id: 'beast_mode',
        title: 'Beast Mode',
        description: 'Complete 10 RPE 10 sets in one week',
        iconName: 'bolt',
        category: AchievementCategory.strength,
        targetValue: 10,
        tier: 2,
      ),
      Achievement(
        id: 'progressive_overload',
        title: 'Progressive Overload',
        description: 'Increase weight for 4 weeks straight',
        iconName: 'trending_up',
        category: AchievementCategory.strength,
        targetValue: 4,
        tier: 2,
      ),
    ];
  }

  List<Achievement> _getStoicAchievements() {
    return [
      Achievement(
        id: 'student_of_seneca',
        title: 'Student of Seneca',
        description: 'Log 10 stoic reflections',
        iconName: 'psychology',
        category: AchievementCategory.stoic,
        targetValue: 10,
        tier: 1,
      ),
      Achievement(
        id: 'discipline',
        title: 'Discipline',
        description: 'Complete 20 scheduled workouts without skipping',
        iconName: 'check_circle',
        category: AchievementCategory.stoic,
        targetValue: 20,
        tier: 2,
      ),
      Achievement(
        id: 'memento_mori',
        title: 'Memento Mori',
        description: 'Complete a workout while traveling',
        iconName: 'flight',
        category: AchievementCategory.stoic,
        targetValue: 1,
        tier: 1,
      ),
    ];
  }
}
