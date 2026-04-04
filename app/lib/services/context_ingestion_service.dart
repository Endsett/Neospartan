import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ai_memory.dart';
import '../models/user_profile.dart';
import '../services/ai_memory_service.dart';

/// Context Ingestion Service - Intelligently feeds memory into Gemini prompts
/// Analyzes context needs and constructs optimal prompts for AI interactions
class ContextIngestionService {
  static final ContextIngestionService _instance = ContextIngestionService._internal();
  factory ContextIngestionService() => _instance;
  ContextIngestionService._internal();

  final AIMemoryService _memoryService = AIMemoryService();
  
  /// Maximum tokens to use for context (leaving room for response)
  static const int _maxContextTokens = 2000;
  
  /// Token estimation: ~4 chars per token
  static const int _charsPerToken = 4;

  /// Context templates for different AI operations
  static const Map<String, String> _contextTemplates = {
    'training_plan': '''
You are an elite combat sports conditioning coach. Create a personalized training plan based on the following athlete context.

{CONTEXT}

Instructions:
1. Consider the athlete's complete history and current state
2. Create progressive, periodized training
3. Account for recovery needs and injury history
4. Balance intensity with sustainability
5. Include specific exercises, sets, reps, and rest periods

Provide the plan in the requested JSON format.
''',
    'plan_adjustment': '''
You are reviewing an athlete's weekly progress and adjusting their training plan.

{CONTEXT}

Instructions:
1. Analyze performance trends from the data
2. Identify areas for improvement or regression
3. Adjust volume, intensity, or exercise selection as needed
4. Consider readiness scores and subjective feedback
5. Maintain progressive overload while preventing overtraining

Provide adjusted plan in the same JSON format.
''',
    'recovery_recommendations': '''
You are a recovery specialist analyzing an athlete's readiness data.

{CONTEXT}

Instructions:
1. Assess current recovery status
2. Identify potential overtraining signals
3. Recommend recovery protocols
4. Suggest lifestyle adjustments
5. Provide timeline for return to full intensity

Provide actionable recommendations.
''',
    'exercise_substitution': '''
You are selecting exercise substitutions for an athlete.

{CONTEXT}

Instructions:
1. Consider available equipment and injuries
2. Maintain training stimulus
3. Match movement patterns
4. Adjust for skill level
5. Ensure safety

Provide specific substitutions with rationale.
''',
    'performance_analysis': '''
You are analyzing an athlete's training data for insights.

{CONTEXT}

Instructions:
1. Identify trends in performance metrics
2. Spot plateaus or decline
3. Highlight strengths and weaknesses
4. Compare to expected progression
5. Provide actionable insights

Provide concise analysis with specific recommendations.
''',
  };

  /// Build a Gemini prompt with ingested context
  Future<String> buildPrompt({
    required String userId,
    required String contextType,
    UserProfile? userProfile,
    Map<String, dynamic>? additionalContext,
    int? maxTokens,
  }) async {
    try {
      // Gather relevant memories
      final contextBundle = await _gatherContext(
        userId: userId,
        contextType: contextType,
        userProfile: userProfile,
        maxTokens: maxTokens ?? _maxContextTokens,
      );

      // Build base context string
      final contextString = contextBundle.toPromptString();

      // Add additional context if provided
      final fullContext = StringBuffer();
      fullContext.writeln(contextString);
      
      if (additionalContext != null && additionalContext.isNotEmpty) {
        fullContext.writeln('\n--- ADDITIONAL CONTEXT ---');
        additionalContext.forEach((key, value) {
          fullContext.writeln('$key: $value');
        });
      }

      // Get template and inject context
      final template = _contextTemplates[contextType] ?? _contextTemplates['training_plan']!;
      final prompt = template.replaceAll('{CONTEXT}', fullContext.toString());

      // Log prompt stats
      final tokenEstimate = prompt.length ~/ _charsPerToken;
      developer.log(
        'Built prompt: $contextType (${contextBundle.memories.length} memories, ~$tokenEstimate tokens)',
        name: 'ContextIngestionService',
      );

      return prompt;
    } catch (e) {
      developer.log('Error building prompt: $e', name: 'ContextIngestionService');
      // Return minimal fallback prompt
      return _buildFallbackPrompt(contextType, userProfile);
    }
  }

  /// Gather relevant context memories based on type
  Future<AIContextBundle> _gatherContext({
    required String userId,
    required String contextType,
    UserProfile? userProfile,
    required int maxTokens,
  }) async {
    final memories = <AIMemoryEntry>[];
    var currentTokens = 0;

    // Define memory priorities for each context type
    final memoryPriorities = _getMemoryPriorities(contextType);

    // Fetch memories by priority order
    for (final priority in memoryPriorities) {
      if (currentTokens >= maxTokens) break;

      final typeMemories = await _memoryService.queryMemories(
        userId,
        options: MemoryQueryOptions(
          types: [priority],
          limit: 10,
        ),
      );

      // Sort by relevance and add until token limit
      typeMemories.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      for (final memory in typeMemories) {
        final memoryTokens = _estimateMemoryTokens(memory);
        
        if (currentTokens + memoryTokens > maxTokens) {
          // Try to add a summarized version if available
          if (memory.summary != null && memoryTokens > 100) {
            final summaryTokens = memory.summary!.length ~/ _charsPerToken;
            if (currentTokens + summaryTokens <= maxTokens) {
              memories.add(memory);
              currentTokens += summaryTokens;
            }
          }
          continue;
        }

        memories.add(memory);
        currentTokens += memoryTokens;
        
        // Record access for relevance tracking
        await _memoryService.recordAccess(userId, memory.id);
      }
    }

    // Add user profile if provided
    if (userProfile != null && currentTokens < maxTokens) {
      final profileMemory = _createProfileMemory(userProfile);
      memories.add(profileMemory);
    }

    return AIContextBundle.create(
      userId: userId,
      contextType: contextType,
      memories: memories,
      promptTemplate: _contextTemplates[contextType],
    );
  }

  /// Get memory type priorities for each context type
  List<AIMemoryType> _getMemoryPriorities(String contextType) {
    switch (contextType) {
      case 'training_plan':
        return [
          AIMemoryType.userProfile,
          AIMemoryType.workoutHistory,
          AIMemoryType.readiness,
          AIMemoryType.healthMetrics,
          AIMemoryType.preferences,
          AIMemoryType.achievements,
        ];
      case 'plan_adjustment':
        return [
          AIMemoryType.workoutHistory,
          AIMemoryType.readiness,
          AIMemoryType.healthMetrics,
          AIMemoryType.feedback,
          AIMemoryType.userProfile,
        ];
      case 'recovery_recommendations':
        return [
          AIMemoryType.healthMetrics,
          AIMemoryType.readiness,
          AIMemoryType.workoutHistory,
          AIMemoryType.userProfile,
        ];
      case 'exercise_substitution':
        return [
          AIMemoryType.preferences,
          AIMemoryType.workoutHistory,
          AIMemoryType.userProfile,
        ];
      case 'performance_analysis':
        return [
          AIMemoryType.workoutHistory,
          AIMemoryType.achievements,
          AIMemoryType.healthMetrics,
          AIMemoryType.userProfile,
        ];
      default:
        return [
          AIMemoryType.userProfile,
          AIMemoryType.workoutHistory,
          AIMemoryType.readiness,
        ];
    }
  }

  /// Estimate token count for a memory
  int _estimateMemoryTokens(AIMemoryEntry memory) {
    if (memory.summary != null) {
      return memory.summary!.length ~/ _charsPerToken;
    }
    return memory.data.toString().length ~/ _charsPerToken;
  }

  /// Create a memory entry from user profile
  AIMemoryEntry _createProfileMemory(UserProfile profile) {
    return AIMemoryEntry(
      id: 'profile_${profile.userId}',
      userId: profile.userId,
      type: AIMemoryType.userProfile,
      priority: MemoryPriority.critical,
      data: profile.toMap(),
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 365)),
      summary: 'Profile: ${profile.displayName}, Level: ${profile.fitnessLevel}, Goal: ${profile.trainingGoal}',
      accessCount: 0,
      lastAccessed: DateTime.now(),
    );
  }

  /// Build minimal fallback prompt
  String _buildFallbackPrompt(String contextType, UserProfile? profile) {
    final buffer = StringBuffer();
    buffer.writeln('You are a fitness coach helping an athlete.');
    
    if (profile != null) {
      buffer.writeln('\nAthlete: ${profile.displayName}');
      buffer.writeln('Level: ${profile.fitnessLevel}');
      buffer.writeln('Goal: ${profile.trainingGoal}');
    }
    
    buffer.writeln('\nProvide a basic training plan.');
    return buffer.toString();
  }

  /// Generate and store memory summary using AI
  Future<String?> generateSummary(String userId, AIMemoryEntry memory) async {
    try {
      // Skip if already has summary
      if (memory.summary != null) return memory.summary;

      // Create mini-prompt for summarization
      final prompt = '''
Summarize the following fitness/training data in one sentence:
Type: ${memory.type.name}
Data: ${memory.data}

Provide a concise summary that captures the key information.
''';    

      // Use Gemini to generate summary
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: 'AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk',
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final summary = response.text?.trim();

      if (summary != null && summary.isNotEmpty) {
        developer.log(
          'Generated summary for memory ${memory.id}: $summary',
          name: 'ContextIngestionService',
        );
        return summary;
      }
    } catch (e) {
      developer.log(
        'Error generating summary: $e',
        name: 'ContextIngestionService',
      );
    }
    return null;
  }

  /// Smart context compression for long memories
  String compressContext(String context, {int maxLength = 1000}) {
    if (context.length <= maxLength) return context;

    // Strategy: Keep headers and structure, compress details
    final lines = context.split('\n');
    final buffer = StringBuffer();
    var currentLength = 0;

    for (final line in lines) {
      if (line.startsWith('---') || line.startsWith('[')) {
        // Keep headers
        buffer.writeln(line);
        currentLength += line.length + 1;
      } else if (currentLength + line.length < maxLength) {
        buffer.writeln(line);
        currentLength += line.length + 1;
      } else {
        // Truncate with indicator
        buffer.writeln('... (additional data truncated)');
        break;
      }
    }

    return buffer.toString();
  }

  /// Get optimal context for a specific query
  Future<List<AIMemoryEntry>> queryRelevantContext({
    required String userId,
    required String query,
    int limit = 10,
  }) async {
    // Determine relevant memory types based on query keywords
    final relevantTypes = _inferTypesFromQuery(query);
    
    final memories = await _memoryService.queryMemories(
      userId,
      options: MemoryQueryOptions(
        types: relevantTypes,
        searchQuery: query,
        limit: limit * 2, // Get more to rank
      ),
    );

    // Rank by relevance to query
    memories.sort((a, b) {
      final scoreA = _calculateQueryRelevance(a, query);
      final scoreB = _calculateQueryRelevance(b, query);
      return scoreB.compareTo(scoreA);
    });

    return memories.take(limit).toList();
  }

  /// Infer memory types from query keywords
  List<AIMemoryType> _inferTypesFromQuery(String query) {
    final lower = query.toLowerCase();
    final types = <AIMemoryType>[];

    if (lower.contains('workout') || 
        lower.contains('exercise') || 
        lower.contains('training')) {
      types.add(AIMemoryType.workoutHistory);
    }
    if (lower.contains('recovery') || 
        lower.contains('sleep') || 
        lower.contains('hrv')) {
      types.add(AIMemoryType.healthMetrics);
      types.add(AIMemoryType.readiness);
    }
    if (lower.contains('goal') || 
        lower.contains('preference') || 
        lower.contains('like')) {
      types.add(AIMemoryType.preferences);
      types.add(AIMemoryType.userProfile);
    }
    if (types.isEmpty) {
      // Default to all types if no keywords match
      return AIMemoryType.values;
    }
    return types;
  }

  /// Calculate relevance score for a query
  double _calculateQueryRelevance(AIMemoryEntry memory, String query) {
    var score = memory.relevanceScore;
    final lowerQuery = query.toLowerCase();
    final dataString = memory.data.toString().toLowerCase();

    // Boost if query keywords appear in data
    if (dataString.contains(lowerQuery)) {
      score *= 2;
    }

    // Boost based on recency (within last 7 days)
    final age = DateTime.now().difference(memory.createdAt).inDays;
    if (age <= 7) score *= 1.5;

    return score;
  }

  /// Analyze prompt effectiveness
  Map<String, dynamic> analyzePrompt(String prompt, {String? expectedOutput}) {
    final analysis = <String, dynamic>{};
    
    // Token estimate
    analysis['tokenEstimate'] = prompt.length ~/ _charsPerToken;
    
    // Memory count (from context markers)
    final memoryMatches = RegExp(r'\[([A-Z_]+)\]').allMatches(prompt);
    analysis['contextSections'] = memoryMatches.map((m) => m.group(1)).toSet().toList();
    
    // Context density
    final lines = prompt.split('\n');
    final contextLines = lines.where((l) => l.startsWith('-')).length;
    analysis['contextDensity'] = contextLines / lines.length;
    
    // Completeness check
    final hasProfile = prompt.contains('userProfile') || prompt.contains('Profile');
    final hasHistory = prompt.contains('workoutHistory') || prompt.contains('Workout');
    final hasReadiness = prompt.contains('readiness') || prompt.contains('Readiness');
    
    analysis['completeness'] = {
      'hasProfile': hasProfile,
      'hasHistory': hasHistory,
      'hasReadiness': hasReadiness,
      'score': (hasProfile ? 1 : 0) + (hasHistory ? 1 : 0) + (hasReadiness ? 1 : 0),
    };

    return analysis;
  }
}
