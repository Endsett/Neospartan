/// AI Smart Workout Service
/// Hybrid AI-powered workout generation using the expanded exercise library
/// Combines library-based selection with AI customization

library ai_smart_workout_service;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/sport_category.dart' hide ExerciseCategory;
import '../models/user_profile.dart';
import '../models/workout_tracking.dart';
import '../models/workout_preferences.dart';
import '../models/workout_template.dart';
import '../models/workout_protocol.dart';
import '../models/ai_memory.dart';
import '../data/combat_exercise_library.dart';
import '../config/ai_config.dart';
import 'gemini_client.dart';
import 'ai_memory_service.dart';

/// Generated workout with AI reasoning
class GeneratedWorkout {
  final String id;
  final String name;
  final String description;
  final SportCategory sportFocus;
  final DateTime generatedAt;
  final WorkoutProtocol protocol;
  final List<GeneratedExercise> exercises;
  final int totalDurationMinutes;
  final int targetIntensity;
  final String aiReasoning;
  final Map<String, dynamic> generationContext;
  final double aiConfidenceScore;

  const GeneratedWorkout({
    required this.id,
    required this.name,
    required this.description,
    required this.sportFocus,
    required this.generatedAt,
    required this.protocol,
    required this.exercises,
    required this.totalDurationMinutes,
    required this.targetIntensity,
    required this.aiReasoning,
    required this.generationContext,
    required this.aiConfidenceScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sport_focus': sportFocus.name,
      'generated_at': generatedAt.toIso8601String(),
      'protocol': protocol.toMap(),
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'total_duration_minutes': totalDurationMinutes,
      'target_intensity': targetIntensity,
      'ai_reasoning': aiReasoning,
      'generation_context': generationContext,
      'ai_confidence_score': aiConfidenceScore,
    };
  }
}

/// Exercise with AI-customized parameters
class GeneratedExercise {
  final CombatExercise exercise;
  final int sets;
  final String reps;
  final int targetRpe;
  final int restSeconds;
  final String? aiNotes;
  final bool isCustomVariation;
  final String? customInstructions;

  const GeneratedExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.targetRpe,
    required this.restSeconds,
    this.aiNotes,
    this.isCustomVariation = false,
    this.customInstructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'exercise_id': exercise.id,
      'exercise_name': exercise.name,
      'sets': sets,
      'reps': reps,
      'target_rpe': targetRpe,
      'rest_seconds': restSeconds,
      'ai_notes': aiNotes,
      'is_custom_variation': isCustomVariation,
      'custom_instructions': customInstructions,
    };
  }
}

/// AI Smart Workout Service
class AISmartWorkoutService {
  static final AISmartWorkoutService _instance =
      AISmartWorkoutService._internal();
  factory AISmartWorkoutService() => _instance;
  AISmartWorkoutService._internal();

  final GeminiClient _geminiClient = GeminiClient();
  final AIMemoryService _memoryService = AIMemoryService();
  bool _initialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      await _geminiClient.initialize();
      _initialized = true;
      debugPrint('AI Smart Workout Service initialized');
    } catch (e) {
      debugPrint('Failed to initialize AI Smart Workout Service: $e');
      _initialized = false;
    }
  }

  bool get isInitialized => _initialized;

  // ============================================================================
  // HYBRID WORKOUT GENERATION
  // ============================================================================

  /// Generate a workout using hybrid approach (library + AI)
  Future<GeneratedWorkout?> generateWorkout({
    required UserProfile profile,
    required WorkoutPreferences preferences,
    required PerformanceContext context,
    WorkoutTemplate? template,
    DateTime? scheduledDate,
  }) async {
    if (!_initialized) {
      debugPrint('AI Smart Workout Service not initialized');
      return _generateFallbackWorkout(profile, preferences, template);
    }

    try {
      // Step 1: Get candidate exercises from library
      final candidateExercises = _selectCandidateExercises(
        profile: profile,
        preferences: preferences,
        context: context,
      );

      // Step 2: Build AI prompt with context
      final prompt = _buildGenerationPrompt(
        profile: profile,
        preferences: preferences,
        context: context,
        candidateExercises: candidateExercises,
        template: template,
      );

      // Step 3: Get AI response
      final aiResponse = await _geminiClient.generateContent(
        prompt,
        maxRetries: AIConfig.maxRetries,
        delay: AIConfig.baseDelay,
      );

      if (aiResponse == null) {
        return _generateFallbackWorkout(profile, preferences, template);
      }

      // Step 4: Parse AI response and generate workout
      final generatedWorkout = _parseAIResponse(
        aiResponse: aiResponse,
        profile: profile,
        preferences: preferences,
        candidateExercises: candidateExercises,
        template: template,
      );

      // Step 5: Store in memory for learning
      await _storeWorkoutMemory(generatedWorkout, profile);

      return generatedWorkout;
    } catch (e) {
      debugPrint('Error generating workout: $e');
      return _generateFallbackWorkout(profile, preferences, template);
    }
  }

  /// Generate workout from template with AI customization
  Future<GeneratedWorkout?> generateFromTemplate({
    required WorkoutTemplate template,
    required UserProfile profile,
    required WorkoutPreferences preferences,
    required PerformanceContext context,
  }) async {
    // Select exercises for each slot in the template
    final generatedExercises = <GeneratedExercise>[];
    var totalDurationMinutes = 0;
    var totalIntensity = 0;
    var exerciseCount = 0;

    for (final block in template.blocks) {
      for (final slot in block.exerciseSlots) {
        // Find best matching exercise from library
        final exercise = _findExerciseForSlot(
          slot: slot,
          profile: profile,
          preferences: preferences,
          context: context,
          usedExercises: generatedExercises.map((e) => e.exercise.id).toList(),
        );

        if (exercise != null) {
          // AI-adjust parameters based on context
          final adjustedParams = _aiAdjustParameters(
            exercise: exercise,
            slot: slot,
            context: context,
            preferences: preferences,
          );

          generatedExercises.add(
            GeneratedExercise(
              exercise: exercise,
              sets: adjustedParams.sets,
              reps: adjustedParams.reps,
              targetRpe: adjustedParams.rpe,
              restSeconds: adjustedParams.restSeconds,
              aiNotes: adjustedParams.notes,
            ),
          );

          totalDurationMinutes +=
              (exercise.estimatedDurationSeconds * adjustedParams.sets) ~/ 60;
          totalIntensity += exercise.intensityLevel;
          exerciseCount++;
        }
      }
    }

    if (generatedExercises.isEmpty) {
      return _generateFallbackWorkout(profile, preferences, template);
    }

    final avgIntensity = exerciseCount > 0
        ? totalIntensity ~/ exerciseCount
        : 5;

    return GeneratedWorkout(
      id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
      name: template.name,
      description: template.description,
      sportFocus: template.primarySport,
      generatedAt: DateTime.now(),
      protocol: _buildProtocolFromExercises(generatedExercises, template.name),
      exercises: generatedExercises,
      totalDurationMinutes: totalDurationMinutes,
      targetIntensity: avgIntensity,
      aiReasoning:
          'Template-based generation with ${generatedExercises.length} exercises',
      generationContext: {
        'template_id': template.id,
        'user_fitness_level': profile.fitnessLevel.name,
        'performance_readiness': context.predictedReadiness,
      },
      aiConfidenceScore: 0.85,
    );
  }

  /// Create custom exercise variation using AI
  Future<CombatExercise?> generateExerciseVariation({
    required CombatExercise baseExercise,
    required VariationIntent intent,
    required UserProfile profile,
    String? specificConstraint,
  }) async {
    if (!_initialized) return null;

    try {
      final prompt = _buildVariationPrompt(
        baseExercise: baseExercise,
        intent: intent,
        profile: profile,
        constraint: specificConstraint,
      );

      final response = await _geminiClient.generateContent(prompt);
      if (response == null) return null;

      return _parseExerciseVariation(response, baseExercise, intent);
    } catch (e) {
      debugPrint('Error generating exercise variation: $e');
      return null;
    }
  }

  /// Adapt existing workout based on new context
  Future<GeneratedWorkout?> adaptWorkout({
    required GeneratedWorkout originalWorkout,
    required PerformanceContext newContext,
    UserProfile? profile,
  }) async {
    if (!_initialized) return originalWorkout;

    try {
      // Check if adaptation is needed
      if (newContext.predictedReadiness >= 70 &&
          newContext.performanceFlags.isEmpty) {
        return originalWorkout;
      }

      // Build adaptation prompt
      final prompt = _buildAdaptationPrompt(
        originalWorkout: originalWorkout,
        newContext: newContext,
        profile: profile,
      );

      final response = await _geminiClient.generateContent(prompt);
      if (response == null) return originalWorkout;

      return _parseAdaptationResponse(response, originalWorkout, newContext);
    } catch (e) {
      debugPrint('Error adapting workout: $e');
      return originalWorkout;
    }
  }

  // ============================================================================
  // INTERNAL METHODS
  // ============================================================================

  /// Select candidate exercises from library
  List<CombatExercise> _selectCandidateExercises({
    required UserProfile profile,
    required WorkoutPreferences preferences,
    required PerformanceContext context,
  }) {
    // Start with exercises for the sport focus
    var candidates = preferences.sportFocus != null
        ? CombatExerciseLibrary.bySport(preferences.sportFocus!)
        : CombatExerciseLibrary.exercises;

    // Filter by equipment
    if (preferences.availableEquipment.isNotEmpty) {
      candidates = candidates
          .where(
            (e) =>
                e.equipment.isEmpty ||
                e.equipment.any(
                  (eq) => preferences.availableEquipment.contains(eq),
                ),
          )
          .toList();
    }

    // Filter by intensity based on context
    final targetIntensity =
        preferences.desiredIntensity ?? context.recommendedIntensity;
    candidates = candidates
        .where(
          (e) =>
              e.intensityLevel >= targetIntensity - 2 &&
              e.intensityLevel <= targetIntensity + 2,
        )
        .toList();

    // Filter out exercises for under-recovered muscles
    if (context.underRecoveredMuscles.isNotEmpty) {
      candidates = candidates.where((e) {
        return !e.primaryMuscles.any(
          (m) => context.underRecoveredMuscles.contains(m),
        );
      }).toList();
    }

    // Filter out exercises that conflict with injuries
    if (preferences.injuriesToAvoid.isNotEmpty) {
      candidates = candidates.where((e) {
        return !preferences.injuriesToAvoid.any((injury) {
          return e.primaryMuscles.any(
                (m) => m.toLowerCase().contains(injury.toLowerCase()),
              ) ||
              e.jointStress.keys.any(
                (j) => j.toLowerCase().contains(injury.toLowerCase()),
              );
        });
      }).toList();
    }

    // Filter by fitness level
    candidates = candidates
        .where(
          (e) =>
              profile.fitnessLevel.index >= e.minFitnessLevel.index &&
              profile.fitnessLevel.index <= e.maxFitnessLevel.index,
        )
        .toList();

    // Sort by relevance (sport-specific first, then by intensity match)
    candidates.sort((a, b) {
      final aSportMatch =
          preferences.sportFocus != null &&
              a.sports.contains(preferences.sportFocus)
          ? 1
          : 0;
      final bSportMatch =
          preferences.sportFocus != null &&
              b.sports.contains(preferences.sportFocus)
          ? 1
          : 0;

      if (aSportMatch != bSportMatch) return bSportMatch - aSportMatch;

      final aIntensityDiff = (a.intensityLevel - targetIntensity).abs();
      final bIntensityDiff = (b.intensityLevel - targetIntensity).abs();
      return aIntensityDiff - bIntensityDiff;
    });

    return candidates.take(50).toList();
  }

  /// Find best exercise for a template slot
  CombatExercise? _findExerciseForSlot({
    required ExerciseSlot slot,
    required UserProfile profile,
    required WorkoutPreferences preferences,
    required PerformanceContext context,
    required List<String> usedExercises,
  }) {
    // Get candidates for this slot
    var candidates = CombatExerciseLibrary.exercises.where((e) {
      // Skip already used exercises
      if (usedExercises.contains(e.id)) {
        return false;
      }

      // Check if fits slot
      if (!slot.fitsExercise(e)) {
        return false;
      }

      // Check fitness level
      if (profile.fitnessLevel.index < e.minFitnessLevel.index ||
          profile.fitnessLevel.index > e.maxFitnessLevel.index) {
        return false;
      }

      // Check equipment
      if (preferences.availableEquipment.isNotEmpty &&
          e.equipment.isNotEmpty &&
          !e.equipment.any(
            (eq) => preferences.availableEquipment.contains(eq),
          )) {
        return false;
      }

      return true;
    }).toList();

    if (candidates.isEmpty) return null;

    // Score candidates
    final scored = candidates.map((e) {
      var score = 0;

      // Sport match bonus
      if (preferences.sportFocus != null &&
          e.sports.contains(preferences.sportFocus!)) {
        score += 10;
      }

      // Intensity match
      final targetIntensity =
          preferences.desiredIntensity ?? context.recommendedIntensity;
      score += 10 - (e.intensityLevel - targetIntensity).abs();

      // Prefer sport-specific exercises
      if (e.isSportSpecific) score += 5;

      // Avoid exercises for under-recovered muscles
      if (e.primaryMuscles.any(
        (m) => context.underRecoveredMuscles.contains(m),
      )) {
        score -= 20;
      }

      return (exercise: e, score: score);
    }).toList();

    scored.sort((a, b) => b.score - a.score);
    return scored.first.exercise;
  }

  /// AI-adjust exercise parameters
  AdjustedParams _aiAdjustParameters({
    required CombatExercise exercise,
    required ExerciseSlot slot,
    required PerformanceContext context,
    required WorkoutPreferences preferences,
  }) {
    var sets = slot.targetSets;
    var reps = slot.targetReps;
    var rpe = slot.targetRpe;
    var restSeconds = slot.restSeconds;
    String? notes;

    // Adjust based on readiness
    if (context.predictedReadiness < 50) {
      sets = (sets * 0.7).round().clamp(1, sets);
      rpe = (rpe - 1).clamp(4, 9);
      restSeconds += 30;
      notes = 'Reduced volume due to low readiness';
    } else if (context.predictedReadiness > 85) {
      sets = (sets * 1.2).round().clamp(sets, sets + 2);
      rpe = (rpe + 1).clamp(6, 10);
      notes = 'Increased volume - high readiness detected';
    }

    // Adjust for training phase
    switch (preferences.phase) {
      case TrainingPhase.preCompetition:
        rpe = (rpe + 1).clamp(7, 10);
        restSeconds += 30;
        break;
      case TrainingPhase.competition:
        sets = (sets * 0.8).round().clamp(2, sets);
        rpe = (rpe - 1).clamp(5, 8);
        break;
      case TrainingPhase.transition:
        sets = (sets * 0.6).round().clamp(1, sets);
        rpe = (rpe - 2).clamp(4, 7);
        restSeconds -= 15;
        break;
      default:
        break;
    }

    return AdjustedParams(
      sets: sets,
      reps: reps,
      rpe: rpe,
      restSeconds: restSeconds,
      notes: notes,
    );
  }

  /// Build protocol from generated exercises
  WorkoutProtocol _buildProtocolFromExercises(
    List<GeneratedExercise> exercises,
    String workoutName,
  ) {
    final entries = exercises.map((ge) {
      return ProtocolEntry(
        exercise: ge.exercise.toLegacyExercise(),
        sets: ge.sets,
        reps: int.tryParse(ge.reps) ?? 10,
        intensityRpe: ge.targetRpe.toDouble(),
        restSeconds: ge.restSeconds,
      );
    }).toList();

    return WorkoutProtocol(
      title: workoutName,
      subtitle: 'AI-generated workout',
      tier: ProtocolTier.ready,
      entries: entries,
      estimatedDurationMinutes: exercises.fold<int>(
        0,
        (sum, ge) =>
            sum +
            (ge.exercise.estimatedDurationSeconds * ge.sets) ~/ 60 +
            ge.restSeconds * (ge.sets - 1) ~/ 60,
      ),
      mindsetPrompt: 'Train with purpose and precision',
    );
  }

  // ============================================================================
  // PROMPT BUILDING
  // ============================================================================

  String _buildGenerationPrompt({
    required UserProfile profile,
    required WorkoutPreferences preferences,
    required PerformanceContext context,
    required List<CombatExercise> candidateExercises,
    WorkoutTemplate? template,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      'You are an elite combat sports conditioning coach. Generate a workout from the provided exercise library.',
    );
    buffer.writeln();
    buffer.writeln('ATHLETE PROFILE:');
    buffer.writeln('- Name: ${profile.displayName ?? 'Athlete'}');
    buffer.writeln('- Fitness Level: ${profile.fitnessLevel.name}');
    buffer.writeln('- Training Goal: ${profile.trainingGoal.name}');
    buffer.writeln(
      '- Sport Focus: ${preferences.sportFocus?.displayName ?? 'General Combat'}',
    );
    buffer.writeln(
      '- Available Time: ${preferences.availableTime.inMinutes} minutes',
    );
    buffer.writeln('- Training Phase: ${preferences.phase.name}');
    buffer.writeln();

    buffer.writeln('PERFORMANCE CONTEXT:');
    buffer.writeln(
      '- Predicted Readiness: ${context.predictedReadiness.toStringAsFixed(0)}/100',
    );
    buffer.writeln(
      '- Recommended Intensity: ${context.recommendedIntensity}/10',
    );
    buffer.writeln('- Days Since Rest: ${context.daysSinceRest}');
    buffer.writeln('- Load Trend: ${context.loadTrend.name}');
    buffer.writeln(
      '- Under-recovered Muscles: ${context.underRecoveredMuscles.join(', ')}}',
    );
    if (context.performanceFlags.isNotEmpty) {
      buffer.writeln('- Flags: ${context.performanceFlags.join(', ')}');
    }
    buffer.writeln();

    if (template != null) {
      buffer.writeln('WORKOUT TEMPLATE: ${template.name}');
      buffer.writeln('Blocks:');
      for (final block in template.blocks) {
        buffer.writeln('- ${block.name}: ${block.exerciseCount} exercises');
      }
      buffer.writeln();
    }

    buffer.writeln('AVAILABLE EXERCISES (select from these):');
    for (final exercise in candidateExercises.take(20)) {
      buffer.writeln(
        '- ${exercise.id}: ${exercise.name} [${exercise.category.name}, Intensity: ${exercise.intensityLevel}/10]',
      );
    }
    buffer.writeln();

    buffer.writeln('RESPONSE FORMAT:');
    buffer.writeln('Return JSON with:');
    buffer.writeln('{');
    buffer.writeln('  "workout_name": "Creative name for the workout",');
    buffer.writeln('  "description": "Brief description",');
    buffer.writeln('  "exercises": [');
    buffer.writeln('    {');
    buffer.writeln('      "exercise_id": "id from library",');
    buffer.writeln('      "sets": number,');
    buffer.writeln('      "reps": "string like 8-12 or 30s",');
    buffer.writeln('      "rpe": 7,');
    buffer.writeln('      "rest_seconds": 60,');
    buffer.writeln('      "notes": "optional coaching notes"');
    buffer.writeln('    }');
    buffer.writeln('  ],');
    buffer.writeln(
      '  "reasoning": "Explain your exercise selection and parameter choices"',
    );
    buffer.writeln('}');

    return buffer.toString();
  }

  String _buildVariationPrompt({
    required CombatExercise baseExercise,
    required VariationIntent intent,
    required UserProfile profile,
    String? constraint,
  }) {
    return '''
Create an exercise variation based on:

BASE EXERCISE:
- Name: ${baseExercise.name}
- Category: ${baseExercise.category.name}
- Intensity: ${baseExercise.intensityLevel}/10
- Patterns: ${baseExercise.movementPatterns.map((p) => p.displayName).join(', ')}

VARIATION INTENT: ${intent.name}
${constraint != null ? 'CONSTRAINT: $constraint' : ''}

ATHLETE LEVEL: ${profile.fitnessLevel.name}

Return JSON with the new exercise details following the same structure as base exercise.
''';
  }

  String _buildAdaptationPrompt({
    required GeneratedWorkout originalWorkout,
    required PerformanceContext newContext,
    UserProfile? profile,
  }) {
    return '''
Adapt this workout based on new performance context:

ORIGINAL WORKOUT: ${originalWorkout.name}
Exercises: ${originalWorkout.exercises.length}
Target Intensity: ${originalWorkout.targetIntensity}/10

NEW CONTEXT:
- Readiness: ${newContext.predictedReadiness.toStringAsFixed(0)}/100
- Flags: ${newContext.performanceFlags.join(', ')}}
- Recommended Intensity: ${newContext.recommendedIntensity}/10

Provide JSON with adjustments:
{
  "adjustments": [
    {"exercise_index": 0, "new_sets": 3, "new_rpe": 7, "reason": "explanation"}
  ],
  "substitutions": [
    {"original_index": 1, "new_exercise_id": "replacement_id", "reason": "explanation"}
  ],
  "reasoning": "overall adaptation reasoning"
}
''';
  }

  // ============================================================================
  // PARSING
  // ============================================================================

  GeneratedWorkout _parseAIResponse({
    required String aiResponse,
    required UserProfile profile,
    required WorkoutPreferences preferences,
    required List<CombatExercise> candidateExercises,
    WorkoutTemplate? template,
  }) {
    try {
      // Extract JSON from response
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('No JSON found in AI response');
      }

      final jsonString = aiResponse.substring(jsonStart, jsonEnd + 1);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse exercises
      final exercises = <GeneratedExercise>[];
      for (final exData in data['exercises'] as List<dynamic>) {
        final exerciseId = exData['exercise_id'] as String;
        final exercise = candidateExercises.firstWhere(
          (e) => e.id == exerciseId,
          orElse: () => candidateExercises.first,
        );

        exercises.add(
          GeneratedExercise(
            exercise: exercise,
            sets: exData['sets'] as int? ?? 3,
            reps: exData['reps'] as String? ?? '10',
            targetRpe: exData['rpe'] as int? ?? 7,
            restSeconds: exData['rest_seconds'] as int? ?? 60,
            aiNotes: exData['notes'] as String?,
          ),
        );
      }

      // Calculate metrics
      final totalDuration =
          exercises.fold<int>(
            0,
            (sum, ge) =>
                sum +
                ge.exercise.estimatedDurationSeconds * ge.sets +
                ge.restSeconds * (ge.sets - 1),
          ) ~/
          60;

      final avgIntensity = exercises.isNotEmpty
          ? exercises
                    .map((e) => e.exercise.intensityLevel)
                    .reduce((a, b) => a + b) ~/
                exercises.length
          : 5;

      return GeneratedWorkout(
        id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
        name:
            data['workout_name'] as String? ??
            template?.name ??
            'Generated Workout',
        description:
            data['description'] as String? ?? template?.description ?? '',
        sportFocus:
            preferences.sportFocus ??
            template?.primarySport ??
            SportCategory.generalCombat,
        generatedAt: DateTime.now(),
        protocol: _buildProtocolFromExercises(
          exercises,
          data['workout_name'] as String? ?? 'Workout',
        ),
        exercises: exercises,
        totalDurationMinutes: totalDuration,
        targetIntensity: avgIntensity,
        aiReasoning: data['reasoning'] as String? ?? 'AI-generated workout',
        generationContext: {
          'template_used': template?.id,
          'user_fitness_level': profile.fitnessLevel.name,
          'exercise_count': exercises.length,
        },
        aiConfidenceScore: 0.90,
      );
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
      return _generateFallbackWorkout(profile, preferences, template);
    }
  }

  CombatExercise? _parseExerciseVariation(
    String response,
    CombatExercise baseExercise,
    VariationIntent intent,
  ) {
    // Implementation would parse exercise variation from AI response
    // Return modified exercise or null
    return null;
  }

  GeneratedWorkout _parseAdaptationResponse(
    String response,
    GeneratedWorkout original,
    PerformanceContext context,
  ) {
    // Implementation would parse adaptation adjustments from AI response
    // Return modified workout
    return original;
  }

  // ============================================================================
  // FALLBACK
  // ============================================================================

  GeneratedWorkout _generateFallbackWorkout(
    UserProfile profile,
    WorkoutPreferences preferences,
    WorkoutTemplate? template,
  ) {
    // Use template if provided, otherwise select based on preferences
    final selectedTemplate = template ?? CombatWorkoutTemplates.mmaConditioning;

    return GeneratedWorkout(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      name: '${selectedTemplate.name} (Template)',
      description: 'Template-based workout (AI unavailable)',
      sportFocus: selectedTemplate.primarySport,
      generatedAt: DateTime.now(),
      protocol: WorkoutProtocol(
        title: selectedTemplate.name,
        subtitle: 'Template fallback',
        tier: ProtocolTier.ready,
        entries: [],
        estimatedDurationMinutes: selectedTemplate.targetDuration.inMinutes,
        mindsetPrompt: 'Focus on quality execution',
      ),
      exercises: [],
      totalDurationMinutes: selectedTemplate.targetDuration.inMinutes,
      targetIntensity: 6,
      aiReasoning: 'Template fallback - AI service unavailable',
      generationContext: {'fallback': true, 'template_id': selectedTemplate.id},
      aiConfidenceScore: 0.50,
    );
  }

  // ============================================================================
  // MEMORY
  // ============================================================================

  Future<void> _storeWorkoutMemory(
    GeneratedWorkout workout,
    UserProfile profile,
  ) async {
    try {
      await _memoryService.storeMemory(
        userId: profile.userId,
        type: AIMemoryType.workoutHistory,
        priority: MemoryPriority.high,
        data: workout.toMap(),
        tags: ['workout', 'generated', workout.sportFocus.shortName],
        summary:
            'Generated ${workout.name} with ${workout.exercises.length} exercises',
      );
    } catch (e) {
      debugPrint('Failed to store workout memory: $e');
    }
  }
}

/// Intent for exercise variation
enum VariationIntent {
  makeEasier,
  makeHarder,
  sportSpecific,
  equipmentSwap,
  rehabFriendly,
}

/// Adjusted exercise parameters
class AdjustedParams {
  final int sets;
  final String reps;
  final int rpe;
  final int restSeconds;
  final String? notes;

  AdjustedParams({
    required this.sets,
    required this.reps,
    required this.rpe,
    required this.restSeconds,
    this.notes,
  });
}
