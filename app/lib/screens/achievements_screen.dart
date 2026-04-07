import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_database_service.dart';

/// Achievements Screen - Gamification and Unlock System
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final SupabaseDatabaseService _database = SupabaseDatabaseService();
  
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = true;
  String? _userId;
  int _unlockedCount = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<AuthProvider>(context, listen: false).userId;
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final achievements = await _database.getUserAchievements(_userId!);
      
      int unlocked = 0;
      int points = 0;
      
      for (final a in achievements) {
        if (a['unlocked'] == true || a['unlocked_at'] != null) {
          unlocked++;
          points += (a['points'] as int?) ?? 100;
        }
      }

      setState(() {
        _achievements = achievements;
        _unlockedCount = unlocked;
        _totalPoints = points;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unlockAchievement(String achievementId) async {
    if (_userId == null) return;
    
    try {
      await _database.unlockAchievement(_userId!, achievementId);
      await _loadAchievements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achievement Unlocked!'),
            backgroundColor: LaconicTheme.secondary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: LaconicTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: LaconicTheme.secondary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.background,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: LaconicTheme.secondary),
            const SizedBox(width: 12),
            Text(
              'HONORS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.secondary,
                letterSpacing: -0.02,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: LaconicTheme.secondary),
            onPressed: _loadAchievements,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Battle',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.onSurface,
                letterSpacing: -0.04,
                height: 1,
              ),
            ),
            Text(
              'Honors',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.secondary,
                letterSpacing: -0.04,
                height: 1,
              ),
            ),
            const SizedBox(height: 32),

            // Progress Overview
            _buildProgressOverview(),
            const SizedBox(height: 32),

            // Achievement Categories
            _buildAchievementList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview() {
    final progress = _achievements.isEmpty 
        ? 0.0 
        : _unlockedCount / _achievements.length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: LaconicTheme.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESS',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: LaconicTheme.secondary,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                '$_unlockedCount / ${_achievements.length}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LaconicTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            width: double.infinity,
            color: LaconicTheme.surfaceContainerHighest,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(color: LaconicTheme.secondary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Total Points', '$_totalPoints'),
              _buildStatCard('Unlocked', '$_unlockedCount'),
              _buildStatCard('Next Tier', '${_getNextTierPoints()}'),
            ],
          ),
        ],
      ),
    );
  }

  int _getNextTierPoints() {
    if (_totalPoints < 500) return 500;
    if (_totalPoints < 1000) return 1000;
    if (_totalPoints < 2500) return 2500;
    return 5000;
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: LaconicTheme.surfaceContainer,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LaconicTheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 10,
              color: LaconicTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementList() {
    if (_achievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: LaconicTheme.surfaceContainerLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACHIEVEMENTS',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.secondary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Complete workouts to earn your first honors.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACHIEVEMENTS',
          style: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.secondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 16),
        ..._achievements.map((achievement) {
          final isUnlocked = achievement['unlocked'] == true || 
                           achievement['unlocked_at'] != null;
          final tier = achievement['tier']?.toString() ?? 'bronze';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LaconicTheme.surfaceContainerLow,
              border: Border(
                left: BorderSide(
                  color: isUnlocked ? LaconicTheme.secondary : LaconicTheme.outline,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? LaconicTheme.secondary.withValues(alpha: 0.2)
                        : LaconicTheme.surfaceContainer,
                  ),
                  child: Center(
                    child: Icon(
                      isUnlocked ? Icons.emoji_events : Icons.lock,
                      color: isUnlocked ? LaconicTheme.secondary : LaconicTheme.outline,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement['name']?.toString() ?? 'Unknown',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked 
                              ? LaconicTheme.onSurface 
                              : LaconicTheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement['description']?.toString() ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: LaconicTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTierColor(tier).withValues(alpha: 0.2),
                            ),
                            child: Text(
                              tier.toUpperCase(),
                              style: GoogleFonts.workSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _getTierColor(tier),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${achievement['points'] ?? 100} PTS',
                            style: GoogleFonts.workSans(
                              fontSize: 10,
                              color: LaconicTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isUnlocked)
                  const Icon(
                    Icons.check_circle,
                    color: LaconicTheme.secondary,
                    size: 24,
                  )
                else
                  TextButton(
                    onPressed: () => _unlockAchievement(achievement['id'].toString()),
                    child: Text(
                      'CLAIM',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return LaconicTheme.secondary;
    }
  }
}
