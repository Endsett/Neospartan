// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/workout_provider.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';
import '../services/supabase_database_service.dart';

/// The Crucible - Workout Session Screen
/// Based on the_crucible_workout design
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  late Stopwatch _workoutStopwatch;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  int _currentSet = 1;
  final List<SetPerformance> _completedSets = [];

  // Weight and reps tracking
  double _currentWeight = 60.0;
  int _currentReps = 10;
  double _actualRPE = 8.0;
  int _repsInReserve = 2;

  // Tempo tracking
  int _eccentricDuration = 3;
  int _pauseDuration = 1;
  int _concentricDuration = 1;

  // Previous performance data
  Map<String, dynamic>? _previousSession;

  // Animation controllers
  late AnimationController _restAnimationController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  // Motivational features
  int _workoutStreak = 0;
  bool _showAchievement = false;
  String? _achievementText;

  // Form check
  // bool _showFormOverlay = false; // TODO: Implement form check overlay

  // Heart rate zone (if available)
  int? _currentHeartRate;

  // Fatigue tracking
  double _fatigueScore = 0.0;
  List<double> _setRPEScores = [];

  // Volume tracking
  double _exerciseVolume = 0.0;

  @override
  void initState() {
    super.initState();
    _workoutStopwatch = Stopwatch()..start();
    _restAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Load data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreviousSessionData();
      _loadWorkoutStreak();
    });
  }

  @override
  void dispose() {
    _workoutStopwatch.stop();
    _restTimer?.cancel();
    _restAnimationController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> _loadPreviousSessionData() async {
    // Fetch previous session data from Supabase
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final entry = provider.currentEntry;

    if (entry != null) {
      try {
        final db = SupabaseDatabaseService();
        final previousData = await db.getPreviousExerciseSession(
          entry.exercise.name,
        );

        if (mounted) {
          setState(() {
            _previousSession = previousData;
          });
        }
      } catch (e) {
        debugPrint('Error loading previous session data: $e');
        // Keep mock data as fallback
        if (mounted) {
          setState(() {
            _previousSession = {
              'weight': 57.5,
              'reps': 9,
              'rpe': 7.5,
              'date': '3 days ago',
            };
          });
        }
      }
    }
  }

  Future<void> _loadWorkoutStreak() async {
    // TODO: Fetch workout streak from Supabase
    setState(() {
      _workoutStreak = 3;
    });
  }

  void _checkAchievements() {
    // Check for various achievements
    if (_completedSets.length == 10 && !_showAchievement) {
      setState(() {
        _showAchievement = true;
        _achievementText = '🔥 10 SETS MILESTONE!';
      });
      _showAchievementNotification();
    }
  }

  void _showAchievementNotification() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showAchievement = false);
      }
    });
  }

  String _getTempoDisplay() {
    return '$_eccentricDuration-$_pauseDuration-$_concentricDuration-$_pauseDuration';
  }

  Color _getRPEColor(double rpe) {
    if (rpe <= 5) return Colors.green;
    if (rpe <= 7) return Colors.orange;
    return Colors.red;
  }

  String _getHeartRateZone() {
    if (_currentHeartRate == null) return 'N/A';
    final maxHR = 220 - 30; // Assuming age 30, should get from user profile
    final percentage = (_currentHeartRate! / maxHR) * 100;

    if (percentage < 60) return 'Zone 1 (Recovery)';
    if (percentage < 70) return 'Zone 2 (Base)';
    if (percentage < 80) return 'Zone 3 (Build)';
    if (percentage < 90) return 'Zone 4 (Threshold)';
    return 'Zone 5 (Max)';
  }

  void _updateFatigueScore() {
    if (_setRPEScores.isEmpty) {
      _fatigueScore = 0.0;
      return;
    }

    // Calculate fatigue as average RPE deviation from target
    final targetRPE =
        Provider.of<WorkoutProvider>(
          context,
          listen: false,
        ).currentEntry?.intensityRpe ??
        7.0;

    final averageRPE =
        _setRPEScores.reduce((a, b) => a + b) / _setRPEScores.length;
    _fatigueScore = (averageRPE - targetRPE).clamp(0.0, 3.0);
  }

  int _getAdaptiveRestTime(int baseRestTime) {
    // Adjust rest time based on fatigue and RIR
    int adjustedTime = baseRestTime;

    // Increase rest if fatigue is high
    if (_fatigueScore > 1.0) {
      adjustedTime += 30; // Add 30 seconds for high fatigue
    } else if (_fatigueScore > 0.5) {
      adjustedTime += 15; // Add 15 seconds for moderate fatigue
    }

    // Decrease rest if RIR is high (easy set)
    if (_repsInReserve >= 3) {
      adjustedTime -= 15; // Reduce 15 seconds if many reps left
    } else if (_repsInReserve == 0) {
      adjustedTime += 30; // Add 30 seconds if failure
    }

    return adjustedTime.clamp(30, 300); // Keep between 30s and 5min
  }

  String _getVolumeDisplay() {
    final totalVolume =
        _exerciseVolume + (_currentWeight * _currentReps * _currentSet);
    return '${totalVolume.toStringAsFixed(0)} kg';
  }

  String _getFatigueMessage() {
    if (_fatigueScore < 0.5) return 'Feeling Fresh 💪';
    if (_fatigueScore < 1.0) return 'Moderate Fatigue 😊';
    if (_fatigueScore < 1.5) return 'Getting Tired 😐';
    return 'High Fatigue ⚠️';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final protocol = provider.activeProtocol;
    final entry = provider.currentEntry;

    if (protocol == null || entry == null) {
      return Scaffold(
        backgroundColor: LaconicTheme.background,
        body: const Center(
          child: Text(
            "No Active Protocol",
            style: TextStyle(color: LaconicTheme.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LaconicTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, provider, protocol),

            // Achievement notification
            if (_showAchievement)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.red.shade400],
                  ),
                ),
                child: Text(
                  _achievementText!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),

            if (_isResting) _buildRestTimer(entry.restSeconds),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Title with Play Icon
                    _buildExerciseHeader(entry),
                    const SizedBox(height: 24),

                    // Previous performance indicator
                    if (_previousSession != null) _buildPreviousSessionCard(),
                    const SizedBox(height: 24),

                    // Tempo display
                    _buildTempoSection(),
                    const SizedBox(height: 24),

                    // Volume and fatigue indicator
                    _buildVolumeFatigueSection(),
                    const SizedBox(height: 24),

                    // Weight Controls
                    _buildControlSection(
                      label: 'WEIGHT',
                      value: '${_currentWeight.toStringAsFixed(1)} KG',
                      onDecrease: () => setState(
                        () =>
                            _currentWeight = math.max(0, _currentWeight - 2.5),
                      ),
                      onIncrease: () => setState(() => _currentWeight += 2.5),
                    ),
                    const SizedBox(height: 24),

                    // Reps Controls
                    _buildControlSection(
                      label: 'REPS COMPLETED',
                      value: '$_currentReps',
                      onDecrease: () => setState(
                        () => _currentReps = math.max(1, _currentReps - 1),
                      ),
                      onIncrease: () => setState(() => _currentReps += 1),
                    ),
                    const SizedBox(height: 24),

                    // RPE Slider
                    _buildRPESlider(),
                    const SizedBox(height: 24),

                    // RIR Selector
                    _buildRIRSelector(),
                    const SizedBox(height: 32),

                    // Action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSecondaryButton(
                            'FORM CHECK',
                            Icons.videocam,
                            () => _showFormCheckPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSecondaryButton(
                            'TEMPO GUIDE',
                            Icons.timer,
                            () => _showTempoGuide(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Log Set Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isResting
                            ? null
                            : () => _logSet(entry.restSeconds),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LaconicTheme.secondary,
                          foregroundColor: LaconicTheme.onSecondary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(
                          'LOG SET $_currentSet',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Voice Command Button
                    Center(
                      child: GestureDetector(
                        onTap: () => _activateVoiceCommand(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: LaconicTheme.surfaceContainer,
                            border: Border.all(
                              color: LaconicTheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + (_pulseController.value * 0.2),
                                    child: const Icon(
                                      Icons.mic,
                                      color: LaconicTheme.primary,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'VOICE COMMAND',
                                style: GoogleFonts.workSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: LaconicTheme.primary,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Heart Rate Zone (if available)
                    if (_currentHeartRate != null) _buildHeartRateSection(),
                    const SizedBox(height: 32),

                    // Next Exercises
                    _buildNextExercisesSection(protocol, provider),
                    const SizedBox(height: 40),

                    // Finish/Next Exercise Button
                    if (_currentSet > entry.sets)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final isLastExercise =
                                provider.currentEntryIndex >=
                                protocol.entries.length - 1;
                            await provider.completeExercise(
                              List<SetPerformance>.from(_completedSets),
                            );
                            _completedSets.clear();
                            if (!mounted) return;
                            if (!isLastExercise) {
                              setState(() => _currentSet = 1);
                            } else {
                              _finishWorkout(context, provider);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LaconicTheme.primary,
                            foregroundColor: LaconicTheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            provider.currentEntryIndex <
                                    protocol.entries.length - 1
                                ? "NEXT EXERCISE"
                                : "FINISH PROTOCOL",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WorkoutProvider provider,
    WorkoutProtocol protocol,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: LaconicTheme.surfaceContainerHigh),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    protocol.title.toUpperCase(),
                    style: GoogleFonts.workSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: LaconicTheme.secondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (_workoutStreak > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(color: Colors.orange.shade400),
                      child: Text(
                        '🔥 $_workoutStreak',
                        style: GoogleFonts.workSans(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              StreamBuilder<int>(
                stream: Stream.periodic(
                  const Duration(seconds: 1),
                  (_) => _workoutStopwatch.elapsed.inSeconds,
                ),
                builder: (context, snapshot) {
                  return Text(
                    _formatTime(snapshot.data ?? 0),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: LaconicTheme.onSurface,
                      letterSpacing: -0.02,
                    ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: LaconicTheme.outline),
            onPressed: () => _showCancelDialog(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(ProtocolEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercise',
          style: GoogleFonts.workSans(
            fontSize: 10,
            color: LaconicTheme.onSurfaceVariant,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: LaconicTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: LaconicTheme.primary.withValues(
                        alpha: 0.3 * _progressController.value,
                      ),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: LaconicTheme.primary,
                    size: 28,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.exercise.name.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: LaconicTheme.onSurface,
                      letterSpacing: -0.02,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMetricChip(
                        '${entry.sets} SETS',
                        LaconicTheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricChip(
                        '${entry.reps} REPS',
                        LaconicTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricChip(
                        'RPE ${entry.intensityRpe.toStringAsFixed(1)}',
                        LaconicTheme.outline,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricChip(
                        _getTempoDisplay(),
                        LaconicTheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: LaconicTheme.surfaceContainerLow),
      child: Text(
        label,
        style: GoogleFonts.workSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildPreviousSessionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.surfaceContainerLow,
        border: Border.all(
          color: LaconicTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 16,
                color: LaconicTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'LAST SESSION',
                style: GoogleFonts.workSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: LaconicTheme.onSurfaceVariant,
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              Text(
                _previousSession!['date'],
                style: GoogleFonts.workSans(
                  fontSize: 10,
                  color: LaconicTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${_previousSession!['weight']} kg × ${_previousSession!['reps']} reps',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: LaconicTheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _currentWeight > _previousSession!['weight']
                      ? Colors.green.withValues(alpha: 0.2)
                      : LaconicTheme.surfaceContainer,
                ),
                child: Text(
                  _currentWeight > _previousSession!['weight']
                      ? '+${(_currentWeight - _previousSession!['weight']).toStringAsFixed(1)} kg'
                      : 'Same weight',
                  style: GoogleFonts.workSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _currentWeight > _previousSession!['weight']
                        ? Colors.green
                        : LaconicTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TEMPO',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.secondary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showTempoGuide(),
              child: const Icon(
                Icons.info_outline,
                size: 14,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: LaconicTheme.surfaceContainer),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTempoPhase('ECCENTRIC', _eccentricDuration, Colors.blue),
              _buildTempoDivider(),
              _buildTempoPhase('PAUSE', _pauseDuration, Colors.grey),
              _buildTempoDivider(),
              _buildTempoPhase('CONCENTRIC', _concentricDuration, Colors.green),
              _buildTempoDivider(),
              _buildTempoPhase('PAUSE', _pauseDuration, Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTempoPhase(String label, int seconds, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${seconds}s',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTempoDivider() {
    return Container(width: 1, height: 40, color: LaconicTheme.outlineVariant);
  }

  Widget _buildRPESlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RATE OF PERCEIVED EXERTION',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.secondary,
                letterSpacing: 0.1,
              ),
            ),
            Text(
              '${_actualRPE.toStringAsFixed(1)}/10',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _getRPEColor(_actualRPE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getRPEColor(_actualRPE),
            inactiveTrackColor: LaconicTheme.surfaceContainerHighest,
            thumbColor: _getRPEColor(_actualRPE),
            overlayColor: _getRPEColor(_actualRPE).withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: _actualRPE,
            min: 1,
            max: 10,
            divisions: 18,
            onChanged: (value) => setState(() => _actualRPE = value),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Easy',
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Very Hard',
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRIRSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPS IN RESERVE (RIR)',
          style: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.secondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final value = index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _repsInReserve = value),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _repsInReserve == value
                        ? LaconicTheme.primary
                        : LaconicTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _repsInReserve == value
                          ? LaconicTheme.onPrimary
                          : LaconicTheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'How many more reps could you have done?',
          style: GoogleFonts.workSans(
            fontSize: 10,
            color: LaconicTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: LaconicTheme.surfaceContainer,
          border: Border.all(
            color: LaconicTheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: LaconicTheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.primary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.surfaceContainerLow,
        border: Border.all(
          color: LaconicTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HEART RATE',
                style: GoogleFonts.workSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: LaconicTheme.onSurfaceVariant,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                '$_currentHeartRate bpm - ${_getHeartRateZone()}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LaconicTheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeFatigueSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.surfaceContainerLow,
        border: Border.all(
          color: LaconicTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VOLUME LOAD',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.onSurfaceVariant,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getVolumeDisplay(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: LaconicTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: LaconicTheme.outlineVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FATIGUE LEVEL',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.onSurfaceVariant,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFatigueMessage(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _fatigueScore > 1.5
                            ? Colors.red
                            : LaconicTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_fatigueScore > 0.5) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
              ),
              child: Text(
                'Rest time adjusted +${_getAdaptiveRestTime(60) - 60}s',
                style: GoogleFonts.workSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlSection({
    required String label,
    required String value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.secondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Decrease Button
            GestureDetector(
              onTap: onDecrease,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: LaconicTheme.surfaceContainerHigh,
                ),
                child: const Icon(
                  Icons.remove,
                  color: LaconicTheme.onSurface,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Value Display
            Expanded(
              child: Container(
                height: 56,
                decoration: const BoxDecoration(
                  color: LaconicTheme.surfaceContainer,
                ),
                child: Center(
                  child: Text(
                    value,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: LaconicTheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Increase Button
            GestureDetector(
              onTap: onIncrease,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(color: LaconicTheme.secondary),
                child: const Icon(
                  Icons.add,
                  color: LaconicTheme.onSecondary,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRestTimer(int totalSeconds) {
    final progress = _restSecondsRemaining / totalSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: LaconicTheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: LaconicTheme.surfaceContainerHigh),
        ),
      ),
      child: Column(
        children: [
          Text(
            'RECOVERY',
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.secondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          // Circular Timer
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: LaconicTheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    LaconicTheme.secondary,
                  ),
                ),
                Center(
                  child: Text(
                    _formatTime(_restSecondsRemaining),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: LaconicTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _skipRest,
            child: Text(
              'SKIP REST',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.outline,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextExercisesSection(
    WorkoutProtocol protocol,
    WorkoutProvider provider,
  ) {
    final nextExercises = protocol.entries
        .skip(provider.currentEntryIndex + 1)
        .take(3)
        .toList();

    if (nextExercises.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEXT EXERCISES',
          style: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.onSurfaceVariant,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: nextExercises.length,
            separatorBuilder: (_, i) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final exercise = nextExercises[index];
              return Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: LaconicTheme.surfaceContainerLow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      exercise.exercise.name.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${exercise.sets} sets x ${exercise.reps} reps',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        color: LaconicTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restSecondsRemaining--;
        if (_restSecondsRemaining <= 0) {
          _isResting = false;
          timer.cancel();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _isResting = false);
  }

  void _logSet(int restSeconds) {
    final performance = SetPerformance(
      setNumber: _currentSet,
      repsPerformed: _currentReps,
      loadUsed: _currentWeight,
      actualRPE: _actualRPE,
      completed: true,
      notes: 'RIR: $_repsInReserve, Tempo: ${_getTempoDisplay()}',
    );

    setState(() {
      _completedSets.add(performance);
      _setRPEScores.add(_actualRPE);
      _exerciseVolume += _currentWeight * _currentReps;
      _currentSet++;
    });

    // Update fatigue score
    _updateFatigueScore();

    // Check for achievements
    _checkAchievements();

    // Trigger progress animation
    _progressController.forward().then((_) {
      _progressController.reset();
    });

    final entry = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    ).currentEntry;
    if (entry != null && _currentSet <= entry.sets) {
      final adaptiveRestTime = _getAdaptiveRestTime(restSeconds);
      _startRest(adaptiveRestTime);
    }
  }

  void _showFormCheckPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Form check feature coming soon! Use a mirror or record yourself for now.',
          style: GoogleFonts.workSans(fontWeight: FontWeight.w500),
        ),
        backgroundColor: LaconicTheme.secondary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _activateVoiceCommand() {
    // Simulate voice command activation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mic, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Listening... Say "log set" or "increase weight"',
              style: GoogleFonts.workSans(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: LaconicTheme.secondary,
        duration: const Duration(seconds: 3),
      ),
    );

    // Simulate voice command processing
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Voice command recognized: "Log set $_currentSet"',
              style: GoogleFonts.workSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _logSet(60); // Default rest time
      }
    });
  }

  void _showTempoGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.surfaceContainer,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'TEMPO GUIDE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: LaconicTheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tempo controls the speed of each rep:',
              style: GoogleFonts.inter(color: LaconicTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _buildTempoExplanation(
              'ECCENTRIC',
              _eccentricDuration,
              'Lowering the weight',
            ),
            _buildTempoExplanation('PAUSE', _pauseDuration, 'Bottom position'),
            _buildTempoExplanation(
              'CONCENTRIC',
              _concentricDuration,
              'Lifting the weight',
            ),
            _buildTempoExplanation('PAUSE', _pauseDuration, 'Top position'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'GOT IT',
              style: GoogleFonts.workSans(
                color: LaconicTheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempoExplanation(String phase, int seconds, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              phase,
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
              ),
            ),
          ),
          Text(
            '${seconds}s - $description',
            style: GoogleFonts.inter(color: LaconicTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _finishWorkout(BuildContext context, WorkoutProvider provider) {
    provider.finishWorkout();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "VICTORY! Protocol Logged.",
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        backgroundColor: LaconicTheme.secondary,
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WorkoutProvider provider) {
    final completedExercises = provider.completedExercises.length;
    final totalExercises = provider.activeProtocol?.entries.length ?? 0;
    final percentage = totalExercises > 0
        ? (completedExercises / totalExercises * 100).toStringAsFixed(0)
        : '0';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.surfaceContainer,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          "ABANDON MISSION?",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: LaconicTheme.onSurface,
          ),
        ),
        content: Text(
          completedExercises > 0
              ? "You've completed $completedExercises of $totalExercises exercises ($percentage%).\n\nYour partial progress will be saved."
              : "The Spartan does not yield lightly. Are you sure?",
          style: GoogleFonts.inter(color: LaconicTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "RESUME",
              style: GoogleFonts.workSans(
                color: LaconicTheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await provider.abandonWorkout();
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              "ABANDON",
              style: GoogleFonts.workSans(
                color: LaconicTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
