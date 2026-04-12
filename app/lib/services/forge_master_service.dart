import 'dart:developer' as developer;
import '../models/warrior_models.dart';
import '../models/user_profile.dart';
import '../models/workout_protocol.dart';
import '../models/workout_preferences.dart';
import '../warrior_constants.dart';
import 'warrior_progress_service.dart';
import 'ai_plan_service.dart';

/// Forge Master Service - AI-driven personalized workout generation
/// Acts as a harsh-but-fair drill instructor mixed with stoic philosopher
class ForgeMasterService {
  static final ForgeMasterService _instance = ForgeMasterService._internal();
  factory ForgeMasterService() => _instance;
  ForgeMasterService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // Forge Master uses AI Plan Service for workout generation

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    developer.log('ForgeMasterService initialized', name: 'ForgeMaster');
  }

  /// Generate personalized trial (workout) based on warrior context
  Future<WorkoutProtocol?> generateTrial({
    required WarriorProfile profile,
    required UserProfile userProfile,
    int? targetDuration,
    int? readinessScore,
  }) async {
    try {
      // Determine focus based on skill gaps
      final skillFocus = _determineSkillFocus(profile);

      // Generate trial name
      final trialName = _generateTrialName(profile, skillFocus);

      // Check if we need a "save the streak" workout
      if (_isStreakAtRisk(profile)) {
        return await _generateStreakSaveTrial(
          profile: profile,
          userProfile: userProfile,
          targetDuration: targetDuration ?? 20,
        );
      }

      // Check if rank-up is close - generate epic trial
      if (_isRankUpClose(profile)) {
        return await _generateEpicTrial(
          profile: profile,
          userProfile: userProfile,
          targetDuration: targetDuration ?? 60,
          skillFocus: skillFocus,
        );
      }

      // Normal trial generation
      return await _generateStandardTrial(
        profile: profile,
        userProfile: userProfile,
        targetDuration: targetDuration,
        readinessScore: readinessScore,
        skillFocus: skillFocus,
        trialName: trialName,
      );
    } catch (e) {
      developer.log('Error generating trial: $e', name: 'ForgeMaster');
      return null;
    }
  }

  /// Determine which skill tree needs focus
  String _determineSkillFocus(WarriorProfile profile) {
    // Find the skill with lowest level
    final skillLevels = WarriorConstants.skillTrees.map((skill) {
      final progress = profile.getSkillProgress(skill.id);
      return (skill.id, progress.level, progress.xp);
    }).toList();

    // Sort by level, then by XP
    skillLevels.sort((a, b) {
      if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
      return a.$3.compareTo(b.$3);
    });

    return skillLevels.first.$1;
  }

  /// Generate thematic trial name
  String _generateTrialName(WarriorProfile profile, String skillFocus) {
    final baseNames = WarriorConstants.trialNames;

    // Add rank-specific prefixes
    String prefix = '';
    if (profile.rankLevel >= 8) {
      prefix = 'The Archon\'s ';
    } else if (profile.rankLevel >= 5) {
      prefix = 'The Spartiate\'s ';
    } else if (profile.rankLevel >= 3) {
      prefix = 'The Aspirant\'s ';
    }

    // Add skill-specific suffixes
    String suffix = '';
    switch (skillFocus) {
      case 'phalanx':
        suffix = ' of Iron';
        break;
      case 'pankration':
        suffix = ' of Agility';
        break;
      case 'dromos':
        suffix = ' of Endurance';
        break;
      case 'agoge':
        suffix = ' of Discipline';
        break;
      case 'tactics':
        suffix = ' of Cunning';
        break;
    }

    // Select base name based on user ID for consistency
    final nameIndex = profile.userId.hashCode % baseNames.length;
    return '$prefix${baseNames[nameIndex.abs()]}${suffix.isNotEmpty ? suffix : ""}';
  }

  /// Check if streak is at risk (missed yesterday)
  bool _isStreakAtRisk(WarriorProfile profile) {
    if (profile.currentStreak == 0) return false;
    if (profile.lastWorkoutDate == null) return true;

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return !_isSameDay(profile.lastWorkoutDate!, yesterday) &&
        !_isSameDay(profile.lastWorkoutDate!, DateTime.now());
  }

  /// Check if rank-up is close (< 20% XP remaining)
  bool _isRankUpClose(WarriorProfile profile) {
    if (profile.nextRank == null) return false;
    return profile.rankProgress >= 0.8;
  }

  /// Generate minimum viable workout to save streak
  Future<WorkoutProtocol?> _generateStreakSaveTrial({
    required WarriorProfile profile,
    required UserProfile userProfile,
    required int targetDuration,
  }) async {
    // Use AI Plan Service with modified prompt for short workout
    final aiService = AIPlanService();

    final preferences = WorkoutPreferences(
      userId: userProfile.userId,
      targetDurationMinutes: targetDuration,
      targetIntensity: 5, // Moderate
      trainingFocus: TrainingFocus.mixed,
      includeCardio: true,
      includeMobility: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final protocol = await aiService.generateCustomProtocol(
      userProfile,
      preferences,
    );

    if (protocol != null) {
      // Rename with streak-save context
      return protocol.copyWith(
        title: 'Streak Defense: ${protocol.title}',
        mindsetPrompt:
            '${protocol.mindsetPrompt}\n\n[FORGE MASTER]: Your streak hangs by a thread, ${profile.rank.name}. This trial will save it.',
      );
    }

    return null;
  }

  /// Generate epic trial for rank-up
  Future<WorkoutProtocol?> _generateEpicTrial({
    required WarriorProfile profile,
    required UserProfile userProfile,
    required int targetDuration,
    required String skillFocus,
  }) async {
    final aiService = AIPlanService();

    final preferences = WorkoutPreferences(
      userId: userProfile.userId,
      targetDurationMinutes: targetDuration,
      targetIntensity: 9, // Maximum
      trainingFocus: _skillToTrainingFocus(skillFocus),
      includeCardio: skillFocus == 'dromos' || skillFocus == 'agoge',
      includeMobility: skillFocus == 'pankration',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final protocol = await aiService.generateCustomProtocol(
      userProfile,
      preferences,
    );

    if (protocol != null) {
      final nextRankName = profile.nextRank?.name ?? 'Glory';
      return protocol.copyWith(
        title: 'Trial of Ascension: ${protocol.title}',
        mindsetPrompt:
            '${protocol.mindsetPrompt}\n\n[FORGE MASTER]: You stand at the threshold of $nextRankName. Conquer this trial, and ascend.',
      );
    }

    return null;
  }

  /// Generate standard trial
  Future<WorkoutProtocol?> _generateStandardTrial({
    required WarriorProfile profile,
    required UserProfile userProfile,
    int? targetDuration,
    int? readinessScore,
    required String skillFocus,
    required String trialName,
  }) async {
    final aiService = AIPlanService();

    // Adjust intensity based on readiness
    int intensityLevel = 3;
    if (readinessScore != null) {
      if (readinessScore >= 85) {
        intensityLevel = 5;
      } else if (readinessScore >= 70) {
        intensityLevel = 4;
      } else if (readinessScore >= 50) {
        intensityLevel = 3;
      } else {
        intensityLevel = 2;
      }
    }

    final preferences = WorkoutPreferences(
      userId: userProfile.userId,
      targetDurationMinutes:
          targetDuration ?? userProfile.preferredWorkoutDuration ?? 45,
      targetIntensity: intensityLevel * 2, // Scale 1-5 to 1-10
      trainingFocus: _skillToTrainingFocus(skillFocus),
      includeCardio: true,
      includeMobility: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final protocol = await aiService.generateCustomProtocol(
      userProfile,
      preferences,
    );

    if (protocol != null) {
      return protocol.copyWith(
        title: trialName,
        mindsetPrompt:
            '${protocol.mindsetPrompt}\n\n[FORGE MASTER]: ${profile.rank.name}, focus your ${skillFocus == 'phalanx'
                ? 'strength'
                : skillFocus == 'pankration'
                ? 'agility'
                : skillFocus == 'dromos'
                ? 'endurance'
                : skillFocus == 'agoge'
                ? 'discipline'
                : 'tactical mind'}. The forge demands progress.',
      );
    }

    return null;
  }

  /// Convert skill ID to TrainingFocus
  TrainingFocus _skillToTrainingFocus(String skillId) {
    switch (skillId) {
      case 'phalanx':
        return TrainingFocus.strength;
      case 'pankration':
        return TrainingFocus.conditioning;
      case 'dromos':
        return TrainingFocus.endurance;
      case 'agoge':
        return TrainingFocus.mixed;
      case 'tactics':
        return TrainingFocus.technique;
      default:
        return TrainingFocus.mixed;
    }
  }

  /// Get motivational message from Forge Master
  String getMotivationalMessage(WarriorProfile profile, {String? context}) {
    final messages = <String>[];

    // Rank-specific messages
    switch (profile.rankLevel) {
      case 1:
        messages.addAll([
          'The journey of a thousand miles begins with a single step. Take it.',
          'Every master was once a beginner. Begin.',
          'The forge does not care about your past. Only your effort today.',
        ]);
      case 2:
      case 3:
        messages.addAll([
          'The bronze is heating. You are beginning to shine.',
          'Discipline is the bridge between goals and accomplishment.',
          'Your shield rises. Soon it will protect more than just you.',
        ]);
      case 4:
      case 5:
        messages.addAll([
          'You are no longer raw metal. You are becoming steel.',
          'The phalanx requires warriors, not wanderers. Stand firm.',
          'Others now look to you. Do not disappoint them.',
        ]);
      case 6:
      case 7:
        messages.addAll([
          'You command respect. Earn it daily.',
          'Leadership is not about being in charge. It is about taking care of those in your charge.',
          'Your name is known in the barracks. Make it worthy.',
        ]);
      case 8:
      case 9:
        messages.addAll([
          'Wars are won by those who prepare when others rest.',
          'You have survived the forge. Now you are the fire.',
          'Legends are not born. They are forged, one battle at a time.',
        ]);
      case 10:
        messages.addAll([
          'You have reached the pinnacle. Now maintain it.',
          'The master\'s journey never ends. There is always more to learn.',
          'You are the standard others aspire to. Never lower it.',
        ]);
      default:
        messages.add('The forge awaits your presence.');
    }

    // Context-specific additions
    if (context == 'pre_battle') {
      messages.addAll([
        'Steel your mind. The trial begins.',
        'Fear is a reaction. Courage is a decision. Decide now.',
        'Pain is temporary. Glory is eternal.',
      ]);
    } else if (context == 'mid_battle') {
      messages.addAll([
        'You are stronger than you think. Keep moving.',
        'The enemy is fatigue. Defeat it.',
        'One more rep. One more step. One more victory.',
      ]);
    } else if (context == 'post_battle') {
      messages.addAll([
        'You have bled. You have grown. You are better.',
        'Another battle won. The war continues.',
        'Rest now, warrior. Tomorrow, we forge again.',
      ]);
    }

    // Streak-based messages
    if (profile.currentStreak >= 7) {
      messages.add('Your streak burns bright. Do not let it fade.');
    }
    if (profile.currentStreak >= 30) {
      messages.add(
        'A month of discipline. You are becoming something greater.',
      );
    }
    if (profile.currentStreak >= 100) {
      messages.add('Immortal. That is what you are becoming.');
    }

    // Return random message based on current time for variety
    final index = DateTime.now().millisecond % messages.length;
    return messages[index.abs()];
  }

  /// Get battle cry for specific moments
  String getBattleCry({String? moment}) {
    final cries = <String>[];

    switch (moment) {
      case 'start':
        cries.addAll([
          'MOLON LABE!',
          'FOR SPARTA!',
          'TO GLORY!',
          'WITH SHIELD OR ON IT!',
        ]);
      case 'struggle':
        cries.addAll([
          'NEVER RETREAT!',
          'HOLD THE LINE!',
          'STEEL YOURSELF!',
          'THE PAIN IS TEMPORARY!',
        ]);
      case 'finish':
        cries.addAll([
          'VICTORY!',
          'ANOTHER CONQUERED!',
          'THE FORGE IS PLEASED!',
          'RETURN WITH SHIELD!',
        ]);
      default:
        cries.addAll(['MOLON LABE!', 'FORGE ON!', 'DISCIPLINE!']);
    }

    final index = DateTime.now().second % cries.length;
    return cries[index];
  }

  /// Analyze warrior's recent performance and provide feedback
  Future<Map<String, dynamic>> analyzePerformance(String userId) async {
    final progressService = WarriorProgressService();
    final profile = progressService.currentProfile;

    if (profile == null) {
      return {'error': 'No profile found'};
    }

    final chronicle = await progressService.getBattleChronicle(limit: 10);

    // Calculate metrics
    final totalBattles = chronicle.length;
    final victories = chronicle.where((c) => c.outcome == 'victory').length;
    final averageDuration = totalBattles > 0
        ? chronicle.map((c) => c.duration).reduce((a, b) => a + b) /
              totalBattles
        : 0;

    // Find most trained skill
    final skillCounts = <String, int>{};
    for (final entry in chronicle) {
      skillCounts[entry.skillFocus] = (skillCounts[entry.skillFocus] ?? 0) + 1;
    }
    final dominantSkill = skillCounts.entries.isNotEmpty
        ? skillCounts.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return {
      'total_battles_analyzed': totalBattles,
      'win_rate': totalBattles > 0
          ? (victories / totalBattles * 100).round()
          : 0,
      'average_duration': averageDuration.round(),
      'dominant_skill': dominantSkill?.key,
      'recommendation': _generateRecommendation(profile, dominantSkill?.key),
    };
  }

  String _generateRecommendation(
    WarriorProfile profile,
    String? dominantSkill,
  ) {
    // Find weakest skill
    final weakest = WarriorConstants.skillTrees
        .map((s) => (s.id, profile.getSkillLevel(s.id)))
        .reduce((a, b) => a.$2 < b.$2 ? a : b);

    if (weakest.$2 < 3) {
      return 'Your ${weakest.$1} skill requires attention. The warrior who neglects any discipline is incomplete.';
    }

    if (profile.currentStreak < 3 && profile.totalWorkouts > 10) {
      return 'Your consistency wavers. Remember: the chain is only as strong as its weakest link.';
    }

    if (dominantSkill != null && dominantSkill == weakest.$1) {
      return 'Good focus on your weakest area. Continue forging ${weakest.$1}.';
    }

    return 'Maintain your discipline. The path of the warrior is endless improvement.';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Extension to add copyWith to WorkoutProtocol
extension WorkoutProtocolCopy on WorkoutProtocol {
  WorkoutProtocol copyWith({
    String? title,
    String? subtitle,
    ProtocolTier? tier,
    List<ProtocolEntry>? entries,
    int? estimatedDurationMinutes,
    String? mindsetPrompt,
  }) {
    return WorkoutProtocol(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      tier: tier ?? this.tier,
      entries: entries ?? this.entries,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      mindsetPrompt: mindsetPrompt ?? this.mindsetPrompt,
    );
  }
}
