import 'dart:convert';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_tracking.dart';
import '../models/user_profile.dart';
import 'gemini_client.dart';

/// Service for managing workout feedback and AI analysis
class WorkoutFeedbackService {
  static final WorkoutFeedbackService _instance =
      WorkoutFeedbackService._internal();
  factory WorkoutFeedbackService() => _instance;
  WorkoutFeedbackService._internal();

  final GeminiClient _geminiClient = GeminiClient();
  SharedPreferences? _prefs;
  bool _initialized = false;

  // Storage keys
  static const String _feedbackKey = 'workout_feedback_v2';
  static const String _aiInsightsKey = 'workout_ai_insights_v2';

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    developer.log(
      'WorkoutFeedbackService initialized',
      name: 'WorkoutFeedback',
    );
  }

  /// Analyze completed workout and generate AI feedback
  Future<WorkoutFeedback> analyzeWorkout({
    required CompletedWorkout workout,
    required UserProfile userProfile,
    required Map<String, dynamic> workoutPlan,
  }) async {
    await initialize();

    try {
      // Prepare workout data for AI analysis
      final workoutData = _prepareWorkoutData(
        workout,
        userProfile,
        workoutPlan,
      );

      // Get AI analysis
      final aiResponse = await _getAIAnalysis(workoutData);

      // Create feedback object
      final feedback = WorkoutFeedback(
        id: 'feedback_${DateTime.now().millisecondsSinceEpoch}',
        workoutId: workout.id,
        userId: userProfile.userId,
        analysisDate: DateTime.now(),
        overallPerformance: aiResponse['overallPerformance'] ?? 'Good',
        performanceScore: (aiResponse['performanceScore'] ?? 7.5).toDouble(),
        strengths: List<String>.from(aiResponse['strengths'] ?? []),
        improvements: List<String>.from(aiResponse['improvements'] ?? []),
        nextWorkoutAdjustments: Map<String, dynamic>.from(
          aiResponse['nextWorkoutAdjustments'] ?? {},
        ),
        progressiveOverloadSuggestions: List<Map<String, dynamic>>.from(
          aiResponse['progressiveOverloadSuggestions'] ?? [],
        ),
        injuryRiskWarnings: List<String>.from(
          aiResponse['injuryRiskWarnings'] ?? [],
        ),
        motivationalMessage: aiResponse['motivationalMessage'] ?? 'Great job!',
        aiReasoning: aiResponse['reasoning'] ?? '',
        confidenceScore: (aiResponse['confidenceScore'] ?? 0.8).toDouble(),
      );

      // Store feedback locally
      await _storeFeedbackLocally(feedback);

      // Store in Supabase
      await _storeFeedbackInSupabase(feedback);

      // Store as AI memory for future reference
      await _storeAsAIMemory(feedback, workout, userProfile);

      developer.log(
        'Workout analysis completed for workout ${workout.id}',
        name: 'WorkoutFeedback',
      );

      return feedback;
    } catch (e) {
      developer.log(
        'Error analyzing workout: $e',
        name: 'WorkoutFeedback',
        level: 1000,
      );

      // Return default feedback on error
      return WorkoutFeedback(
        id: 'feedback_${DateTime.now().millisecondsSinceEpoch}',
        workoutId: workout.id,
        userId: userProfile.userId,
        analysisDate: DateTime.now(),
        overallPerformance: 'Completed',
        performanceScore: 7.0,
        strengths: ['Workout completed'],
        improvements: ['Continue consistent training'],
        nextWorkoutAdjustments: {},
        progressiveOverloadSuggestions: [],
        injuryRiskWarnings: [],
        motivationalMessage: 'Good work completing your workout!',
        aiReasoning: 'Default feedback due to analysis error',
        confidenceScore: 0.5,
      );
    }
  }

  /// Get feedback for a specific workout
  Future<WorkoutFeedback?> getFeedbackForWorkout(String workoutId) async {
    await initialize();

    // Try local storage first
    final localFeedback = await _getFeedbackLocally(workoutId);
    if (localFeedback != null) return localFeedback;

    // Try Supabase
    return await _getFeedbackFromSupabase(workoutId);
  }

  /// Get all feedback for a user
  Future<List<WorkoutFeedback>> getAllUserFeedback(String userId) async {
    await initialize();

    try {
      final response = await Supabase.instance.client
          .from('ai_memories')
          .select()
          .eq('user_id', userId)
          .eq('type', 'workout_feedback')
          .order('created_at', ascending: false);

      return response
          .map((row) => WorkoutFeedback.fromSupabaseRow(row))
          .toList();
    } catch (e) {
      developer.log(
        'Error fetching user feedback: $e',
        name: 'WorkoutFeedback',
      );
      return [];
    }
  }

  /// Get performance trends over time
  Future<Map<String, dynamic>> getPerformanceTrends(String userId) async {
    await initialize();

    final feedbacks = await getAllUserFeedback(userId);

    if (feedbacks.isEmpty) {
      return {
        'trend': 'insufficient_data',
        'averageScore': 0.0,
        'improvementAreas': <String>[],
        'strengthAreas': <String>[],
      };
    }

    // Analyze trends
    final scores = feedbacks.map((f) => f.performanceScore).toList();
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;

    // Get most common improvements and strengths
    final improvements = <String, int>{};
    final strengths = <String, int>{};

    for (final feedback in feedbacks) {
      for (final improvement in feedback.improvements) {
        improvements[improvement] = (improvements[improvement] ?? 0) + 1;
      }
      for (final strength in feedback.strengths) {
        strengths[strength] = (strengths[strength] ?? 0) + 1;
      }
    }

    // Determine trend
    String trend = 'stable';
    if (scores.length >= 4) {
      final recent =
          scores.sublist(0, scores.length ~/ 2).reduce((a, b) => a + b) /
          (scores.length ~/ 2);
      final older =
          scores.sublist(scores.length ~/ 2).reduce((a, b) => a + b) /
          (scores.length ~/ 2);

      if (recent > older + 0.5) {
        trend = 'improving';
      } else if (recent < older - 0.5) {
        trend = 'declining';
      }
    }

    return {
      'trend': trend,
      'averageScore': averageScore,
      'improvementAreas': improvements.entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .toList(),
      'strengthAreas': strengths.entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .toList(),
    };
  }

  /// Generate next workout adjustments based on feedback history
  Future<Map<String, dynamic>> generateNextWorkoutAdjustments(
    String userId,
    String sportFocus,
  ) async {
    await initialize();

    final feedbacks = await getAllUserFeedback(userId);
    final trends = await getPerformanceTrends(userId);

    final adjustments = <String, dynamic>{};

    // Adjust intensity based on trend
    if (trends['trend'] == 'improving') {
      adjustments['intensityModifier'] = 1.1; // Increase by 10%
    } else if (trends['trend'] == 'declining') {
      adjustments['intensityModifier'] = 0.9; // Decrease by 10%
    } else {
      adjustments['intensityModifier'] = 1.0; // Maintain
    }

    // Adjust volume based on average performance score
    final avgScore = trends['averageScore'] as double;
    if (avgScore > 8.0) {
      adjustments['volumeModifier'] = 1.1; // Increase volume
    } else if (avgScore < 6.0) {
      adjustments['volumeModifier'] = 0.9; // Decrease volume
    } else {
      adjustments['volumeModifier'] = 1.0; // Maintain
    }

    // Add focus areas based on common improvements
    final improvementAreas = trends['improvementAreas'] as List<String>;
    if (improvementAreas.isNotEmpty) {
      adjustments['focusAreas'] = improvementAreas.take(3).toList();
    }

    // Add exercise substitutions based on warnings
    final warnings = feedbacks
        .expand((f) => f.injuryRiskWarnings)
        .where(
          (w) =>
              w.contains('shoulder') ||
              w.contains('knee') ||
              w.contains('back'),
        )
        .toList();

    if (warnings.isNotEmpty) {
      adjustments['substitutionSuggestions'] = warnings;
    }

    return adjustments;
  }

  Map<String, dynamic> _prepareWorkoutData(
    CompletedWorkout workout,
    UserProfile profile,
    Map<String, dynamic> workoutPlan,
  ) {
    return {
      'workout': {
        'id': workout.id,
        'workoutType': workout.protocolTitle ?? 'Unknown',
        'duration': workout.totalDurationMinutes,
        'exercises': workout.exercises
            .map(
              (e) => {
                'name': e.exercise.name,
                'sets': e.sets.length,
                'totalReps': e.sets.fold(
                  0,
                  (sum, s) => sum + (s.repsPerformed ?? 0),
                ),
                'totalVolume': e.sets.fold(
                  0.0,
                  (sum, s) =>
                      sum + (s.loadUsed ?? 0.0) * (s.repsPerformed ?? 0),
                ),
                'averageRPE': e.sets.isEmpty
                    ? 0.0
                    : e.sets
                              .where((s) => s.actualRPE != null)
                              .map((s) => s.actualRPE!)
                              .reduce((a, b) => a + b) /
                          e.sets.where((s) => s.actualRPE != null).length,
              },
            )
            .toList(),
        'averageRPE': workout.averageRPE,
        'totalVolume': workout.totalVolume,
        'readinessScore': workout.readinessScoreAtStart,
      },
      'user': {
        'id': profile.userId,
        'fitnessLevel': profile.fitnessLevel?.name ?? 'intermediate',
        'trainingGoal': profile.trainingGoal,
        'experienceLevel': profile.experienceLevel,
        'injuries': profile.injuriesOrLimitations,
      },
      'plan': workoutPlan,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _getAIAnalysis(
    Map<String, dynamic> workoutData,
  ) async {
    final prompt =
        '''
    Analyze this workout performance and provide detailed feedback:
    
    ${jsonEncode(workoutData)}
    
    Provide feedback in the following JSON format:
    {
      "overallPerformance": "Excellent/Good/Average/Poor",
      "performanceScore": 7.5,
      "strengths": ["list of what went well"],
      "improvements": ["list of areas to improve"],
      "nextWorkoutAdjustments": {
        "intensity": "increase/decrease/maintain",
        "volume": "increase/decrease/maintain",
        "exerciseChanges": ["specific exercise recommendations"]
      },
      "progressiveOverloadSuggestions": [
        {"exercise": "name", "suggestion": "increase weight by 2.5kg"}
      ],
      "injuryRiskWarnings": ["any potential concerns"],
      "motivationalMessage": "encouraging message",
      "reasoning": "detailed analysis reasoning",
      "confidenceScore": 0.85
    }
    ''';

    try {
      final response = await _geminiClient.generateContent(prompt);
      if (response == null) {
        throw Exception('Failed to generate AI feedback');
      }
      final jsonMatch = RegExp(r'\{.*\}').firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }
    } catch (e) {
      developer.log('AI analysis error: $e', name: 'WorkoutFeedback');
    }

    // Return default response on error
    return {
      'overallPerformance': 'Good',
      'performanceScore': 7.0,
      'strengths': ['Workout completed'],
      'improvements': ['Continue consistent training'],
      'nextWorkoutAdjustments': {
        'intensity': 'maintain',
        'volume': 'maintain',
        'exerciseChanges': [],
      },
      'progressiveOverloadSuggestions': [],
      'injuryRiskWarnings': [],
      'motivationalMessage': 'Good work completing your workout!',
      'reasoning': 'Unable to generate detailed analysis',
      'confidenceScore': 0.5,
    };
  }

  Future<void> _storeFeedbackLocally(WorkoutFeedback feedback) async {
    await initialize();

    final feedbacks = await _getAllLocalFeedback();
    feedbacks.add(feedback);

    // Keep only last 50 feedbacks locally
    if (feedbacks.length > 50) {
      feedbacks.removeRange(0, feedbacks.length - 50);
    }

    await _prefs?.setString(
      _feedbackKey,
      jsonEncode(feedbacks.map((f) => f.toMap()).toList()),
    );
  }

  Future<WorkoutFeedback?> _getFeedbackLocally(String workoutId) async {
    await initialize();

    final feedbacks = await _getAllLocalFeedback();
    try {
      return feedbacks.firstWhere((f) => f.workoutId == workoutId);
    } catch (e) {
      return null;
    }
  }

  Future<List<WorkoutFeedback>> _getAllLocalFeedback() async {
    await initialize();

    final json = _prefs?.getString(_feedbackKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((f) => WorkoutFeedback.fromMap(f)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _storeFeedbackInSupabase(WorkoutFeedback feedback) async {
    try {
      await Supabase.instance.client.from('ai_memories').insert({
        'user_id': feedback.userId,
        'type': 'workout_feedback',
        'priority': 'medium',
        'data': feedback.toMap(),
        'summary': 'Workout feedback for ${feedback.workoutId}',
        'tags': ['workout', 'feedback', 'performance'],
        'expires_at': DateTime.now()
            .add(const Duration(days: 365))
            .toIso8601String(),
      });
    } catch (e) {
      developer.log(
        'Error storing feedback in Supabase: $e',
        name: 'WorkoutFeedback',
      );
    }
  }

  Future<WorkoutFeedback?> _getFeedbackFromSupabase(String workoutId) async {
    try {
      final response = await Supabase.instance.client
          .from('ai_memories')
          .select()
          .eq('type', 'workout_feedback')
          .like('data', '%"workoutId":"$workoutId"%')
          .maybeSingle();

      if (response != null) {
        return WorkoutFeedback.fromSupabaseRow(response);
      }
    } catch (e) {
      developer.log(
        'Error fetching feedback from Supabase: $e',
        name: 'WorkoutFeedback',
      );
    }

    return null;
  }

  Future<void> _storeAsAIMemory(
    WorkoutFeedback feedback,
    CompletedWorkout workout,
    UserProfile profile,
  ) async {
    try {
      // Store workout performance as memory
      await Supabase.instance.client.from('ai_memories').insert({
        'user_id': profile.userId,
        'type': 'workout_performance',
        'priority': 'high',
        'data': {
          'workoutId': workout.id,
          'performanceScore': feedback.performanceScore,
          'totalVolume': workout.totalVolume,
          'averageRPE': workout.averageRPE,
          'duration': workout.totalDurationMinutes,
          'exerciseCount': workout.exercises.length,
        },
        'summary':
            'Performance: ${workout.protocolTitle} - Score: ${feedback.performanceScore}',
        'tags': ['workout', 'performance', workout.protocolTitle.toLowerCase()],
        'expires_at': DateTime.now()
            .add(const Duration(days: 730))
            .toIso8601String(),
      });
    } catch (e) {
      developer.log('Error storing AI memory: $e', name: 'WorkoutFeedback');
    }
  }
}

/// Workout feedback model
class WorkoutFeedback {
  final String id;
  final String workoutId;
  final String userId;
  final DateTime analysisDate;
  final String overallPerformance;
  final double performanceScore;
  final List<String> strengths;
  final List<String> improvements;
  final Map<String, dynamic> nextWorkoutAdjustments;
  final List<Map<String, dynamic>> progressiveOverloadSuggestions;
  final List<String> injuryRiskWarnings;
  final String motivationalMessage;
  final String aiReasoning;
  final double confidenceScore;

  const WorkoutFeedback({
    required this.id,
    required this.workoutId,
    required this.userId,
    required this.analysisDate,
    required this.overallPerformance,
    required this.performanceScore,
    required this.strengths,
    required this.improvements,
    required this.nextWorkoutAdjustments,
    required this.progressiveOverloadSuggestions,
    required this.injuryRiskWarnings,
    required this.motivationalMessage,
    required this.aiReasoning,
    required this.confidenceScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'userId': userId,
      'analysisDate': analysisDate.toIso8601String(),
      'overallPerformance': overallPerformance,
      'performanceScore': performanceScore,
      'strengths': strengths,
      'improvements': improvements,
      'nextWorkoutAdjustments': nextWorkoutAdjustments,
      'progressiveOverloadSuggestions': progressiveOverloadSuggestions,
      'injuryRiskWarnings': injuryRiskWarnings,
      'motivationalMessage': motivationalMessage,
      'aiReasoning': aiReasoning,
      'confidenceScore': confidenceScore,
    };
  }

  factory WorkoutFeedback.fromMap(Map<String, dynamic> map) {
    return WorkoutFeedback(
      id: map['id'] ?? '',
      workoutId: map['workoutId'] ?? '',
      userId: map['userId'] ?? '',
      analysisDate: DateTime.parse(
        map['analysisDate'] ?? DateTime.now().toIso8601String(),
      ),
      overallPerformance: map['overallPerformance'] ?? '',
      performanceScore: (map['performanceScore'] ?? 0.0).toDouble(),
      strengths: List<String>.from(map['strengths'] ?? []),
      improvements: List<String>.from(map['improvements'] ?? []),
      nextWorkoutAdjustments: Map<String, dynamic>.from(
        map['nextWorkoutAdjustments'] ?? {},
      ),
      progressiveOverloadSuggestions: List<Map<String, dynamic>>.from(
        map['progressiveOverloadSuggestions'] ?? [],
      ),
      injuryRiskWarnings: List<String>.from(map['injuryRiskWarnings'] ?? []),
      motivationalMessage: map['motivationalMessage'] ?? '',
      aiReasoning: map['aiReasoning'] ?? '',
      confidenceScore: (map['confidenceScore'] ?? 0.0).toDouble(),
    );
  }

  factory WorkoutFeedback.fromSupabaseRow(Map<String, dynamic> row) {
    final data = row['data'] as Map<String, dynamic>;
    return WorkoutFeedback.fromMap(data);
  }
}
