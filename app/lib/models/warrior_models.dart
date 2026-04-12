import '../warrior_constants.dart';

/// Warrior Profile - Core user progression data
class WarriorProfile {
  final String userId;
  final int rankLevel;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  final DateTime? lastWorkoutDate;
  final DateTime? rankAchievedDate;
  final Map<String, SkillProgress> skillProgress;
  final List<String> unlockedAchievements;
  final List<String> unlockedTitles;
  final String? currentTitle;
  final DateTime createdAt;
  final DateTime updatedAt;

  WarriorProfile({
    required this.userId,
    this.rankLevel = 1,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWorkouts = 0,
    this.lastWorkoutDate,
    this.rankAchievedDate,
    Map<String, SkillProgress>? skillProgress,
    List<String>? unlockedAchievements,
    List<String>? unlockedTitles,
    this.currentTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : skillProgress = skillProgress ?? {},
       unlockedAchievements = unlockedAchievements ?? [],
       unlockedTitles = unlockedTitles ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  WarriorRank get rank => WarriorConstants.getRank(rankLevel);
  WarriorRank? get nextRank => WarriorConstants.getNextRank(rankLevel);

  double get rankProgress {
    return WarriorConstants.rankProgress(rankLevel, totalXp);
  }

  int get xpToNextRank {
    final next = nextRank;
    if (next == null) return 0;
    return next.requiredXp - totalXp;
  }

  bool get canRankUp {
    final next = nextRank;
    if (next == null) return false;
    return totalXp >= next.requiredXp;
  }

  SkillProgress getSkillProgress(String skillId) {
    return skillProgress[skillId] ??
        SkillProgress(skillId: skillId, level: 0, xp: 0);
  }

  int getSkillLevel(String skillId) {
    return getSkillProgress(skillId).level;
  }

  WarriorProfile copyWith({
    String? userId,
    int? rankLevel,
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    int? totalWorkouts,
    DateTime? lastWorkoutDate,
    DateTime? rankAchievedDate,
    Map<String, SkillProgress>? skillProgress,
    List<String>? unlockedAchievements,
    List<String>? unlockedTitles,
    String? currentTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WarriorProfile(
      userId: userId ?? this.userId,
      rankLevel: rankLevel ?? this.rankLevel,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      rankAchievedDate: rankAchievedDate ?? this.rankAchievedDate,
      skillProgress: skillProgress ?? this.skillProgress,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      unlockedTitles: unlockedTitles ?? this.unlockedTitles,
      currentTitle: currentTitle ?? this.currentTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'rank_level': rankLevel,
      'total_xp': totalXp,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_workouts': totalWorkouts,
      'last_workout_date': lastWorkoutDate?.toIso8601String(),
      'rank_achieved_date': rankAchievedDate?.toIso8601String(),
      'skill_progress': skillProgress.map((k, v) => MapEntry(k, v.toJson())),
      'unlocked_achievements': unlockedAchievements,
      'unlocked_titles': unlockedTitles,
      'current_title': currentTitle,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WarriorProfile.fromJson(Map<String, dynamic> json) {
    return WarriorProfile(
      userId: json['user_id'] as String,
      rankLevel: json['rank_level'] as int? ?? 1,
      totalXp: json['total_xp'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      totalWorkouts: json['total_workouts'] as int? ?? 0,
      lastWorkoutDate: json['last_workout_date'] != null
          ? DateTime.parse(json['last_workout_date'] as String)
          : null,
      rankAchievedDate: json['rank_achieved_date'] != null
          ? DateTime.parse(json['rank_achieved_date'] as String)
          : null,
      skillProgress:
          (json['skill_progress'] as Map<String, dynamic>?)?.map(
            (k, v) =>
                MapEntry(k, SkillProgress.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
      unlockedAchievements:
          (json['unlocked_achievements'] as List<dynamic>?)?.cast<String>() ??
          [],
      unlockedTitles:
          (json['unlocked_titles'] as List<dynamic>?)?.cast<String>() ?? [],
      currentTitle: json['current_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Skill Progress - Individual skill tree advancement
class SkillProgress {
  final String skillId;
  final int level;
  final int xp;
  final int workoutsCompleted;
  final DateTime? lastWorkoutDate;

  const SkillProgress({
    required this.skillId,
    this.level = 0,
    this.xp = 0,
    this.workoutsCompleted = 0,
    this.lastWorkoutDate,
  });

  static const int xpPerLevel = 1000;

  int get xpToNextLevel {
    return ((level + 1) * xpPerLevel) - xp;
  }

  double get progressPercent {
    final currentLevelBase = level * xpPerLevel;
    final xpInLevel = xp - currentLevelBase;
    return (xpInLevel / xpPerLevel).clamp(0.0, 1.0);
  }

  SkillProgress copyWith({
    String? skillId,
    int? level,
    int? xp,
    int? workoutsCompleted,
    DateTime? lastWorkoutDate,
  }) {
    return SkillProgress(
      skillId: skillId ?? this.skillId,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill_id': skillId,
      'level': level,
      'xp': xp,
      'workouts_completed': workoutsCompleted,
      'last_workout_date': lastWorkoutDate?.toIso8601String(),
    };
  }

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    return SkillProgress(
      skillId: json['skill_id'] as String,
      level: json['level'] as int? ?? 0,
      xp: json['xp'] as int? ?? 0,
      workoutsCompleted: json['workouts_completed'] as int? ?? 0,
      lastWorkoutDate: json['last_workout_date'] != null
          ? DateTime.parse(json['last_workout_date'] as String)
          : null,
    );
  }
}

/// Trial State - Active workout as combat engagement
class TrialState {
  final String trialId;
  final String trialName;
  final TrialPhase phase;
  final DateTime startTime;
  final DateTime? endTime;
  final int readinessScore;
  final int targetDuration;
  final int completedExercises;
  final int totalExercises;
  final int xpEarned;
  final bool isCompleted;
  final String? outcome; // 'victory', 'retreat', 'defeat'

  const TrialState({
    required this.trialId,
    required this.trialName,
    this.phase = TrialPhase.preparation,
    required this.startTime,
    this.endTime,
    this.readinessScore = 70,
    this.targetDuration = 45,
    this.completedExercises = 0,
    this.totalExercises = 0,
    this.xpEarned = 0,
    this.isCompleted = false,
    this.outcome,
  });

  Duration get elapsedTime {
    return DateTime.now().difference(startTime);
  }

  Duration? get totalDuration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  double get completionPercent {
    if (totalExercises == 0) return 0.0;
    return (completedExercises / totalExercises).clamp(0.0, 1.0);
  }

  TrialState copyWith({
    String? trialId,
    String? trialName,
    TrialPhase? phase,
    DateTime? startTime,
    DateTime? endTime,
    int? readinessScore,
    int? targetDuration,
    int? completedExercises,
    int? totalExercises,
    int? xpEarned,
    bool? isCompleted,
    String? outcome,
  }) {
    return TrialState(
      trialId: trialId ?? this.trialId,
      trialName: trialName ?? this.trialName,
      phase: phase ?? this.phase,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      readinessScore: readinessScore ?? this.readinessScore,
      targetDuration: targetDuration ?? this.targetDuration,
      completedExercises: completedExercises ?? this.completedExercises,
      totalExercises: totalExercises ?? this.totalExercises,
      xpEarned: xpEarned ?? this.xpEarned,
      isCompleted: isCompleted ?? this.isCompleted,
      outcome: outcome ?? this.outcome,
    );
  }
}

enum TrialPhase {
  preparation, // Pre-battle formation
  warmup, // Equipment check, preparation
  combat, // Active workout
  cooldown, // Recovery
  reflection, // Post-combat
}

/// Forge Progress - Overall progression summary
class ForgeProgress {
  final int totalBattles;
  final int victories;
  final int defeats;
  final int retreats;
  final Duration totalTimeInCombat;
  final int totalReps;
  final int totalSets;
  final double totalVolume;
  final Map<String, int> battlesBySkill;
  final List<String> recentAchievements;
  final DateTime lastUpdated;

  ForgeProgress({
    this.totalBattles = 0,
    this.victories = 0,
    this.defeats = 0,
    this.retreats = 0,
    this.totalTimeInCombat = Duration.zero,
    this.totalReps = 0,
    this.totalSets = 0,
    this.totalVolume = 0.0,
    Map<String, int>? battlesBySkill,
    List<String>? recentAchievements,
    DateTime? lastUpdated,
  }) : battlesBySkill = battlesBySkill ?? const {},
       recentAchievements = recentAchievements ?? const [],
       lastUpdated = lastUpdated ?? DateTime.now();

  double get winRate {
    if (totalBattles == 0) return 0.0;
    return (victories / totalBattles) * 100;
  }

  int get skillCount => battlesBySkill.length;

  String get dominantSkill {
    if (battlesBySkill.isEmpty) return 'None';
    return battlesBySkill.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  ForgeProgress copyWith({
    int? totalBattles,
    int? victories,
    int? defeats,
    int? retreats,
    Duration? totalTimeInCombat,
    int? totalReps,
    int? totalSets,
    double? totalVolume,
    Map<String, int>? battlesBySkill,
    List<String>? recentAchievements,
    DateTime? lastUpdated,
  }) {
    return ForgeProgress(
      totalBattles: totalBattles ?? this.totalBattles,
      victories: victories ?? this.victories,
      defeats: defeats ?? this.defeats,
      retreats: retreats ?? this.retreats,
      totalTimeInCombat: totalTimeInCombat ?? this.totalTimeInCombat,
      totalReps: totalReps ?? this.totalReps,
      totalSets: totalSets ?? this.totalSets,
      totalVolume: totalVolume ?? this.totalVolume,
      battlesBySkill: battlesBySkill ?? this.battlesBySkill,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_battles': totalBattles,
      'victories': victories,
      'defeats': defeats,
      'retreats': retreats,
      'total_time_in_combat': totalTimeInCombat.inSeconds,
      'total_reps': totalReps,
      'total_sets': totalSets,
      'total_volume': totalVolume,
      'battles_by_skill': battlesBySkill,
      'recent_achievements': recentAchievements,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory ForgeProgress.fromJson(Map<String, dynamic> json) {
    return ForgeProgress(
      totalBattles: json['total_battles'] as int? ?? 0,
      victories: json['victories'] as int? ?? 0,
      defeats: json['defeats'] as int? ?? 0,
      retreats: json['retreats'] as int? ?? 0,
      totalTimeInCombat: Duration(
        seconds: json['total_time_in_combat'] as int? ?? 0,
      ),
      totalReps: json['total_reps'] as int? ?? 0,
      totalSets: json['total_sets'] as int? ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
      battlesBySkill:
          (json['battles_by_skill'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      recentAchievements:
          (json['recent_achievements'] as List<dynamic>?)?.cast<String>() ?? [],
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }
}

/// Battle Chronicle Entry - Record of completed workout
class BattleChronicleEntry {
  final String id;
  final String trialName;
  final DateTime date;
  final String outcome;
  final int xpEarned;
  final int duration;
  final int exercisesCompleted;
  final String skillFocus;
  final String? notes;
  final List<String> achievements;
  final int? prCount;

  const BattleChronicleEntry({
    required this.id,
    required this.trialName,
    required this.date,
    required this.outcome,
    required this.xpEarned,
    required this.duration,
    required this.exercisesCompleted,
    required this.skillFocus,
    this.notes,
    this.achievements = const [],
    this.prCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trial_name': trialName,
      'date': date.toIso8601String(),
      'outcome': outcome,
      'xp_earned': xpEarned,
      'duration': duration,
      'exercises_completed': exercisesCompleted,
      'skill_focus': skillFocus,
      'notes': notes,
      'achievements': achievements,
      'pr_count': prCount,
    };
  }

  factory BattleChronicleEntry.fromJson(Map<String, dynamic> json) {
    return BattleChronicleEntry(
      id: json['id'] as String,
      trialName: json['trial_name'] as String,
      date: DateTime.parse(json['date'] as String),
      outcome: json['outcome'] as String,
      xpEarned: json['xp_earned'] as int,
      duration: json['duration'] as int,
      exercisesCompleted: json['exercises_completed'] as int,
      skillFocus: json['skill_focus'] as String,
      notes: json['notes'] as String?,
      achievements:
          (json['achievements'] as List<dynamic>?)?.cast<String>() ?? [],
      prCount: json['pr_count'] as int?,
    );
  }
}

/// Daily Oath - User's daily commitment
class DailyOath {
  final String id;
  final String oath;
  final DateTime date;
  final bool isCompleted;
  final DateTime createdAt;

  const DailyOath({
    required this.id,
    required this.oath,
    required this.date,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oath': oath,
      'date': date.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyOath.fromJson(Map<String, dynamic> json) {
    return DailyOath(
      id: json['id'] as String,
      oath: json['oath'] as String,
      date: DateTime.parse(json['date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// User Achievement Progress
class UserAchievement {
  final String achievementId;
  final DateTime unlockedAt;
  final bool isNew;

  const UserAchievement({
    required this.achievementId,
    required this.unlockedAt,
    this.isNew = false,
  });

  Achievement get definition {
    return WarriorConstants.achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => WarriorConstants.achievements.first,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
      'is_new': isNew,
    };
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      isNew: json['is_new'] as bool? ?? false,
    );
  }
}
