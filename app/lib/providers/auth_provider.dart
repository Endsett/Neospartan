import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';

/// Provider managing authentication state and user profile
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  StreamSubscription<User?>? _authStateSubscription;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  String? get userId => _user?.uid;
  String? get displayName => _user?.displayName ?? _userProfile?.displayName;
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;

  AuthProvider() {
    _init();
  }

  /// Initialize auth state listener
  void _init() {
    _authStateSubscription = _authService.authStateChanges.listen(
      (User? user) async {
        developer.log(
          'Auth state changed: ${user?.uid ?? 'signed out'}',
          name: 'AuthProvider',
        );
        _user = user;

        if (user != null) {
          // Load or create user profile
          await _loadUserProfile();
        } else {
          _userProfile = null;
        }

        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        developer.log(
          'Auth state stream error: $error',
          name: 'AuthProvider',
          error: error,
        );
        _error = 'Authentication service error';
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    try {
      if (_user == null) return;

      _userProfile = await _userRepository.getUserProfile(_user!.uid);

      // If profile doesn't exist, create it
      if (_userProfile == null) {
        final isGuest = _user!.isAnonymous;
        _userProfile = UserProfile(
          userId: _user!.uid,
          displayName: isGuest
              ? 'Guest Spartan'
              : (_user!.displayName ?? 'Spartan'),
          photoUrl: _user!.photoURL,
          bodyComposition: const BodyComposition(
            weight: 70,
            height: 175,
            age: 25,
          ),
          fitnessLevel: FitnessLevel.beginner,
          trainingGoal: TrainingGoal.generalCombat,
          experienceLevel: ExperienceLevel.novice,
          philosophicalBaseline: isGuest ? 'Just exploring' : null,
          createdAt: DateTime.now(),
        );

        await _userRepository.createUserProfile(_userProfile!);
        developer.log(
          'Created new user profile for ${_user!.uid}',
          name: 'AuthProvider',
        );
      }
    } catch (e) {
      developer.log(
        'Error loading user profile: $e',
        name: 'AuthProvider',
        error: e,
      );
      // Don't throw - user can still use app with basic profile
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.signInWithGoogle();
      // Profile will be loaded by auth state listener
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      developer.log(
        'Google sign in error: ${e.message}',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      developer.log(
        'Unexpected Google sign in error: $e',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    }
  }

  /// Sign up with Email and Password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      developer.log(
        'Email sign up error: ${e.message}',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      developer.log(
        'Unexpected email sign up error: $e',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with Email and Password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.signInWithEmail(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      developer.log(
        'Email sign in error: ${e.message}',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      developer.log(
        'Unexpected email sign in error: $e',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      developer.log(
        'Password reset error: ${e.message}',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      developer.log(
        'Unexpected password reset error: $e',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    }
  }

  /// Sign in anonymously (preview mode)
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.signInAnonymously();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      developer.log(
        'Anonymous sign in error: ${e.message}',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      developer.log(
        'Unexpected anonymous sign in error: $e',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    }
  }

  /// Link anonymous account to Google
  Future<bool> linkAnonymousToGoogle() async {
    if (!isAnonymous) {
      _error = 'Account is not anonymous';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      await _authService.linkAnonymousToGoogle();
      // Profile will be updated by auth state listener
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      developer.log(
        'Link to Google error: ${e.message}',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      developer.log(
        'Unexpected link to Google error: $e',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    }
  }

  /// Link anonymous account to Email
  Future<bool> linkAnonymousToEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!isAnonymous) {
      _error = 'Account is not anonymous';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      await _authService.linkAnonymousToEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      // Update profile with new info
      _userProfile = _userProfile!.copyWith(
        displayName: displayName,
        updatedAt: DateTime.now(),
      );

      await _userRepository.saveUserProfile(_userProfile!);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      developer.log(
        'Link to Email error: ${e.message}',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      developer.log(
        'Unexpected link to Email error: $e',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.signOut();
      _user = null;
      _userProfile = null;
      _setLoading(false);
    } on AuthException catch (e) {
      _error = e.message;
      developer.log(
        'Sign out error: ${e.message}',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
    } catch (e) {
      _error = 'An unexpected error occurred';
      developer.log(
        'Unexpected sign out error: $e',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    String? philosophicalBaseline,
    ExperienceLevel? experienceLevel,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    List<String>? fitnessGoals,
    List<String>? equipment,
    List<String>? injuryHistory,
    Map<String, dynamic>? preferences,
    BodyComposition? bodyComposition,
    FitnessLevel? fitnessLevel,
    TrainingGoal? trainingGoal,
    int? trainingDaysPerWeek,
    int? preferredWorkoutDuration,
    List<String>? injuriesOrLimitations,
    bool? enablePushNotifications,
    bool? enableWeeklyEmails,
    String? preferredWorkoutTime,
    bool? hasCompletedOnboarding,
  }) async {
    if (_user == null || _userProfile == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      // Update Firebase Auth display name if provided
      if (displayName != null && displayName != _user!.displayName) {
        await _authService.updateDisplayName(displayName);
      }

      // Update profile in Firestore
      _userProfile = _userProfile!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
        philosophicalBaseline: philosophicalBaseline,
        experienceLevel: experienceLevel,
        bodyComposition: bodyComposition,
        fitnessLevel: fitnessLevel,
        trainingGoal: trainingGoal,
        trainingDaysPerWeek: trainingDaysPerWeek,
        preferredWorkoutDuration: preferredWorkoutDuration,
        injuriesOrLimitations: injuriesOrLimitations,
        hasCompletedOnboarding:
            hasCompletedOnboarding ?? _userProfile!.hasCompletedOnboarding,
        updatedAt: DateTime.now(),
      );

      await _userRepository.saveUserProfile(_userProfile!);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Failed to update profile';
      developer.log('Update profile error: $e', name: 'AuthProvider', error: e);
      _setLoading(false);
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.deleteAccount();
      _user = null;
      _userProfile = null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      developer.log(
        'Delete account error: ${e.message}',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      developer.log(
        'Unexpected delete account error: $e',
        name: 'AuthProvider',
        error: e,
      );
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
