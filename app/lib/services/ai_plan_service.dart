import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_profile.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';
import '../models/exercise.dart';

/// AI Plan Service using Gemini 2.5 Flash for intelligent training plans
class AIPlanService {
  static final AIPlanService _instance = AIPlanService._internal();
  factory AIPlanService() => _instance;
  AIPlanService._internal();

  // Gemini 2.5 Flash API Key
  static const String _apiKey = 'AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk';

  late GenerativeModel _model;
  bool _initialized = false;

  /// Initialize the service with Gemini 2.5 Flash
  Future<void> initialize() async {
    try {
      _model = GenerativeModel(model: 'gemini-2.0-flash-exp', apiKey: _apiKey);
      _initialized = true;
      debugPrint('AI Plan Service initialized with Gemini 2.0 Flash');
    } catch (e) {
      debugPrint('Failed to initialize AI service: $e');
      _initialized = false;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Generate initial training plan based on user profile using Gemini AI
  Future<WeeklyPlan> generateInitialTrainingPlan(UserProfile profile) async {
    if (!_initialized) {
      debugPrint('AI not initialized, using fallback plan generation');
      return _generateFallbackPlan(profile);
    }

    try {
      final prompt = _buildInitialPlanPrompt(profile);

      final response = await _model.generateContent([Content.text(prompt)]);

      final planText = response.text;
      debugPrint('Gemini Response: $planText');

      // Parse the AI response into a WeeklyPlan
      return _parseAIResponseToPlan(planText!, profile);
    } catch (e) {
      debugPrint('Error generating AI plan: $e');
      return _generateFallbackPlan(profile);
    }
  }

  /// Adjust training plan based on weekly progress
  Future<WeeklyPlan> adjustPlanBasedOnProgress(
    UserProfile profile,
    WeeklyPlan currentPlan,
    WeeklyProgress progress,
  ) async {
    if (!isInitialized) {
      return _generateFallbackAdjustment(profile, currentPlan, progress);
    }

    try {
      final content = jsonEncode({
        'user_profile': profile.toMap(),
        'current_plan': currentPlan.toMap(),
        'progress': progress.toMap(),
        'request': 'Adjust the training plan based on progress',
      });

      debugPrint('AI Plan Request: $content');

      // Simplified: Use fallback adjustment
      return _generateFallbackAdjustment(profile, currentPlan, progress);
    } catch (e) {
      debugPrint('Error adjusting AI plan: $e');
      return _generateFallbackAdjustment(profile, currentPlan, progress);
    }
  }

  /// Get AI recommendations for specific workout adjustments
  Future<String> getWorkoutRecommendations(
    UserProfile profile,
    DailyLog recentLogs,
  ) async {
    if (!isInitialized) {
      return 'AI recommendations not available. Continue with current plan.';
    }

    try {
      final prompt =
          '''
You are an elite combat sports conditioning coach. Based on the user's recent training data, provide specific recommendations for their next workout.

User Profile:
- Level: ${profile.fitnessLevelText}
- Goal: ${profile.trainingGoalText}
- Training days/week: ${profile.trainingDaysPerWeek}

Recent Training Data:
- Readiness Score: ${recentLogs.readinessScore}/100
- Sleep Quality: ${recentLogs.sleepQuality}/10
- Sleep Hours: ${recentLogs.sleepHours}
- Joint Fatigue: ${recentLogs.jointFatigue}
- RPE Entries: ${recentLogs.rpeEntries}

Provide 2-3 specific recommendations for the next workout. Be concise and actionable. Focus on intensity, exercise selection, and recovery considerations.
''';

      // Simplified: Return static recommendation
      return prompt;
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return 'Continue with current plan based on your readiness score.';
    }
  }

  /// Build prompt for initial plan generation using Gemini
  String _buildInitialPlanPrompt(UserProfile profile) {
    return '''
You are an elite combat sports conditioning coach and strength trainer. Create a detailed weekly training plan for a ${profile.fitnessLevelText} level athlete training for ${profile.trainingGoalText}.

ATHLETE PROFILE:
- Name: ${profile.displayName ?? 'Athlete'}
- Age: ${profile.bodyComposition.age}
- Weight: ${profile.bodyComposition.weight}kg
- Height: ${profile.bodyComposition.height}cm
- BMI: ${profile.bodyComposition.bmi.toStringAsFixed(1)}
- Body Fat: ${profile.bodyComposition.bodyFatPercentage?.toStringAsFixed(1) ?? 'unknown'}%
- Gender: ${profile.bodyComposition.gender ?? 'not specified'}

TRAINING PARAMETERS:
- Level: ${profile.fitnessLevelText}
- Goal: ${profile.trainingGoalText}
- Days per week: ${profile.trainingDaysPerWeek}
- Session duration: ${profile.preferredWorkoutDuration} minutes
${profile.injuriesOrLimitations != null ? '- Injuries/Limitations: ${profile.injuriesOrLimitations!.join(', ')}' : ''}

INSTRUCTIONS:
1. Create a ${profile.trainingDaysPerWeek}-day weekly split focusing on ${profile.trainingGoalText}
2. Include strength training, conditioning, and skill work appropriate for the level
3. Each workout should be ${profile.preferredWorkoutDuration} minutes
4. Consider any injuries/limitations when selecting exercises
5. Balance intensity across the week (hard days followed by lighter/recovery days)
6. Include specific exercises, sets, reps, and RPE targets

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
          "rest_seconds": 180,
          "notes": "Focus on explosive concentric"
        }
      ]
    }
  ],
  "weekly_notes": "Overall progression strategy for the week",
  "intensity_recommendation": "Based on athlete level and goals"
}

Ensure the JSON is valid and contains all required fields. Use realistic exercises appropriate for combat sports training.
''';
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
          final exercise = _matchExercise(ex['name']);

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

  /// Match exercise name to library
  Exercise _matchExercise(String name) {
    // Try to find matching exercise in library
    final normalizedName = name.toLowerCase();

    for (final exercise in Exercise.library) {
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
      primaryMuscles: ['Full Body'],
      jointStress: {},
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
    final exercises = <ProtocolEntry>[];

    // Add basic exercises based on workout type
    if (type.contains('Strength')) {
      exercises.addAll([
        ProtocolEntry(
          exercise: Exercise.library.firstWhere(
            (e) => e.name == 'Squat',
            orElse: () => Exercise.library.first,
          ),
          sets: 4,
          reps: profile.fitnessLevel == FitnessLevel.beginner ? 8 : 5,
          intensityRpe: 7.5,
          restSeconds: 180,
        ),
        ProtocolEntry(
          exercise: Exercise.library.firstWhere(
            (e) => e.name == 'Push Ups',
            orElse: () => Exercise.library.first,
          ),
          sets: 3,
          reps: profile.fitnessLevel == FitnessLevel.beginner ? 10 : 15,
          intensityRpe: 7,
          restSeconds: 90,
        ),
      ]);
    } else if (type.contains('Conditioning')) {
      exercises.addAll([
        ProtocolEntry(
          exercise: Exercise.library.firstWhere(
            (e) => e.name == 'Burpees',
            orElse: () => Exercise.library.first,
          ),
          sets: 5,
          reps: 10,
          intensityRpe: 8,
          restSeconds: 60,
        ),
        ProtocolEntry(
          exercise: Exercise.library.firstWhere(
            (e) => e.name == 'Mountain Climbers',
            orElse: () => Exercise.library.first,
          ),
          sets: 4,
          reps: 20,
          intensityRpe: 7,
          restSeconds: 45,
        ),
      ]);
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
}

/// Weekly plan structure
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
