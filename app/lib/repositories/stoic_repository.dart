import 'dart:developer' as developer;
import '../services/supabase_database_service.dart';

/// Stoic Entry types
enum StoicEntryType { reflection, flowLog, quoteView }

/// Stoic Entry model for database operations
class StoicEntry {
  final String? id;
  final String userId;
  final StoicEntryType entryType;
  final int? flowStateValue;
  final String? reflectionText;
  final String? quoteId;
  final String? quoteAuthor;
  final String? quoteText;
  final DateTime sessionDate;
  final DateTime createdAt;

  StoicEntry({
    this.id,
    required this.userId,
    required this.entryType,
    this.flowStateValue,
    this.reflectionText,
    this.quoteId,
    this.quoteAuthor,
    this.quoteText,
    required this.sessionDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'entry_type': entryType.name,
      'flow_state_value': flowStateValue,
      'reflection_text': reflectionText,
      'quote_id': quoteId,
      'quote_author': quoteAuthor,
      'quote_text': quoteText,
      'session_date': _dateOnly(sessionDate),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StoicEntry.fromMap(Map<String, dynamic> map) {
    return StoicEntry(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      entryType: StoicEntryType.values.firstWhere(
        (e) => e.name == map['entry_type'],
        orElse: () => StoicEntryType.reflection,
      ),
      flowStateValue: map['flow_state_value']?.toInt(),
      reflectionText: map['reflection_text'],
      quoteId: map['quote_id'],
      quoteAuthor: map['quote_author'],
      quoteText: map['quote_text'],
      sessionDate: DateTime.parse(map['session_date'] ?? map['created_at']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Repository for Stoic entries using Supabase
class StoicRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Save a stoic entry
  Future<bool> saveEntry(StoicEntry entry) async {
    try {
      await _database.saveStoicEntry(entry.toMap());
      developer.log('Stoic entry saved', name: 'StoicRepository');
      return true;
    } catch (e) {
      developer.log('Error saving stoic entry: $e', name: 'StoicRepository');
      return false;
    }
  }

  /// Get entries for user by type
  Future<List<StoicEntry>> getEntriesByType(
    String userId,
    StoicEntryType type, {
    int limit = 30,
  }) async {
    try {
      final data = await _database.getStoicEntriesByType(userId, type.name, limit: limit);
      return data.map((m) => StoicEntry.fromMap(m)).toList();
    } catch (e) {
      developer.log('Error getting stoic entries: $e', name: 'StoicRepository');
      return [];
    }
  }

  /// Get entries for date range
  Future<List<StoicEntry>> getEntriesForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _database.getStoicEntriesForRange(userId, startDate, endDate);
      return data.map((m) => StoicEntry.fromMap(m)).toList();
    } catch (e) {
      developer.log('Error getting stoic entries for range: $e', name: 'StoicRepository');
      return [];
    }
  }

  /// Get flow state history (for chart data)
  Future<List<Map<String, dynamic>>> getFlowStateHistory(
    String userId, {
    int days = 30,
  }) async {
    try {
      final entries = await getEntriesForRange(
        userId,
        DateTime.now().subtract(Duration(days: days)),
        DateTime.now(),
      );
      return entries
          .where((e) => e.flowStateValue != null)
          .map((e) => {
                'date': e.sessionDate.toIso8601String(),
                'flow_state': e.flowStateValue,
              })
          .toList();
    } catch (e) {
      developer.log('Error getting flow state history: $e', name: 'StoicRepository');
      return [];
    }
  }

  /// Delete an entry
  Future<bool> deleteEntry(String entryId) async {
    try {
      await _database.deleteStoicEntry(entryId);
      developer.log('Stoic entry deleted', name: 'StoicRepository');
      return true;
    } catch (e) {
      developer.log('Error deleting stoic entry: $e', name: 'StoicRepository');
      return false;
    }
  }
}
