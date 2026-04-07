import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';

/// Forgot Password Screen - Password reset with Blood & Bronze design
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
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
          child: _emailSent
              ? _buildSuccessView()
              : _buildFormView(authProvider),
        ),
      ),
    );
  }

  Widget _buildFormView(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainerLow),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'RESET PASSWORD',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.primary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your email and we\'ll send you a link to reset your password.',
              style: GoogleFonts.inter(
                color: LaconicTheme.onSurfaceVariant,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),

            // Error message
            if (authProvider.error != null) ...[
              _buildErrorMessage(authProvider.error!),
              const SizedBox(height: 16),
            ],

            // Email field
            TextFormField(
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
                  borderSide: BorderSide(
                    color: LaconicTheme.secondary,
                    width: 2,
                  ),
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
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Send button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleSendReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LaconicTheme.secondary,
                  foregroundColor: LaconicTheme.onSecondary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
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
                        'SEND RESET LINK',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Back to login
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'BACK TO LOGIN',
                  style: GoogleFonts.spaceGrotesk(
                    color: LaconicTheme.outline,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainerLow),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: LaconicTheme.secondary.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.check,
              color: LaconicTheme.secondary,
              size: 40,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'CHECK YOUR EMAIL',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LaconicTheme.secondary,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We\'ve sent a password reset link to:',
            style: GoogleFonts.inter(
              color: LaconicTheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _emailController.text,
            style: GoogleFonts.spaceGrotesk(
              color: LaconicTheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Click the link in the email to reset your password. If you don\'t see it, check your spam folder.',
            style: GoogleFonts.inter(color: LaconicTheme.outline, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: LaconicTheme.secondary,
                foregroundColor: LaconicTheme.onSecondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                'BACK TO LOGIN',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _emailSent = false;
              });
            },
            child: Text(
              'RESEND EMAIL',
              style: GoogleFonts.workSans(
                color: LaconicTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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

  Future<void> _handleSendReset() async {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthProvider>().clearError();

    final success = await context.read<AuthProvider>().sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
    }
  }
}
