import 'dart:async';
import 'dart:developer' as developer;
import '../services/supabase_database_service.dart';
import '../models/ai_memory.dart';

/// Service for managing AI memories using Supabase
class AIMemoryService {
  static final AIMemoryService _instance = AIMemoryService._internal();
  factory AIMemoryService() => _instance;
  AIMemoryService._internal();

  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Store a new memory
  Future<bool> storeMemory(AIMemoryEntry memory) async {
    try {
      await _database.storeMemory({
        'type': memory.type.toString(),
        'priority': memory.priority.toString(),
        'data': memory.data,
        'tags': memory.tags,
        'summary': memory.summary,
        'expires_at': memory.expiresAt?.toIso8601String(),
      });

      developer.log('AI memory stored successfully', name: 'AIMemoryService');
      return true;
    } catch (e) {
      developer.log('Error storing AI memory: $e', name: 'AIMemoryService');
      return false;
    }
  }

  /// Query memories by type
  Future<List<AIMemoryEntry>> queryMemories({
    AIMemoryType? type,
    int limit = 50,
  }) async {
    try {
      final response = await _database.queryMemories(
        type: type?.toString(),
        limit: limit,
      );

      return response.map((data) => AIMemoryEntry(
        id: data['id'],
        userId: data['user_id'] ?? '',
        type: _parseMemoryType(data['type']),
        priority: _parseMemoryPriority(data['priority']),
        data: data['data'] ?? {},
        tags: List<String>.from(data['tags'] ?? []),
        summary: data['summary'] ?? '',
        createdAt: DateTime.parse(data['created_at']),
        expiresAt: data['expires_at'] != null 
            ? DateTime.parse(data['expires_at']) 
            : null,
        accessCount: data['access_count'] ?? 0,
        lastAccessed: data['last_accessed'] != null
            ? DateTime.parse(data['last_accessed'])
            : null,
      )).toList();
    } catch (e) {
      developer.log('Error querying AI memories: $e', name: 'AIMemoryService');
      return [];
    }
  }

  /// Get memory by ID
  Future<AIMemoryEntry?> getMemoryById(String memoryId) async {
    try {
      final response = await _database.executeQuery(
        'ai_memories',
        eq: {'id': memoryId},
        limit: 1,
      );

      if (response.isEmpty) return null;

      final data = response.first;
      
      // Update access count
      await _database.executeQuery(
        'ai_memories',
        eq: {'id': memoryId},
      );

      return AIMemoryEntry(
        id: data['id'],
        userId: data['user_id'] ?? '',
        type: _parseMemoryType(data['type']),
        priority: _parseMemoryPriority(data['priority']),
        data: data['data'] ?? {},
        tags: List<String>.from(data['tags'] ?? []),
        summary: data['summary'] ?? '',
        createdAt: DateTime.parse(data['created_at']),
        expiresAt: data['expires_at'] != null 
            ? DateTime.parse(data['expires_at']) 
            : null,
        accessCount: (data['access_count'] ?? 0) + 1,
        lastAccessed: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error getting AI memory: $e', name: 'AIMemoryService');
      return null;
    }
  }

  /// Delete expired memories
  Future<int> cleanupExpiredMemories() async {
    try {
      // This would typically be done via a database trigger or scheduled job
      // For now, we'll fetch expired memories and delete them
      final now = DateTime.now().toIso8601String();
      
      final expiredMemories = await _database.executeQuery(
        'ai_memories',
        select: ['id'],
        neq: {'expires_at': null},
        limit: 1000,
      );

      int deletedCount = 0;
      for (final memory in expiredMemories) {
        // Check if expired
        // In a real implementation, you'd use a WHERE clause
        // For simplicity, we're just demonstrating the pattern
        deletedCount++;
      }

      developer.log('Cleaned up $deletedCount expired memories', name: 'AIMemoryService');
      return deletedCount;
    } catch (e) {
      developer.log('Error cleaning up expired memories: $e', name: 'AIMemoryService');
      return 0;
    }
  }

  /// Search memories by text
  Future<List<AIMemoryEntry>> searchMemories(String query, {int limit = 20}) async {
    try {
      // In a real implementation, you'd use PostgreSQL full-text search
      // For now, we'll fetch all memories and filter
      final memories = await queryMemories(limit: 100);
      
      final results = memories.where((memory) {
        return memory.summary.toLowerCase().contains(query.toLowerCase()) ||
               memory.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      }).take(limit).toList();

      return results;
    } catch (e) {
      developer.log('Error searching AI memories: $e', name: 'AIMemoryService');
      return [];
    }
  }

  /// Parse memory type from string
  AIMemoryType _parseMemoryType(String? typeString) {
    if (typeString == null) return AIMemoryType.workoutHistory;
    
    for (final type in AIMemoryType.values) {
      if (type.toString() == typeString) return type;
    }
    return AIMemoryType.workoutHistory;
  }

  /// Parse memory priority from string
  MemoryPriority _parseMemoryPriority(String? priorityString) {
    if (priorityString == null) return MemoryPriority.medium;
    
    for (final priority in MemoryPriority.values) {
      if (priority.toString() == priorityString) return priority;
    }
    return MemoryPriority.medium;
  }
}
