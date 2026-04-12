import 'package:flutter/material.dart';

/// Warrior Forge Constants
/// Rank hierarchy, skill trees, achievements, and XP formulas
class WarriorConstants {
  WarriorConstants._();

  // === XP FORMULAS ===
  static int xpForRank(int rank) {
    if (rank <= 1) return 0;
    if (rank == 2) return 500;
    if (rank == 3) return 1500;
    if (rank == 4) return 3000;
    if (rank == 5) return 5000;
    if (rank == 6) return 8000;
    if (rank == 7) return 12000;
    if (rank == 8) return 20000;
    if (rank == 9) return 35000;
    if (rank >= 10) return 60000;
    return 0;
  }

  static int xpToNextRank(int currentRank, int currentXp) {
    final nextRankXp = xpForRank(currentRank + 1);
    return nextRankXp - currentXp;
  }

  static double rankProgress(int currentRank, int currentXp) {
    final currentRankXp = xpForRank(currentRank);
    final nextRankXp = xpForRank(currentRank + 1);
    if (nextRankXp <= currentRankXp) return 1.0;
    final xpInRank = currentXp - currentRankXp;
    final xpNeeded = nextRankXp - currentRankXp;
    return (xpInRank / xpNeeded).clamp(0.0, 1.0);
  }

  // === WARRIOR RANKS ===
  static const List<WarriorRank> ranks = [
    WarriorRank(
      level: 1,
      name: 'Helot',
      subtitle: 'Raw Recruit',
      icon: Icons.construction,
      requiredXp: 0,
      color: Color(0xFF8B7355),
      description: 'You stand at the threshold. The forge awaits.',
      badgeAsset: 'assets/ranks/helot_badge.png',
    ),
    WarriorRank(
      level: 2,
      name: 'Perioikoi',
      subtitle: 'Trainee',
      icon: Icons.fitness_center,
      requiredXp: 500,
      color: Color(0xFFA0A0A0),
      description: 'The first sparks fly. You begin to understand discipline.',
      badgeAsset: 'assets/ranks/perioikoi_badge.png',
    ),
    WarriorRank(
      level: 3,
      name: 'Hypomeion',
      subtitle: 'Aspirant',
      icon: Icons.shield,
      requiredXp: 1500,
      color: Color(0xFFB87333),
      description: 'Your shield rises. You aspire to something greater.',
      badgeAsset: 'assets/ranks/hypomeion_badge.png',
    ),
    WarriorRank(
      level: 4,
      name: 'Trophimoi',
      subtitle: 'Cadet',
      icon: Icons.sports_martial_arts,
      requiredXp: 3000,
      color: Color(0xFFCD7F32),
      description: 'Training intensifies. The bronze begins to gleam.',
      badgeAsset: 'assets/ranks/trophimoi_badge.png',
    ),
    WarriorRank(
      level: 5,
      name: 'Spartiate',
      subtitle: 'Warrior',
      icon: Icons.local_fire_department,
      requiredXp: 5000,
      color: Color(0xFFD4AF37),
      description: 'You are now a true Spartiate. The phalanx welcomes you.',
      badgeAsset: 'assets/ranks/spartiate_badge.png',
    ),
    WarriorRank(
      level: 6,
      name: 'Harmost',
      subtitle: 'Squad Leader',
      icon: Icons.military_tech,
      requiredXp: 8000,
      color: Color(0xFFE5B80B),
      description: 'Others look to you for guidance. Lead by example.',
      badgeAsset: 'assets/ranks/harmost_badge.png',
    ),
    WarriorRank(
      level: 7,
      name: 'Lochagos',
      subtitle: 'Captain',
      icon: Icons.emoji_events,
      requiredXp: 12000,
      color: Color(0xFFFFD700),
      description: 'You command respect. Your presence steadies the line.',
      badgeAsset: 'assets/ranks/lochagos_badge.png',
    ),
    WarriorRank(
      level: 8,
      name: 'Polemarch',
      subtitle: 'War Leader',
      icon: Icons.star,
      requiredXp: 20000,
      color: Color(0xFFFF4500),
      description: 'Blood and glory follow your name. You are feared.',
      badgeAsset: 'assets/ranks/polemarch_badge.png',
    ),
    WarriorRank(
      level: 9,
      name: 'Strategos',
      subtitle: 'General',
      icon: Icons.workspace_premium,
      requiredXp: 35000,
      color: Color(0xFFFF0000),
      description: 'Wars are won by your design. Kings seek your counsel.',
      badgeAsset: 'assets/ranks/strategos_badge.png',
    ),
    WarriorRank(
      level: 10,
      name: 'Archon',
      subtitle: 'Master',
      icon: Icons.military_tech,
      requiredXp: 60000,
      color: Color(0xFF8B0000),
      description: 'You have reached the pinnacle. Your legend is eternal.',
      badgeAsset: 'assets/ranks/archon_badge.png',
    ),
  ];

  static WarriorRank getRank(int level) {
    return ranks.firstWhere((r) => r.level == level, orElse: () => ranks.first);
  }

  static WarriorRank? getNextRank(int currentLevel) {
    if (currentLevel >= 10) return null;
    return ranks.firstWhere(
      (r) => r.level == currentLevel + 1,
      orElse: () => ranks.last,
    );
  }

  // === SKILL TREES ===
  static const List<SkillTree> skillTrees = [
    SkillTree(
      id: 'phalanx',
      name: 'Phalanx Strength',
      icon: Icons.fitness_center,
      color: Color(0xFFB87333),
      description: 'Heavy compound lifts, power development, raw strength',
      workouts: ['deadlift', 'squat', 'bench_press', 'overhead_press', 'row'],
    ),
    SkillTree(
      id: 'pankration',
      name: 'Pankration Agility',
      icon: Icons.sports_martial_arts,
      color: Color(0xFF4A90E2),
      description: 'Bodyweight mastery, mobility, explosive movement',
      workouts: ['calisthenics', 'plyometrics', 'mobility', 'gymnastics'],
    ),
    SkillTree(
      id: 'dromos',
      name: 'Dromos Endurance',
      icon: Icons.directions_run,
      color: Color(0xFF50C878),
      description: 'Cardiovascular capacity, stamina, work capacity',
      workouts: ['running', 'cycling', 'rowing', 'hiit', 'circuit'],
    ),
    SkillTree(
      id: 'agoge',
      name: 'Agoge Discipline',
      icon: Icons.self_improvement,
      color: Color(0xFFD4AF37),
      description: 'Mental toughness, consistency, habit formation',
      workouts: ['daily_workout', 'streak_maintenance', 'early_training'],
    ),
    SkillTree(
      id: 'tactics',
      name: 'Tactics Knowledge',
      icon: Icons.psychology,
      color: Color(0xFF9B59B6),
      description: 'Exercise variety, workout complexity, form mastery',
      workouts: ['new_exercises', 'complex_movements', 'technique_focus'],
    ),
  ];

  // === XP REWARDS ===
  static const int xpWorkoutCompleted = 100;
  static const int xpWorkoutPR = 50;
  static const int xpNewExercise = 25;
  static const int xpStreak3Day = 50;
  static const int xpStreak7Day = 150;
  static const int xpStreak30Day = 500;
  static const int xpStreak100Day = 2000;
  static const int xpRankUpBonus = 200;
  static const int xpSkillLevelUp = 100;

  // === ACHIEVEMENT CATEGORIES ===
  static const List<AchievementCategory> achievementCategories = [
    AchievementCategory(
      id: 'combat',
      name: 'Combat Medals',
      icon: Icons.military_tech,
      description: 'Milestones in your warrior journey',
    ),
    AchievementCategory(
      id: 'skill',
      name: 'Skill Badges',
      icon: Icons.workspace_premium,
      description: 'Mastery in specific disciplines',
    ),
    AchievementCategory(
      id: 'secret',
      name: 'Secret Honors',
      icon: Icons.lock,
      description: 'Hidden achievements for the worthy',
    ),
    AchievementCategory(
      id: 'social',
      name: 'Phalanx Honors',
      icon: Icons.people,
      description: 'Achievements shared with fellow warriors',
    ),
  ];

  // === ACHIEVEMENTS ===
  static const List<Achievement> achievements = [
    // Combat Medals
    Achievement(
      id: 'first_blood',
      categoryId: 'combat',
      name: 'First Blood',
      description: 'Complete your first workout',
      icon: Icons.bloodtype,
      xpReward: 50,
      secret: false,
    ),
    Achievement(
      id: 'shield_wall',
      categoryId: 'combat',
      name: 'Shield Wall',
      description: 'Maintain a 7-day streak',
      icon: Icons.shield,
      xpReward: 150,
      secret: false,
    ),
    Achievement(
      id: 'last_stand',
      categoryId: 'combat',
      name: 'Last Stand',
      description: 'Complete a workout despite low readiness',
      icon: Icons.local_fire_department,
      xpReward: 100,
      secret: false,
    ),
    Achievement(
      id: 'never_surrender',
      categoryId: 'combat',
      name: 'Never Surrender',
      description: 'Complete 100 total workouts',
      icon: Icons.emoji_events,
      xpReward: 500,
      secret: false,
    ),
    Achievement(
      id: 'iron_will',
      categoryId: 'combat',
      name: 'Iron Will',
      description: 'Maintain a 30-day streak',
      icon: Icons.fitness_center,
      xpReward: 1000,
      secret: false,
    ),
    Achievement(
      id: 'immortal',
      categoryId: 'combat',
      name: 'Immortal',
      description: 'Maintain a 100-day streak',
      icon: Icons.star,
      xpReward: 5000,
      secret: false,
    ),

    // Skill Badges
    Achievement(
      id: 'iron_grip',
      categoryId: 'skill',
      name: 'Iron Grip',
      description: 'Deadlift 1.5x bodyweight',
      icon: Icons.sports_gymnastics,
      xpReward: 200,
      secret: false,
    ),
    Achievement(
      id: 'marathon_runner',
      categoryId: 'skill',
      name: 'Marathon Runner',
      description: 'Run 100km total',
      icon: Icons.directions_run,
      xpReward: 300,
      secret: false,
    ),
    Achievement(
      id: 'phalanx_master',
      categoryId: 'skill',
      name: 'Phalanx Master',
      description: 'Complete 100 strength workouts',
      icon: Icons.fitness_center,
      xpReward: 400,
      secret: false,
    ),
    Achievement(
      id: 'pankration_expert',
      categoryId: 'skill',
      name: 'Pankration Expert',
      description: 'Complete 50 bodyweight workouts',
      icon: Icons.sports_martial_arts,
      xpReward: 350,
      secret: false,
    ),
    Achievement(
      id: 'dromos_champion',
      categoryId: 'skill',
      name: 'Dromos Champion',
      description: 'Complete 50 endurance workouts',
      icon: Icons.timer,
      xpReward: 350,
      secret: false,
    ),

    // Secret Achievements
    Achievement(
      id: 'spartan_dawn',
      categoryId: 'secret',
      name: 'Spartan Dawn',
      description: 'Complete a workout before 5am',
      icon: Icons.wb_sunny,
      xpReward: 100,
      secret: true,
    ),
    Achievement(
      id: 'blood_sweat',
      categoryId: 'secret',
      name: 'Blood & Sweat',
      description: 'Complete a workout in harsh weather',
      icon: Icons.water_drop,
      xpReward: 150,
      secret: true,
    ),
    Achievement(
      id: 'never_retreat',
      categoryId: 'secret',
      name: 'Never Retreat',
      description: 'Complete workout despite wanting to quit',
      icon: Icons.arrow_upward,
      xpReward: 75,
      secret: true,
    ),
    Achievement(
      id: 'lone_wolf',
      categoryId: 'secret',
      name: 'Lone Wolf',
      description: 'Train alone for 30 consecutive days',
      icon: Icons.person,
      xpReward: 200,
      secret: true,
    ),
    Achievement(
      id: 'berserker',
      categoryId: 'secret',
      name: 'Berserker',
      description: 'Complete 3 workouts in one day',
      icon: Icons.local_fire_department,
      xpReward: 300,
      secret: true,
    ),
  ];

  // === STOIC QUOTES ===
  static const List<String> stoicQuotes = [
    '"The impediment to action advances action. What stands in the way becomes the way." - Marcus Aurelius',
    '"You have power over your mind—not outside events. Realize this, and you will find strength." - Marcus Aurelius',
    '"First say to yourself what you would be; and then do what you have to do." - Epictetus',
    '"No man is free who is not master of himself." - Epictetus',
    '"Difficulties strengthen the mind, as labor does the body." - Seneca',
    '"It is not that we have a short time to live, but that we waste a lot of it." - Seneca',
    '"He who fears death will never do anything worth of a man who is alive." - Seneca',
    '"Waste no more time arguing about what a good man should be. Be one." - Marcus Aurelius',
    '"The happiness of your life depends upon the quality of your thoughts." - Marcus Aurelius',
    '"Make the best use of what is in your power, and take the rest as it happens." - Epictetus',
  ];

  static String getRandomQuote() {
    return stoicQuotes[DateTime.now().millisecond % stoicQuotes.length];
  }

  // === TRIAL NAMES ===
  static const List<String> trialNames = [
    'The Agoge Test',
    'Phalanx Formation',
    'The 300 Challenge',
    'Thermopylae Defense',
    'Spear of Leonidas',
    'Shield Wall',
    'Bronze Trial',
    'Iron Will',
    'Blood & Sweat',
    'The Spartan Way',
    'Warrior\'s Path',
    'Forge of Men',
    'Discipline Protocol',
    'Molon Labe',
    'Return with Shield',
  ];

  static String getRandomTrialName() {
    return trialNames[DateTime.now().millisecond % trialNames.length];
  }
}

// === DATA CLASSES ===
class WarriorRank {
  final int level;
  final String name;
  final String subtitle;
  final IconData icon;
  final int requiredXp;
  final Color color;
  final String description;
  final String badgeAsset;

  const WarriorRank({
    required this.level,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.requiredXp,
    required this.color,
    required this.description,
    required this.badgeAsset,
  });
}

class SkillTree {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> workouts;

  const SkillTree({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.workouts,
  });
}

class AchievementCategory {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  const AchievementCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}

class Achievement {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final IconData icon;
  final int xpReward;
  final bool secret;

  const Achievement({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.secret,
  });
}
