import 'dart:developer' as developer;
import '../models/user_profile.dart';
import '../services/supabase_database_service.dart';

/// Repository for User Profile CRUD operations using Supabase
class UserRepository {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final data = await _database.getUserProfile(userId);
      
      if (data != null) {
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      developer.log('Error getting user profile: $e', name: 'UserRepository');
      return null;
    }
  }

  /// Create user profile
  Future<bool> createUserProfile(UserProfile profile) async {
    return saveUserProfile(profile);
  }

  /// Get user profile stream for real-time updates
  Stream<UserProfile?> userProfileStream(String userId) {
    return _database
        .subscribeToTable('user_profiles', column: 'id', value: userId)
        .map((data) => data.isNotEmpty ? UserProfile.fromMap(data.first) : null);
  }

  /// Complete onboarding
  Future<bool> completeOnboarding(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        final updatedProfile = UserProfile(
          userId: profile.userId,
          displayName: profile.displayName,
          photoUrl: profile.photoUrl,
          bodyComposition: profile.bodyComposition,
          fitnessLevel: profile.fitnessLevel,
          experienceLevel: profile.experienceLevel,
          trainingGoal: profile.trainingGoal,
          philosophicalBaseline: profile.philosophicalBaseline,
          trainingDaysPerWeek: profile.trainingDaysPerWeek,
          preferredWorkoutDuration: profile.preferredWorkoutDuration,
          injuriesOrLimitations: profile.injuriesOrLimitations,
          dateOfBirth: profile.dateOfBirth,
          createdAt: profile.createdAt,
          updatedAt: DateTime.now(),
          hasCompletedOnboarding: true,
        );
        return saveUserProfile(updatedProfile);
      }
      return false;
    } catch (e) {
      developer.log('Error completing onboarding: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Update workout stats
  Future<bool> updateWorkoutStats(String userId, Map<String, dynamic> stats) async {
    try {
      // This would update workout-related stats in the user profile
      // Implementation depends on how you want to track these stats
      developer.log('Updating workout stats for user: $userId', name: 'UserRepository');
      return true;
    } catch (e) {
      developer.log('Error updating workout stats: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Save or update user profile
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      await _database.saveUserProfile(profile.userId, profile.toMap());
      developer.log('User profile saved successfully', name: 'UserRepository');
      return true;
    } catch (e) {
      developer.log('Error saving user profile: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(UserProfile profile) async {
    return saveUserProfile(profile); // Supabase upsert handles both
  }

  /// Delete user profile
  Future<bool> deleteUserProfile(String userId) async {
    try {
      await _database.deleteRecord('user_profiles', userId);
      developer.log('User profile deleted successfully', name: 'UserRepository');
      return true;
    } catch (e) {
      developer.log('Error deleting user profile: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    final profile = await getUserProfile(userId);
    return profile != null;
  }

  /// Get all user profiles (admin only)
  Future<List<UserProfile>> getAllUserProfiles() async {
    try {
      final response = await _database.executeQuery('user_profiles');
      
      final profiles = response.map((data) => UserProfile.fromMap(data)).toList();
      return profiles;
    } catch (e) {
      developer.log('Error getting all user profiles: $e', name: 'UserRepository');
      return [];
    }
  }
}
