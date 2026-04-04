import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/workout_provider.dart';
import '../models/workout_tracking.dart';
import '../models/workout_protocol.dart';
import '../models/exercise.dart';
import '../services/firebase_sync_service.dart';
import '../services/armor_analytics_service.dart';
import '../services/tactical_retreat_service.dart';
import 'flow_state_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late Stopwatch _workoutStopwatch;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  
  final Map<int, List<SetPerformance>> _setPerformances = {};
  final Map<String, int> _currentJointStress = {};
  
  final FirebaseSyncService _firebase = FirebaseSyncService();
  final ArmorAnalyticsService _armor = ArmorAnalyticsService();
  final TacticalRetreatService _tacticalRetreat = TacticalRetreatService();

  @override
  void initState() {
    super.initState();
    _workoutStopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _workoutStopwatch.stop();
    _restTimer?.cancel();
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
        body: Center(child: Text("No Active Protocol", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, provider, protocol),
            const Divider(color: LaconicTheme.ironGray, height: 1),
            if (_isResting)
              _buildRestTimer(entry.restSeconds),
            Expanded(
              child: _buildExerciseView(entry, provider, protocol),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkoutProvider provider, WorkoutProtocol protocol) {
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
                stream: Stream.periodic(const Duration(seconds: 1), (_) => _workoutStopwatch.elapsed.inSeconds),
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
      color: LaconicTheme.spartanBronze.withOpacity(0.2),
      child: Column(
        children: [
          const Text('RECOVERY', style: TextStyle(color: LaconicTheme.spartanBronze, fontSize: 12, letterSpacing: 4.0)),
          const SizedBox(height: 12),
          Text(
            _formatTime(_restSecondsRemaining),
            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontFamily: "Courier"),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skipRest,
            child: const Text('SKIP REST', style: TextStyle(color: Colors.grey)),
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

  Widget _buildExerciseView(ProtocolEntry entry, WorkoutProvider provider, WorkoutProtocol protocol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            "EXERCISE ${provider.currentEntryIndex + 1}/${protocol.entries.length}",
            style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 4.0),
          ),
          const SizedBox(height: 16),
          Text(
            entry.exercise.name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
          const SizedBox(height: 24),
          Text(
            "GOAL: ${entry.sets} SETS × ${entry.reps > 0 ? entry.reps : 'MAX'} REPS",
            style: const TextStyle(color: LaconicTheme.spartanBronze, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("TARGET RPE: ${entry.intensityRPE}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          
          // Set tracking cards with RPE logging
          ...List.generate(entry.sets, (index) {
            final isCompleted = index < (_currentSet - 1);
            final isCurrent = index == (_currentSet - 1);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted ? LaconicTheme.spartanBronze.withOpacity(0.1) : 
                       isCurrent ? LaconicTheme.ironGray.withOpacity(0.2) : 
                       LaconicTheme.ironGray.withOpacity(0.1),
                border: Border.all(
                  color: isCompleted ? LaconicTheme.spartanBronze.withOpacity(0.5) : 
                         isCurrent ? LaconicTheme.spartanBronze : 
                         LaconicTheme.ironGray.withOpacity(0.3),
                  width: isCurrent ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SET ${index + 1}',
                        style: TextStyle(
                          color: isCompleted || isCurrent ? LaconicTheme.spartanBronze : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCompleted) 
                        const Icon(Icons.check_circle, color: LaconicTheme.spartanBronze, size: 20),
                    ],
                  ),
                  if (isCurrent && !_isResting) ...[
                    const SizedBox(height: 12),
                    const Text('LOG RPE:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(8, (i) {
                        final rpe = i + 3;
                        return GestureDetector(
                          onTap: () => _logSet(entry, rpe.toDouble()),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: rpe == entry.intensityRPE.round() 
                                  ? LaconicTheme.spartanBronze.withOpacity(0.3)
                                  : LaconicTheme.ironGray.withOpacity(0.3),
                              border: Border.all(
                                color: rpe == entry.intensityRPE.round() 
                                    ? LaconicTheme.spartanBronze 
                                    : Colors.transparent,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '$rpe',
                                style: TextStyle(
                                  color: rpe == entry.intensityRPE.round() 
                                      ? LaconicTheme.spartanBronze 
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            );
          }),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: (_currentSet > entry.sets) ? () {
              if (provider.currentEntryIndex < protocol.entries.length - 1) {
                setState(() => _currentSet = 1);
                provider.nextExercise();
              } else {
                _finishWorkout(context, provider);
              }
            } : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 60),
              shape: const BeveledRectangleBorder(),
              disabledBackgroundColor: Colors.grey.shade800,
            ),
            child: Text(
              provider.currentEntryIndex < protocol.entries.length - 1 ? "NEXT EXERCISE" : "FINISH PROTOCOL",
              style: const TextStyle(letterSpacing: 2.0),
            ),
          ),
        ],
      ),
    );
  }

  void _logSet(ProtocolEntry entry, double rpe) {
    setState(() => _currentSet++);
    if (_currentSet <= entry.sets) {
      _startRest(entry.restSeconds);
    }
  }

  int _currentSet = 1;

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
        title: const Text("ABANDON MISSION?", style: TextStyle(color: Colors.white)),
        content: const Text("The Spartan does not yield lightly. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("RESUME", style: TextStyle(color: LaconicTheme.spartanBronze)),
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
