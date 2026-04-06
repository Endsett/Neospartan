import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../widgets/glass_card.dart';
import '../widgets/warrior_animations.dart';
import 'auth/login_screen.dart';
import 'workout_preferences_screen.dart';

/// Profile Screen - User account, settings, and sign out
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
        CombatPageTransition(child: const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSignOutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.deepBlack,
        title: const Text(
          'LEAVE THE FIELD?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You will be signed out and returned to the login screen.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'STAY',
              style: TextStyle(color: LaconicTheme.spartanBronze),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSignOut();
            },
            child: const Text('DEPART', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: LaconicTheme.deepBlack,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PROFILE',
          style: TextStyle(color: LaconicTheme.spartanBronze, letterSpacing: 2),
        ),
      ),
      body: _isSigningOut
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: LaconicTheme.spartanBronze),
                  SizedBox(height: 16),
                  Text('Signing out...', style: TextStyle(color: Colors.grey)),
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
                      // Avatar with glass effect
                      GlassCard(
                        elevated: true,
                        padding: const EdgeInsets.all(4),
                        borderRadius: 60,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                LaconicTheme.spartanBronze,
                                LaconicTheme.warmGold,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: LaconicTheme.deepBlack,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        profile?.displayName ?? user?.email ?? 'Warrior',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),

                      // Email
                      if (user?.email != null)
                        Text(
                          user!.email!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: LaconicTheme.mistGray),
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
                        child: OutlinedButton.icon(
                          onPressed: _showSignOutConfirmDialog,
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'SIGN OUT',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Version
                      Text(
                        'Neospartan v1.0',
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.5),
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: LaconicTheme.spartanBronze,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserProfile? profile) {
    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            profile?.trainingDaysPerWeek.toString() ?? '-',
            'Days/Week',
          ),
          Container(
            width: 1,
            height: 40,
            color: LaconicTheme.ironGray.withOpacity(0.5),
          ),
          _buildStatItem(
            profile?.preferredWorkoutDuration?.toString() ?? '-',
            'Min/Session',
          ),
          Container(
            width: 1,
            height: 40,
            color: LaconicTheme.ironGray.withOpacity(0.5),
          ),
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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: LaconicTheme.brightGold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: LaconicTheme.mistGray),
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
                        const SnackBar(
                          content: Text('Preferences updated'),
                          backgroundColor: LaconicTheme.spartanBronze,
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
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LaconicTheme.spartanBronze, LaconicTheme.warmGold],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: LaconicTheme.deepBlack, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: LaconicTheme.mistGray),
        ],
      ),
    );
  }
}
