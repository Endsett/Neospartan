import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/ai_memory.dart';
import '../models/user_profile.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';
import '../models/workout_preferences.dart';
import '../models/exercise.dart';
import '../models/session_readiness_input.dart';
import '../config/ai_config.dart';
import 'ai_memory_service.dart';
import 'context_ingestion_service.dart';
import 'gemini_client.dart';
import 'supabase_database_service.dart';

/// Weekly plan structure for AI-generated training plans
class WeeklyPlan {
  final DateTime weekStarting;
  final List<DailyWorkout> dailyWorkouts;
  final String weeklyNotes;
  final String intensityRecommendation;

  const WeeklyPlan({
    required this.weekStarting,
    required this.dailyWorkouts,
    required this.weeklyNotes,
    required this.intensityRecommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'week_starting': weekStarting.toIso8601String(),
      'daily_workouts': dailyWorkouts.map((d) => d.toMap()).toList(),
      'weekly_notes': weeklyNotes,
      'intensity_recommendation': intensityRecommendation,
    };
  }
}

class ExerciseRecommendationItem {
  final String name;
  final ExerciseCategory category;
  final int intensityLevel;
  final String targetMetaphor;
  final String instructions;

  const ExerciseRecommendationItem({
    required this.name,
    required this.category,
    required this.intensityLevel,
    required this.targetMetaphor,
    required this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name,
      'intensity_level': intensityLevel,
      'target_metaphor': targetMetaphor,
      'instructions': instructions,
    };
  }
}

class WorkoutRecommendation {
  final String goal;
  final String recoveryState;
  final String progressionDirective;
  final String sessionFocus;
  final List<ExerciseRecommendationItem> exercises;
  final List<String> recoveryGuidance;

  const WorkoutRecommendation({
    required this.goal,
    required this.recoveryState,
    required this.progressionDirective,
    required this.sessionFocus,
    required this.exercises,
    required this.recoveryGuidance,
  });

  Map<String, dynamic> toMap() {
    return {
      'goal': goal,
      'recovery_state': recoveryState,
      'progression_directive': progressionDirective,
      'session_focus': sessionFocus,
      'recommended_exercises': exercises.map((e) => e.toMap()).toList(),
      'recovery_guidance': recoveryGuidance,
    };
  }
}

/// Daily workout structure
class DailyWorkout {
  final String day;
  final String workoutType;
  final String focus;
  final WorkoutProtocol protocol;

  const DailyWorkout({
    required this.day,
    required this.workoutType,
    required this.focus,
    required this.protocol,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'workout_type': workoutType,
      'focus': focus,
      'protocol': protocol.toMap(),
    };
  }
}

// Extension to add toMap method to WorkoutProtocol
extension WorkoutProtocolMap on WorkoutProtocol {
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'tier': tier.toString(),
      'estimated_duration_minutes': estimatedDurationMinutes,
      'mindset_prompt': mindsetPrompt,
      'entries': entries
          .map(
            (e) => {
              'exercise_name': e.exercise.name,
              'sets': e.sets,
              'reps': e.reps,
              'rpe': e.intensityRpe,
              'rest_seconds': e.restSeconds,
            },
          )
          .toList(),
    };
  }
}

/// AI Plan Service using Gemini 2.5 Flash for intelligent training plans
class AIPlanService {
  static final AIPlanService _instance = AIPlanService._internal();
  factory AIPlanService() => _instance;
  AIPlanService._internal();

  final GeminiClient _geminiClient = GeminiClient();
  bool _initialized = false;
  final AIMemoryService _memoryService = AIMemoryService();
  final ContextIngestionService _contextService = ContextIngestionService();
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Fetch recent workout analytics from Supabase and format as a prompt-ready string.
  /// Returns null if no data is available so callers can degrade gracefully.
  Future<String?> buildPerformanceContext() async {
    try {
      final summary = await _database.getRecentPerformanceSummary();
      if (summary['empty'] == true) return null;

      final buf = StringBuffer();
      buf.writeln(
        'PREVIOUS PERFORMANCE DATA (last ${summary['sessions_analyzed']} sessions, ${summary['total_sets_analyzed']} sets logged):',
      );

      // Per-exercise breakdown
      final exercises = summary['exercise_summaries'] as List<dynamic>? ?? [];
      if (exercises.isNotEmpty) {
        buf.writeln('\nExercise History (most frequent first):');
        for (final ex in exercises) {
          buf.writeln(
            '- ${ex['exercise']}: ${ex['sets_logged']} sets, '
            '${ex['total_reps']} total reps, '
            'max load ${ex['max_load']}kg, '
            'avg RPE ${ex['avg_rpe']}, '
            'volume ${ex['total_volume']}kg',
          );
        }
      }

      // Weekly trends
      final weeks = summary['weekly_progress'] as List<dynamic>? ?? [];
      if (weeks.isNotEmpty) {
        buf.writeln('\nWeekly Progress Trend (most recent first):');
        for (final w in weeks) {
          buf.writeln(
            '- Week ${w['week']}: '
            '${w['workouts_completed']} workouts, '
            'avg RPE ${w['average_rpe']}, '
            'volume ${w['total_volume']}kg, '
            'readiness ${w['average_readiness']}/100',
          );
        }
      }

      if (summary['overall_avg_rpe'] != null) {
        buf.writeln(
          '\nOverall average RPE across sessions: ${summary['overall_avg_rpe']}',
        );
      }
      buf.writeln(
        'Most recent session: ${summary['most_recent_session_date']}',
      );

      return buf.toString();
    } catch (e) {
      debugPrint('Error building performance context: $e');
      return null;
    }
  }

  /// Initialize the service with Gemini 2.5 Flash and memory system
  Future<void> initialize() async {
    try {
      await _geminiClient.initialize();
      // Memory service doesn't need initialization
      _initialized = true;
      debugPrint(
        'AI Plan Service initialized with Gemini 2.0 Flash and memory system',
      );
      if (AIConfig.isUsingDevKey) {
        debugPrint('WARNING: Using development API key');
      }
    } catch (e) {
      debugPrint('Failed to initialize AI service: $e');
      _initialized = false;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Generate initial training plan based on user profile using Gemini AI with memory context
  Future<WeeklyPlan?> generateInitialTrainingPlan(UserProfile profile) async {
    if (!isInitialized) {
      debugPrint('AI Plan Service not initialized');
      return null;
    }

    try {
      // Store user profile in memory
      try {
        await _memoryService.storeMemory(
          userId: profile.userId,
          type: AIMemoryType.userProfile,
          priority: MemoryPriority.high,
          data: profile.toMap(),
          tags: ['profile', 'initial'],
          summary: 'Initial user profile setup',
        );
      } catch (e) {
        debugPrint('Memory storage failed, continuing without memory: $e');
      }

      // Fetch recent performance analytics for personalization
      final performanceContext = await buildPerformanceContext();

      // Build context-aware prompt
      String prompt;
      try {
        prompt = await _contextService.buildPrompt(
          userId: profile.userId,
          contextType: 'training_plan_generation',
          userProfile: profile,
          additionalContext: performanceContext != null
              ? {'performance_history': performanceContext}
              : null,
          maxTokens: 8000,
        );
      } catch (e) {
        debugPrint('Context building failed, using basic prompt: $e');
        prompt = _buildBasicPrompt(
          profile,
          performanceContext: performanceContext,
        );
      }

      final planText = await _geminiClient.generateContent(
        prompt,
        maxRetries: AIConfig.maxRetries,
        delay: AIConfig.baseDelay,
      );

      if (planText != null) {
        final plan = _parseAIResponseToPlan(planText, profile);

        // Store generated plan in memory
        try {
          await _memoryService.storeMemory(
            userId: profile.userId,
            type: AIMemoryType.workoutHistory,
            priority: MemoryPriority.high,
            data: plan.toMap(),
            tags: ['plan', 'initial'],
          );
        } catch (e) {
          debugPrint('Failed to store plan in memory: $e');
        }

        return plan;
      }
    } catch (e) {
      debugPrint('Error generating AI plan: $e');
    }

    return _generateFallbackPlan(profile);
  }

  /// Build basic prompt when memory system fails
  String _buildBasicPrompt(UserProfile profile, {String? performanceContext}) {
    final perfBlock = performanceContext != null
        ? '''

$performanceContext

IMPORTANT: Use the above performance data to:
- Apply progressive overload on exercises the athlete has been doing (increase load/reps slightly)
- Avoid over-programming exercises with high RPE trends (risk of overtraining)
- Introduce variety where the athlete has plateaued
- Adjust intensity based on recent readiness trends
'''
        : '';

    return '''
You are an elite combat sports conditioning coach. Create a detailed weekly training plan for a ${profile.fitnessLevelText} level athlete training for ${profile.trainingGoalText}.

ATHLETE PROFILE:
- Name: ${profile.displayName ?? 'Athlete'}
- Age: ${profile.bodyComposition.age}
- Weight: ${profile.bodyComposition.weight}kg
- Height: ${profile.bodyComposition.height}cm
- Level: ${profile.fitnessLevelText}
- Goal: ${profile.trainingGoalText}
- Days per week: ${profile.trainingDaysPerWeek}
- Session duration: ${profile.preferredWorkoutDuration} minutes
$perfBlock
RESPONSE FORMAT:
Return a JSON object with the following structure:
{
  "week_plan": [
    {
      "day": "Monday",
      "workout_type": "Strength/Power",
      "focus": "Lower Body Explosiveness",
      "exercises": [
        {
          "name": "Back Squat",
          "sets": 4,
          "reps": "5",
          "rpe": 8,
          "rest_seconds": 180
        }
      ]
    }
  ],
  "weekly_notes": "Overall progression strategy",
  "intensity_recommendation": "Based on athlete level"
}
''';
  }

  /// Adjust training plan based on weekly progress using memory context
  Future<WeeklyPlan> adjustPlanBasedOnProgress(
    UserProfile profile,
    WeeklyPlan currentPlan,
    WeeklyProgress progress,
  ) async {
    if (!_initialized) {
      return _generateFallbackAdjustment(profile, currentPlan, progress);
    }

    try {
      // Store progress in memory
      try {
        await _memoryService.storeMemory(
          userId: profile.userId,
          type: AIMemoryType.workoutHistory,
          priority: MemoryPriority.medium,
          data: progress.toMap(),
          tags: ['progress', 'weekly'],
        );
      } catch (e) {
        debugPrint('Failed to store progress in memory: $e');
      }

      // Fetch recent performance analytics for personalization
      final performanceContext = await buildPerformanceContext();

      // Build context-aware prompt
      String prompt;
      try {
        prompt = await _contextService.buildPrompt(
          userId: profile.userId,
          contextType: 'plan_adjustment',
          userProfile: profile,
          additionalContext: performanceContext != null
              ? {'performance_history': performanceContext}
              : null,
          maxTokens: 8000,
        );
      } catch (e) {
        debugPrint('Context building failed, using basic prompt: $e');
        prompt = _buildAdjustmentPrompt(
          profile,
          currentPlan,
          progress,
          performanceContext: performanceContext,
        );
      }

      final planText = await _geminiClient.generateContent(
        prompt,
        maxRetries: AIConfig.maxRetries,
        delay: AIConfig.baseDelay,
      );

      if (planText != null) {
        final adjustedPlan = _parseAIResponseToPlan(planText, profile);

        // Store feedback in memory
        try {
          await _memoryService.storeMemory(
            userId: profile.userId,
            type: AIMemoryType.feedback,
            priority: MemoryPriority.low,
            data: {
              'adjustment_reason': 'weekly_progress',
              'previous_plan': currentPlan.toMap(),
              'progress_data': progress.toMap(),
            },
            tags: ['feedback', 'adjustment'],
          );
        } catch (e) {
          debugPrint('Failed to store feedback in memory: $e');
        }

        return adjustedPlan;
      }
    } catch (e) {
      debugPrint('Error adjusting AI plan: $e');
    }

    return _generateFallbackAdjustment(profile, currentPlan, progress);
  }

  /// Get AI recommendations for specific workout adjustments
  Future<String> getWorkoutRecommendations(
    UserProfile profile,
    DailyLog recentLogs, {
    SessionReadinessInput? readinessInput,
  }) async {
    try {
      final recommendation = await getStructuredWorkoutRecommendations(
        profile,
        recentLogs,
        readinessInput: readinessInput,
      );

      final exerciseBlock = recommendation.exercises.isEmpty
          ? 'No specific exercise matches found; use your current protocol with adjusted intensity.'
          : recommendation.exercises
                .map(
                  (exercise) =>
                      '- ${exercise.name} (${exercise.category.name.toUpperCase()}) · Intensity ${exercise.intensityLevel}/10',
                )
                .join('\n');

      return '''
DEVELOPMENT PLAN RECOMMENDATION
- Goal: ${recommendation.goal}
- Recovery state: ${recommendation.recoveryState.replaceAll('_', ' ')}
- Progression directive: ${recommendation.progressionDirective}
- Suggested session focus: ${recommendation.sessionFocus}

NEXT SESSION EXERCISE RECOMMENDATIONS
$exerciseBlock

RECOVERY GUIDANCE
${recommendation.recoveryGuidance.map((line) => '- $line').join('\n')}
''';
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return 'Continue with current plan based on your readiness score.';
    }
  }

  Future<WorkoutRecommendation> getStructuredWorkoutRecommendations(
    UserProfile profile,
    DailyLog recentLogs, {
    SessionReadinessInput? readinessInput,
  }) async {
    final adjustedLog = _applyReadinessInputToLog(recentLogs, readinessInput);

    final recoveryState = _determineRecoveryState(adjustedLog);
    final progressionDirective = _determineProgressionDirective(
      profile,
      adjustedLog,
    );
    final workoutType = _recommendWorkoutType(profile, recoveryState);

    final candidateExercises = Exercise.forUserProfile(
      profile,
      workoutType: workoutType,
      limit: 80,
    );

    final selectedExercises = _selectExercisesForRecoveryState(
      candidateExercises,
      recoveryState,
    ).take(6).toList();

    final maxJoint = adjustedLog.jointFatigue.entries.isEmpty
        ? null
        : adjustedLog.jointFatigue.entries.reduce(
            (a, b) => a.value >= b.value ? a : b,
          );

    final recoveryNote = recoveryState == 'recovery'
        ? 'Prioritize mobility, isometrics, and low-impact conditioning. Keep RPE 5-6.'
        : recoveryState == 'high_performance'
        ? 'Recovered and ready: include one explosive block at RPE 8-9 while keeping form strict.'
        : 'Maintain workload at RPE 6-8 and focus on technical quality.';

    final jointNote = maxJoint == null
        ? 'No significant joint stress flags logged.'
        : maxJoint.value >= 7
        ? 'Protect ${maxJoint.key}: reduce joint-heavy loading and use controlled tempo.'
        : 'Joint stress acceptable. Continue monitoring ${maxJoint.key}.';

    final exercises = selectedExercises
        .map(
          (exercise) => ExerciseRecommendationItem(
            name: exercise.name,
            category: exercise.category,
            intensityLevel: exercise.intensityLevel,
            targetMetaphor: exercise.targetMetaphor,
            instructions: exercise.instructions,
          ),
        )
        .toList();

    return WorkoutRecommendation(
      goal: profile.trainingGoalText,
      recoveryState: recoveryState,
      progressionDirective: progressionDirective,
      sessionFocus: workoutType,
      exercises: exercises,
      recoveryGuidance: [
        recoveryNote,
        jointNote,
        if (readinessInput != null)
          'Questionnaire-adjusted readiness: ${adjustedLog.readinessScore}/100 (soreness ${readinessInput.soreness}/10, stress ${readinessInput.stress}/10).',
        'Sleep target: 7.5-9.0 hours before next hard session.',
      ],
    );
  }

  /// Generate a customized daily workout protocol based on user preferences
  /// Uses enhanced AI prompting with exercise validation
  Future<WorkoutProtocol?> generateCustomProtocol(
    UserProfile profile,
    WorkoutPreferences preferences, {
    List<Exercise>? availableExercises,
  }) async {
    if (!_initialized) {
      debugPrint('AI Plan Service not initialized');
      return null;
    }

    try {
      // Fetch recent performance analytics for personalization
      final performanceContext = await buildPerformanceContext();

      // Build enhanced prompt with preferences and analytics
      final prompt = _buildCustomWorkoutPrompt(
        profile,
        preferences,
        availableExercises,
        performanceContext: performanceContext,
      );

      debugPrint(
        'Generating custom workout with preferences: ${preferences.toMap()}',
      );

      final response = await _geminiClient.generateContent(
        prompt,
        maxRetries: AIConfig.maxRetries,
        delay: AIConfig.baseDelay,
      );

      if (response != null) {
        final protocol = _parseCustomWorkoutResponse(
          response,
          profile,
          preferences,
        );

        // Store in memory
        try {
          await _memoryService.storeMemory(
            userId: profile.userId,
            type: AIMemoryType.workoutHistory,
            priority: MemoryPriority.high,
            data: protocol.toMap(),
            summary:
                'Custom AI workout: ${protocol.title} (${protocol.estimatedDurationMinutes}min, ${protocol.entries.length} exercises)',
            tags: ['custom', 'ai_generated', preferences.trainingFocus.name],
          );
        } catch (e) {
          debugPrint('Failed to store custom workout in memory: $e');
        }

        return protocol;
      }
    } catch (e) {
      debugPrint('Error generating custom protocol: $e');
    }

    // Fallback to template generation
    return _generateFallbackCustomProtocol(profile, preferences);
  }

  /// Build enhanced prompt for custom workout generation
  String _buildCustomWorkoutPrompt(
    UserProfile profile,
    WorkoutPreferences preferences,
    List<Exercise>? availableExercises, {
    String? performanceContext,
  }) {
    final exerciseList =
        availableExercises != null && availableExercises.isNotEmpty
        ? availableExercises
              .map((e) => '- ${e.name} (${e.category.name})')
              .join('\n')
        : 'Use standard strength and conditioning exercises';

    final perfBlock = performanceContext != null
        ? '''

$performanceContext

IMPORTANT: Use the above performance data to:
- Apply progressive overload on exercises the athlete has done before (increase load or reps slightly)
- Avoid repeating exercises with very high recent RPE (risk of overtraining)
- Introduce variety for exercises the athlete has plateaued on
- Prioritise exercises the athlete hasn't done recently to balance development
'''
        : '';

    return '''
You are an elite combat sports conditioning coach. Create a personalized single-session workout plan tailored to the athlete's specific preferences.

ATHLETE PROFILE:
- Name: ${profile.displayName ?? 'Athlete'}
- Level: ${profile.fitnessLevelText}
- Goal: ${profile.trainingGoalText}

WORKOUT PREFERENCES:
- Target Intensity: ${preferences.targetIntensity}/10 (${preferences.intensityLabel})
- Target Duration: ${preferences.targetDurationMinutes} minutes
- Training Focus: ${preferences.trainingFocusLabel}
- Preferred Categories: ${preferences.preferredCategories.map((c) => c.name).join(', ')}
- Number of Exercises: ${preferences.preferredExerciseCount}
- Sets per Exercise: ${preferences.setsPerExercise}
${preferences.specificFocus != null ? '- Specific Focus: ${preferences.specificFocus}' : ''}
${preferences.includeCardio ? '- Include cardiovascular conditioning' : ''}
${preferences.includeMobility ? '- Include mobility work' : ''}
$perfBlock
AVAILABLE EXERCISES:
$exerciseList

INSTRUCTIONS:
1. Select exactly ${preferences.preferredExerciseCount} exercises that match the focus and categories
2. Design sets/reps to achieve intensity level ${preferences.targetIntensity}/10
3. Target total duration: ${preferences.targetDurationMinutes} minutes (include appropriate rest)
4. Provide a motivational title and mindset prompt
5. If performance data is available, use it to set progressive targets (slightly higher load/reps than last session)

RESPONSE FORMAT:
Return a JSON object:
{
  "title": "Creative workout name",
  "subtitle": "Brief description",
  "exercises": [
    {
      "name": "Exercise name from available list",
      "sets": ${preferences.setsPerExercise},
      "reps": number or "MAX",
      "rpe": ${preferences.targetIntensity - 2} to ${preferences.targetIntensity + 1},
      "rest_seconds": 30-180
    }
  ],
  "mindset_prompt": "Motivational message"
}
''';
  }

  /// Parse AI response for custom workout
  WorkoutProtocol _parseCustomWorkoutResponse(
    String response,
    UserProfile profile,
    WorkoutPreferences preferences,
  ) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('No JSON found in response');
      }

      final jsonString = response.substring(jsonStart, jsonEnd + 1);
      final data = jsonDecode(jsonString);

      final entries = <ProtocolEntry>[];

      for (final ex in data['exercises']) {
        final exercise = _matchExercise(
          ex['name'],
          profile: profile,
          workoutType: preferences.trainingFocus.name,
        );

        entries.add(
          ProtocolEntry(
            exercise: exercise,
            sets: ex['sets'] ?? preferences.setsPerExercise,
            reps: int.tryParse(ex['reps'].toString()) ?? 10,
            intensityRpe:
                (ex['rpe'] as num?)?.toDouble() ??
                preferences.targetIntensity.toDouble(),
            restSeconds: ex['rest_seconds'] ?? 60,
          ),
        );
      }

      return WorkoutProtocol(
        title:
            data['title'] ?? 'Custom ${preferences.trainingFocusLabel} Workout',
        subtitle:
            data['subtitle'] ??
            'AI-Personalized (${preferences.intensityLabel} Intensity)',
        tier: _intensityToTier(preferences.targetIntensity),
        entries: entries,
        estimatedDurationMinutes: preferences.targetDurationMinutes,
        mindsetPrompt:
            data['mindset_prompt'] ?? 'Train with purpose and discipline.',
      );
    } catch (e) {
      debugPrint('Error parsing custom workout response: $e');
      return _generateFallbackCustomProtocol(profile, preferences);
    }
  }

  /// Generate fallback protocol when AI is unavailable
  WorkoutProtocol _generateFallbackCustomProtocol(
    UserProfile profile,
    WorkoutPreferences preferences,
  ) {
    final exercises = <ProtocolEntry>[];

    // Select exercises based on preferences
    final candidates = preferences.preferredCategories.isNotEmpty
        ? Exercise.library
              .where(
                (e) => preferences.preferredCategories.contains(e.category),
              )
              .toList()
        : Exercise.library;

    final selected = candidates
        .take(preferences.preferredExerciseCount)
        .toList();

    if (selected.isEmpty) {
      selected.addAll(
        Exercise.library.take(preferences.preferredExerciseCount),
      );
    }

    for (var i = 0; i < selected.length; i++) {
      final exercise = selected[i];

      exercises.add(
        ProtocolEntry(
          exercise: exercise,
          sets: preferences.setsPerExercise,
          reps: preferences.targetIntensity > 7
              ? 6
              : (preferences.targetIntensity < 4 ? 15 : 10),
          intensityRpe: preferences.targetIntensity.toDouble(),
          restSeconds: preferences.targetIntensity > 7 ? 120 : 60,
        ),
      );
    }

    return WorkoutProtocol(
      title:
          '${preferences.trainingFocusLabel} - ${preferences.intensityLabel}',
      subtitle: '${preferences.targetDurationMinutes}min personalized workout',
      tier: _intensityToTier(preferences.targetIntensity),
      entries: exercises,
      estimatedDurationMinutes: preferences.targetDurationMinutes,
      mindsetPrompt: 'Adapt and overcome. This workout is tailored for you.',
    );
  }

  /// Convert intensity level to protocol tier
  ProtocolTier _intensityToTier(int intensity) {
    if (intensity >= 9) return ProtocolTier.elite;
    if (intensity >= 6) return ProtocolTier.ready;
    if (intensity >= 4) return ProtocolTier.fatigued;
    return ProtocolTier.recovery;
  }

  DailyLog _applyReadinessInputToLog(
    DailyLog log,
    SessionReadinessInput? readinessInput,
  ) {
    if (readinessInput == null) {
      return log;
    }

    return DailyLog(
      date: log.date,
      rpeEntries: log.rpeEntries,
      sleepQuality: ((log.sleepQuality + readinessInput.sleepQuality) / 2)
          .round()
          .clamp(1, 10),
      sleepHours: log.sleepHours,
      jointFatigue: log.jointFatigue,
      flowState: log.flowState,
      readinessScore: readinessInput.applyToReadiness(log.readinessScore),
    );
  }

  String _determineRecoveryState(DailyLog log) {
    final avgRpe = log.averageRPE;
    final maxJoint = log.jointFatigue.values.isEmpty
        ? 0
        : log.jointFatigue.values.reduce((a, b) => a > b ? a : b);

    if (log.readinessScore < 45 ||
        log.sleepHours < 6 ||
        log.sleepQuality < 5 ||
        maxJoint >= 8) {
      return 'recovery';
    }
    if (log.readinessScore >= 80 && log.sleepHours >= 7.5 && avgRpe <= 8) {
      return 'high_performance';
    }
    return 'balanced';
  }

  String _determineProgressionDirective(UserProfile profile, DailyLog log) {
    final state = _determineRecoveryState(log);
    if (state == 'recovery') {
      return 'DELOAD: reduce volume 25-35% and keep intensity moderate';
    }

    if (state == 'high_performance' &&
        profile.fitnessLevel != FitnessLevel.beginner) {
      return 'OVERLOAD: add one progression set or 2.5-5% load increase';
    }

    return 'MAINTAIN: keep volume stable and improve movement quality';
  }

  String _recommendWorkoutType(UserProfile profile, String recoveryState) {
    if (recoveryState == 'recovery') {
      return 'Active Recovery';
    }

    switch (profile.trainingGoal) {
      case TrainingGoal.mma:
        return 'MMA Skills & Conditioning';
      case TrainingGoal.boxing:
        return 'Boxing Footwork & Power';
      case TrainingGoal.muayThai:
        return 'Muay Thai Clinch & Striking';
      case TrainingGoal.wrestling:
        return 'Wrestling Takedown Chain';
      case TrainingGoal.bjj:
        return 'BJJ Guard & Control';
      case TrainingGoal.generalCombat:
        return 'Mixed Combat Conditioning';
      case TrainingGoal.strength:
        return 'Strength Progression';
      case TrainingGoal.conditioning:
        return 'Conditioning Intervals';
    }
  }

  List<Exercise> _selectExercisesForRecoveryState(
    List<Exercise> exercises,
    String recoveryState,
  ) {
    if (exercises.isEmpty) return exercises;

    final filtered = exercises.where((exercise) {
      if (recoveryState == 'recovery') {
        return exercise.intensityLevel <= 6 ||
            exercise.category == ExerciseCategory.mobility ||
            exercise.workoutTags.contains('recovery');
      }

      if (recoveryState == 'high_performance') {
        return exercise.intensityLevel >= 7;
      }

      return exercise.intensityLevel >= 5 && exercise.intensityLevel <= 8;
    }).toList();

    if (filtered.isEmpty) {
      return exercises.take(6).toList();
    }

    filtered.sort((a, b) => b.intensityLevel.compareTo(a.intensityLevel));
    return filtered;
  }

  /// Build adjustment prompt when memory system fails
  String _buildAdjustmentPrompt(
    UserProfile profile,
    WeeklyPlan currentPlan,
    WeeklyProgress progress, {
    String? performanceContext,
  }) {
    final perfBlock = performanceContext != null
        ? '''

$performanceContext

'''
        : '';

    return '''
You are an elite combat sports conditioning coach. Based on the athlete's weekly progress, adjust their training plan for the upcoming week.

ATHLETE PROFILE:
- Level: ${profile.fitnessLevelText}
- Goal: ${profile.trainingGoalText}

WEEKLY PROGRESS:
- Completion Rate: ${(progress.completionRate * 100).toStringAsFixed(1)}%
- Average RPE: ${progress.averageRPE}/10
- Workouts Completed: ${progress.workoutsCompleted}/${progress.totalPlannedWorkouts}
- Average Readiness: ${progress.averageReadiness}/100
- Total Volume: ${progress.totalVolume}kg
- Goals Achieved: ${progress.achievedGoals ? 'Yes' : 'No'}
$perfBlock
CURRENT PLAN:
${currentPlan.dailyWorkouts.map((d) => '- ${d.day}: ${d.workoutType} - ${d.focus}').join('\n')}

INSTRUCTIONS:
1. Adjust the intensity and volume based on performance
2. Modify exercises if needed to address weaknesses
3. Ensure proper recovery between intense sessions
4. Keep the same structure (days per week)
5. Use per-exercise history to apply progressive overload where appropriate
6. Reduce volume on exercises showing high RPE trends

RESPONSE FORMAT:
Return a JSON object with the same structure as before:
{
  "week_plan": [
    {
      "day": "Monday",
      "workout_type": "Strength/Power",
      "focus": "Updated focus",
      "exercises": [...]
    }
  ],
  "weekly_notes": "Adjustment rationale",
  "intensity_recommendation": "Updated intensity guidance"
}
''';
  }

  /// Generate training plan with thinking model and thought summaries (for debugging)
  Future<Map<String, dynamic>> generatePlanWithThinking(
    UserProfile profile,
  ) async {
    if (!isInitialized) {
      debugPrint('AI Plan Service not initialized');
      return {'plan': null, 'thoughts': null, 'error': 'Not initialized'};
    }

    try {
      // Fetch recent performance analytics for personalization
      final performanceContext = await buildPerformanceContext();

      final prompt = _buildBasicPrompt(
        profile,
        performanceContext: performanceContext,
      );

      debugPrint('Generating plan with thinking model...');

      final result = await _geminiClient.generateContentWithThoughts(
        prompt,
        maxRetries: AIConfig.maxRetries,
        delay: AIConfig.baseDelay,
        includeThoughts: AIConfig.includeThoughts,
      );

      if (result.text != null) {
        final plan = _parseAIResponseToPlan(result.text!, profile);

        return {
          'plan': plan,
          'thoughts': result.thoughtSummary,
          'hasThoughts': result.hasThoughts,
          'error': null,
        };
      }
    } catch (e) {
      debugPrint('Error generating plan with thinking: $e');
      return {'plan': null, 'thoughts': null, 'error': e.toString()};
    }

    return {'plan': null, 'thoughts': null, 'error': 'Failed to generate plan'};
  }

  /// Parse Gemini AI response into WeeklyPlan
  WeeklyPlan _parseAIResponseToPlan(String response, UserProfile profile) {
    try {
      // Try to extract JSON from the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('No JSON found in response');
      }

      final jsonString = response.substring(jsonStart, jsonEnd + 1);
      final data = jsonDecode(jsonString);

      final weekPlan = <DailyWorkout>[];

      for (final dayData in data['week_plan']) {
        final entries = <ProtocolEntry>[];

        for (final ex in dayData['exercises']) {
          // Match exercise from library or create custom
          final exercise = _matchExercise(
            ex['name'],
            profile: profile,
            workoutType: dayData['workout_type']?.toString(),
          );

          entries.add(
            ProtocolEntry(
              exercise: exercise,
              sets: ex['sets'] ?? 3,
              reps: int.tryParse(ex['reps'].toString()) ?? 10,
              intensityRpe: (ex['rpe'] as num?)?.toDouble() ?? 7.0,
              restSeconds: ex['rest'] ?? 120,
            ),
          );
        }

        weekPlan.add(
          DailyWorkout(
            day: _getDayOfWeek(dayData['day']),
            workoutType: dayData['workout_type'] ?? 'Training',
            focus: dayData['focus'] ?? '',
            protocol: WorkoutProtocol(
              title:
                  '${dayData['workout_type'] ?? 'Training'} - ${dayData['focus'] ?? ''}',
              subtitle: 'AI-generated workout',
              tier: ProtocolTier.ready,
              entries: entries,
              estimatedDurationMinutes:
                  int.tryParse(dayData['duration'].toString()) ?? 60,
              mindsetPrompt: 'Focus on perfect form and controlled movement',
            ),
          ),
        );
      }

      return WeeklyPlan(
        weekStarting: DateTime.now(),
        dailyWorkouts: weekPlan,
        weeklyNotes: data['weekly_notes'] ?? '',
        intensityRecommendation: data['intensity_recommendation'] ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing Gemini response: $e');
      debugPrint('Response: $response');
      return _generateFallbackPlan(profile);
    }
  }

  /// Get today's workout protocol - either from weekly plan or generate on-demand
  /// Returns a fully populated WorkoutProtocol with exercises, sets, reps, rest periods
  Future<WorkoutProtocol?> getTodaysProtocol({
    required UserProfile profile,
    WeeklyPlan? existingWeeklyPlan,
    SessionReadinessInput? readinessInput,
  }) async {
    final today = _getDayOfWeek(_getDayName(DateTime.now().weekday - 1));

    // Option 1: Use existing weekly plan if available
    if (existingWeeklyPlan != null) {
      final todaysWorkout = existingWeeklyPlan.dailyWorkouts
          .where((d) => d.day.toLowerCase() == today.toLowerCase())
          .firstOrNull;

      if (todaysWorkout != null) {
        debugPrint(
          'Loading workout from weekly plan: ${todaysWorkout.protocol.title}',
        );
        return todaysWorkout.protocol;
      }
    }

    // Option 2: Generate on-demand using AI
    debugPrint(
      'No weekly plan found for $today, generating AI workout on-demand',
    );

    // Create default preferences based on profile
    final now = DateTime.now();
    final preferences = WorkoutPreferences(
      userId: profile.userId,
      targetIntensity: readinessInput != null
          ? (readinessInput.applyToReadiness(70) / 10).round().clamp(3, 10)
          : 7,
      targetDurationMinutes: profile.preferredWorkoutDuration ?? 45,
      trainingFocus: _mapGoalToTrainingFocus(profile.trainingGoal),
      preferredCategories: _getCategoriesForGoal(profile.trainingGoal),
      preferredExerciseCount: 4,
      setsPerExercise: 3,
      createdAt: now,
      updatedAt: now,
    );

    // Try AI generation first
    if (_initialized) {
      final aiProtocol = await generateCustomProtocol(profile, preferences);
      if (aiProtocol != null) {
        debugPrint(
          'AI generated workout: ${aiProtocol.title} with ${aiProtocol.entries.length} exercises',
        );
        return aiProtocol;
      }
    }

    // Fallback: Generate template protocol
    debugPrint('Using fallback template workout');
    return _generateFallbackCustomProtocol(profile, preferences);
  }

  /// Map training goal to training focus
  TrainingFocus _mapGoalToTrainingFocus(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.mma:
      case TrainingGoal.boxing:
      case TrainingGoal.muayThai:
        return TrainingFocus.power;
      case TrainingGoal.wrestling:
      case TrainingGoal.bjj:
        return TrainingFocus.strength;
      case TrainingGoal.strength:
        return TrainingFocus.strength;
      case TrainingGoal.conditioning:
        return TrainingFocus.conditioning;
      case TrainingGoal.generalCombat:
        return TrainingFocus.mixed;
    }
  }

  /// Get exercise categories based on training goal
  List<ExerciseCategory> _getCategoriesForGoal(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.mma:
      case TrainingGoal.boxing:
      case TrainingGoal.muayThai:
        return [
          ExerciseCategory.strength,
          ExerciseCategory.combat,
          ExerciseCategory.plyometric,
        ];
      case TrainingGoal.wrestling:
      case TrainingGoal.bjj:
        return [
          ExerciseCategory.strength,
          ExerciseCategory.isometric,
          ExerciseCategory.combat,
        ];
      case TrainingGoal.strength:
        return [ExerciseCategory.strength, ExerciseCategory.plyometric];
      case TrainingGoal.conditioning:
        return [ExerciseCategory.plyometric, ExerciseCategory.sprint];
      case TrainingGoal.generalCombat:
        return [
          ExerciseCategory.strength,
          ExerciseCategory.combat,
          ExerciseCategory.mobility,
        ];
    }
  }

  Exercise _matchExercise(
    String name, {
    required UserProfile profile,
    String? workoutType,
  }) {
    // Try to find matching exercise in library
    final normalizedName = name.toLowerCase();
    final userLibrary = Exercise.forUserProfile(
      profile,
      workoutType: workoutType,
      limit: 200,
    );

    for (final exercise in userLibrary) {
      if (normalizedName.contains(exercise.name.toLowerCase())) {
        return exercise;
      }
    }

    // Return generic exercise if not found
    return Exercise(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: ExerciseCategory.strength,
      youtubeId: '',
      targetMetaphor: name,
      instructions: 'Perform with proper form',
      intensityLevel: 5,
      primaryMuscles: const ['full_body'],
      jointStress: {},
      idealGoals: [profile.trainingGoal],
      minFitnessLevel: profile.fitnessLevel,
      maxFitnessLevel: FitnessLevel.advanced,
      workoutTags: workoutType != null ? [workoutType.toLowerCase()] : const [],
    );
  }

  /// Convert day string to standard format
  String _getDayOfWeek(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'monday':
        return 'Monday';
      case 'tuesday':
        return 'Tuesday';
      case 'wednesday':
        return 'Wednesday';
      case 'thursday':
        return 'Thursday';
      case 'friday':
        return 'Friday';
      case 'saturday':
        return 'Saturday';
      case 'sunday':
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  /// Generate fallback plan when AI is unavailable
  WeeklyPlan _generateFallbackPlan(UserProfile profile) {
    // Create a basic template plan based on level and goal
    final weekPlan = <DailyWorkout>[];

    final workoutTypes = _getWorkoutTypesForGoal(profile.trainingGoal);

    for (int i = 0; i < profile.trainingDaysPerWeek; i++) {
      final dayName = _getDayName(i);
      final workoutType = workoutTypes[i % workoutTypes.length];

      weekPlan.add(
        DailyWorkout(
          day: dayName,
          workoutType: workoutType,
          focus: '${profile.trainingGoalText} - $workoutType',
          protocol: _generateFallbackProtocol(profile, workoutType),
        ),
      );
    }

    return WeeklyPlan(
      weekStarting: DateTime.now(),
      dailyWorkouts: weekPlan,
      weeklyNotes: 'Generated template plan. AI customization unavailable.',
      intensityRecommendation: 'Train at RPE 7-8, focus on technique',
    );
  }

  /// Generate fallback protocol
  WorkoutProtocol _generateFallbackProtocol(UserProfile profile, String type) {
    final userLibrary = Exercise.forUserProfile(
      profile,
      workoutType: type,
      limit: 40,
    );
    final exercises = <ProtocolEntry>[];

    final selected = userLibrary.take(4).toList();

    if (selected.isEmpty) {
      selected.addAll(Exercise.library.take(3));
    }

    for (var i = 0; i < selected.length; i++) {
      final exercise = selected[i];
      final isConditioning = type.toLowerCase().contains('conditioning');
      final baseSets = isConditioning ? 4 : 3;
      final baseReps = isConditioning ? 12 : 8;
      final levelAdjustment = profile.fitnessLevel == FitnessLevel.beginner
          ? 0
          : 2;

      exercises.add(
        ProtocolEntry(
          exercise: exercise,
          sets: baseSets + (i % 2),
          reps: baseReps + levelAdjustment,
          intensityRpe: (exercise.intensityLevel / 1.2).clamp(5, 9).toDouble(),
          restSeconds: isConditioning ? 45 + (i * 10) : 90 + (i * 15),
        ),
      );
    }

    return WorkoutProtocol(
      title: '${profile.trainingGoalText} - $type',
      subtitle: 'Template workout for ${profile.fitnessLevelText} level',
      tier: ProtocolTier.ready,
      entries: exercises,
      estimatedDurationMinutes: 45,
      mindsetPrompt: 'Train with discipline',
    );
  }

  /// Generate fallback adjustment
  WeeklyPlan _generateFallbackAdjustment(
    UserProfile profile,
    WeeklyPlan currentPlan,
    WeeklyProgress progress,
  ) {
    if (progress.shouldIncreaseDifficulty) {
      // Add more volume or intensity
      return _generateFallbackPlan(
        profile.copyWith(
          fitnessLevel: profile.fitnessLevel == FitnessLevel.beginner
              ? FitnessLevel.intermediate
              : FitnessLevel.advanced,
        ),
      );
    } else if (progress.shouldDecreaseDifficulty) {
      // Reduce volume
      return _generateFallbackPlan(profile);
    }

    return currentPlan;
  }

  /// Get workout types based on training goal
  List<String> _getWorkoutTypesForGoal(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.mma:
      case TrainingGoal.boxing:
      case TrainingGoal.muayThai:
        return [
          'Striking Technique',
          'Strength & Power',
          'Conditioning',
          'Skills & Drills',
          'Active Recovery',
        ];
      case TrainingGoal.wrestling:
      case TrainingGoal.bjj:
        return [
          'Grappling Strength',
          'Technique Work',
          'Conditioning',
          'Mobility',
          'Active Recovery',
        ];
      case TrainingGoal.strength:
        return [
          'Upper Body Strength',
          'Lower Body Power',
          'Core & Stability',
          'Active Recovery',
        ];
      case TrainingGoal.conditioning:
      case TrainingGoal.generalCombat:
        return [
          'Strength Training',
          'HIIT Conditioning',
          'Technique',
          'Active Recovery',
          'Endurance',
        ];
    }
  }

  String _getDayName(int index) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[index % 7];
  }

  // ============ MEMORY MANAGEMENT HELPERS ============

  /// Store completed workout in AI memory
  Future<void> storeWorkoutInMemory(
    String userId,
    CompletedWorkout workout,
  ) async {
    if (!_initialized) return;

    try {
      await _memoryService.storeMemory(
        userId: userId,
        type: AIMemoryType.workoutHistory,
        priority: MemoryPriority.high,
        data: workout.toMap(),
        summary:
            '${workout.protocolTitle}: ${workout.totalDurationMinutes}min, ${workout.exercises.length} exercises',
        tags: ['workout', 'completed'],
      );
      debugPrint('Workout stored in AI memory: ${workout.id}');
    } catch (e) {
      debugPrint('Error storing workout in memory: $e');
    }
  }

  /// Store readiness score in AI memory
  Future<void> storeReadinessInMemory(
    String userId,
    int readinessScore, {
    Map<String, dynamic>? additionalMetrics,
  }) async {
    if (!_initialized) return;

    try {
      await _memoryService.storeMemory(
        userId: userId,
        type: AIMemoryType.readiness,
        priority: MemoryPriority.medium,
        data: {
          'score': readinessScore,
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalMetrics,
        },
        summary: 'Readiness: $readinessScore/100',
        tags: ['readiness', 'daily'],
      );
    } catch (e) {
      debugPrint('Error storing readiness in memory: $e');
    }
  }

  /// Store health metrics in AI memory
  Future<void> storeHealthMetricsInMemory(
    String userId, {
    int? hrv,
    int? sleepScore,
    double? weight,
    Map<String, dynamic>? otherMetrics,
  }) async {
    if (!_initialized) return;

    try {
      final data = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        if (hrv != null) 'hrv': hrv,
        if (sleepScore != null) 'sleepScore': sleepScore,
        if (weight != null) 'weight': weight,
        ...?otherMetrics,
      };

      String summary = 'Health metrics';
      if (hrv != null) summary += ' - HRV: $hrv';
      if (sleepScore != null) summary += ' - Sleep: $sleepScore';

      await _memoryService.storeMemory(
        userId: userId,
        type: AIMemoryType.healthMetrics,
        priority: MemoryPriority.medium,
        data: data,
        summary: summary,
        tags: ['health', 'metrics'],
      );
    } catch (e) {
      debugPrint('Error storing health metrics in memory: $e');
    }
  }

  /// Store user feedback in AI memory
  Future<void> storeFeedbackInMemory(
    String userId,
    String feedback, {
    String? category,
  }) async {
    if (!_initialized) return;

    try {
      await _memoryService.storeMemory(
        userId: userId,
        type: AIMemoryType.feedback,
        priority: MemoryPriority.medium,
        data: {
          'feedback': feedback,
          'category': category ?? 'general',
          'timestamp': DateTime.now().toIso8601String(),
        },
        summary:
            'Feedback: ${feedback.substring(0, feedback.length > 100 ? 100 : feedback.length)}...',
        tags: ['feedback', category ?? 'general'],
      );
    } catch (e) {
      debugPrint('Error storing feedback in memory: $e');
    }
  }

  /// Get memory statistics
  Future<Map<String, dynamic>> getMemoryStats(String userId) async {
    return await _memoryService.getMemoryStats(userId);
  }

  /// Cleanup expired memories
  Future<int> cleanupExpiredMemories(String userId) async {
    return await _memoryService.cleanupExpiredMemories(userId);
  }

  /// Query relevant context for a specific need
  Future<List<AIMemoryEntry>> queryRelevantContext(
    String userId,
    String query,
  ) async {
    return await _contextService.queryRelevantContext(
      userId: userId,
      query: query,
    );
  }
}
