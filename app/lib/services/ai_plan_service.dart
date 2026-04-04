import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_profile.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';
import '../models/exercise.dart';

/// AI Plan Service using Gemini for generating and adjusting training plans
class AIPlanService {
  static final AIPlanService _instance = AIPlanService._internal();
  factory AIPlanService() => _instance;
  AIPlanService._internal();

  GenerativeModel? _model;
  bool _initialized = false;

  // Gemini API Key - In production, this should be stored securely
  // For now, we'll use a placeholder that users need to replace
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  /// Initialize the Gemini model
  void initialize() {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      debugPrint('WARNING: Gemini API key not set. AI features will be disabled.');
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        ),
      );
      _initialized = true;
      debugPrint('AI Plan Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AI Plan Service: $e');
    }
  }

  /// Check if AI service is available
  bool get isAvailable => _initialized && _model != null;

  /// Generate initial training plan based on user profile
  Future<WeeklyPlan> generateInitialTrainingPlan(UserProfile profile) async {
    if (!isAvailable) {
      debugPrint('AI not available, using fallback plan generation');
      return _generateFallbackPlan(profile);
    }

    try {
      final prompt = _buildInitialPlanPrompt(profile);
      
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Parse the JSON response
      final plan = _parseAIResponse(responseText, profile);
      return plan;
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
    if (!isAvailable) {
      return _generateFallbackAdjustment(profile, currentPlan, progress);
    }

    try {
      final prompt = _buildAdjustmentPrompt(profile, currentPlan, progress);
      
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from AI');
      }

      return _parseAIResponse(responseText, profile);
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
    if (!isAvailable) {
      return 'AI recommendations not available. Continue with current plan.';
    }

    try {
      final prompt = '''
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
      
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      return response.text ?? 'No recommendations available.';
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return 'Continue with current plan based on your readiness score.';
    }
  }

  /// Build prompt for initial plan generation
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
''';  }

  /// Build prompt for plan adjustment
  String _buildAdjustmentPrompt(
    UserProfile profile,
    WeeklyPlan currentPlan,
    WeeklyProgress progress,
  ) {
    return '''
You are an elite combat sports conditioning coach. Review the athlete's progress and adjust their training plan for next week.

CURRENT PROFILE:
- Level: ${profile.fitnessLevelText}
- Goal: ${profile.trainingGoalText}

LAST WEEK'S RESULTS:
- Workouts Completed: ${progress.workoutsCompleted}/${progress.totalPlannedWorkouts}
- Completion Rate: ${(progress.completionRate * 100).toStringAsFixed(0)}%
- Average RPE: ${progress.averageRPE.toStringAsFixed(1)}
- Average Readiness: ${progress.averageReadiness}/100
- Total Volume: ${progress.totalVolume.toStringAsFixed(0)}kg
${progress.userFeedback != null ? '- User Feedback: ${progress.userFeedback}' : ''}

ADJUSTMENT GUIDELINES:
${progress.shouldIncreaseDifficulty 
  ? '- Athlete is progressing well - INCREASE difficulty: add volume or intensity' 
  : progress.shouldDecreaseDifficulty
    ? '- Athlete is struggling - DECREASE difficulty: reduce volume, focus on recovery'
    : '- Maintain current intensity with minor adjustments'}

Create an adjusted weekly plan for next week. Consider:
1. Progression based on last week's performance
2. Recovery needs based on readiness scores
3. User feedback if provided
4. Injury prevention and balanced programming

Use the same JSON format as before.
''';  }

  /// Parse AI response into WeeklyPlan
  WeeklyPlan _parseAIResponse(String response, UserProfile profile) {
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
          
          entries.add(ProtocolEntry(
            exercise: exercise,
            sets: ex['sets'],
            reps: int.tryParse(ex['reps'].toString()) ?? 0,
            intensityRpe: (ex['rpe'] as num).toDouble(),
            restSeconds: ex['rest_seconds'],
            notes: ex['notes'],
          ));
        }
        
        weekPlan.add(DailyWorkout(
          day: dayData['day'],
          workoutType: dayData['workout_type'],
          focus: dayData['focus'],
          protocol: WorkoutProtocol(
            title: '${dayData['day']} - ${dayData['workout_type']}',
            description: dayData['focus'],
            entries: entries,
            difficulty: _mapLevelToDifficulty(profile.fitnessLevel),
          ),
        ));
      }
      
      return WeeklyPlan(
        weekStarting: DateTime.now(),
        dailyWorkouts: weekPlan,
        weeklyNotes: data['weekly_notes'] ?? '',
        intensityRecommendation: data['intensity_recommendation'] ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
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
      primaryMuscles: ['Full Body'],
      jointStressMap: {},
    );
  }

  /// Generate fallback plan when AI is unavailable
  WeeklyPlan _generateFallbackPlan(UserProfile profile) {
    // Create a basic template plan based on level and goal
    final weekPlan = <DailyWorkout>[];
    
    final workoutTypes = _getWorkoutTypesForGoal(profile.trainingGoal);
    
    for (int i = 0; i < profile.trainingDaysPerWeek; i++) {
      final dayName = _getDayName(i);
      final workoutType = workoutTypes[i % workoutTypes.length];
      
      weekPlan.add(DailyWorkout(
        day: dayName,
        workoutType: workoutType,
        focus: '${profile.trainingGoalText} - $workoutType',
        protocol: _generateFallbackProtocol(profile, workoutType),
      ));
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
          exercise: Exercise.library.firstWhere((e) => e.name == 'Squat', orElse: () => Exercise.library.first),
          sets: 4,
          reps: profile.fitnessLevel == FitnessLevel.beginner ? 8 : 5,
          intensityRpe: 7.5,
          restSeconds: 180,
        ),
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.name == 'Push Ups', orElse: () => Exercise.library.first),
          sets: 3,
          reps: profile.fitnessLevel == FitnessLevel.beginner ? 10 : 15,
          intensityRpe: 7,
          restSeconds: 90,
        ),
      ]);
    } else if (type.contains('Conditioning')) {
      exercises.addAll([
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.name == 'Burpees', orElse: () => Exercise.library.first),
          sets: 5,
          reps: 10,
          intensityRpe: 8,
          restSeconds: 60,
        ),
        ProtocolEntry(
          exercise: Exercise.library.firstWhere((e) => e.name == 'Mountain Climbers', orElse: () => Exercise.library.first),
          sets: 4,
          reps: 20,
          intensityRpe: 7,
          restSeconds: 45,
        ),
      ]);
    }
    
    return WorkoutProtocol(
      title: '${profile.trainingGoalText} - $type',
      description: 'Template workout for ${profile.fitnessLevelText} level',
      entries: exercises,
      difficulty: _mapLevelToDifficulty(profile.fitnessLevel),
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
      return _generateFallbackPlan(profile.copyWith(
        fitnessLevel: profile.fitnessLevel == FitnessLevel.beginner 
            ? FitnessLevel.intermediate 
            : FitnessLevel.advanced,
      ));
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
        return ['Striking Technique', 'Strength & Power', 'Conditioning', 'Skills & Drills', 'Active Recovery'];
      case TrainingGoal.wrestling:
      case TrainingGoal.bjj:
        return ['Grappling Strength', 'Technique Work', 'Conditioning', 'Mobility', 'Active Recovery'];
      case TrainingGoal.strength:
        return ['Upper Body Strength', 'Lower Body Power', 'Core & Stability', 'Active Recovery'];
      case TrainingGoal.conditioning:
      case TrainingGoal.generalCombat:
      default:
        return ['Strength Training', 'HIIT Conditioning', 'Technique', 'Active Recovery', 'Endurance'];
    }
  }

  String _getDayName(int index) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[index % 7];
  }

  int _mapLevelToDifficulty(FitnessLevel level) {
    switch (level) {
      case FitnessLevel.beginner:
        return 1;
      case FitnessLevel.intermediate:
        return 2;
      case FitnessLevel.advanced:
        return 3;
    }
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
      'description': description,
      'difficulty': difficulty,
      'entries': entries.map((e) => {
        'exercise_name': e.exercise.name,
        'sets': e.sets,
        'reps': e.reps,
        'rpe': e.intensityRpe,
        'rest_seconds': e.restSeconds,
        'notes': e.notes,
      }).toList(),
    };
  }
}
