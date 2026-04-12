import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../warrior_theme.dart';
import '../warrior_constants.dart';
import '../models/warrior_models.dart';
import '../services/warrior_progress_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/rank_badge.dart';
import 'rituals/daily_oath_screen.dart';

/// Agoge Screen V2 - Shield Wall Dashboard
/// Redesigned with warrior forge theme
class AgogeScreenV2 extends StatefulWidget {
  const AgogeScreenV2({super.key});

  @override
  State<AgogeScreenV2> createState() => _AgogeScreenV2State();
}

class _AgogeScreenV2State extends State<AgogeScreenV2>
    with SingleTickerProviderStateMixin {
  final _progressService = WarriorProgressService();
  WarriorProfile? _profile;
  DailyOath? _todayOath;
  bool _isLoading = true;
  bool _showingOath = false;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _progressService.initialize();
      
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      
      if (userId != null) {
        // Create profile if doesn't exist
        if (_progressService.currentProfile == null) {
          await _progressService.createProfile(userId);
        }
        
        _profile = _progressService.currentProfile;
        _todayOath = await _progressService.getTodayOath();
        
        // Check if oath is needed
        if (_todayOath == null || !_todayOath!.isCompleted) {
          setState(() => _showingOath = true);
        }
      }
      
      setState(() => _isLoading = false);
      _controller.forward();
    } catch (e) {
      developer.log('Error initializing AgogeScreenV2: $e', name: 'AgogeScreenV2');
      setState(() => _isLoading = false);
    }
  }

  void _onOathCompleted() {
    setState(() {
      _showingOath = false;
      _todayOath = DailyOath(
        id: 'oath_${DateTime.now().millisecondsSinceEpoch}',
        oath: 'I will forge myself today',
        date: DateTime.now(),
        isCompleted: true,
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show oath screen if needed
    if (_showingOath) {
      return DailyOathScreen(
        onOathCompleted: _onOathCompleted,
      );
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    final profile = _profile;
    if (profile == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: WarriorTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: _buildAppBar(profile),
            ),
            
            // Hero Section with Rank
            SliverToBoxAdapter(
              child: _buildHeroSection(profile),
            ),
            
            // Stats Row
            SliverToBoxAdapter(
              child: _buildStatsRow(profile),
            ),
            
            // Streak Display
            SliverToBoxAdapter(
              child: _buildStreakCard(profile),
            ),
            
            // Skill Trees
            SliverToBoxAdapter(
              child: _buildSkillTrees(profile),
            ),
            
            // Stoic Quote
            SliverToBoxAdapter(
              child: _buildStoicQuote(),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: WarriorTheme.spaceXl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: WarriorTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield,
              size: 64,
              color: WarriorTheme.bronze,
            ),
            const SizedBox(height: WarriorTheme.spaceLg),
            Text(
              'INITIALIZING FORGE...',
              style: WarriorTheme.labelMedium.copyWith(
                color: WarriorTheme.ash,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: WarriorTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: WarriorTheme.crimson,
            ),
            const SizedBox(height: WarriorTheme.spaceLg),
            Text(
              'FORGE ERROR',
              style: WarriorTheme.headlineMedium,
            ),
            const SizedBox(height: WarriorTheme.spaceMd),
            ElevatedButton(
              onPressed: _initialize,
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(WarriorProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(WarriorTheme.spaceLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SHIELD WALL',
                style: WarriorTheme.labelMedium.copyWith(
                  color: WarriorTheme.bronze,
                ),
              ),
              Text(
                'AGOGÊ',
                style: WarriorTheme.headlineLarge.copyWith(
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          
          // Settings
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(
              Icons.settings,
              color: WarriorTheme.ash,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(WarriorProfile profile) {
    final nextRank = profile.nextRank;
    
    return Padding(
      padding: const EdgeInsets.all(WarriorTheme.spaceLg),
      child: Container(
        padding: const EdgeInsets.all(WarriorTheme.spaceLg),
        decoration: BoxDecoration(
          gradient: WarriorTheme.gradientDark,
          border: Border.all(
            color: WarriorTheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Rank Badge
            RankBadge(
              rankLevel: profile.rankLevel,
              size: 140,
              showProgress: nextRank != null,
              currentXp: profile.totalXp,
              xpToNext: profile.xpToNextRank,
            ),
            
            const SizedBox(height: WarriorTheme.spaceLg),
            
            // Progress bar
            if (nextRank != null) ...[
              XpProgressBar(
                currentXp: profile.totalXp - profile.rank.requiredXp,
                xpToNext: profile.xpToNextRank,
                height: 6,
              ),
              const SizedBox(height: WarriorTheme.spaceSm),
              Text(
                '${profile.xpToNextRank} XP TO ${nextRank.name.toUpperCase()}',
                style: WarriorTheme.labelSmall.copyWith(
                  color: WarriorTheme.ash,
                ),
              ),
            ] else ...[
              Text(
                'MAX RANK ACHIEVED',
                style: WarriorTheme.labelSmall.copyWith(
                  color: WarriorTheme.gold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(WarriorProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WarriorTheme.spaceLg),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              value: profile.totalWorkouts.toString(),
              label: 'BATTLES',
              icon: Icons.fitness_center,
            ),
          ),
          const SizedBox(width: WarriorTheme.spaceMd),
          Expanded(
            child: _StatCard(
              value: '${profile.totalXp}',
              label: 'XP EARNED',
              icon: Icons.bolt,
            ),
          ),
          const SizedBox(width: WarriorTheme.spaceMd),
          Expanded(
            child: _StatCard(
              value: profile.longestStreak.toString(),
              label: 'BEST STREAK',
              icon: Icons.local_fire_department,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(WarriorProfile profile) {
    final isOnStreak = profile.currentStreak > 0;
    
    return Padding(
      padding: const EdgeInsets.all(WarriorTheme.spaceLg),
      child: Container(
        padding: const EdgeInsets.all(WarriorTheme.spaceLg),
        decoration: BoxDecoration(
          color: isOnStreak 
            ? WarriorTheme.crimson.withValues(alpha: 0.1)
            : WarriorTheme.surface,
          border: Border.all(
            color: isOnStreak ? WarriorTheme.crimson : WarriorTheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: isOnStreak ? WarriorTheme.fireCore : WarriorTheme.ash,
                  size: 32,
                ),
                const SizedBox(width: WarriorTheme.spaceMd),
                Text(
                  profile.currentStreak.toString(),
                  style: WarriorTheme.displayMedium.copyWith(
                    color: isOnStreak ? WarriorTheme.fireCore : WarriorTheme.ash,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WarriorTheme.spaceSm),
            Text(
              'DAY${profile.currentStreak == 1 ? '' : 'S'} STREAK',
              style: WarriorTheme.labelMedium.copyWith(
                color: isOnStreak ? WarriorTheme.fireOuter : WarriorTheme.ash,
              ),
            ),
            if (!isOnStreak) ...[
              const SizedBox(height: WarriorTheme.spaceSm),
              Text(
                'Start your streak today',
                style: WarriorTheme.bodySmall.copyWith(
                  color: WarriorTheme.ash,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillTrees(WarriorProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WarriorTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: WarriorTheme.spaceSm),
            child: Text(
              'SKILL TREES',
              style: WarriorTheme.labelMedium.copyWith(
                color: WarriorTheme.ash,
              ),
            ),
          ),
          const SizedBox(height: WarriorTheme.spaceMd),
          ...WarriorConstants.skillTrees.map((skill) {
            final progress = profile.getSkillProgress(skill.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: WarriorTheme.spaceMd),
              child: _SkillTreeItem(
                skill: skill,
                level: progress.level,
                progress: progress.progressPercent,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStoicQuote() {
    return Padding(
      padding: const EdgeInsets.all(WarriorTheme.spaceLg),
      child: Container(
        padding: const EdgeInsets.all(WarriorTheme.spaceLg),
        decoration: BoxDecoration(
          color: WarriorTheme.surface,
          border: Border(
            left: BorderSide(
              color: WarriorTheme.bronze.withValues(alpha: 0.5),
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STOIC WISDOM',
              style: WarriorTheme.labelSmall.copyWith(
                color: WarriorTheme.bronze,
              ),
            ),
            const SizedBox(height: WarriorTheme.spaceMd),
            Text(
              WarriorConstants.getRandomQuote(),
              style: WarriorTheme.oathText.copyWith(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WarriorTheme.spaceMd),
      decoration: BoxDecoration(
        color: WarriorTheme.surface,
        border: Border.all(
          color: WarriorTheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: WarriorTheme.bronze,
            size: 24,
          ),
          const SizedBox(height: WarriorTheme.spaceSm),
          Text(
            value,
            style: WarriorTheme.titleLarge.copyWith(
              color: WarriorTheme.onSurface,
            ),
          ),
          const SizedBox(height: WarriorTheme.spaceXs),
          Text(
            label,
            style: WarriorTheme.labelSmall.copyWith(
              color: WarriorTheme.ash,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skill Tree Item Widget
class _SkillTreeItem extends StatelessWidget {
  final SkillTree skill;
  final int level;
  final double progress;

  const _SkillTreeItem({
    required this.skill,
    required this.level,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WarriorTheme.spaceMd),
      decoration: BoxDecoration(
        color: WarriorTheme.surface,
        border: Border.all(
          color: WarriorTheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(WarriorTheme.spaceSm),
            decoration: BoxDecoration(
              color: skill.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(WarriorTheme.cornerMinimal),
            ),
            child: Icon(
              skill.icon,
              color: skill.color,
              size: 20,
            ),
          ),
          const SizedBox(width: WarriorTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: WarriorTheme.titleSmall.copyWith(
                    color: WarriorTheme.onSurface,
                  ),
                ),
                const SizedBox(height: WarriorTheme.spaceXs),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: WarriorTheme.ironDark,
                          valueColor: AlwaysStoppedAnimation<Color>(skill.color),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: WarriorTheme.spaceSm),
                    Text(
                      'L$level',
                      style: WarriorTheme.labelSmall.copyWith(
                        color: skill.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
