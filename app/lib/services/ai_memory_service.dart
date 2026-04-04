import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_memory.dart';

/// AI Memory Service - Manages context storage for AI interactions
/// Supports both Firebase (authenticated users) and local storage (guest users)
class AIMemoryService {
  static final AIMemoryService _instance = AIMemoryService._internal();
  factory AIMemoryService() => _instance;
  AIMemoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  bool _initialized = false;
  bool _isGuest = false;

  /// TTL configuration for different priorities (in days)
  static const Map<MemoryPriority, int> _ttlDays = {
    MemoryPriority.critical: 365, // 1 year
    MemoryPriority.high: 90, // 3 months
    MemoryPriority.medium: 30, // 1 month
    MemoryPriority.low: 7, // 1 week
  };

  /// Initialize the service
  Future<void> initialize({String? userId, bool isGuest = false}) async {
    _isGuest = isGuest;
    _initialized = true;
    developer.log(
      'AI Memory Service initialized - Guest: $isGuest',
      name: 'AIMemoryService',
    );
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Store a memory entry
  Future<AIMemoryEntry> storeMemory({
    required String userId,
    required AIMemoryType type,
    required MemoryPriority priority,
    required Map<String, dynamic> data,
    List<String>? tags,
    String? summary,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final ttl = _ttlDays[priority] ?? 30;

    final entry = AIMemoryEntry(
      id: id,
      userId: userId,
      type: type,
      priority: priority,
      data: data,
      createdAt: now,
      expiresAt: now.add(Duration(days: ttl)),
      tags: tags,
      summary: summary,
      accessCount: 0,
      lastAccessed: now,
    );

    try {
      if (_isGuest) {
        await _storeLocally(entry);
      } else {
        await _storeInFirestore(entry);
      }

      developer.log(
        'Memory stored: ${entry.id} (Type: ${entry.type.name})',
        name: 'AIMemoryService',
      );

      return entry;
    } catch (e) {
      developer.log(
        'Error storing memory: $e',
        name: 'AIMemoryService',
        error: e,
      );
      rethrow;
    }
  }

  /// Store memory in Firestore (for authenticated users)
  Future<void> _storeInFirestore(AIMemoryEntry entry) async {
    await _firestore
        .collection('users')
        .doc(entry.userId)
        .collection('ai_memories')
        .doc(entry.id)
        .set(entry.toMap());
  }

  /// Store memory locally (for guest users)
  Future<void> _storeLocally(AIMemoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final memories = await _getLocalMemories(entry.userId);
    memories.add(entry);

    final memoriesJson = memories.map((m) => m.toJson()).toList();
    await prefs.setString(
      'ai_memories_${entry.userId}',
      jsonEncode(memoriesJson),
    );
  }

  /// Get memories from local storage
  Future<List<AIMemoryEntry>> _getLocalMemories(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = prefs.getString('ai_memories_$userId');

    if (memoriesJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(memoriesJson);
      return decoded
          .map((json) => AIMemoryEntry.fromJson(jsonEncode(json)))
          .where((entry) => !entry.isExpired)
          .toList();
    } catch (e) {
      developer.log(
        'Error loading local memories: $e',
        name: 'AIMemoryService',
      );
      return [];
    }
  }

  /// Query memories based on filters
  Future<List<AIMemoryEntry>> queryMemories(
    String userId, {
    MemoryQueryOptions? options,
  }) async {
    try {
      List<AIMemoryEntry> memories;

      if (_isGuest) {
        memories = await _getLocalMemories(userId);
      } else {
        memories = await _queryFirestore(userId, options);
      }

      // Apply filters
      return _applyFilters(memories, options);
    } catch (e) {
      developer.log('Error querying memories: $e', name: 'AIMemoryService');
      return [];
    }
  }

  /// Query Firestore with filters
  Future<List<AIMemoryEntry>> _queryFirestore(
    String userId,
    MemoryQueryOptions? options,
  ) async {
    var query = _firestore
        .collection('users')
        .doc(userId)
        .collection('ai_memories')
        .where('expiresAt', isGreaterThan: DateTime.now().toIso8601String());

    // Apply type filter
    if (options?.types != null && options!.types!.isNotEmpty) {
      query = query.where(
        'type',
        whereIn: options.types!.map((t) => t.toString()).toList(),
      );
    }

    // Apply date filters
    if (options?.since != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: options!.since!.toIso8601String(),
      );
    }

    if (options?.until != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: options!.until!.toIso8601String(),
      );
    }

    // Order by relevance (priority + recency)
    query = query.orderBy('priority', descending: true);
    query = query.orderBy('createdAt', descending: true);

    // Apply limit
    if (options?.limit != null) {
      query = query.limit(options!.limit!);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AIMemoryEntry.fromMap(doc.data()))
        .toList();
  }

  /// Apply additional filters to memory list
  List<AIMemoryEntry> _applyFilters(
    List<AIMemoryEntry> memories,
    MemoryQueryOptions? options,
  ) {
    if (options == null) return memories;

    return memories.where((memory) {
      // Priority filter
      if (options.minPriority != null) {
        final priorityValues = MemoryPriority.values;
        final memoryIndex = priorityValues.indexOf(memory.priority);
        final minIndex = priorityValues.indexOf(options.minPriority!);
        if (memoryIndex < minIndex) return false;
      }

      // Tag filter
      if (options.tags != null && options.tags!.isNotEmpty) {
        if (memory.tags == null) return false;
        if (!options.tags!.any((tag) => memory.tags!.contains(tag))) {
          return false;
        }
      }

      // Expired filter
      if (!(options.includeExpired ?? false) && memory.isExpired) {
        return false;
      }

      // Search query
      if (options.searchQuery != null && options.searchQuery!.isNotEmpty) {
        final query = options.searchQuery!.toLowerCase();
        final inSummary =
            memory.summary?.toLowerCase().contains(query) ?? false;
        final inData = memory.data.toString().toLowerCase().contains(query);
        if (!inSummary && !inData) return false;
      }

      return true;
    }).toList();
  }

  /// Get memories by type
  Future<List<AIMemoryEntry>> getMemoriesByType(
    String userId,
    AIMemoryType type, {
    int? limit,
  }) async {
    return queryMemories(
      userId,
      options: MemoryQueryOptions(types: [type], limit: limit),
    );
  }

  /// Update memory access count
  Future<void> recordAccess(String userId, String memoryId) async {
    try {
      if (_isGuest) {
        await _updateLocalAccess(userId, memoryId);
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('ai_memories')
            .doc(memoryId)
            .update({
              'accessCount': FieldValue.increment(1),
              'lastAccessed': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      developer.log('Error recording access: $e', name: 'AIMemoryService');
    }
  }

  /// Update access count in local storage
  Future<void> _updateLocalAccess(String userId, String memoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final memories = await _getLocalMemories(userId);

    final index = memories.indexWhere((m) => m.id == memoryId);
    if (index != -1) {
      memories[index] = memories[index].copyWith(
        accessCount: memories[index].accessCount + 1,
        lastAccessed: DateTime.now(),
      );

      final memoriesJson = memories.map((m) => m.toJson()).toList();
      await prefs.setString('ai_memories_$userId', jsonEncode(memoriesJson));
    }
  }

  /// Delete expired memories
  Future<int> cleanupExpiredMemories(String userId) async {
    try {
      if (_isGuest) {
        return await _cleanupLocalExpired(userId);
      } else {
        return await _cleanupFirestoreExpired(userId);
      }
    } catch (e) {
      developer.log('Error cleaning up memories: $e', name: 'AIMemoryService');
      return 0;
    }
  }

  /// Cleanup expired memories from local storage
  Future<int> _cleanupLocalExpired(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final memories = await _getLocalMemories(userId);
    final validMemories = memories.where((m) => !m.isExpired).toList();

    final removed = memories.length - validMemories.length;

    if (removed > 0) {
      final memoriesJson = validMemories.map((m) => m.toJson()).toList();
      await prefs.setString('ai_memories_$userId', jsonEncode(memoriesJson));
    }

    return removed;
  }

  /// Cleanup expired memories from Firestore
  Future<int> _cleanupFirestoreExpired(String userId) async {
    final batch = _firestore.batch();
    var count = 0;

    final expired = await _firestore
        .collection('users')
        .doc(userId)
        .collection('ai_memories')
        .where('expiresAt', isLessThan: DateTime.now().toIso8601String())
        .get();

    for (final doc in expired.docs) {
      batch.delete(doc.reference);
      count++;
    }

    if (count > 0) {
      await batch.commit();
    }

    return count;
  }

  /// Delete a specific memory
  Future<void> deleteMemory(String userId, String memoryId) async {
    try {
      if (_isGuest) {
        await _deleteLocalMemory(userId, memoryId);
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('ai_memories')
            .doc(memoryId)
            .delete();
      }
    } catch (e) {
      developer.log('Error deleting memory: $e', name: 'AIMemoryService');
      rethrow;
    }
  }

  /// Delete memory from local storage
  Future<void> _deleteLocalMemory(String userId, String memoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final memories = await _getLocalMemories(userId);
    memories.removeWhere((m) => m.id == memoryId);

    final memoriesJson = memories.map((m) => m.toJson()).toList();
    await prefs.setString('ai_memories_$userId', jsonEncode(memoriesJson));
  }

  /// Get memory statistics
  Future<Map<String, dynamic>> getMemoryStats(String userId) async {
    final memories = await queryMemories(userId);

    final byType = <String, int>{};
    final byPriority = <String, int>{};
    var expired = 0;

    for (final memory in memories) {
      byType[memory.type.name] = (byType[memory.type.name] ?? 0) + 1;
      byPriority[memory.priority.name] =
          (byPriority[memory.priority.name] ?? 0) + 1;
      if (memory.isExpired) expired++;
    }

    return {
      'total': memories.length,
      'byType': byType,
      'byPriority': byPriority,
      'expired': expired,
      'storage': _isGuest ? 'local' : 'firebase',
    };
  }

  /// Clear all memories (use with caution)
  Future<void> clearAllMemories(String userId) async {
    try {
      if (_isGuest) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('ai_memories_$userId');
      } else {
        final batch = _firestore.batch();
        final memories = await _firestore
            .collection('users')
            .doc(userId)
            .collection('ai_memories')
            .get();

        for (final doc in memories.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      developer.log(
        'All memories cleared for user: $userId',
        name: 'AIMemoryService',
      );
    } catch (e) {
      developer.log('Error clearing memories: $e', name: 'AIMemoryService');
      rethrow;
    }
  }
}
