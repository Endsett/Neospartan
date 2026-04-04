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

  /// Save or update user profile
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      await _database.saveUserProfile(userId: profile.userId, data: profile.toMap());
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
