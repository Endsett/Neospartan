import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service handling all authentication operations
/// Supports Google Sign-in, Email/Password, and Anonymous authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Check if user is anonymous
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      developer.log('Starting Google Sign-in', name: 'AuthService');

      // Trigger Google Sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException(
          'Google Sign-in cancelled',
          AuthErrorCode.cancelled,
        );
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      developer.log(
        'Google Sign-in successful: ${userCredential.user?.uid}',
        name: 'AuthService',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Google Sign-in Firebase error: ${e.code}',
          name: 'AuthService', error: e);
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    } catch (e) {
      developer.log('Google Sign-in error: $e', name: 'AuthService', error: e);
      throw AuthException(
        'Failed to sign in with Google. Please try again.',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Sign up with Email and Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      developer.log('Starting Email Sign-up', name: 'AuthService');

      // Create user
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Reload user to get updated info
      await userCredential.user?.reload();

      developer.log(
        'Email Sign-up successful: ${userCredential.user?.uid}',
        name: 'AuthService',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Email Sign-up Firebase error: ${e.code}',
          name: 'AuthService', error: e);
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    } catch (e) {
      developer.log('Email Sign-up error: $e', name: 'AuthService', error: e);
      throw AuthException(
        'Failed to create account. Please try again.',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      developer.log('Starting Email Sign-in', name: 'AuthService');

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      developer.log(
        'Email Sign-in successful: ${userCredential.user?.uid}',
        name: 'AuthService',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Email Sign-in Firebase error: ${e.code}',
          name: 'AuthService', error: e);
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    } catch (e) {
      developer.log('Email Sign-in error: $e', name: 'AuthService', error: e);
      throw AuthException(
        'Failed to sign in. Please try again.',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      developer.log('Sending password reset email to: $email',
          name: 'AuthService');

      await _auth.sendPasswordResetEmail(email: email);

      developer.log('Password reset email sent', name: 'AuthService');
    } on FirebaseAuthException catch (e) {
      developer.log('Password reset Firebase error: ${e.code}',
          name: 'AuthService', error: e);
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    } catch (e) {
      developer.log('Password reset error: $e', name: 'AuthService', error: e);
      throw AuthException(
        'Failed to send password reset email. Please try again.',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Sign in anonymously for preview/onboarding
  Future<UserCredential> signInAnonymously() async {
    try {
      developer.log('Starting Anonymous Sign-in', name: 'AuthService');

      final UserCredential userCredential = await _auth.signInAnonymously();

      developer.log(
        'Anonymous Sign-in successful: ${userCredential.user?.uid}',
        name: 'AuthService',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Anonymous Sign-in Firebase error: ${e.code}',
          name: 'AuthService', error: e);
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    } catch (e) {
      developer.log('Anonymous Sign-in error: $e', name: 'AuthService',
          error: e);
      throw AuthException(
        'Failed to start preview mode. Please try again.',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Link anonymous account to Google
  Future<UserCredential> linkAnonymousToGoogle() async {
    try {
      if (!isAnonymous) {
        throw AuthException(
          'User is not anonymous',
          AuthErrorCode.invalidState,
        );
      }

      developer.log('Linking anonymous account to Google', name: 'AuthService');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException(
          'Google Sign-in cancelled',
          AuthErrorCode.cancelled,
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await currentUser!.linkWithCredential(credential);

      developer.log(
        'Anonymous account linked to Google: ${userCredential.user?.uid}',
        name: 'AuthService',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Link to Google Firebase error: ${e.code}',
          name: 'AuthService', error: e);
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    } catch (e) {
      developer.log('Link to Google error: $e', name: 'AuthService', error: e);
      throw AuthException(
        'Failed to link account. Please try again.',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Link anonymous account to Email/Password
  Future<UserCredential> linkAnonymousToEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      if (!isAnonymous) {
        throw AuthException(
          'User is not anonymous',
          AuthErrorCode.invalidState,
        );
      }

      developer.log('Linking anonymous account to Email', name: 'AuthService');

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final UserCredential userCredential =
          await currentUser!.linkWithCredential(credential);

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      developer.log(
        'Anonymous account linked to Email: ${userCredential.user?.uid}',
        name: 'AuthService',
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Link to Email Firebase error: ${e.code}',
          name: 'AuthService', error: e);
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    } catch (e) {
      developer.log('Link to Email error: $e', name: 'AuthService', error: e);
      throw AuthException(
        'Failed to link account. Please try again.',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      developer.log('Signing out user', name: 'AuthService');

      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _auth.signOut();

      developer.log('Sign out successful', name: 'AuthService');
    } catch (e) {
      developer.log('Sign out error: $e', name: 'AuthService', error: e);
      throw AuthException(
        'Failed to sign out. Please try again.',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      developer.log('Deleting user account', name: 'AuthService');

      await currentUser?.delete();

      developer.log('Account deleted', name: 'AuthService');
    } on FirebaseAuthException catch (e) {
      developer.log('Delete account Firebase error: ${e.code}',
          name: 'AuthService', error: e);
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    } catch (e) {
      developer.log('Delete account error: $e', name: 'AuthService', error: e);
      throw AuthException(
        'Failed to delete account. Please try again.',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Reauthenticate user (required for sensitive operations)
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw AuthException(
          'No authenticated user',
          AuthErrorCode.notAuthenticated,
        );
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.reload();
    } catch (e) {
      throw AuthException(
        'Failed to update display name',
        AuthErrorCode.unknown,
      );
    }
  }

  /// Update user email
  Future<void> updateEmail(String newEmail) async {
    try {
      await currentUser?.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getFirebaseErrorMessage(e.code),
        _mapFirebaseErrorCode(e.code),
      );
    }
  }

  /// Get Firebase error message
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Map Firebase error code to app error code
  AuthErrorCode _mapFirebaseErrorCode(String code) {
    switch (code) {
      case 'invalid-email':
      case 'weak-password':
        return AuthErrorCode.invalidInput;
      case 'user-not-found':
      case 'wrong-password':
        return AuthErrorCode.invalidCredentials;
      case 'email-already-in-use':
        return AuthErrorCode.emailInUse;
      case 'user-disabled':
        return AuthErrorCode.accountDisabled;
      case 'too-many-requests':
        return AuthErrorCode.rateLimited;
      case 'network-request-failed':
        return AuthErrorCode.networkError;
      case 'requires-recent-login':
        return AuthErrorCode.reauthenticationRequired;
      default:
        return AuthErrorCode.unknown;
    }
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final AuthErrorCode code;

  AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Authentication error codes
enum AuthErrorCode {
  unknown,
  cancelled,
  invalidInput,
  invalidCredentials,
  emailInUse,
  accountDisabled,
  notAuthenticated,
  invalidState,
  networkError,
  rateLimited,
  reauthenticationRequired,
}
