import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../theme.dart';
import '../models/workout_plan_enhanced.dart';
import '../models/workout_tracking.dart';
import '../models/exercise.dart';
import '../widgets/exercise_progress_card.dart';
import '../widgets/voice_command_overlay.dart';
import '../services/workout_plan_storage_service.dart';

class WorkoutProgressScreen extends StatefulWidget {
  final EnhancedDailyWorkoutPlan workoutPlan;
  final int readinessScore;

  const WorkoutProgressScreen({
    super.key,
    required this.workoutPlan,
    required this.readinessScore,
  });

  @override
  State<WorkoutProgressScreen> createState() => _WorkoutProgressScreenState();
}

class _WorkoutProgressScreenState extends State<WorkoutProgressScreen>
    with TickerProviderStateMixin {
  // Progress tracking
  final Map<String, ExerciseProgress> _exerciseProgress = {};
  final Map<String, List<SetPerformance>> _setPerformances = {};
  final Map<String, bool> _exerciseCompleted = {};

  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _restTimerController;
  late Animation<double> _restTimerAnimation;

  // Timer and state
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  DateTime? _workoutStartTime;
  int _currentExerciseIndex = 0;

  // Voice and haptic
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  String _lastWords = '';
  late FlutterTts _flutterTts;
  bool _showVoiceOverlay = false;

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoice();
    _initializeProgress();
    _startWorkout();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _restTimerController.dispose();
    _restTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _restTimerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _restTimerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _restTimerController, curve: Curves.linear),
    );
  }

  void _initializeVoice() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    bool available = await _speech.initialize(
      onError: (val) => print('Speech error: $val'),
      onStatus: (val) => print('Speech status: $val'),
    );

    if (available) {
      setState(() {
        _speechEnabled = true;
      });
    }

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  void _initializeProgress() {
    for (final exercise in widget.workoutPlan.allExercises) {
      _exerciseProgress[exercise.id] = ExerciseProgress(
        completedSets: 0,
        totalSets: exercise.sets,
        completedReps: 0,
        totalReps: exercise.targetReps * exercise.sets,
        completedWeight: 0.0,
        totalWeight:
            (exercise.suggestedWeight ?? 0.0) *
            exercise.targetReps *
            exercise.sets,
      );

      _setPerformances[exercise.id] = [];
      _exerciseCompleted[exercise.id] = false;
    }
  }

  void _startWorkout() {
    setState(() {
      _workoutStartTime = DateTime.now();
    });

    _speak(
      "Workout started. Let's begin with ${widget.workoutPlan.allExercises.first.name}.",
    );
    _vibratePattern([0, 100, 50, 100]);
  }

  void _updateExerciseProgress(
    String exerciseId, {
    int? setNumber,
    int? reps,
    double? weight,
    double? rpe,
    bool? completed,
  }) {
    final progress = _exerciseProgress[exerciseId];
    if (progress == null) return;

    setState(() {
      if (setNumber != null && reps != null) {
        final setPerformance = SetPerformance(
          setNumber: setNumber,
          repsPerformed: reps,
          loadUsed: weight,
          actualRPE: rpe,
          completed: completed ?? true,
        );

        _setPerformances[exerciseId]!.add(setPerformance);
        progress.completedSets++;

        if (progress.completedSets >= progress.targetSets) {
          _exerciseCompleted[exerciseId] = true;
          _vibratePattern([0, 200, 100, 200]);
          _speak("Exercise completed!");

          // Move to next exercise
          if (_currentExerciseIndex <
              widget.workoutPlan.allExercises.length - 1) {
            _currentExerciseIndex++;
            _scrollToNextExercise();
          }
        }
      }

      _progressController.reset();
      _progressController.forward();
    });
  }

  void _startRestTimer(int seconds) {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
    });

    _restTimerController.duration = Duration(seconds: seconds);
    _restTimerController.reset();
    _restTimerController.forward();

    _speak("Rest for $seconds seconds");

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restSecondsRemaining--;

        if (_restSecondsRemaining <= 3 && _restSecondsRemaining > 0) {
          _speak("$_restSecondsRemaining");
          _vibrate(100);
        }

        if (_restSecondsRemaining <= 0) {
          timer.cancel();
          _isResting = false;
          _speak("Rest complete. Ready for next set!");
          _vibratePattern([0, 100, 50, 100, 50, 200]);
        }
      });
    });
  }

  void _scrollToNextExercise() {
    if (_currentExerciseIndex < widget.workoutPlan.allExercises.length) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _currentExerciseIndex * 200.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _vibrate(int duration) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration);
    }
  }

  Future<void> _vibratePattern(List<int> pattern) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: pattern);
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _listenForCommands() {
    if (!_speechEnabled) return;

    _speech.listen(
      onResult: (val) => setState(() {
        _lastWords = val.recognizedWords;
        _processVoiceCommand(_lastWords);
      }),
    );
  }

  void _processVoiceCommand(String command) {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('next set') || lowerCommand.contains('next')) {
      _startRestTimer(90);
    } else if (lowerCommand.contains('complete') ||
        lowerCommand.contains('done')) {
      final currentExercise =
          widget.workoutPlan.allExercises[_currentExerciseIndex];
      _updateExerciseProgress(
        currentExercise.id,
        setNumber: _exerciseProgress[currentExercise.id]!.completedSets + 1,
        reps: currentExercise.targetReps,
        completed: true,
      );
    } else if (lowerCommand.contains('rest')) {
      _startRestTimer(
        int.tryParse(lowerCommand.replaceAll(RegExp(r'[^0-9]'), '')) ?? 60,
      );
    }
  }

  void _handleVoiceCommand(String command) {
    if (command.startsWith('start_rest:')) {
      final seconds = int.tryParse(command.split(':')[1]) ?? 60;
      _startRestTimer(seconds);
    } else if (command == 'next_set') {
      _startRestTimer(90);
    } else if (command == 'complete_exercise') {
      final currentExercise =
          widget.workoutPlan.allExercises[_currentExerciseIndex];
      _updateExerciseProgress(
        currentExercise.id,
        setNumber: _exerciseProgress[currentExercise.id]!.completedSets + 1,
        reps: currentExercise.targetReps,
        completed: true,
      );
    } else if (command == 'skip_exercise') {
      if (_currentExerciseIndex < widget.workoutPlan.allExercises.length - 1) {
        _currentExerciseIndex++;
        _scrollToNextExercise();
      }
    } else if (command == 'pause_workout') {
      // TODO: Implement pause functionality
      _speak('Workout paused');
    } else if (command == 'resume_workout') {
      // TODO: Implement resume functionality
      _speak('Workout resumed');
    } else if (command == 'finish_workout') {
      _completeWorkout();
    } else {
      _processVoiceCommand(command);
    }
  }

  double get overallProgress {
    if (_exerciseProgress.isEmpty) return 0.0;

    int totalSets = 0;
    int completedSets = 0;

    for (final progress in _exerciseProgress.values) {
      totalSets += progress.targetSets;
      completedSets += progress.completedSets;
    }

    return totalSets > 0 ? completedSets / totalSets : 0.0;
  }

  int get totalExercises => widget.workoutPlan.allExercises.length;
  int get completedExercises =>
      _exerciseCompleted.values.where((c) => c).length;

  Future<void> _completeWorkout() async {
    final completedWorkout = CompletedWorkout(
      id: 'completed_${DateTime.now().millisecondsSinceEpoch}',
      protocolTitle: widget.workoutPlan.workoutType,
      exercises: widget.workoutPlan.allExercises.map((workoutExercise) {
        return CompletedExerciseEntry(
          exercise: Exercise(
            id: workoutExercise.id,
            name: workoutExercise.name,
            category: workoutExercise.category,
            youtubeId: workoutExercise.youtubeId ?? '',
            targetMetaphor: workoutExercise.targetMetaphor ?? '',
            instructions: workoutExercise.instructions,
            intensityLevel: 1, // Default intensity level
            primaryMuscles: [],
            jointStress: {},
            workoutTags: [],
          ),
          sets: _setPerformances[workoutExercise.id] ?? [],
          completedAt: DateTime.now(),
          progressiveOverloadData: workoutExercise.hasProgressiveOverloadData
              ? {
                  'previousWeight': workoutExercise.previousWeight,
                  'previousReps': workoutExercise.previousReps,
                  'weightIncrease': workoutExercise.weightIncrease,
                  'repIncrease': workoutExercise.repIncrease,
                }
              : null,
          substitutionOptions: workoutExercise.substitutionExerciseNames,
        );
      }).toList(),
      startTime: _workoutStartTime ?? DateTime.now(),
      endTime: DateTime.now(),
      totalDurationMinutes: DateTime.now()
          .difference(_workoutStartTime ?? DateTime.now())
          .inMinutes,
      readinessScoreAtStart: widget.readinessScore,
    );

    // Save completed workout
    final storageService = WorkoutPlanStorageService();
    await storageService.completeWorkoutSession();

    // Show completion dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) =>
            WorkoutCompletionDialog(completedWorkout: completedWorkout),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_isResting) _buildRestTimer(),
                Expanded(child: _buildExerciseList()),
                _buildBottomControls(),
              ],
            ),
          ),
          VoiceCommandOverlay(
            isVisible: _showVoiceOverlay,
            onCommand: _handleVoiceCommand,
            onToggleVisibility: () {
              setState(() {
                _showVoiceOverlay = !_showVoiceOverlay;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.workoutPlan.workoutType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _completeWorkout,
                child: const Text(
                  'Finish Workout',
                  style: TextStyle(color: LaconicTheme.accentRed, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: overallProgress,
                  backgroundColor: LaconicTheme.ironGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    LaconicTheme.accentRed,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(overallProgress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercises: $completedExercises/$totalExercises',
                style: const TextStyle(
                  color: LaconicTheme.silverGray,
                  fontSize: 14,
                ),
              ),
              if (_workoutStartTime != null)
                Text(
                  'Time: ${DateTime.now().difference(_workoutStartTime!).inMinutes}m',
                  style: const TextStyle(
                    color: LaconicTheme.silverGray,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'REST TIME',
            style: TextStyle(
              color: LaconicTheme.silverGray,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _restTimerAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _restTimerAnimation.value,
                      strokeWidth: 8,
                      backgroundColor: LaconicTheme.darkGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        LaconicTheme.accentRed,
                      ),
                    ),
                  ),
                  Text(
                    '$_restSecondsRemaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.workoutPlan.allExercises.length,
      itemBuilder: (context, index) {
        final exercise = widget.workoutPlan.allExercises[index];
        final progress = _exerciseProgress[exercise.id]!;
        final isCompleted = _exerciseCompleted[exercise.id]!;
        final isCurrent = index == _currentExerciseIndex;

        return ExerciseProgressCard(
          exercise: exercise,
          progress: progress,
          setPerformances: _setPerformances[exercise.id]!,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          onSetCompleted: (setNumber, reps, weight, rpe) {
            developer.log(
              'Exercise ${exercise.id} updated: set $setNumber, reps $reps, weight $weight, rpe $rpe',
              name: 'WorkoutProgress',
            );
            _updateExerciseProgress(
              exercise.id,
              setNumber: setNumber,
              reps: reps,
              weight: weight,
              rpe: rpe,
              completed: true,
            );

            // Start rest timer if not the last set
            if (setNumber < exercise.sets) {
              _startRestTimer(exercise.restSeconds);
            }
          },
          onExerciseSubstituted: (substitutionId) {
            // Handle exercise substitution
            _speak('Exercise substituted');
          },
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_speechEnabled)
            FloatingActionButton(
              onPressed: _listenForCommands,
              backgroundColor: LaconicTheme.ironGray,
              child: const Icon(Icons.mic, color: Colors.white),
            ),
          FloatingActionButton(
            onPressed: () {
              // Quick rest button
              _startRestTimer(60);
            },
            backgroundColor: LaconicTheme.ironGray,
            child: const Icon(Icons.timer, color: Colors.white),
          ),
          FloatingActionButton(
            onPressed: () {
              // Skip exercise
              if (_currentExerciseIndex <
                  widget.workoutPlan.allExercises.length - 1) {
                _currentExerciseIndex++;
                _scrollToNextExercise();
              }
            },
            backgroundColor: LaconicTheme.ironGray,
            child: const Icon(Icons.skip_next, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class WorkoutCompletionDialog extends StatelessWidget {
  final CompletedWorkout completedWorkout;

  const WorkoutCompletionDialog({super.key, required this.completedWorkout});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: LaconicTheme.darkGray,
      title: const Text(
        'Workout Complete!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Great job! You completed ${completedWorkout.exercises.length} exercises.',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Duration: ${completedWorkout.totalDurationMinutes} minutes',
            style: const TextStyle(color: LaconicTheme.silverGray),
          ),
          Text(
            'Total Sets: ${completedWorkout.totalSets}',
            style: const TextStyle(color: LaconicTheme.silverGray),
          ),
          Text(
            'Total Volume: ${completedWorkout.totalVolume.toStringAsFixed(0)} kg',
            style: const TextStyle(color: LaconicTheme.silverGray),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Done',
            style: TextStyle(color: LaconicTheme.accentRed, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
