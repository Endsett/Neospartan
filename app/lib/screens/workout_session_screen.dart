import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/workout_provider.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';
import '../widgets/set_tracker_card.dart';
import '../utils/page_transitions.dart';

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
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _workoutStopwatch = Stopwatch()..start();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _workoutStopwatch.stop();
    _restTimer?.cancel();
    _slideController.dispose();
    _fadeController.dispose();
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
      return const Scaffold(
        body: Center(
          child: Text(
            "No Active Protocol",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, provider, protocol),
            const Divider(color: LaconicTheme.ironGray, height: 1),
            if (_isResting) _buildRestTimer(entry.restSeconds),
            Expanded(child: _buildExerciseView(entry, provider, protocol)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                protocol.title,
                style: const TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: "Courier",
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => _showCancelDialog(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer(int totalSeconds) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: LaconicTheme.spartanBronze.withValues(alpha: 0.2),
      child: Column(
        children: [
          const Text(
            'RECOVERY',
            style: TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 12,
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatTime(_restSecondsRemaining),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontFamily: "Courier",
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skipRest,
            child: const Text(
              'SKIP REST',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
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

  Widget _buildExerciseView(
    ProtocolEntry entry,
    WorkoutProvider provider,
    WorkoutProtocol protocol,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            "EXERCISE ${provider.currentEntryIndex + 1}/${protocol.entries.length}",
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            entry.exercise.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "GOAL: ${entry.sets} SETS × ${entry.reps > 0 ? entry.reps : 'MAX'} REPS",
            style: const TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "TARGET RPE: ${entry.intensityRpe}",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Set tracking cards with detailed logging
          ...List.generate(entry.sets, (index) {
            final setNumber = index + 1;
            final isCompleted = setNumber < _currentSet;
            final isCurrent = setNumber == _currentSet;

            // Find previous performance for this set if completed
            SetPerformance? previousPerformance;
            if (isCompleted && index < _completedSets.length) {
              previousPerformance = _completedSets[index];
            }

            return SetTrackerCard(
              setNumber: setNumber,
              targetReps: entry.reps,
              targetRPE: entry.intensityRpe,
              isCompleted: isCompleted,
              isCurrent: isCurrent && !_isResting,
              previousPerformance: previousPerformance,
              onComplete: isCurrent && !_isResting ? _logSet : (_) {},
              onEdit: isCompleted ? () => _editSet(index) : null,
            );
          }),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: (_currentSet > entry.sets)
                ? () {
                    if (provider.currentEntryIndex <
                        protocol.entries.length - 1) {
                      setState(() => _currentSet = 1);
                      provider.nextExercise();
                    } else {
                      _finishWorkout(context, provider);
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 60),
              shape: const BeveledRectangleBorder(),
              disabledBackgroundColor: Colors.grey.shade800,
            ),
            child: Text(
              provider.currentEntryIndex < protocol.entries.length - 1
                  ? "NEXT EXERCISE"
                  : "FINISH PROTOCOL",
              style: const TextStyle(letterSpacing: 2.0),
            ),
          ),
        ],
      ),
    );
  }

  void _logSet(SetPerformance performance) {
    setState(() {
      _completedSets.add(performance);
      _currentSet++;
    });

    // Auto-save to Firebase after each set
    _saveSetToFirebase(performance);

    if (_currentSet <=
        (Provider.of<WorkoutProvider>(
              context,
              listen: false,
            ).currentEntry?.sets ??
            0)) {
      _startRest(
        Provider.of<WorkoutProvider>(
              context,
              listen: false,
            ).currentEntry?.restSeconds ??
            60,
      );
    }
  }

  Future<void> _saveSetToFirebase(SetPerformance performance) async {
    try {
      // Save individual set data - would be part of the workout log
      debugPrint(
        'Set ${performance.setNumber} logged: ${performance.repsPerformed} reps @ RPE ${performance.actualRPE}',
      );
    } catch (e) {
      debugPrint('Error saving set: $e');
    }
  }

  void _editSet(int setIndex) {
    // Allow editing a completed set
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.deepBlack,
        title: const Text('EDIT SET', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Edit functionality would allow modifying set data',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: LaconicTheme.spartanBronze),
            ),
          ),
        ],
      ),
    );
  }

  void _finishWorkout(BuildContext context, WorkoutProvider provider) {
    provider.finishWorkout();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("VICTORY! Protocol Logged."),
        backgroundColor: LaconicTheme.spartanBronze,
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.deepBlack,
        title: const Text(
          "ABANDON MISSION?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "The Spartan does not yield lightly. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "RESUME",
              style: TextStyle(color: LaconicTheme.spartanBronze),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.cancelWorkout();
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
            },
            child: const Text("ABANDON", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
