import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/analytics_metrics.dart';
import '../providers/auth_provider.dart';
import '../services/analytics_query_service.dart';
import '../widgets/analytics_charts.dart';

/// Analytics Dashboard - Enhanced warrior performance analytics
class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  final AnalyticsQueryService _analyticsService = AnalyticsQueryService();
  WarriorAnalyticsSnapshot? _snapshot;
  bool _isLoading = true;
  String? _error;

  // Time range selection
  int _selectedDays = 30;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception('No authenticated user');
      }

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: _selectedDays));

      final snapshot = await _analyticsService.getAnalyticsSnapshot(
        startDate: startDate,
        endDate: endDate,
        includeComparison: _selectedDays >= 30,
      );

      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onTimeRangeChanged(int days) {
    setState(() {
      _selectedDays = days;
    });
    _loadData();
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
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildTimeRangeSelector(),
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
                        _buildKeyMetrics(),
                        const SizedBox(height: 24),
                        _buildInsights(),
                        const SizedBox(height: 24),
                        _buildTabBar(),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 500,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOverviewTab(),
                              _buildVolumeTab(),
                              _buildProgressionTab(),
                              _buildConsistencyTab(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName =
        authProvider.user?.email?.split('@').first.toUpperCase() ?? 'WARRIOR';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WARRIOR ANALYTICS',
              style: TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 12,
                letterSpacing: 3.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
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

  Widget _buildTimeRangeSelector() {
    final options = [
      {'label': '7D', 'days': 7},
      {'label': '30D', 'days': 30},
      {'label': '90D', 'days': 90},
    ];

    return Row(
      children: options.map((opt) {
        final days = opt['days'] as int;
        final isSelected = _selectedDays == days;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _onTimeRangeChanged(days),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? LaconicTheme.spartanBronze
                    : LaconicTheme.ironGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                opt['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: LaconicTheme.spartanBronze,
      labelColor: LaconicTheme.spartanBronze,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
        Tab(icon: Icon(Icons.trending_up), text: 'Volume'),
        Tab(icon: Icon(Icons.fitness_center), text: 'Progress'),
        Tab(icon: Icon(Icons.local_fire_department), text: 'Streaks'),
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

  Widget _buildKeyMetrics() {
    final snapshot = _snapshot!;
    final metrics = snapshot.volumeMetrics;
    final consistency = snapshot.consistencyMetrics;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'TOTAL VOLUME',
            '${(metrics.totalVolume / 1000).toStringAsFixed(1)}k',
            Icons.scale,
            LaconicTheme.spartanBronze,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'WORKOUTS',
            '${consistency.totalWorkouts}',
            Icons.fitness_center,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'STREAK',
            '${consistency.currentStreak}',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.2),
        border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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

  Widget _buildInsights() {
    final insights = _snapshot?.insights ?? [];
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI INSIGHTS',
          style: TextStyle(
            color: LaconicTheme.spartanBronze,
            fontSize: 12,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...insights
            .map(
              (insight) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LaconicTheme.spartanBronze.withValues(alpha: 0.1),
                  border: Border.all(
                    color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: LaconicTheme.spartanBronze,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final snapshot = _snapshot!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (snapshot.periodComparison != null)
            PeriodComparisonCard(comparison: snapshot.periodComparison!),
          const SizedBox(height: 24),
          VolumeTrendChart(
            data: snapshot.volumeMetrics.weeklyVolumes,
            title: 'WEEKLY VOLUME',
            height: 200,
          ),
          const SizedBox(height: 24),
          if (snapshot.exerciseFrequency.isNotEmpty)
            ExerciseFrequencyChart(
              frequencies: snapshot.exerciseFrequency.take(5).toList(),
              height: 180,
            ),
        ],
      ),
    );
  }

  Widget _buildVolumeTab() {
    final metrics = _snapshot!.volumeMetrics;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVolumeStats(),
          const SizedBox(height: 24),
          VolumeTrendChart(
            data: metrics.dailyVolumes,
            title: 'DAILY VOLUME',
            height: 250,
          ),
          const SizedBox(height: 24),
          VolumeTrendChart(
            data: metrics.weeklyVolumes,
            title: 'WEEKLY VOLUME TREND',
            lineColor: Colors.blue,
            height: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeStats() {
    final metrics = _snapshot!.volumeMetrics;

    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            'Avg/Day',
            '${metrics.averageDailyVolume.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            'Best Week',
            '${(metrics.bestWeekVolume / 1000).toStringAsFixed(1)}k',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            'Trend',
            '${metrics.trendSlope > 0 ? '+' : ''}${metrics.trendSlope.toStringAsFixed(1)}',
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildProgressionTab() {
    final progressions = _snapshot!.exerciseProgressions;

    if (progressions.isEmpty) {
      return _buildEmptyState(
        'Complete more workouts to see exercise progression',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (progressions.any((p) => p.personalRecord != null))
            _buildPRSection(),
          const SizedBox(height: 24),
          const Text(
            'TOP PROGRESSING',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          ...progressions
              .where((p) => p.progressionRate > 0)
              .take(3)
              .map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LaconicTheme.ironGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExerciseProgressionChart(progression: p, height: 150),
                ),
              )
              .toList(),
          if (progressions.any((p) => p.isPlateauing)) ...[
            const SizedBox(height: 24),
            const Text(
              'PLATEAU ALERTS',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            ...progressions
                .where((p) => p.isPlateauing)
                .take(2)
                .map(
                  (p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_flat, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.exerciseName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Progress stalled - vary your training',
                                style: TextStyle(
                                  color: Colors.orange.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildPRSection() {
    final prs = _snapshot!.exerciseProgressions
        .where((p) => p.personalRecord != null)
        .take(3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LaconicTheme.spartanBronze.withValues(alpha: 0.2),
            LaconicTheme.spartanBronze.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: LaconicTheme.spartanBronze),
              SizedBox(width: 8),
              Text(
                'PERSONAL RECORDS',
                style: TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...prs
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.exerciseName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        '${p.personalRecord!.toStringAsFixed(1)} ${p.prDate != null ? '(${DateFormat('MMM d').format(p.prDate!)})' : ''}',
                        style: const TextStyle(
                          color: LaconicTheme.spartanBronze,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildConsistencyTab() {
    final consistency = _snapshot!.consistencyMetrics;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StreakCounter(
                currentStreak: consistency.currentStreak,
                longestStreak: consistency.longestStreak,
                size: 100,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConsistencyStat(
                      'Total Workouts',
                      '${consistency.totalWorkouts}',
                    ),
                    const SizedBox(height: 8),
                    _buildConsistencyStat(
                      'Adherence',
                      '${consistency.adherencePercentage.toStringAsFixed(0)}%',
                    ),
                    const SizedBox(height: 8),
                    _buildConsistencyStat(
                      'Missed',
                      '${consistency.missedWorkouts}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (consistency.weeklyRates.isNotEmpty) ...[
            const Text(
              'WEEKLY COMPLETION',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            WeeklyCompletionChart(
              weeklyRates: consistency.weeklyRates,
              height: 200,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsistencyStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
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
