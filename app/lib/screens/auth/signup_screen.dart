import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';

/// Signup Screen - Account creation with Blood & Bronze theme
class SignupScreen extends StatefulWidget {
  final VoidCallback? onSignupComplete;

  const SignupScreen({super.key, this.onSignupComplete});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LaconicTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildTitle(),
                  const SizedBox(height: 32),

                  // Error message
                  if (authProvider.error != null) ...[
                    _buildErrorMessage(authProvider.error!),
                    const SizedBox(height: 16),
                  ],

                  // Name field
                  _buildNameField(),
                  const SizedBox(height: 16),

                  // Email field
                  _buildEmailField(),
                  const SizedBox(height: 16),

                  // Password field
                  _buildPasswordField(),
                  const SizedBox(height: 16),

                  // Confirm password field
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 16),

                  // Terms checkbox
                  _buildTermsCheckbox(),
                  const SizedBox(height: 32),

                  // Sign up button
                  _buildSignUpButton(authProvider),
                  const SizedBox(height: 24),

                  // Divider
                  _buildDivider(),
                  const SizedBox(height: 24),

                  // Google Sign up
                  _buildGoogleSignUpButton(authProvider),
                  const SizedBox(height: 16),

                  // Link anonymous account (if currently anonymous)
                  if (authProvider.isAnonymous)
                    _buildLinkAnonymousButton(authProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JOIN THE AGŌGĒ',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: LaconicTheme.onSurface,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Begin your transformation',
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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: GoogleFonts.inter(color: LaconicTheme.onSurface),
      decoration: _inputDecoration(
        label: 'SPARTAN NAME',
        icon: Icons.person_outline,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter your name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.inter(color: LaconicTheme.onSurface),
      decoration: _inputDecoration(label: 'EMAIL', icon: Icons.email_outlined),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter your email';
        }
        if (!value.contains('@') || !value.contains('.')) {
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
      decoration: _inputDecoration(
        label: 'PASSWORD',
        icon: Icons.lock_outline,
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
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (!value.contains(RegExp(r'[A-Z]'))) {
          return 'Include at least one uppercase letter';
        }
        if (!value.contains(RegExp(r'[0-9]'))) {
          return 'Include at least one number';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: GoogleFonts.inter(color: LaconicTheme.onSurface),
      decoration: _inputDecoration(
        label: 'CONFIRM PASSWORD',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: LaconicTheme.outline,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
          activeColor: LaconicTheme.secondary,
          checkColor: LaconicTheme.onSecondary,
          side: const BorderSide(color: LaconicTheme.outline),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreeToTerms = !_agreeToTerms;
              });
            },
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: GoogleFonts.inter(
                  color: LaconicTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: GoogleFonts.inter(
                      color: LaconicTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: GoogleFonts.inter(
                      color: LaconicTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authProvider.isLoading || !_agreeToTerms
            ? null
            : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: LaconicTheme.primary,
          foregroundColor: LaconicTheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          disabledBackgroundColor: LaconicTheme.surfaceContainerHighest,
        ),
        child: authProvider.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    LaconicTheme.onPrimary,
                  ),
                ),
              )
            : Text(
                'CREATE ACCOUNT',
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

  Widget _buildGoogleSignUpButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: authProvider.isLoading ? null : _handleGoogleSignUp,
        icon: const Icon(
          Icons.g_mobiledata,
          color: LaconicTheme.onSurface,
          size: 24,
        ),
        label: Text(
          'SIGN UP WITH GOOGLE',
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

  Widget _buildLinkAnonymousButton(AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.surfaceContainer,
        border: Border.all(color: LaconicTheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            'You have a preview account',
            style: GoogleFonts.spaceGrotesk(
              color: LaconicTheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a permanent account to save your progress',
            style: GoogleFonts.inter(
              color: LaconicTheme.onSurfaceVariant,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleLinkAnonymous,
              style: ElevatedButton.styleFrom(
                backgroundColor: LaconicTheme.secondary,
                foregroundColor: LaconicTheme.onSecondary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                elevation: 0,
              ),
              child: Text(
                'SAVE PROGRESS',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: LaconicTheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      prefixIcon: Icon(icon, color: LaconicTheme.outline),
      suffixIcon: suffixIcon,
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: LaconicTheme.outlineVariant),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: LaconicTheme.secondary, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: LaconicTheme.error),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: LaconicTheme.error),
      ),
      filled: true,
      fillColor: LaconicTheme.surfaceContainer,
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to the Terms of Service',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: LaconicTheme.error,
        ),
      );
      return;
    }

    context.read<AuthProvider>().clearError();

    final success = await context.read<AuthProvider>().signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (success && mounted) {
      widget.onSignupComplete?.call();
    }
  }

  Future<void> _handleGoogleSignUp() async {
    context.read<AuthProvider>().clearError();

    final success = await context.read<AuthProvider>().signInWithGoogle();

    if (success && mounted) {
      widget.onSignupComplete?.call();
    }
  }

  Future<void> _handleLinkAnonymous() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) return;

    context.read<AuthProvider>().clearError();

    final success = await context.read<AuthProvider>().linkAnonymousToEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: LaconicTheme.secondary,
        ),
      );
    }
  }
}
