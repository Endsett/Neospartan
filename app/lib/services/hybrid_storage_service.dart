import 'dart:async';
import 'dart:developer' as developer;
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import 'guest_storage_service.dart';
import 'supabase_database_service.dart';

/// Hybrid Storage Service that routes between local and cloud storage
/// Automatically detects guest/authenticated mode and provides seamless fallbacks
class HybridStorageService {
  static final HybridStorageService _instance =
      HybridStorageService._internal();
  factory HybridStorageService() => _instance;
  HybridStorageService._internal();

  final GuestStorageService _guestStorage = GuestStorageService();
  final SupabaseDatabaseService _cloudStorage = SupabaseDatabaseService();
  AuthProvider? _authProvider;

  /// Initialize with AuthProvider reference
  void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  /// Check if current user is in guest mode
  bool get _isGuestMode => _authProvider?.isGuestMode ?? true;

  /// Get current user ID (guest or authenticated)
  String? get _currentUserId => _authProvider?.userId;

  // ==================== User Profiles ====================

  /// Save user profile
  Future<bool> saveUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      if (_isGuestMode) {
        final profile = UserProfile.fromMap({...data, 'userId': userId});
        await _guestStorage.saveUserProfile(profile);
        developer.log('Profile saved to local storage', name: 'HybridStorage');
        return true;
      } else {
        await _cloudStorage.saveUserProfile(userId, data);
        developer.log('Profile saved to cloud storage', name: 'HybridStorage');
        return true;
      }
    } catch (e) {
      developer.log('Error saving profile: $e', name: 'HybridStorage');

      // Fallback to local storage if cloud fails
      if (!_isGuestMode) {
        try {
          final profile = UserProfile.fromMap({...data, 'userId': userId});
          await _guestStorage.saveUserProfile(profile);
          developer.log(
            'Profile saved to local storage (fallback)',
            name: 'HybridStorage',
          );
          return true;
        } catch (fallbackError) {
          developer.log(
            'Fallback also failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
      return false;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      if (_isGuestMode) {
        final profile = _guestStorage.getUserProfile();
        if (profile != null) {
          developer.log(
            'Profile loaded from local storage',
            name: 'HybridStorage',
          );
          return profile.toMap();
        }
      } else {
        final profile = await _cloudStorage.getUserProfile(userId);
        if (profile != null) {
          developer.log(
            'Profile loaded from cloud storage',
            name: 'HybridStorage',
          );
          return profile;
        }

        // Fallback to local storage
        final localProfile = _guestStorage.getUserProfile();
        if (localProfile != null) {
          developer.log(
            'Profile loaded from local storage (fallback)',
            name: 'HybridStorage',
          );
          return localProfile.toMap();
        }
      }
    } catch (e) {
      developer.log('Error getting profile: $e', name: 'HybridStorage');

      // Try local storage as fallback
      if (!_isGuestMode) {
        try {
          final profile = _guestStorage.getUserProfile();
          if (profile != null) {
            return profile.toMap();
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
    }
    return null;
  }

  // ==================== AI Memories ====================

  /// Store AI memory
  Future<bool> storeMemory(Map<String, dynamic> memoryData) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('No user ID available');
      }

      if (_isGuestMode) {
        // Store locally
        final memories = _guestStorage.getAIMemories() ?? [];
        final newMemory = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          ...memoryData,
        };
        memories.add(newMemory);
        await _guestStorage.saveAIMemories(memories);
        developer.log(
          'AI memory saved to local storage',
          name: 'HybridStorage',
        );
        return true;
      } else {
        await _cloudStorage.storeMemory(memoryData);
        developer.log(
          'AI memory saved to cloud storage',
          name: 'HybridStorage',
        );
        return true;
      }
    } catch (e) {
      developer.log('Error storing AI memory: $e', name: 'HybridStorage');

      // Fallback to local storage
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final memories = _guestStorage.getAIMemories() ?? [];
            final newMemory = {
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'userId': userId,
              'createdAt': DateTime.now().toIso8601String(),
              ...memoryData,
            };
            memories.add(newMemory);
            await _guestStorage.saveAIMemories(memories);
            developer.log(
              'AI memory saved to local storage (fallback)',
              name: 'HybridStorage',
            );
            return true;
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
      return false;
    }
  }

  /// Query AI memories
  Future<List<Map<String, dynamic>>> queryMemories({
    String? type,
    int limit = 50,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return [];
      }

      if (_isGuestMode) {
        // Query locally
        final memories = _guestStorage.getAIMemories() ?? [];
        var filtered = memories.where((m) => m['userId'] == userId);

        if (type != null) {
          filtered = filtered.where((m) => m['type'] == type);
        }

        final result = filtered
            .take(limit)
            .toList()
            .cast<Map<String, dynamic>>();

        developer.log(
          'Retrieved ${result.length} AI memories from local storage',
          name: 'HybridStorage',
        );
        return result;
      } else {
        // Query cloud storage
        final memories = await _cloudStorage.queryMemories(
          type: type,
          limit: limit,
        );
        developer.log(
          'Retrieved ${memories.length} AI memories from cloud storage',
          name: 'HybridStorage',
        );
        return memories;
      }
    } catch (e) {
      developer.log('Error querying AI memories: $e', name: 'HybridStorage');

      // Fallback to local storage
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final memories = _guestStorage.getAIMemories() ?? [];
            var filtered = memories.where((m) => m['userId'] == userId);

            if (type != null) {
              filtered = filtered.where((m) => m['type'] == type);
            }

            return filtered.take(limit).toList().cast<Map<String, dynamic>>();
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
      return [];
    }
  }

  // ==================== Workout Sessions ====================

  /// Save workout session
  Future<String?> saveWorkoutSession(Map<String, dynamic> data) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('No user ID available');
      }

      if (_isGuestMode) {
        // Save locally
        final sessions = _guestStorage.getWorkoutSessions() ?? [];
        final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
        final session = {
          'id': sessionId,
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          ...data,
        };
        sessions.add(session);
        await _guestStorage.saveWorkoutSessions(sessions);
        developer.log(
          'Workout session saved to local storage',
          name: 'HybridStorage',
        );
        return sessionId;
      } else {
        final sessionId = await _cloudStorage.saveWorkoutSession(data);
        developer.log(
          'Workout session saved to cloud storage',
          name: 'HybridStorage',
        );
        return sessionId;
      }
    } catch (e) {
      developer.log('Error saving workout session: $e', name: 'HybridStorage');

      // Fallback to local storage
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final sessions = _guestStorage.getWorkoutSessions() ?? [];
            final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
            final session = {
              'id': sessionId,
              'userId': userId,
              'createdAt': DateTime.now().toIso8601String(),
              ...data,
            };
            sessions.add(session);
            await _guestStorage.saveWorkoutSessions(sessions);
            developer.log(
              'Workout session saved to local storage (fallback)',
              name: 'HybridStorage',
            );
            return sessionId;
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
      return null;
    }
  }

  /// Get workout sessions
  Future<List<Map<String, dynamic>>> getWorkoutSessions({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return [];
      }

      if (_isGuestMode) {
        // Query locally
        final sessions = _guestStorage.getWorkoutSessions() ?? [];
        var filtered = sessions.where((s) => s['userId'] == userId);

        if (startDate != null) {
          filtered = filtered.where((s) {
            final date = DateTime.tryParse(s['date'] ?? '');
            return date != null && !date.isBefore(startDate);
          });
        }

        if (endDate != null) {
          filtered = filtered.where((s) {
            final date = DateTime.tryParse(s['date'] ?? '');
            return date != null && !date.isAfter(endDate);
          });
        }

        final result = filtered
            .take(limit)
            .toList()
            .cast<Map<String, dynamic>>();

        developer.log(
          'Retrieved ${result.length} workout sessions from local storage',
          name: 'HybridStorage',
        );
        return result;
      } else {
        // Query cloud storage
        final sessions = await _cloudStorage.getWorkoutSessions(
          startDate: startDate,
          endDate: endDate,
          limit: limit,
        );
        developer.log(
          'Retrieved ${sessions.length} workout sessions from cloud storage',
          name: 'HybridStorage',
        );
        return sessions;
      }
    } catch (e) {
      developer.log(
        'Error getting workout sessions: $e',
        name: 'HybridStorage',
      );

      // Fallback to local storage
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final sessions = _guestStorage.getWorkoutSessions() ?? [];
            var filtered = sessions.where((s) => s['userId'] == userId);

            if (startDate != null) {
              filtered = filtered.where((s) {
                final date = DateTime.tryParse(s['date'] ?? '');
                return date != null && !date.isBefore(startDate);
              });
            }

            if (endDate != null) {
              filtered = filtered.where((s) {
                final date = DateTime.tryParse(s['date'] ?? '');
                return date != null && !date.isAfter(endDate);
              });
            }

            return filtered.take(limit).toList().cast<Map<String, dynamic>>();
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
      return [];
    }
  }

  // ==================== Weekly Progress ====================

  /// Save weekly progress
  Future<bool> saveWeeklyProgress(Map<String, dynamic> progressData) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('No user ID available');
      }

      if (_isGuestMode) {
        // Save locally
        final progress =
            _guestStorage.getWeeklyProgress(
              DateTime.parse(progressData['week_starting']),
            ) ??
            {};
        final weekKey = progressData['week_starting'].toString();
        progress[weekKey] = {
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          ...progressData,
        };
        await _guestStorage.saveWeeklyProgress(progress);
        developer.log(
          'Weekly progress saved to local storage',
          name: 'HybridStorage',
        );
        return true;
      } else {
        await _cloudStorage.saveWeeklyProgress(progressData);
        developer.log(
          'Weekly progress saved to cloud storage',
          name: 'HybridStorage',
        );
        return true;
      }
    } catch (e) {
      developer.log('Error saving weekly progress: $e', name: 'HybridStorage');

      // Fallback to local storage
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final progress =
                _guestStorage.getWeeklyProgress(
                  DateTime.parse(progressData['week_starting']),
                ) ??
                {};
            final weekKey = progressData['week_starting'].toString();
            progress[weekKey] = {
              'userId': userId,
              'createdAt': DateTime.now().toIso8601String(),
              ...progressData,
            };
            await _guestStorage.saveWeeklyProgress(progress);
            developer.log(
              'Weekly progress saved to local storage (fallback)',
              name: 'HybridStorage',
            );
            return true;
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
      return false;
    }
  }

  /// Get weekly progress
  Future<Map<String, dynamic>?> getWeeklyProgress(DateTime weekStart) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return null;
      }

      if (_isGuestMode) {
        // Query locally
        final progress = _guestStorage.getWeeklyProgress(weekStart);

        if (progress != null) {
          developer.log(
            'Weekly progress retrieved from local storage',
            name: 'HybridStorage',
          );
          return progress;
        }
      } else {
        // Query cloud storage
        final result = await _cloudStorage.getWeeklyProgress(weekStart);
        if (result != null) {
          developer.log(
            'Weekly progress retrieved from cloud storage',
            name: 'HybridStorage',
          );
          return result;
        }

        // Fallback to local storage
        final progress = _guestStorage.getWeeklyProgress(weekStart);

        if (progress != null) {
          developer.log(
            'Weekly progress retrieved from local storage (fallback)',
            name: 'HybridStorage',
          );
          return progress;
        }
      }
    } catch (e) {
      developer.log('Error getting weekly progress: $e', name: 'HybridStorage');

      // Try local storage as fallback
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final progress = _guestStorage.getWeeklyProgress(weekStart);
            if (progress != null) {
              return progress;
            }
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
    }
    return null;
  }

  // ==================== Session Readiness ====================

  /// Save session readiness input
  Future<String?> saveSessionReadinessInput(Map<String, dynamic> data) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('No user ID available');
      }

      if (_isGuestMode) {
        // Save locally
        final inputs = _guestStorage.getSessionReadinessInputs() ?? [];
        final inputId = DateTime.now().millisecondsSinceEpoch.toString();
        final input = {
          'id': inputId,
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          ...data,
        };
        inputs.add(input);
        await _guestStorage.saveSessionReadinessInputs(inputs);
        developer.log(
          'Session readiness saved to local storage',
          name: 'HybridStorage',
        );
        return inputId;
      } else {
        final inputId = await _cloudStorage.saveSessionReadinessInput(data);
        developer.log(
          'Session readiness saved to cloud storage',
          name: 'HybridStorage',
        );
        return inputId;
      }
    } catch (e) {
      developer.log(
        'Error saving session readiness: $e',
        name: 'HybridStorage',
      );

      // Fallback to local storage
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final inputs = _guestStorage.getSessionReadinessInputs() ?? [];
            final inputId = DateTime.now().millisecondsSinceEpoch.toString();
            final input = {
              'id': inputId,
              'userId': userId,
              'createdAt': DateTime.now().toIso8601String(),
              ...data,
            };
            inputs.add(input);
            await _guestStorage.saveSessionReadinessInputs(inputs);
            developer.log(
              'Session readiness saved to local storage (fallback)',
              name: 'HybridStorage',
            );
            return inputId;
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
      return null;
    }
  }

  /// Get session readiness input
  Future<Map<String, dynamic>?> getSessionReadinessInput(DateTime date) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return null;
      }

      if (_isGuestMode) {
        // Query locally
        final inputs = _guestStorage.getSessionReadinessInputs() ?? [];
        final result = inputs.firstWhere(
          (input) =>
              input['userId'] == userId &&
              input['session_date'] == date.toIso8601String().split('T')[0],
          orElse: () => {},
        );

        if (result.isNotEmpty) {
          developer.log(
            'Session readiness retrieved from local storage',
            name: 'HybridStorage',
          );
          return result.cast<String, dynamic>();
        }
      } else {
        // Query cloud storage
        final result = await _cloudStorage.getSessionReadinessInput(date);
        if (result != null) {
          developer.log(
            'Session readiness retrieved from cloud storage',
            name: 'HybridStorage',
          );
          return result;
        }

        // Fallback to local storage
        final inputs = _guestStorage.getSessionReadinessInputs() ?? [];
        final localResult = inputs.firstWhere(
          (input) =>
              input['userId'] == userId &&
              input['session_date'] == date.toIso8601String().split('T')[0],
          orElse: () => {},
        );

        if (localResult.isNotEmpty) {
          developer.log(
            'Session readiness retrieved from local storage (fallback)',
            name: 'HybridStorage',
          );
          return localResult.cast<String, dynamic>();
        }
      }
    } catch (e) {
      developer.log(
        'Error getting session readiness: $e',
        name: 'HybridStorage',
      );

      // Try local storage as fallback
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final inputs = _guestStorage.getSessionReadinessInputs() ?? [];
            final result = inputs.firstWhere(
              (input) =>
                  input['userId'] == userId &&
                  input['session_date'] == date.toIso8601String().split('T')[0],
              orElse: () => {},
            );

            if (result.isNotEmpty) {
              return result.cast<String, dynamic>();
            }
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
    }
    return null;
  }

  // ==================== Weekly Directives ====================

  /// Save weekly directive
  Future<String?> saveWeeklyDirective(Map<String, dynamic> data) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('No user ID available');
      }

      if (_isGuestMode) {
        // Save locally
        final directives = _guestStorage.getWeeklyDirectives() ?? [];
        final directiveId = DateTime.now().millisecondsSinceEpoch.toString();
        final directive = {
          'id': directiveId,
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
          ...data,
        };
        directives.add(directive);
        await _guestStorage.saveWeeklyDirectives(directives);
        developer.log(
          'Weekly directive saved to local storage',
          name: 'HybridStorage',
        );
        return directiveId;
      } else {
        final directiveId = await _cloudStorage.saveWeeklyDirective(data);
        developer.log(
          'Weekly directive saved to cloud storage',
          name: 'HybridStorage',
        );
        return directiveId;
      }
    } catch (e) {
      developer.log('Error saving weekly directive: $e', name: 'HybridStorage');

      // Fallback to local storage
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final directives = _guestStorage.getWeeklyDirectives() ?? [];
            final directiveId = DateTime.now().millisecondsSinceEpoch
                .toString();
            final directive = {
              'id': directiveId,
              'userId': userId,
              'createdAt': DateTime.now().toIso8601String(),
              ...data,
            };
            directives.add(directive);
            await _guestStorage.saveWeeklyDirectives(directives);
            developer.log(
              'Weekly directive saved to local storage (fallback)',
              name: 'HybridStorage',
            );
            return directiveId;
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
      return null;
    }
  }

  /// Get weekly directive
  Future<Map<String, dynamic>?> getWeeklyDirective(DateTime weekStart) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return null;
      }

      if (_isGuestMode) {
        // Query locally
        final directives = _guestStorage.getWeeklyDirectives() ?? [];
        final result = directives.firstWhere(
          (directive) =>
              directive['userId'] == userId &&
              directive['week_starting'] == _dateOnly(weekStart),
          orElse: () => {},
        );

        if (result.isNotEmpty) {
          developer.log(
            'Weekly directive retrieved from local storage',
            name: 'HybridStorage',
          );
          return result.cast<String, dynamic>();
        }
      } else {
        // Query cloud storage
        final result = await _cloudStorage.getWeeklyDirective(weekStart);
        if (result != null) {
          developer.log(
            'Weekly directive retrieved from cloud storage',
            name: 'HybridStorage',
          );
          return result;
        }

        // Fallback to local storage
        final directives = _guestStorage.getWeeklyDirectives() ?? [];
        final localResult = directives.firstWhere(
          (directive) =>
              directive['userId'] == userId &&
              directive['week_starting'] == _dateOnly(weekStart),
          orElse: () => {},
        );

        if (localResult.isNotEmpty) {
          developer.log(
            'Weekly directive retrieved from local storage (fallback)',
            name: 'HybridStorage',
          );
          return localResult.cast<String, dynamic>();
        }
      }
    } catch (e) {
      developer.log(
        'Error getting weekly directive: $e',
        name: 'HybridStorage',
      );

      // Try local storage as fallback
      if (!_isGuestMode) {
        try {
          final userId = _currentUserId;
          if (userId != null) {
            final directives = _guestStorage.getWeeklyDirectives() ?? [];
            final result = directives.firstWhere(
              (directive) =>
                  directive['userId'] == userId &&
                  directive['week_starting'] == _dateOnly(weekStart),
              orElse: () => {},
            );

            if (result.isNotEmpty) {
              return result.cast<String, dynamic>();
            }
          }
        } catch (fallbackError) {
          developer.log(
            'Fallback failed: $fallbackError',
            name: 'HybridStorage',
          );
        }
      }
    }
    return null;
  }

  // ==================== Utility Methods ====================

  /// Format date to YYYY-MM-DD string
  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  /// Check if device is online
  bool get isOnline => true; // TODO: Implement actual connectivity check

  /// Sync local data to cloud (for when user authenticates)
  Future<void> syncToCloud() async {
    if (_isGuestMode || _currentUserId == null) {
      developer.log(
        'Cannot sync to cloud: guest mode or no user ID',
        name: 'HybridStorage',
      );
      return;
    }

    developer.log('Starting sync to cloud...', name: 'HybridStorage');

    try {
      // TODO: Implement sync logic for each data type
      // This would involve:
      // 1. Getting all local data
      // 2. Uploading to cloud with proper conflict resolution
      // 3. Clearing local storage after successful sync

      developer.log('Sync to cloud completed', name: 'HybridStorage');
    } catch (e) {
      developer.log('Sync to cloud failed: $e', name: 'HybridStorage');
    }
  }
}
