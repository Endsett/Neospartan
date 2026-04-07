// ignore_for_file: unused_field
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/armor_analytics_service.dart';
import '../services/supabase_database_service.dart';
import '../models/armor_analytics.dart';
import '../models/workout_tracking.dart';
import '../models/biometrics.dart';
import '../repositories/weekly_directive_repository.dart';
import '../repositories/biometrics_repository.dart';
import '../providers/auth_provider.dart';

/// The Garrison - Analytics Hub
/// Based on the_garrison_analytics design
class GarrisonScreen extends StatefulWidget {
  const GarrisonScreen({super.key});

  @override
  State<GarrisonScreen> createState() => _GarrisonScreenState();
}

class _GarrisonScreenState extends State<GarrisonScreen> {
  final ArmorAnalyticsService _armorService = ArmorAnalyticsService();
  final WeeklyDirectiveRepository _directiveRepo = WeeklyDirectiveRepository();
  final BiometricsRepository _biometricsRepo = BiometricsRepository();
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  // Real data from Supabase
  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _domRlLog = [];
  List<Map<String, dynamic>> _weeklyVolumeData = [];
  List<Map<String, dynamic>> _rpeTrendData = [];
  bool _isLoading = true;
  String? _error;
  ArmorAnalyticsResult? _armorResult;
  List<Biometrics> _biometricsHistory = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId == null) {
      setState(() {
        _error = 'Not authenticated';
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _fetchBiometrics(userId),
        _fetchWorkoutData(userId),
        _fetchWeeklyDirectives(userId),
        _fetchAnalyticsEvents(userId),
      ]);

      final biometrics = results[0] as Map<String, dynamic>;
      final workoutData = results[1] as Map<String, dynamic>;
      final directives = results[2] as List<Map<String, dynamic>>;
      final analytics = results[3] as List<Map<String, dynamic>>;

      // Build DOM-RL log from directives and analytics
      final domLog = _buildDomRlLog(directives, analytics);

      // Build armor analytics from real workout data
      final microCycle = workoutData['microCycle'] as MicroCycle;
      final armorResult = _armorService.analyze(microCycle);

      if (mounted) {
        setState(() {
          _data = biometrics;
          _domRlLog = domLog;
          _weeklyVolumeData =
              workoutData['weeklyVolume'] as List<Map<String, dynamic>>;
          _rpeTrendData = workoutData['rpeTrend'] as List<Map<String, dynamic>>;
          _armorResult = armorResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading garrison data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load analytics data';
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchBiometrics(String userId) async {
    try {
      final latest = await _biometricsRepo.getLatestBiometrics(userId);
      return {
        'hrv': latest?.hrv ?? 70,
        'sleep': latest?.sleepHours ?? 7.0,
        'rhr': latest?.rhr ?? 60,
        'score': _calculateScore(latest),
        'weight': latest?.weight,
        'bodyFat': latest?.bodyFat,
      };
    } catch (e) {
      debugPrint('Error fetching biometrics: $e');
      return {'hrv': 70, 'sleep': 7.0, 'rhr': 60, 'score': 75};
    }
  }

  int _calculateScore(Biometrics? bio) {
    if (bio == null) return 75;
    int score = 70;
    if (bio.hrv != null) score += ((bio.hrv! - 60) / 2).round();
    if (bio.sleepHours != null) score += ((bio.sleepHours! - 6) * 5).round();
    if (bio.rhr != null) score += ((70 - bio.rhr!) / 2).round();
    return score.clamp(0, 100);
  }

  Future<Map<String, dynamic>> _fetchWorkoutData(String userId) async {
    try {
      // Fetch last 14 days of workout sessions
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 14));

      final sessions = await _database.getWorkoutSessions(
        startDate: startDate,
        endDate: endDate,
        limit: 100,
      );

      // Build weekly volume data
      final weeklyVolume = _buildWeeklyVolume(sessions);

      // Build RPE trend data
      final rpeTrend = _buildRpeTrend(sessions);

      // Build MicroCycle from sessions
      final microCycle = await _buildMicroCycle(userId, sessions);

      return {
        'weeklyVolume': weeklyVolume,
        'rpeTrend': rpeTrend,
        'microCycle': microCycle,
      };
    } catch (e) {
      debugPrint('Error fetching workout data: $e');
      return {
        'weeklyVolume': _getDefaultVolumeData(),
        'rpeTrend': _getDefaultRpeData(),
        'microCycle': MicroCycle(
          days: [],
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
        ),
      };
    }
  }

  List<Map<String, dynamic>> _buildWeeklyVolume(
    List<Map<String, dynamic>> sessions,
  ) {
    // Group sessions by day of week
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final volumeByDay = <int, double>{};

    for (final session in sessions) {
      final date = DateTime.tryParse(session['date']?.toString() ?? '');
      if (date == null) continue;

      final weekday = date.weekday - 1; // 0-6
      final volume = _extractVolumeFromSession(session);

      volumeByDay[weekday] = (volumeByDay[weekday] ?? 0) + volume;
    }

    // Build result list
    final maxVolume = volumeByDay.values.isEmpty
        ? 1
        : volumeByDay.values.reduce(math.max);
    return List.generate(7, (index) {
      final volume = volumeByDay[index] ?? 0;
      return {
        'day': dayNames[index],
        'volume': volume,
        'percentage': maxVolume > 0 ? volume / maxVolume : 0.2,
      };
    });
  }

  double _extractVolumeFromSession(Map<String, dynamic> session) {
    // Try to extract volume from notes or session data
    final notes = session['notes']?.toString() ?? '';
    final volumeMatch = RegExp(r'volume:([\d.]+)').firstMatch(notes);
    if (volumeMatch != null) {
      return double.tryParse(volumeMatch.group(1)!) ?? 0;
    }
    // Default: estimate from workout type
    final workoutType = session['workout_type']?.toString().toLowerCase() ?? '';
    if (workoutType.contains('strength')) return 5000;
    if (workoutType.contains('hypertrophy')) return 8000;
    if (workoutType.contains('endurance')) return 3000;
    return 4000;
  }

  List<Map<String, dynamic>> _buildRpeTrend(
    List<Map<String, dynamic>> sessions,
  ) {
    return sessions.map((session) {
      final notes = session['notes']?.toString() ?? '';
      final rpeMatch = RegExp(r'averageRpe:([\d.]+)').firstMatch(notes);
      final rpe = double.tryParse(rpeMatch?.group(1) ?? '') ?? 7.0;

      final date = DateTime.tryParse(session['date']?.toString() ?? '');
      return {
        'date': date,
        'rpe': rpe,
        'workoutType': session['workout_type']?.toString() ?? 'Workout',
      };
    }).toList();
  }

  Future<MicroCycle> _buildMicroCycle(
    String userId,
    List<Map<String, dynamic>> sessions,
  ) async {
    final days = <DailyLog>[];

    for (final session in sessions) {
      final date = DateTime.tryParse(session['date']?.toString() ?? '');
      if (date == null) continue;

      // Get sets for this session
      final sessionId = session['id']?.toString();
      List<Map<String, dynamic>> sets = [];
      if (sessionId != null) {
        sets = await _database.getWorkoutSets(sessionId);
      }

      // Extract RPEs
      final rpes = sets
          .where((s) => s['actual_rpe'] != null)
          .map((s) => (s['actual_rpe'] as num).toDouble())
          .toList();

      // Extract joint stress from notes
      final notes = session['notes']?.toString() ?? '';
      final jointStress = <String, int>{};

      days.add(
        DailyLog(
          date: date,
          rpeEntries: rpes,
          sleepQuality: 7,
          sleepHours: 7,
          jointFatigue: jointStress,
          flowState: 7,
          readinessScore: _extractReadiness(notes),
        ),
      );
    }

    return MicroCycle(
      days: days,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    );
  }

  int _extractReadiness(String notes) {
    final match = RegExp(r'readiness:(\d+)').firstMatch(notes);
    return int.tryParse(match?.group(1) ?? '') ?? 70;
  }

  Future<List<Map<String, dynamic>>> _fetchWeeklyDirectives(
    String userId,
  ) async {
    try {
      return await _directiveRepo.getRecentDirectives(userId, limit: 7);
    } catch (e) {
      debugPrint('Error fetching directives: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAnalyticsEvents(
    String userId,
  ) async {
    try {
      // Fetch analytics events for DOM-RL actions
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      return await _database.getAnalyticsEvents(
        userId: userId,
        eventType: 'dom_rl_action',
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error fetching analytics events: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _buildDomRlLog(
    List<Map<String, dynamic>> directives,
    List<Map<String, dynamic>> analytics,
  ) {
    final log = <Map<String, dynamic>>[];

    // Add directive-based entries
    for (final directive in directives.take(3)) {
      final action = directive['directive']?.toString() ?? 'MAINTAIN';
      log.add({
        'timestamp': _formatTimestamp(directive['created_at']),
        'action': _mapDirectiveToAction(action),
        'target': 'Weekly Plan',
        'rationale': directive['summary'] ?? 'Based on performance analysis',
      });
    }

    // Add analytics-based entries
    for (final event in analytics.take(2)) {
      final payload = event['payload'] as Map<String, dynamic>? ?? {};
      log.add({
        'timestamp': _formatTimestamp(event['created_at']),
        'action': payload['action']?.toString() ?? 'ADJUST',
        'target': payload['target']?.toString() ?? 'Protocol',
        'rationale': payload['rationale']?.toString() ?? 'System adaptation',
      });
    }

    // Add default entry if empty
    if (log.isEmpty) {
      log.add({
        'timestamp': 'Today',
        'action': 'STATUS_OK',
        'target': 'All Systems',
        'rationale': 'Biometrics optimal. Protocol executed as written.',
      });
    }

    return log;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Today';
    final date = DateTime.tryParse(timestamp.toString());
    if (date == null) return 'Today';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _mapDirectiveToAction(String directive) {
    switch (directive.toLowerCase()) {
      case 'overload':
        return 'OVERLOAD';
      case 'deload':
        return 'DEL_LOAD';
      case 'maintain':
      default:
        return 'MAINTAIN';
    }
  }

  List<Map<String, dynamic>> _getDefaultVolumeData() {
    return [
      {'day': 'Mon', 'volume': 0, 'percentage': 0.2},
      {'day': 'Tue', 'volume': 0, 'percentage': 0.2},
      {'day': 'Wed', 'volume': 0, 'percentage': 0.2},
      {'day': 'Thu', 'volume': 0, 'percentage': 0.2},
      {'day': 'Fri', 'volume': 0, 'percentage': 0.2},
      {'day': 'Sat', 'volume': 0, 'percentage': 0.2},
      {'day': 'Sun', 'volume': 0, 'percentage': 0.2},
    ];
  }

  List<Map<String, dynamic>> _getDefaultRpeData() {
    return List.generate(
      5,
      (index) => {
        'date': DateTime.now().subtract(Duration(days: 4 - index)),
        'rpe': 7.0,
        'workoutType': 'Workout',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.background,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.fort, color: LaconicTheme.secondary),
            const SizedBox(width: 12),
            Text(
              'THE GARRISON',
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
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LaconicTheme.secondary),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: LaconicTheme.secondary,
              backgroundColor: LaconicTheme.surfaceContainer,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'War Room Analytics',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.secondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Physical Assets',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: LaconicTheme.onSurface,
                        letterSpacing: -0.04,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Status',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: LaconicTheme.secondary,
                        letterSpacing: -0.04,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Heat Map Visualization
                    _buildHeatMapSection(),
                    const SizedBox(height: 32),

                    // DOM-RL Engine Log
                    _buildDomRlLogSection(),
                    const SizedBox(height: 32),

                    // Cumulative Volume Chart
                    _buildVolumeChartSection(),
                    const SizedBox(height: 32),

                    // Barbell Velocity Trend
                    _buildVelocityChartSection(),
                    const SizedBox(height: 32),

                    // Deload Alert
                    _buildDeloadAlert(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeatMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Heat Map',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
              ),
            ),
            Text(
              'High Strain >72h',
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: LaconicTheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: const BoxDecoration(
            color: LaconicTheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              // Body silhouette placeholder
              Container(
                width: 120,
                color: LaconicTheme.surfaceContainer,
                child: Center(
                  child: Icon(
                    Icons.accessibility,
                    color: LaconicTheme.outlineVariant,
                    size: 64,
                  ),
                ),
              ),
              // Heat indicators
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeatIndicator('Quads', 0.8, LaconicTheme.primary),
                      const SizedBox(height: 12),
                      _buildHeatIndicator(
                        'Lower Back',
                        0.6,
                        LaconicTheme.secondary,
                      ),
                      const SizedBox(height: 12),
                      _buildHeatIndicator(
                        'Shoulders',
                        0.4,
                        LaconicTheme.tertiary,
                      ),
                      const SizedBox(height: 12),
                      _buildHeatIndicator(
                        'Upper Back',
                        0.3,
                        LaconicTheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeatIndicator(String label, double intensity, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 24,
          color: color.withValues(alpha: intensity),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: LaconicTheme.onSurface),
        ),
        const Spacer(),
        Text(
          '${(intensity * 100).toInt()}%',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDomRlLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DOM-RL Engine Log',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
              ),
            ),
            Text(
              'Last 7 Days',
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: const BoxDecoration(
            color: LaconicTheme.surfaceContainerLow,
          ),
          child: Column(
            children: _domRlLog.map((entry) {
              Color actionColor;
              switch (entry['action']) {
                case 'DEL_LOAD':
                  actionColor = LaconicTheme.primary;
                  break;
                case 'SUB_EXERCISE':
                  actionColor = LaconicTheme.secondary;
                  break;
                default:
                  actionColor = LaconicTheme.outline;
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: LaconicTheme.surfaceContainer.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: 0.2),
                      ),
                      child: Text(
                        entry['timestamp'] as String,
                        style: GoogleFonts.workSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: actionColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                entry['action'] as String,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: actionColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '> ${entry['target']}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: LaconicTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry['rationale'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: LaconicTheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cumulative Volume',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
              ),
            ),
            Row(
              children: [
                Container(width: 12, height: 12, color: LaconicTheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '12,450 kg',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LaconicTheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: LaconicTheme.surfaceContainerLow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildVolumeBar('Mon', 0.6),
              _buildVolumeBar('Tue', 0.8),
              _buildVolumeBar('Wed', 0.4),
              _buildVolumeBar('Thu', 0.9),
              _buildVolumeBar('Fri', 0.5),
              _buildVolumeBar('Sat', 0.3),
              _buildVolumeBar('Sun', 0.2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeBar(String day, double height) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(height: height * 80, color: LaconicTheme.secondary),
            const SizedBox(height: 8),
            Text(
              day,
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVelocityChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barbell Velocity Trend',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: LaconicTheme.surfaceContainerLow,
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 60),
            painter: VelocityChartPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeloadAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.primary.withValues(alpha: 0.1),
        border: const Border(
          left: BorderSide(color: LaconicTheme.primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: LaconicTheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELOAD IMMINENT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: LaconicTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'System strain >85% for 14 days. Consider reducing volume by 40% next week.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: LaconicTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for velocity chart
class VelocityChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LaconicTheme.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.4, size.height * 0.6);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.4);

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = LaconicTheme.secondary
      ..style = PaintingStyle.fill;

    final points = [
      Offset(size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.5),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
