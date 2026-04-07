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

  late AnimationController _restAnimationController;

  @override
  void initState() {
    super.initState();
    _workoutStopwatch = Stopwatch()..start();
    _restAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _workoutStopwatch.stop();
    _restTimer?.cancel();
    _restAnimationController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
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
            if (_isResting) _buildRestTimer(entry.restSeconds),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Title with Play Icon
                    _buildExerciseHeader(entry),
                    const SizedBox(height: 32),

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
                    const SizedBox(height: 32),

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
                        onTap: () {
                          // Voice command functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Voice command activated'),
                              backgroundColor:
                                  LaconicTheme.surfaceContainerHigh,
                            ),
                          );
                        },
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
                              const Icon(
                                Icons.mic,
                                color: LaconicTheme.primary,
                                size: 20,
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
              Text(
                protocol.title.toUpperCase(),
                style: GoogleFonts.workSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: LaconicTheme.secondary,
                  letterSpacing: 0.2,
                ),
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
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: LaconicTheme.surfaceContainer,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: LaconicTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                entry.exercise.name.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: LaconicTheme.onSurface,
                  letterSpacing: -0.02,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMetricChip('${entry.sets} SETS', LaconicTheme.secondary),
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
      actualRPE: 8.0, // Default RPE
      completed: true,
    );

    setState(() {
      _completedSets.add(performance);
      _currentSet++;
    });

    final entry = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    ).currentEntry;
    if (entry != null && _currentSet <= entry.sets) {
      _startRest(restSeconds);
    }
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
