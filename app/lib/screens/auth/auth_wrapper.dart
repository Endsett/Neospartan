import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import 'login_screen.dart';

/// Auth Wrapper - Routes users based on authentication state
/// Shows Login screen for unauthenticated users, transitions to main app when authenticated
class AuthWrapper extends StatefulWidget {
  final Widget authenticatedChild;
  final VoidCallback? onAuthComplete;

  const AuthWrapper({
    super.key,
    required this.authenticatedChild,
    this.onAuthComplete,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Still initializing - show loading
    if (!authProvider.isInitialized) {
      return _buildLoadingScreen();
    }

    // Not authenticated - show login
    if (!authProvider.isAuthenticated) {
      _animationController.reverse();
      return const LoginScreen();
    }

    // Authenticated - show main app with transition
    _animationController.forward();
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.authenticatedChild,
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 64,
              color: LaconicTheme.spartanBronze,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                LaconicTheme.spartanBronze,
              ),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'INITIALIZING...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Auth gate for checking onboarding status after authentication
class AuthGate extends StatelessWidget {
  final Widget homeScreen;
  final Widget onboardingScreen;

  const AuthGate({
    super.key,
    required this.homeScreen,
    required this.onboardingScreen,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isInitialized) {
      return _buildLoadingScreen();
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Check if user has completed onboarding by looking at their profile
    // If they're new, the profile will have default values
    final profile = authProvider.userProfile;
    final needsOnboarding =
        profile == null ||
        profile.experienceLevel == null ||
        profile.philosophicalBaseline == null;

    if (needsOnboarding) {
      return onboardingScreen;
    }

    return homeScreen;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 64,
              color: LaconicTheme.spartanBronze,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                LaconicTheme.spartanBronze,
              ),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'LOADING...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
