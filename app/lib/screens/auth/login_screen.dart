import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// Login Screen - Blood & Bronze themed authentication
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
      backgroundColor: LaconicTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: LaconicTheme.surfaceContainerLow,
              ),
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
                    _buildSignInButton(authProvider),
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
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: LaconicTheme.secondary),
          child: const Icon(
            Icons.shield,
            size: 48,
            color: LaconicTheme.onSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'NEOSPARTAN',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: LaconicTheme.onSurface,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Forge Your Discipline',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: LaconicTheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.error.withValues(alpha: 0.1),
        border: Border.all(color: LaconicTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: LaconicTheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(color: LaconicTheme.error, fontSize: 14),
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
      style: GoogleFonts.inter(color: LaconicTheme.onSurface),
      decoration: InputDecoration(
        labelText: 'EMAIL',
        labelStyle: GoogleFonts.inter(
          color: LaconicTheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: LaconicTheme.outline,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: LaconicTheme.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: LaconicTheme.secondary, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: LaconicTheme.error),
        ),
        filled: true,
        fillColor: LaconicTheme.surfaceContainer,
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
      style: GoogleFonts.inter(color: LaconicTheme.onSurface),
      decoration: InputDecoration(
        labelText: 'PASSWORD',
        labelStyle: GoogleFonts.inter(
          color: LaconicTheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        prefixIcon: const Icon(Icons.lock_outline, color: LaconicTheme.outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: LaconicTheme.outline,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: LaconicTheme.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: LaconicTheme.secondary, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: LaconicTheme.error),
        ),
        filled: true,
        fillColor: LaconicTheme.surfaceContainer,
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
          'FORGOT PASSWORD?',
          style: GoogleFonts.workSans(
            color: LaconicTheme.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: LaconicTheme.secondary,
          foregroundColor: LaconicTheme.onSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: authProvider.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    LaconicTheme.onSecondary,
                  ),
                ),
              )
            : Text(
                'SIGN IN',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: LaconicTheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.workSans(
              color: LaconicTheme.outline,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: LaconicTheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
        icon: const Icon(
          Icons.g_mobiledata,
          color: LaconicTheme.onSurface,
          size: 24,
        ),
        label: Text(
          'SIGN IN WITH GOOGLE',
          style: GoogleFonts.spaceGrotesk(
            color: LaconicTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: LaconicTheme.outlineVariant),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
          style: GoogleFonts.inter(
            color: LaconicTheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
          child: Text(
            'JOIN THE AGŌGĒ',
            style: GoogleFonts.spaceGrotesk(
              color: LaconicTheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.05,
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
