import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';
import '../services/supabase_auth_service.dart';
import '../services/guest_storage_service.dart';

/// Provider managing authentication state and user profile
/// Supports both authenticated (Supabase) and guest (local storage) modes
class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final UserRepository _userRepository = UserRepository();
  final GuestStorageService _guestStorage = GuestStorageService();

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isGuestMode = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isGuestMode => _isGuestMode;
  bool get isAuthenticated => _user != null || _isGuestMode;
  String? get userId => _isGuestMode ? 'guest_user' : _user?.id;
  String? get displayName =>
      _user?.userMetadata?['display_name'] ?? _userProfile?.displayName;
  String? get email => _user?.email;
  String? get photoUrl =>
      _user?.userMetadata?['photo_url'] ?? _userProfile?.photoUrl;

  AuthProvider() {
    _init();
  }

  Future<bool> saveOnboardingProfile(UserProfile profile) async {
    _setLoading(true);
    _clearError();

    try {
      if (_isGuestMode) {
        // Save to local storage for guest mode
        await _guestStorage.saveUserProfile(profile);
        await _guestStorage.completeOnboarding();
        _userProfile = profile;
        notifyListeners();
        return true;
      } else {
        // Save to Supabase for authenticated users
        final ok = await _userRepository.saveUserProfile(profile);
        if (!ok) {
          _setError('Failed to save onboarding profile');
          return false;
        }

        _userProfile = profile;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Initialize auth state listener
  void _init() {
    // First check if we're in guest mode
    _checkGuestMode();

    _authStateSubscription = _authService.authState.listen((
      AuthState authState,
    ) async {
      developer.log(
        'Auth state changed: ${authState.session?.user.id ?? 'signed out'}',
        name: 'AuthProvider',
      );
      _user = authState.session?.user;

      if (_user != null) {
        // User is authenticated with Supabase - not in guest mode
        _isGuestMode = false;
        await _guestStorage.disableGuestMode();
        // Load or create user profile
        await _loadUserProfile();
      } else if (!_isGuestMode) {
        // Not authenticated and not in guest mode
        _userProfile = null;
      }

      _isInitialized = true;
      notifyListeners();
    });
  }

  /// Check if guest mode was previously enabled
  void _checkGuestMode() {
    _isGuestMode = _guestStorage.isGuestMode;
    if (_isGuestMode) {
      // Load guest profile
      _userProfile = _guestStorage.getUserProfile();
      _isInitialized = true;
      developer.log(
        'Guest mode detected - profile loaded',
        name: 'AuthProvider',
      );
    }
  }

  /// Enable guest mode for users who don't want to sign in
  Future<bool> enableGuestMode() async {
    _setLoading(true);
    _clearError();

    try {
      await _guestStorage.initialize();
      await _guestStorage.enableGuestMode();
      _isGuestMode = true;

      // Create a default guest profile
      final now = DateTime.now();
      final guestProfile = UserProfile(
        userId: 'guest_user',
        displayName: 'Guest Warrior',
        bodyComposition: const BodyComposition(
          weight: 70,
          height: 175,
          age: 25,
        ),
        fitnessLevel: FitnessLevel.beginner,
        trainingGoal: TrainingGoal.generalCombat,
        createdAt: now,
        updatedAt: now,
        hasCompletedOnboarding: false,
      );

      await _guestStorage.saveUserProfile(guestProfile);
      _userProfile = guestProfile;

      developer.log('Guest mode enabled', name: 'AuthProvider');
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to enable guest mode: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in anonymously (enables guest mode)
  Future<bool> signInAnonymously() async {
    return enableGuestMode();
  }

  /// Convert guest account to authenticated account
  Future<bool> convertGuestToAuthenticated(
    String email,
    String password,
  ) async {
    if (!_isGuestMode) {
      _setError('Not in guest mode');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // TODO: Implement migration of guest data to Supabase
      // This would involve:
      // 1. Creating a new Supabase account
      // 2. Migrating all guest data to the new account
      // 3. Clearing local guest data

      developer.log(
        'Guest to authenticated conversion not yet implemented',
        name: 'AuthProvider',
      );
      _setError('Guest account conversion coming soon');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load user profile from repository
  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      _userProfile = await _userRepository.getUserProfile(_user!.id);

      if (_userProfile == null) {
        final now = DateTime.now();
        final bootstrapProfile = UserProfile(
          userId: _user!.id,
          displayName: _user?.userMetadata?['display_name'] ?? _user?.email,
          photoUrl: _user?.userMetadata?['photo_url'],
          bodyComposition: const BodyComposition(weight: 0, height: 0, age: 0),
          fitnessLevel: FitnessLevel.beginner,
          trainingGoal: TrainingGoal.generalCombat,
          createdAt: now,
          updatedAt: now,
          hasCompletedOnboarding: false,
        );

        final created = await _userRepository.saveUserProfile(bootstrapProfile);
        if (created) {
          _userProfile = bootstrapProfile;
        }
      }

      notifyListeners();
    } catch (e) {
      developer.log('Error loading user profile: $e', name: 'AuthProvider');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        developer.log('Sign in successful', name: 'AuthProvider');
        return true;
      } else {
        _setError('Sign in failed');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (response.user != null) {
        developer.log('Sign up successful', name: 'AuthProvider');
        return true;
      } else {
        _setError('Sign up failed');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signInWithGoogle();

      if (response.user != null) {
        developer.log('Google sign in successful', name: 'AuthProvider');
        return true;
      } else {
        _setError('Google sign in failed');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out - handles both authenticated and guest modes
  Future<void> signOut() async {
    _setLoading(true);

    try {
      if (_isGuestMode) {
        // Clear guest data and exit guest mode
        await _guestStorage.clearAllData();
        await _guestStorage.disableGuestMode();
        _isGuestMode = false;
        _userProfile = null;
        developer.log('Guest session ended', name: 'AuthProvider');
      } else {
        // Sign out from Supabase
        await _authService.signOut();
        developer.log('Sign out successful', name: 'AuthProvider');
      }
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      developer.log('Password reset email sent', name: 'AuthProvider');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email (alias for resetPassword)
  Future<bool> sendPasswordResetEmail(String email) async {
    return resetPassword(email);
  }

  /// Update user profile (supports both authenticated and guest modes)
  Future<bool> updateProfile({String? displayName, String? photoUrl}) async {
    _setLoading(true);
    _clearError();

    try {
      if (_userProfile == null) {
        _setError('No profile to update');
        return false;
      }

      final updatedProfile = UserProfile(
        userId: _userProfile!.userId,
        displayName: displayName ?? _userProfile!.displayName,
        photoUrl: photoUrl ?? _userProfile!.photoUrl,
        bodyComposition: _userProfile!.bodyComposition,
        fitnessLevel: _userProfile!.fitnessLevel,
        experienceLevel: _userProfile!.experienceLevel,
        trainingGoal: _userProfile!.trainingGoal,
        philosophicalBaseline: _userProfile!.philosophicalBaseline,
        trainingDaysPerWeek: _userProfile!.trainingDaysPerWeek,
        preferredWorkoutDuration: _userProfile!.preferredWorkoutDuration,
        injuriesOrLimitations: _userProfile!.injuriesOrLimitations,
        dateOfBirth: _userProfile!.dateOfBirth,
        createdAt: _userProfile!.createdAt,
        updatedAt: DateTime.now(),
        hasCompletedOnboarding: _userProfile!.hasCompletedOnboarding,
      );

      if (_isGuestMode) {
        // Save to local storage for guest mode
        await _guestStorage.saveUserProfile(updatedProfile);
      } else {
        // Update auth metadata for Supabase users
        await _authService.updateProfile(
          displayName: displayName,
          photoUrl: photoUrl,
        );
        // Save to Supabase
        await _userRepository.saveUserProfile(updatedProfile);
      }

      _userProfile = updatedProfile;
      developer.log('Profile updated successfully', name: 'AuthProvider');
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.deleteAccount();
      developer.log('Account deleted successfully', name: 'AuthProvider');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh session
  Future<void> refreshSession() async {
    try {
      await _authService.refreshSession();
    } catch (e) {
      developer.log('Session refresh failed: $e', name: 'AuthProvider');
    }
  }

  /// Check if user is in anonymous/guest mode
  bool get isAnonymous => _isGuestMode;

  /// Link guest account to email (convert guest to authenticated)
  Future<bool> linkAnonymousToEmail(String email, String password) async {
    return convertGuestToAuthenticated(email, password);
  }

  /// Clear error
  void clearError() {
    _clearError();
  }

  /// Clear error (private)
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set error
  void _setError(String error) {
    _error = error;
    developer.log('Auth error: $error', name: 'AuthProvider');
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _authService.dispose();
    super.dispose();
  }
}
