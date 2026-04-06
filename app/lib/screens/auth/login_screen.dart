import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// Login Screen - Spartan themed authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: GlassCard(
              elevated: true,
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Title
                    _buildTitle(),
                    const SizedBox(height: 32),

                    // Error message
                    if (authProvider.error != null) ...[
                      _buildErrorMessage(authProvider.error!),
                      const SizedBox(height: 16),
                    ],

                    // Email field
                    _buildEmailField(),
                    const SizedBox(height: 16),

                    // Password field
                    _buildPasswordField(),
                    const SizedBox(height: 8),

                    // Forgot password
                    _buildForgotPasswordLink(),
                    const SizedBox(height: 24),

                    // Sign in button
                    GradientButton(
                      label: 'SIGN IN',
                      onPressed: authProvider.isLoading ? null : _handleSignIn,
                      isLoading: authProvider.isLoading,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // Google Sign in
                    _buildGoogleSignInButton(authProvider),

                    const SizedBox(height: 24),

                    // Sign up link
                    _buildSignUpLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LaconicTheme.spartanBronze, LaconicTheme.warmGold],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: LaconicTheme.spartanBronze.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_outlined,
            size: 48,
            color: LaconicTheme.deepBlack,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'NEOSPARTAN',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(letterSpacing: 6),
        ),
        const SizedBox(height: 8),
        Text(
          'Forge Your Discipline',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: LaconicTheme.mistGray),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'EMAIL',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LaconicTheme.spartanBronze),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[900],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter your email';
        }
        if (!value.contains('@')) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'PASSWORD',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LaconicTheme.spartanBronze),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[900],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ForgotPasswordScreen(),
            ),
          );
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: LaconicTheme.spartanBronze.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[800])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildGoogleSignInButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
        icon: Image.asset(
          'assets/google_logo.png',
          height: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.g_mobiledata, color: Colors.white);
          },
        ),
        label: const Text(
          'Sign in with Google',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[700]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.grey[400]),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
          child: Text(
            'SIGN UP',
            style: TextStyle(
              color: LaconicTheme.spartanBronze,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthProvider>().clearError();

    final success = await context.read<AuthProvider>().signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // AuthProvider will handle navigation via auth state
    }
  }

  Future<void> _handleGoogleSignIn() async {
    context.read<AuthProvider>().clearError();

    final success = await context.read<AuthProvider>().signInWithGoogle();

    if (success && mounted) {
      // AuthProvider will handle navigation via auth state
    }
  }
}
