import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/warrior_models.dart';
import '../warrior_constants.dart';

/// Warrior Progress Service - Manages XP, ranks, skill progression, and achievements
/// Uses SharedPreferences for local storage (consistent with existing app architecture)
class WarriorProgressService {
  static final WarriorProgressService _instance =
      WarriorProgressService._internal();
  factory WarriorProgressService() => _instance;
  WarriorProgressService._internal();

  SharedPreferences? _prefs;

  // Stream controllers for reactive updates
  final _profileController = StreamController<WarriorProfile?>.broadcast();
  final _xpController = StreamController<XPUpdateEvent>.broadcast();
  final _achievementController = StreamController<AchievementEvent>.broadcast();
  final _rankUpController = StreamController<WarriorRank>.broadcast();

  // State
  WarriorProfile? _currentProfile;
  bool _initialized = false;

  // Constants for storage keys
  static const String _profileKey = 'warrior_profile';
  static const String _forgeProgressKey = 'forge_progress';
  static const String _chroniclePrefix = 'chronicle_';
  static const String _oathPrefix = 'oath_';

  // Getters
  Stream<WarriorProfile?> get profileStream => _profileController.stream;
  Stream<XPUpdateEvent> get xpStream => _xpController.stream;
  Stream<AchievementEvent> get achievementStream =>
      _achievementController.stream;
  Stream<WarriorRank> get rankUpStream => _rankUpController.stream;
  WarriorProfile? get currentProfile => _currentProfile;
  bool get isInitialized => _initialized;

  /// Initialize the service and load local data
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCachedProfile();

      _initialized = true;
      developer.log(
        'WarriorProgressService initialized',
        name: 'WarriorProgress',
      );
    } catch (e) {
      developer.log(
        'Failed to initialize WarriorProgressService: $e',
        name: 'WarriorProgress',
      );
      rethrow;
    }
  }

  /// Load cached profile from local storage
  Future<void> _loadCachedProfile() async {
    try {
      final cached = _prefs?.getString(_profileKey);
      if (cached != null) {
        _currentProfile = WarriorProfile.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
        _profileController.add(_currentProfile);
      }
    } catch (e) {
      developer.log(
        'Error loading cached profile: $e',
        name: 'WarriorProgress',
      );
    }
  }

  /// Create or update warrior profile
  Future<WarriorProfile> createProfile(String userId) async {
    final profile = WarriorProfile(userId: userId);
    await _saveProfile(profile);
    return profile;
  }

  /// Save profile to local storage
  Future<void> _saveProfile(WarriorProfile profile) async {
    _currentProfile = profile;
    await _prefs?.setString(_profileKey, jsonEncode(profile.toJson()));
    _profileController.add(profile);
  }

  /// Award XP for various activities
  Future<XPUpdateEvent> awardXp({
    required String activity,
    required int baseAmount,
    String? skillId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentProfile == null) {
      throw StateError('No warrior profile loaded');
    }

    // Calculate final XP amount
    int finalAmount = baseAmount;
    List<String> bonuses = [];

    // Streak bonus (up to 2x)
    final streak = _currentProfile!.currentStreak;
    if (streak >= 100) {
      finalAmount = (finalAmount * 2).round();
      bonuses.add('Immortal Streak (2x)');
    } else if (streak >= 30) {
      finalAmount = (finalAmount * 1.5).round();
      bonuses.add('Iron Will (1.5x)');
    } else if (streak >= 7) {
      finalAmount = (finalAmount * 1.25).round();
      bonuses.add('Shield Wall (1.25x)');
    }

    // Rank-based scaling (higher ranks need more XP, but get bonuses for harder activities)
    if (_currentProfile!.rankLevel >= 5) {
      finalAmount += (baseAmount * 0.1).round();
      bonuses.add('Spartiate Bonus (+10%)');
    }

    // Update profile
    final oldRank = _currentProfile!.rank;
    var updatedProfile = _currentProfile!.copyWith(
      totalXp: _currentProfile!.totalXp + finalAmount,
      updatedAt: DateTime.now(),
    );

    // Check for rank up
    bool rankUp = false;
    WarriorRank? newRank;
    while (updatedProfile.canRankUp) {
      newRank = updatedProfile.nextRank;
      if (newRank != null) {
        updatedProfile = updatedProfile.copyWith(
          rankLevel: newRank.level,
          rankAchievedDate: DateTime.now(),
        );
        rankUp = true;

        // Award rank-up bonus XP
        updatedProfile = updatedProfile.copyWith(
          totalXp: updatedProfile.totalXp + WarriorConstants.xpRankUpBonus,
        );

        _rankUpController.add(newRank);
        developer.log(
          'RANK UP! ${oldRank.name} -> ${newRank.name}',
          name: 'WarriorProgress',
        );
      }
    }

    // Award skill XP if applicable
    if (skillId != null) {
      updatedProfile = await _addSkillXp(
        updatedProfile,
        skillId,
        finalAmount ~/ 2,
      );
    }

    await _saveProfile(updatedProfile);

    final event = XPUpdateEvent(
      amount: finalAmount,
      activity: activity,
      bonuses: bonuses,
      newTotal: updatedProfile.totalXp,
      rankUp: rankUp,
      newRank: newRank,
      metadata: metadata,
    );

    _xpController.add(event);
    return event;
  }

  /// Add XP to a specific skill tree
  Future<WarriorProfile> _addSkillXp(
    WarriorProfile profile,
    String skillId,
    int xp,
  ) async {
    final currentSkill = profile.getSkillProgress(skillId);
    final newSkillXp = currentSkill.xp + xp;

    // Calculate new level
    final newLevel = (newSkillXp / SkillProgress.xpPerLevel).floor();

    final updatedSkills = Map<String, SkillProgress>.from(
      profile.skillProgress,
    );
    updatedSkills[skillId] = SkillProgress(
      skillId: skillId,
      level: newLevel,
      xp: newSkillXp,
      workoutsCompleted: currentSkill.workoutsCompleted + 1,
      lastWorkoutDate: DateTime.now(),
    );

    // Check for skill level up
    if (newLevel > currentSkill.level) {
      developer.log(
        'SKILL LEVEL UP! $skillId -> Level $newLevel',
        name: 'WarriorProgress',
      );
      // Award bonus XP for skill level up
      await awardXp(
        activity: 'Skill Level Up: $skillId',
        baseAmount: WarriorConstants.xpSkillLevelUp,
      );
    }

    return profile.copyWith(skillProgress: updatedSkills);
  }

  /// Award XP for workout completion
  Future<XPUpdateEvent> awardWorkoutXp({
    required int duration,
    required int exercises,
    required String primarySkill,
    bool isPR = false,
    bool completedDespiteLowReadiness = false,
  }) async {
    int baseXp = WarriorConstants.xpWorkoutCompleted;

    // Duration bonus
    if (duration >= 60) baseXp += 25;
    if (duration >= 90) baseXp += 25;

    // Volume bonus
    if (exercises >= 6) baseXp += 15;
    if (exercises >= 10) baseXp += 15;

    // PR bonus
    if (isPR) baseXp += WarriorConstants.xpWorkoutPR;

    // Last stand bonus
    if (completedDespiteLowReadiness) baseXp += 50;

    return awardXp(
      activity: 'Trial Completed',
      baseAmount: baseXp,
      skillId: primarySkill,
      metadata: {
        'duration': duration,
        'exercises': exercises,
        'is_pr': isPR,
        'low_readiness_overcome': completedDespiteLowReadiness,
      },
    );
  }

  /// Update workout streak
  Future<void> updateStreak(bool workedOutToday) async {
    if (_currentProfile == null) return;

    final lastWorkout = _currentProfile!.lastWorkoutDate;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    int newStreak = _currentProfile!.currentStreak;
    int newLongestStreak = _currentProfile!.longestStreak;

    if (workedOutToday) {
      if (lastWorkout == null) {
        // First workout ever
        newStreak = 1;
      } else if (_isSameDay(lastWorkout, today)) {
        // Already worked out today, no change
        return;
      } else if (_isSameDay(lastWorkout, yesterday)) {
        // Continued streak
        newStreak++;
      } else {
        // Streak broken, start fresh
        newStreak = 1;
      }

      if (newStreak > newLongestStreak) {
        newLongestStreak = newStreak;
      }

      // Award streak bonuses
      if (newStreak == 7) {
        await awardXp(
          activity: '7-Day Streak',
          baseAmount: WarriorConstants.xpStreak7Day,
        );
      } else if (newStreak == 30) {
        await awardXp(
          activity: '30-Day Streak',
          baseAmount: WarriorConstants.xpStreak30Day,
        );
      } else if (newStreak == 100) {
        await awardXp(
          activity: '100-Day Streak',
          baseAmount: WarriorConstants.xpStreak100Day,
        );
      }

      final updated = _currentProfile!.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        lastWorkoutDate: today,
        totalWorkouts: _currentProfile!.totalWorkouts + 1,
        updatedAt: today,
      );

      await _saveProfile(updated);
    }
  }

  /// Check and unlock achievements
  Future<List<AchievementEvent>> checkAchievements() async {
    if (_currentProfile == null) return [];

    final unlocked = <AchievementEvent>[];
    final currentAchievements = _currentProfile!.unlockedAchievements;

    for (final achievement in WarriorConstants.achievements) {
      if (currentAchievements.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      // Check unlock conditions
      switch (achievement.id) {
        case 'first_blood':
          shouldUnlock = _currentProfile!.totalWorkouts >= 1;
          break;
        case 'shield_wall':
          shouldUnlock = _currentProfile!.currentStreak >= 7;
          break;
        case 'iron_will':
          shouldUnlock = _currentProfile!.currentStreak >= 30;
          break;
        case 'immortal':
          shouldUnlock = _currentProfile!.currentStreak >= 100;
          break;
        case 'never_surrender':
          shouldUnlock = _currentProfile!.totalWorkouts >= 100;
          break;
        case 'spartan_dawn':
          // Check via workout history
          shouldUnlock = await _checkSpartanDawn();
          break;
        // Add more achievement checks as needed
      }

      if (shouldUnlock) {
        await _unlockAchievement(achievement);
        final event = AchievementEvent(
          achievement: achievement,
          unlockedAt: DateTime.now(),
          isNew: true,
        );
        unlocked.add(event);
        _achievementController.add(event);

        // Award achievement XP
        await awardXp(
          activity: 'Achievement: ${achievement.name}',
          baseAmount: achievement.xpReward,
        );
      }
    }

    return unlocked;
  }

  Future<bool> _checkSpartanDawn() async {
    // Check chronicle for early morning workouts
    final chronicle = await getBattleChronicle();
    for (final entry in chronicle) {
      final hour = entry.date.hour;
      if (hour < 5) return true;
    }
    return false;
  }

  Future<void> _unlockAchievement(Achievement achievement) async {
    final updated = _currentProfile!.copyWith(
      unlockedAchievements: [
        ..._currentProfile!.unlockedAchievements,
        achievement.id,
      ],
      updatedAt: DateTime.now(),
    );
    await _saveProfile(updated);
  }

  /// Add entry to battle chronicle
  Future<void> addToChronicle(BattleChronicleEntry entry) async {
    final key = '$_chroniclePrefix${entry.id}';
    await _prefs?.setString(key, jsonEncode(entry.toJson()));
  }

  /// Get battle chronicle (sorted by date desc)
  Future<List<BattleChronicleEntry>> getBattleChronicle({
    int limit = 50,
  }) async {
    final entries = <BattleChronicleEntry>[];

    if (_prefs == null) return entries;

    final keys = _prefs!.getKeys().where((k) => k.startsWith(_chroniclePrefix));
    for (final key in keys) {
      final data = _prefs!.getString(key);
      if (data != null) {
        try {
          entries.add(
            BattleChronicleEntry.fromJson(
              jsonDecode(data) as Map<String, dynamic>,
            ),
          );
        } catch (e) {
          developer.log(
            'Error parsing chronicle entry: $e',
            name: 'WarriorProgress',
          );
        }
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.take(limit).toList();
  }

  /// Get Forge Progress summary
  Future<ForgeProgress> getForgeProgress() async {
    final cached = _prefs?.getString(_forgeProgressKey);
    if (cached != null) {
      return ForgeProgress.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }
    return ForgeProgress();
  }

  /// Update Forge Progress
  Future<void> updateForgeProgress(ForgeProgress progress) async {
    await _prefs?.setString(_forgeProgressKey, jsonEncode(progress.toJson()));
  }

  /// Get or create today's oath
  Future<DailyOath?> getTodayOath() async {
    final today = DateTime.now();
    final key = _oathKey(today);

    final cached = _prefs?.getString(key);
    if (cached != null) {
      return DailyOath.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }
    return null;
  }

  /// Create today's oath
  Future<DailyOath> createOath(String oath) async {
    final today = DateTime.now();
    final dailyOath = DailyOath(
      id: 'oath_${today.millisecondsSinceEpoch}',
      oath: oath,
      date: today,
      createdAt: DateTime.now(),
    );

    await _prefs?.setString(_oathKey(today), jsonEncode(dailyOath.toJson()));
    return dailyOath;
  }

  /// Complete today's oath
  Future<void> completeOath() async {
    final today = DateTime.now();
    final key = _oathKey(today);

    final cached = _prefs?.getString(key);
    if (cached != null) {
      final oath = DailyOath.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
      final completed = DailyOath(
        id: oath.id,
        oath: oath.oath,
        date: oath.date,
        isCompleted: true,
        createdAt: oath.createdAt,
      );
      await _prefs?.setString(key, jsonEncode(completed.toJson()));
    }
  }

  String _oathKey(DateTime date) {
    return '${_oathPrefix}${date.year}_${date.month}_${date.day}';
  }

  /// Reset streak (for testing or correction)
  Future<void> resetStreak() async {
    if (_currentProfile == null) return;

    final updated = _currentProfile!.copyWith(
      currentStreak: 0,
      updatedAt: DateTime.now(),
    );
    await _saveProfile(updated);
  }

  /// Debug: Get full state
  Map<String, dynamic> getDebugState() {
    return {'initialized': _initialized, 'profile': _currentProfile?.toJson()};
  }

  /// Dispose
  void dispose() {
    _profileController.close();
    _xpController.close();
    _achievementController.close();
    _rankUpController.close();
  }

  // Helpers
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// XP Update Event
class XPUpdateEvent {
  final int amount;
  final String activity;
  final List<String> bonuses;
  final int newTotal;
  final bool rankUp;
  final WarriorRank? newRank;
  final Map<String, dynamic>? metadata;

  const XPUpdateEvent({
    required this.amount,
    required this.activity,
    this.bonuses = const [],
    required this.newTotal,
    this.rankUp = false,
    this.newRank,
    this.metadata,
  });

  @override
  String toString() {
    return 'XPUpdateEvent(amount: $amount, activity: $activity, rankUp: $rankUp)';
  }
}

/// Achievement Unlock Event
class AchievementEvent {
  final Achievement achievement;
  final DateTime unlockedAt;
  final bool isNew;

  const AchievementEvent({
    required this.achievement,
    required this.unlockedAt,
    this.isNew = false,
  });

  @override
  String toString() {
    return 'AchievementEvent(${achievement.name}, isNew: $isNew)';
  }
}
