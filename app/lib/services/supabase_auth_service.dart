import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Authentication Service
/// Handles all authentication operations using Supabase Auth
class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  final SupabaseClient _supabase = SupabaseConfig.client;
  StreamController<AuthState>? _authStateController;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get authentication state stream
  Stream<AuthState> get authState {
    _authStateController ??= StreamController<AuthState>.broadcast();
    _supabase.auth.onAuthStateChange.listen((data) {
      _authStateController?.add(data);
    });
    return _authStateController!.stream;
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      debugPrint('Signing up with email: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      debugPrint('Sign up successful: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Signing in with email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('Sign in successful: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      debugPrint('Signing in with Google');

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://callback',
      );

      debugPrint('Google sign in initiated');
      // signInWithOAuth might return bool or AuthResponse depending on version
      if (response is AuthResponse) {
        return response;
      } else {
        // Return a default response if boolean is returned
        throw Exception('OAuth sign-in requires redirect completion');
      }
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      debugPrint('Signing out');
      await _supabase.auth.signOut();
      debugPrint('Sign out successful');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('Sending password reset to: $email');
      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('Password reset email sent');
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  /// Update user metadata
  Future<User> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (photoUrl != null) updates['photo_url'] = photoUrl;

      final response = await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );

      debugPrint('Profile updated successfully');
      return response.user!;
    } catch (e) {
      debugPrint('Profile update error: $e');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');

      // First delete user profile data
      await _supabase.from('user_profiles').delete().eq('id', user.id);

      // Then delete the auth user (requires admin privileges)
      // This should be done via a Supabase Edge Function
      debugPrint('Account deletion requested');

      await signOut();
    } catch (e) {
      debugPrint('Account deletion error: $e');
      rethrow;
    }
  }

  /// Refresh session
  Future<Session?> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response.session;
    } catch (e) {
      debugPrint('Session refresh error: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController?.close();
    _authStateController = null;
  }
}
