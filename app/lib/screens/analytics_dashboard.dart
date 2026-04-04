import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/workout_tracking.dart';
import '../models/user_profile.dart';
import '../services/firebase_sync_service.dart';
import '../providers/auth_provider.dart';

/// Analytics Dashboard - Shows workout progress and AI insights
class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final _firebase = FirebaseSyncService();
  UserProfile? _profile;
  List<CompletedWorkout> _workouts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? '';
      final profile = await _firebase.getUserProfile(userId);
      final workouts = await _firebase.getWorkoutHistory(limit: 100);

      setState(() {
        _profile = profile;
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: LaconicTheme.spartanBronze,
          backgroundColor: LaconicTheme.ironGray,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: LaconicTheme.spartanBronze,
                    ),
                  )
                else if (_error != null)
                  _buildErrorState()
                else ...[
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildProgressChart(),
                  const SizedBox(height: 24),
                  _buildWorkoutHistory(),
                  const SizedBox(height: 24),
                  _buildAIInsights(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ANALYTICS',
              style: TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 12,
                letterSpacing: 3.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _profile?.displayName?.toUpperCase() ?? 'WARRIOR',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: LaconicTheme.spartanBronze),
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'Error loading analytics: $_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalWorkouts = _workouts.length;
    final totalVolume = _workouts.fold<double>(
      0,
      (sum, w) =>
          sum +
          w.exercises.fold<double>(
            0,
            (eSum, e) =>
                eSum +
                e.sets.fold<double>(
                  0,
                  (sSum, s) =>
                      sSum + ((s.loadUsed ?? 0) * (s.repsPerformed ?? 0)),
                ),
          ),
    );
    final totalDuration = _workouts.fold<int>(
      0,
      (sum, w) => sum + w.totalDurationMinutes,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'WORKOUTS',
            '$totalWorkouts',
            Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'VOLUME',
            '${(totalVolume / 1000).toStringAsFixed(1)}k',
            Icons.scale,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'HOURS',
            (totalDuration / 60).toStringAsFixed(0),
            Icons.timer,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.2),
        border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: LaconicTheme.spartanBronze, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_workouts.isEmpty) {
      return _buildEmptyState('No workouts logged yet. Start training!');
    }

    // Get last 7 workouts
    final recentWorkouts = _workouts.take(7).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LAST 7 WORKOUTS',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recentWorkouts.map((workout) {
                final volume = workout.exercises.fold<double>(
                  0,
                  (sum, e) =>
                      sum +
                      e.sets.fold<double>(
                        0,
                        (sSum, s) =>
                            sSum + ((s.loadUsed ?? 0) * (s.repsPerformed ?? 0)),
                      ),
                );
                final maxVolume = recentWorkouts
                    .map(
                      (w) => w.exercises.fold<double>(
                        0,
                        (sum, e) =>
                            sum +
                            e.sets.fold<double>(
                              0,
                              (sSum, s) =>
                                  sSum +
                                  ((s.loadUsed ?? 0) * (s.repsPerformed ?? 0)),
                            ),
                      ),
                    )
                    .reduce((a, b) => a > b ? a : b);

                final heightPercent = maxVolume > 0 ? volume / maxVolume : 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (100 * heightPercent).toDouble(),
                          decoration: BoxDecoration(
                            color: LaconicTheme.spartanBronze.withValues(
                              alpha: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${workout.startTime.day}/${workout.startTime.month}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistory() {
    if (_workouts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT WORKOUTS',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        ..._workouts.take(5).map((workout) => _buildWorkoutCard(workout)),
      ],
    );
  }

  Widget _buildWorkoutCard(CompletedWorkout workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LaconicTheme.spartanBronze.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center,
              color: LaconicTheme.spartanBronze,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.protocolTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${workout.exercises.length} exercises • ${workout.totalDurationMinutes} min',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${workout.startTime.day}/${workout.startTime.month}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.spartanBronze.withValues(alpha: 0.1),
        border: Border.all(
          color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: LaconicTheme.spartanBronze,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'AI INSIGHTS',
                style: TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_profile != null) ...[
            _buildInsightRow('Fitness Level', _profile!.fitnessLevelText),
            _buildInsightRow('Training Goal', _profile!.trainingGoalText),
            _buildInsightRow(
              'Training Days',
              '${_profile!.trainingDaysPerWeek} days/week',
            ),
            _buildInsightRow(
              'Workout Duration',
              '${_profile!.preferredWorkoutDuration} min',
            ),
          ] else
            const Text(
              'Complete onboarding to get AI-powered insights',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.show_chart, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
