import 'dart:convert';

/// Types of AI memory/context data
enum AIMemoryType {
  userProfile,        // User preferences, fitness level, goals
  workoutHistory,     // Past workouts, performance data
  healthMetrics,      // HRV, sleep, recovery data
  conversation,       // Previous AI conversations
  feedback,          // User feedback on plans
  readiness,         // Daily readiness scores
  achievements,      // Unlocked achievements, milestones
  preferences,       // Training preferences, exercise likes/dislikes
}

/// Priority levels for memory retention
enum MemoryPriority {
  critical,    // Always keep (user profile, goals)
  high,        // Keep for 90 days (recent workouts, progress)
  medium,      // Keep for 30 days (daily metrics, readiness)
  low,         // Keep for 7 days (temporary context, chat)
}

/// AI Memory Entry - Stores a single piece of context data
class AIMemoryEntry {
  final String id;
  final String userId;
  final AIMemoryType type;
  final MemoryPriority priority;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String>? tags;
  final String? summary;  // AI-generated summary for quick ingestion
  final int accessCount;  // How many times this memory was accessed
  final DateTime lastAccessed;

  const AIMemoryEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    this.tags,
    this.summary,
    this.accessCount = 0,
    required this.lastAccessed,
  });

  /// Create from Firestore map
  factory AIMemoryEntry.fromMap(Map<String, dynamic> map) {
    return AIMemoryEntry(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: AIMemoryType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => AIMemoryType.conversation,
      ),
      priority: MemoryPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => MemoryPriority.medium,
      ),
      data: Map<String, dynamic>.from(map['data'] as Map),
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      tags: (map['tags'] as List<dynamic>?)?.cast<String>(),
      summary: map['summary'] as String?,
      accessCount: map['accessCount'] as int? ?? 0,
      lastAccessed: DateTime.parse(map['lastAccessed'] as String),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'priority': priority.toString(),
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'tags': tags,
      'summary': summary,
      'accessCount': accessCount,
      'lastAccessed': lastAccessed.toIso8601String(),
    };
  }

  /// Convert to JSON string for local storage
  String toJson() => jsonEncode(toMap());

  /// Create from JSON string
  factory AIMemoryEntry.fromJson(String json) {
    return AIMemoryEntry.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Create a copy with updated fields
  AIMemoryEntry copyWith({
    int? accessCount,
    DateTime? lastAccessed,
    String? summary,
  }) {
    return AIMemoryEntry(
      id: id,
      userId: userId,
      type: type,
      priority: priority,
      data: data,
      createdAt: createdAt,
      expiresAt: expiresAt,
      tags: tags,
      summary: summary ?? this.summary,
      accessCount: accessCount ?? this.accessCount,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  /// Check if memory has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Calculate relevance score based on priority and recency
  double get relevanceScore {
    final age = DateTime.now().difference(createdAt).inDays;
    final priorityMultiplier = switch (priority) {
      MemoryPriority.critical => 10.0,
      MemoryPriority.high => 5.0,
      MemoryPriority.medium => 2.0,
      MemoryPriority.low => 1.0,
    };
    final accessBoost = accessCount * 0.1;
    return (priorityMultiplier / (age + 1)) + accessBoost;
  }
}

/// AI Context Bundle - Groups related memories for prompt injection
class AIContextBundle {
  final String id;
  final String userId;
  final String contextType;  // e.g., "training_plan", "recovery_check"
  final List<AIMemoryEntry> memories;
  final DateTime createdAt;
  final String? promptTemplate;
  final int tokenEstimate;

  const AIContextBundle({
    required this.id,
    required this.userId,
    required this.contextType,
    required this.memories,
    required this.createdAt,
    this.promptTemplate,
    required this.tokenEstimate,
  });

  /// Generate a formatted context string for Gemini prompt
  String toPromptString() {
    final buffer = StringBuffer();
    
    buffer.writeln('--- USER CONTEXT ---');
    
    // Group memories by type
    final grouped = <AIMemoryType, List<AIMemoryEntry>>{};
    for (final memory in memories) {
      grouped.putIfAbsent(memory.type, () => []).add(memory);
    }
    
    // Format each group
    for (final entry in grouped.entries) {
      buffer.writeln('\n[${entry.key.name.toUpperCase()}]');
      for (final memory in entry.value) {
        if (memory.summary != null) {
          buffer.writeln('- ${memory.summary}');
        } else {
          buffer.writeln('- ${_formatMemoryData(memory)}');
        }
      }
    }
    
    buffer.writeln('\n--- END CONTEXT ---');
    return buffer.toString();
  }

  String _formatMemoryData(AIMemoryEntry memory) {
    // Format based on memory type
    switch (memory.type) {
      case AIMemoryType.userProfile:
        return 'Level: ${memory.data['fitnessLevel']}, Goal: ${memory.data['trainingGoal']}';
      case AIMemoryType.workoutHistory:
        return '${memory.data['workoutName']}: ${memory.data['completionRate']}% completion';
      case AIMemoryType.healthMetrics:
        return 'HRV: ${memory.data['hrv']}, Sleep: ${memory.data['sleepScore']}';
      case AIMemoryType.readiness:
        return 'Readiness Score: ${memory.data['score']}/100';
      default:
        return memory.data.toString();
    }
  }

  /// Create from list of memories
  factory AIContextBundle.create({
    required String userId,
    required String contextType,
    required List<AIMemoryEntry> memories,
    String? promptTemplate,
  }) {
    return AIContextBundle(
      id: '${userId}_${contextType}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      contextType: contextType,
      memories: memories,
      createdAt: DateTime.now(),
      promptTemplate: promptTemplate,
      tokenEstimate: _estimateTokens(memories),
    );
  }

  static int _estimateTokens(List<AIMemoryEntry> memories) {
    // Rough estimate: 1 token ~= 4 characters
    int chars = 0;
    for (final memory in memories) {
      chars += memory.data.toString().length;
      if (memory.summary != null) chars += memory.summary!.length;
    }
    return (chars / 4).ceil();
  }
}

/// Memory Query Options for retrieving relevant context
class MemoryQueryOptions {
  final List<AIMemoryType>? types;
  final MemoryPriority? minPriority;
  final DateTime? since;
  final DateTime? until;
  final List<String>? tags;
  final int? limit;
  final bool? includeExpired;
  final String? searchQuery;

  const MemoryQueryOptions({
    this.types,
    this.minPriority,
    this.since,
    this.until,
    this.tags,
    this.limit,
    this.includeExpired = false,
    this.searchQuery,
  });
}
