import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Repository for User Profile CRUD operations
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();

      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
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
      await _usersCollection
          .doc(profile.userId)
          .set(
            profile.copyWith(updatedAt: DateTime.now()).toMap(),
            SetOptions(merge: true),
          );
      developer.log(
        'User profile saved: ${profile.userId}',
        name: 'UserRepository',
      );
      return true;
    } catch (e) {
      developer.log('Error saving user profile: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Create new user profile
  Future<bool> createUserProfile(UserProfile profile) async {
    try {
      await _usersCollection.doc(profile.userId).set(profile.toMap());
      developer.log(
        'User profile created: ${profile.userId}',
        name: 'UserRepository',
      );
      return true;
    } catch (e) {
      developer.log('Error creating user profile: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Update specific fields of user profile
  Future<bool> updateProfileFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _usersCollection.doc(userId).update({
        ...fields,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      developer.log('User profile updated: $userId', name: 'UserRepository');
      return true;
    } catch (e) {
      developer.log(
        'Error updating profile fields: $e',
        name: 'UserRepository',
      );
      return false;
    }
  }

  /// Update workout stats (workouts completed, streak, etc.)
  Future<bool> updateWorkoutStats(
    String userId, {
    int? workoutsCompleted,
    int? workoutMinutes,
    DateTime? lastWorkoutDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (workoutsCompleted != null) {
        updates['total_workouts_completed'] = FieldValue.increment(
          workoutsCompleted,
        );
      }
      if (workoutMinutes != null) {
        updates['total_workout_minutes'] = FieldValue.increment(workoutMinutes);
      }
      if (lastWorkoutDate != null) {
        updates['last_workout_date'] = lastWorkoutDate.toIso8601String();
      }

      await _usersCollection.doc(userId).update(updates);
      return true;
    } catch (e) {
      developer.log('Error updating workout stats: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Update streak
  Future<bool> updateStreak(
    String userId,
    int currentStreak,
    int longestStreak,
  ) async {
    try {
      await _usersCollection.doc(userId).update({
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      developer.log('Error updating streak: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Mark onboarding as complete
  Future<bool> completeOnboarding(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'has_completed_onboarding': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      developer.log('Error completing onboarding: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Delete user profile
  Future<bool> deleteUserProfile(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      developer.log('User profile deleted: $userId', name: 'UserRepository');
      return true;
    } catch (e) {
      developer.log('Error deleting user profile: $e', name: 'UserRepository');
      return false;
    }
  }

  /// Stream user profile for real-time updates
  Stream<UserProfile?> userProfileStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      developer.log(
        'Error checking user existence: $e',
        name: 'UserRepository',
      );
      return false;
    }
  }
}
