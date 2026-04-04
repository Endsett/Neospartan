import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/workout_protocol.dart';

/// Backend API Client for NeoSpartan DOM-RL Engine
/// Connects to Python FastAPI server for AI recommendations
class BackendApiService {
  static final BackendApiService _instance = BackendApiService._internal();
  factory BackendApiService() => _instance;
  BackendApiService._internal();

  // Default to localhost for development
  // In production, this would be your deployed API URL
  String _baseUrl = 'http://localhost:8000';
  
  bool _isSimulated = true; // Default to simulated responses

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  void toggleSimulation(bool value) {
    _isSimulated = value;
  }

  // ============ EXERCISE LIBRARY ============

  Future<List<Exercise>> getExercises({ExerciseCategory? category}) async {
    if (_isSimulated) {
      return _getSimulatedExercises(category);
    }

    try {
      final url = category != null 
          ? '$_baseUrl/exercises?category=${category.name}'
          : '$_baseUrl/exercises';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => _exerciseFromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Backend API error: $e');
    }
    return _getSimulatedExercises(category);
  }

  Future<Exercise?> getExercise(String id) async {
    if (_isSimulated) {
      return Exercise.library.firstWhere(
        (e) => e.id == id,
        orElse: () => Exercise.library.first,
      );
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl/exercises/$id'));
      if (response.statusCode == 200) {
        return _exerciseFromJson(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Backend API error: $e');
    }
    return null;
  }

  // ============ PROTOCOL GENERATION ============

  Future<Map<String, dynamic>> generateProtocol(
    int readinessScore, {
    bool useDomRl = false,
    Map<String, dynamic>? microCycleData,
  }) async {
    if (_isSimulated) {
      return _generateSimulatedProtocol(readinessScore, useDomRl);
    }

    try {
      final url = '$_baseUrl/protocols/generate/$readinessScore?use_dom_rl=$useDomRl';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: microCycleData != null ? json.encode(microCycleData) : null,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Backend API error: $e');
    }
    return _generateSimulatedProtocol(readinessScore, useDomRl);
  }

  // ============ DOM-RL OPTIMIZATION ============

  Future<Map<String, dynamic>> optimizeWithDomRl(
    Map<String, dynamic> microCycle,
    WorkoutProtocol baseProtocol,
  ) async {
    if (_isSimulated) {
      return _simulateDomRlOptimization(microCycle, baseProtocol);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/dom-rl/optimize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'micro_cycle': microCycle,
          'base_protocol': _protocolToJson(baseProtocol),
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('DOM-RL API error: $e');
    }
    return _simulateDomRlOptimization(microCycle, baseProtocol);
  }

  // ============ EPHOR SCRUTINY ============

  Future<Map<String, dynamic>> runEphorScrutiny(
    Map<String, dynamic> microCycle,
  ) async {
    if (_isSimulated) {
      return _simulateEphorScrutiny(microCycle);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ephor-scrutiny/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(microCycle),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Ephor API error: $e');
    }
    return _simulateEphorScrutiny(microCycle);
  }

  // ============ REAL-TIME ADAPTATION ============

  Future<Map<String, dynamic>> realtimeAdaptation(
    Map<String, dynamic> currentState,
    WorkoutProtocol performedProtocol,
  ) async {
    if (_isSimulated) {
      return _simulateRealtimeAdaptation(currentState, performedProtocol);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/realtime-adaptation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'current_state': currentState,
          'performed_protocol': _protocolToJson(performedProtocol),
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Realtime adaptation API error: $e');
    }
    return _simulateRealtimeAdaptation(currentState, performedProtocol);
  }

  // ============ TACTICAL RETREAT ============

  Future<Map<String, dynamic>> checkTacticalRetreat(
    int currentReadiness,
    Map<String, int> jointStress,
  ) async {
    if (_isSimulated) {
      return _simulateTacticalRetreat(currentReadiness, jointStress);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tactical-retreat/check'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'current_readiness': currentReadiness,
          'joint_stress': jointStress,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Tactical retreat API error: $e');
    }
    return _simulateTacticalRetreat(currentReadiness, jointStress);
  }

  // ============ ARMOR ANALYTICS ============

  Future<Map<String, dynamic>> runArmorAnalytics(
    Map<String, dynamic> microCycle,
  ) async {
    if (_isSimulated) {
      return _simulateArmorAnalytics(microCycle);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/armor-analytics/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(microCycle),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Armor analytics API error: $e');
    }
    return _simulateArmorAnalytics(microCycle);
  }

  // ============ STOIC MIND ============

  Future<Map<String, dynamic>> getStoicPrimer() async {
    if (_isSimulated) {
      return _simulateStoicPrimer();
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl/stoic/primer'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Stoic API error: $e');
    }
    return _simulateStoicPrimer();
  }

  Future<Map<String, dynamic>> getFlowTrackingPrompts() async {
    if (_isSimulated) {
      return {
        'mental_engagement_questions': [
          'How present were you during the session? (1-10)',
          'Did external thoughts intrude? (1-10, higher = fewer intrusions)',
          'Rate your discipline in maintaining form. (1-10)',
        ],
        'correlation_factors': [
          'sleep_quality_correlation',
          'readiness_correlation',
          'time_of_day_correlation',
        ],
      };
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl/stoic/flow-prompts'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Flow prompts API error: $e');
    }
    return {
      'mental_engagement_questions': [
        'How present were you during the session? (1-10)',
        'Did external thoughts intrude? (1-10)',
        'Rate your discipline in maintaining form. (1-10)',
      ],
    };
  }

  // ============ SIMULATION METHODS ============

  List<Exercise> _getSimulatedExercises(ExerciseCategory? category) {
    var exercises = Exercise.library;
    if (category != null) {
      exercises = exercises.where((e) => e.category == category).toList();
    }
    return exercises.isNotEmpty ? exercises : Exercise.library;
  }

  Map<String, dynamic> _generateSimulatedProtocol(int readinessScore, bool useDomRl) {
    ProtocolTier tier;
    String title;
    String subtitle;
    String mindset;
    
    if (readinessScore >= 85) {
      tier = ProtocolTier.elite;
      title = 'THE SPARTAN CHARGE';
      subtitle = 'Maximum intensity activated';
      mindset = 'Leonidas would not hesitate. Push the limits of your endurance.';
    } else if (readinessScore >= 60) {
      tier = ProtocolTier.ready;
      title = 'THE PHALANX';
      subtitle = 'Structured strength';
      mindset = 'Consistency is the foundation of the phalanx. Maintain form.';
    } else if (readinessScore >= 40) {
      tier = ProtocolTier.fatigued;
      title = 'THE GARRISON';
      subtitle = 'Maintenance & readiness';
      mindset = 'A warrior knows when to hold the line and conserve strength.';
    } else {
      tier = ProtocolTier.recovery;
      title = 'STOIC RESTORATION';
      subtitle = 'Mind over muscle';
      mindset = 'Victory is won in recovery. Master the stillness.';
    }

    final entries = _generateEntriesForTier(tier);
    
    return {
      'protocol': {
        'title': useDomRl ? 'AI-OPTIMIZED: $title' : title,
        'subtitle': subtitle,
        'tier': tier.name,
        'entries': entries.map((e) => _entryToJson(e)).toList(),
        'estimated_duration_minutes': tier == ProtocolTier.elite ? 60 : tier == ProtocolTier.ready ? 50 : tier == ProtocolTier.fatigued ? 35 : 25,
        'mindset_prompt': mindset,
      },
      'optimization_applied': useDomRl,
    };
  }

  List<ProtocolEntry> _generateEntriesForTier(ProtocolTier tier) {
    switch (tier) {
      case ProtocolTier.elite:
        return [
          ProtocolEntry(
            exercise: Exercise.library.firstWhere((e) => e.id == 'ex_004'),
            sets: 5,
            reps: 0,
            intensityRPE: 10,
            restSeconds: 90,
          ),
          ProtocolEntry(
            exercise: Exercise.library.firstWhere((e) => e.id == 'ex_006'),
            sets: 4,
            reps: 12,
            intensityRPE: 9,
            restSeconds: 60,
          ),
          ProtocolEntry(
            exercise: Exercise.library.firstWhere((e) => e.id == 'ex_005'),
            sets: 5,
            reps: 5,
            intensityRPE: 9,
            restSeconds: 120,
          ),
        ];
      case ProtocolTier.ready:
        return [
          ProtocolEntry(
            exercise: Exercise.library.firstWhere((e) => e.id == 'ex_001'),
            sets: 4,
            reps: 12,
            intensityRPE: 8,
            restSeconds: 60,
          ),
          ProtocolEntry(
            exercise: Exercise.library.firstWhere((e) => e.id == 'ex_002'),
            sets: 4,
            reps: 20,
            intensityRPE: 7,
            restSeconds: 45,
          ),
          ProtocolEntry(
            exercise: Exercise.library.firstWhere((e) => e.id == 'ex_003'),
            sets: 3,
            reps: 0,
            intensityRPE: 6,
            restSeconds: 30,
          ),
        ];
      case ProtocolTier.fatigued:
        return [
          ProtocolEntry(
            exercise: Exercise.library.firstWhere((e) => e.id == 'ex_003'),
            sets: 3,
            reps: 0,
            intensityRPE: 5,
            restSeconds: 60,
          ),
          ProtocolEntry(
            exercise: Exercise.library.firstWhere((e) => e.id == 'ex_001'),
            sets: 2,
            reps: 10,
            intensityRPE: 6,
            restSeconds: 90,
          ),
        ];
      case ProtocolTier.recovery:
        return [
          ProtocolEntry(
            exercise: Exercise.library.firstWhere((e) => e.id == 'ex_003'),
            sets: 2,
            reps: 0,
            intensityRPE: 3,
            restSeconds: 120,
          ),
        ];
    }
  }

  Map<String, dynamic> _simulateDomRlOptimization(
    Map<String, dynamic> microCycle,
    WorkoutProtocol baseProtocol,
  ) {
    // Simulate DOM-RL state calculation
    final days = microCycle['days'] as List<dynamic>? ?? [];
    final avgReadiness = days.isNotEmpty
        ? days.map((d) => (d['readiness_score'] ?? 70) as int).reduce((a, b) => a + b) / days.length
        : 70.0;

    // Generate optimization action
    final action = {
      'volume_adjustment': avgReadiness > 80 ? 0.1 : avgReadiness < 50 ? -0.3 : 0.0,
      'intensity_adjustment': avgReadiness > 85 ? 0.1 : avgReadiness < 45 ? -0.3 : 0.0,
      'rest_adjustment': avgReadiness < 50 ? 20 : -10,
      'focus_area': avgReadiness > 80 ? 'power' : avgReadiness < 50 ? 'recovery' : 'balanced',
    };

    // Apply adjustments to protocol
    final adjustedEntries = baseProtocol.entries.map((entry) {
      final newSets = (entry.sets * (1 + (action['volume_adjustment'] as double))).clamp(1, 10).round();
      final newRpe = (entry.intensityRPE + (action['intensity_adjustment'] as double) * 3).clamp(3.0, 10.0);
      final newRest = (entry.restSeconds + (action['rest_adjustment'] as int)).clamp(15, 300);

      return {
        'exercise': _exerciseToJson(entry.exercise),
        'sets': newSets,
        'reps': entry.reps,
        'intensity_rpe': newRpe,
        'rest_seconds': newRest,
      };
    }).toList();

    return {
      'optimized_protocol': {
        'title': '${action['focus_area'].toString().toUpperCase()}: ${baseProtocol.title}',
        'subtitle': 'AI-Optimized | ${baseProtocol.subtitle}',
        'tier': baseProtocol.tier.name,
        'entries': adjustedEntries,
        'estimated_duration_minutes': (baseProtocol.estimatedDurationMinutes * (1 + (action['volume_adjustment'] as double) * 0.5)).round(),
        'mindset_prompt': baseProtocol.mindsetPrompt,
      },
      'dom_rl_action': action,
    };
  }

  Map<String, dynamic> _simulateEphorScrutiny(Map<String, dynamic> microCycle) {
    final days = microCycle['days'] as List<dynamic>? ?? [];
    if (days.length < 3) {
      return {
        'recommendation': 'INSUFFICIENT_DATA',
        'message': 'At least 3 days of data required for analysis',
      };
    }

    final readinessScores = days.map((d) => (d['readiness_score'] ?? 70) as int).toList();
    final avgReadiness = readinessScores.reduce((a, b) => a + b) / readinessScores.length;
    final sleepScores = days.map((d) => (d['sleep_quality'] ?? 7) as int).toList();
    final avgSleep = sleepScores.reduce((a, b) => a + b) / sleepScores.length;

    String recommendation;
    String tier;
    String message;

    if (avgReadiness < 50 && avgSleep < 5) {
      recommendation = 'DELoad_RECOVERY';
      tier = 'recovery';
      message = 'Central nervous system shows signs of overreaching. Mandatory deload.';
    } else if (avgReadiness < 65) {
      recommendation = 'MAINTENANCE';
      tier = 'fatigued';
      message = 'Fatigue accumulation detected. Reduce volume 30%, maintain intensity.';
    } else if (avgReadiness > 85 && avgSleep > 7) {
      recommendation = 'PROGRESSIVE_OVERLOAD';
      tier = 'elite';
      message = 'Excellent recovery metrics. Increase volume 10% and test new RPE thresholds.';
    } else {
      recommendation = 'STEADY_STATE';
      tier = 'ready';
      message = 'Stable metrics. Continue current progression.';
    }

    return {
      'recommendation': recommendation,
      'protocol_tier': tier,
      'message': message,
      'metrics': {
        'avg_readiness': avgReadiness,
        'avg_sleep_quality': avgSleep,
      },
    };
  }

  Map<String, dynamic> _simulateRealtimeAdaptation(
    Map<String, dynamic> currentState,
    WorkoutProtocol performedProtocol,
  ) {
    final readiness = currentState['readiness_score'] as int? ?? 70;
    final adjustments = <String>[];

    if (readiness > 80) {
      adjustments.add('High readiness detected. Adding plyometric activation work.');
    } else if (readiness < 50) {
      adjustments.add('Low readiness. Switching to non-impact movements.');
    }

    return {
      'adapted_protocol': _protocolToJson(performedProtocol),
      'adjustments_made': adjustments,
      'adaptation_reason': readiness > 80 ? 'power' : readiness < 50 ? 'recovery' : 'balanced',
    };
  }

  Map<String, dynamic> _simulateTacticalRetreat(int currentReadiness, Map<String, int> jointStress) {
    const criticalReadiness = 35;
    const criticalJointStress = 8;

    final shouldRetreat = currentReadiness < criticalReadiness ||
        jointStress.values.any((s) => s >= criticalJointStress);

    final reasons = <String>[];
    if (currentReadiness < criticalReadiness) {
      reasons.add('Readiness $currentReadiness below critical threshold $criticalReadiness');
    }
    if (jointStress.values.any((s) => s >= criticalJointStress)) {
      reasons.add('Critical joint stress detected');
    }

    return {
      'should_retreat': shouldRetreat,
      'reasons': reasons,
      'enforced_protocol': shouldRetreat ? {
        'title': 'TACTICAL RETREAT: MANDATORY RECOVERY',
        'subtitle': 'Your body demands restoration. Honor it.',
        'tier': 'recovery',
        'entries': [
          {
            'exercise': _exerciseToJson(Exercise.library.firstWhere((e) => e.id == 'ex_003')),
            'sets': 2,
            'reps': 0,
            'intensity_rpe': 3,
            'rest_seconds': 120,
          },
        ],
        'estimated_duration_minutes': 25,
        'mindset_prompt': 'The wise warrior knows when to rest. This is not weakness. This is strategy.',
      } : null,
    };
  }

  Map<String, dynamic> _simulateArmorAnalytics(Map<String, dynamic> microCycle) {
    final days = microCycle['days'] as List<dynamic>? ?? [];
    final riskFlags = <Map<String, dynamic>>[];

    // Aggregate joint stress
    final jointStress = <String, List<int>>{};
    for (final day in days) {
      final fatigue = day['joint_fatigue'] as Map<String, dynamic>? ?? {};
      fatigue.forEach((joint, value) {
        jointStress.putIfAbsent(joint, () => []);
        jointStress[joint]!.add(value as int);
      });
    }

    // Check for risks
    jointStress.forEach((joint, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      final max = values.reduce((a, b) => a > b ? a : b);

      if (avg > 6.5) {
        riskFlags.add({
          'joint': joint,
          'risk_level': 'HIGH',
          'message': '$joint averaging ${avg.toStringAsFixed(1)}/10 stress.',
        });
      } else if (max > 8) {
        riskFlags.add({
          'joint': joint,
          'risk_level': 'CRITICAL',
          'message': '$joint peaked at $max/10.',
        });
      }
    });

    return {
      'joint_load_history': jointStress,
      'risk_flags': riskFlags,
      'summary': riskFlags.isNotEmpty ? '${riskFlags.length} risk flags detected' : 'All systems nominal',
    };
  }

  Map<String, dynamic> _simulateStoicPrimer() {
    final quotes = [
      {'text': 'The obstacle is the way.', 'author': 'Marcus Aurelius'},
      {'text': 'You have power over your mind - not outside events.', 'author': 'Marcus Aurelius'},
      {'text': 'Waste no more time arguing what a good man should be. Be one.', 'author': 'Marcus Aurelius'},
    ];

    final metaphors = [
      'Today you forge your shield. Tomorrow you stand the line.',
      'The phalanx is only as strong as its weakest warrior.',
      'Fear is the enemy. Discipline is your spear.',
    ];

    final random = Random();
    return {
      'quote': quotes[random.nextInt(quotes.length)],
      'metaphor': metaphors[random.nextInt(metaphors.length)],
      'acknowledgment_required': true,
    };
  }

  // ============ JSON HELPERS ============

  Exercise _exerciseFromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExerciseCategory.strength,
      ),
      youtubeId: json['youtube_id'] as String,
      targetMetaphor: json['target_metaphor'] as String,
      instructions: json['instructions'] as String,
      intensityLevel: json['intensity_level'] as int? ?? 5,
    );
  }

  Map<String, dynamic> _exerciseToJson(Exercise exercise) {
    return {
      'id': exercise.id,
      'name': exercise.name,
      'category': exercise.category.name,
      'youtube_id': exercise.youtubeId,
      'target_metaphor': exercise.targetMetaphor,
      'instructions': exercise.instructions,
      'intensity_level': exercise.intensityLevel,
    };
  }

  Map<String, dynamic> _entryToJson(ProtocolEntry entry) {
    return {
      'exercise': _exerciseToJson(entry.exercise),
      'sets': entry.sets,
      'reps': entry.reps,
      'intensityRPE': entry.intensityRPE,
      'rest_seconds': entry.restSeconds,
    };
  }

  Map<String, dynamic> _protocolToJson(WorkoutProtocol protocol) {
    return {
      'title': protocol.title,
      'subtitle': protocol.subtitle,
      'tier': protocol.tier.name,
      'entries': protocol.entries.map((e) => _entryToJson(e)).toList(),
      'estimated_duration_minutes': protocol.estimatedDurationMinutes,
      'mindset_prompt': protocol.mindsetPrompt,
    };
  }
}
