import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import 'auth/login_screen.dart';
import 'workout_preferences_screen.dart';

/// Profile Screen - User account, settings, and sign out
/// Blood & Bronze themed Spartan profile management
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);

    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSignOutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: LaconicTheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LEAVE THE FIELD?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: LaconicTheme.onSurface,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You will be signed out and returned to the login screen.',
                style: GoogleFonts.inter(
                  color: LaconicTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: LaconicTheme.outlineVariant,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'STAY',
                        style: GoogleFonts.spaceGrotesk(
                          color: LaconicTheme.outline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleSignOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LaconicTheme.error,
                        foregroundColor: LaconicTheme.onError,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'DEPART',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SPARTAN PROFILE',
          style: GoogleFonts.spaceGrotesk(
            color: LaconicTheme.secondary,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
      body: _isSigningOut
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: LaconicTheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Signing out...',
                    style: GoogleFonts.inter(color: LaconicTheme.outline),
                  ),
                ],
              ),
            )
          : Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final profile = authProvider.userProfile;
                final user = authProvider.user;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar with bronze accent
                      _buildAvatar(),
                      const SizedBox(height: 24),

                      // Name
                      Text(
                        profile?.displayName ?? user?.email ?? 'WARRIOR',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: LaconicTheme.onSurface,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Email
                      if (user?.email != null)
                        Text(
                          user!.email!,
                          style: GoogleFonts.inter(
                            color: LaconicTheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Stats Card
                      _buildSectionTitle('COMBAT STATS'),
                      const SizedBox(height: 16),
                      _buildStatsCard(profile),
                      const SizedBox(height: 32),

                      // Settings Section
                      _buildSectionTitle('SETTINGS'),
                      const SizedBox(height: 16),
                      _buildSettingsList(),
                      const SizedBox(height: 32),

                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _showSignOutConfirmDialog,
                          icon: const Icon(
                            Icons.logout,
                            color: LaconicTheme.error,
                          ),
                          label: Text(
                            'SIGN OUT',
                            style: GoogleFonts.spaceGrotesk(
                              color: LaconicTheme.error,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.1,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: LaconicTheme.error),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Version
                      Text(
                        'Neospartan v1.0',
                        style: GoogleFonts.inter(
                          color: LaconicTheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(color: LaconicTheme.secondary),
      child: const Icon(
        Icons.shield_outlined,
        size: 60,
        color: LaconicTheme.onSecondary,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: LaconicTheme.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainer),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            profile?.trainingDaysPerWeek.toString() ?? '-',
            'Days/Week',
          ),
          Container(width: 1, height: 40, color: LaconicTheme.outlineVariant),
          _buildStatItem(
            profile?.preferredWorkoutDuration?.toString() ?? '-',
            'Min/Session',
          ),
          Container(width: 1, height: 40, color: LaconicTheme.outlineVariant),
          _buildStatItem(
            profile?.fitnessLevelText.toUpperCase() ?? '-',
            'Level',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: LaconicTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: LaconicTheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        _buildSettingTile(
          icon: Icons.tune,
          title: 'Workout Preferences',
          subtitle: 'Intensity, duration, focus',
          onTap: () {
            final authProvider = context.read<AuthProvider>();
            final profile = authProvider.userProfile;
            if (profile != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutPreferencesScreen(
                    profile: profile,
                    onGenerate: (prefs) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Preferences updated',
                            style: GoogleFonts.inter(),
                          ),
                          backgroundColor: LaconicTheme.secondary,
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          icon: Icons.psychology,
          title: 'Philosophy',
          subtitle: 'View stoic teachings',
          onTap: () {
            Navigator.pushNamed(context, '/stoic');
          },
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          icon: Icons.upload_file,
          title: 'Import Plans',
          subtitle: 'Phalanx workout import',
          onTap: () {
            Navigator.pushNamed(context, '/phalanx');
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: LaconicTheme.surfaceContainer),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: LaconicTheme.secondaryContainer,
              ),
              child: Icon(icon, color: LaconicTheme.secondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: LaconicTheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: LaconicTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: LaconicTheme.outline),
          ],
        ),
      ),
    );
  }
}
