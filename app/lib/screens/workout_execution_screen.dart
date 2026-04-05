import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import '../theme.dart';
import '../models/workout_tracking.dart';
import '../services/workout_plan_storage_service.dart';
import '../widgets/set_tracker_widget.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final DailyWorkoutPlan workout;

  const WorkoutExecutionScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen>
    with TickerProviderStateMixin {
  final WorkoutPlanStorageService _planService = WorkoutPlanStorageService();
  
  int _currentExerciseIndex = 0;
  final Map<String, List<SetPerformance>> _exerciseSets = {};
  bool _isWorkoutComplete = false;
  bool _isResting = false;
  int _restSecondsRemaining = 0;
  Timer? _restTimer;
  
  late AnimationController _progressController;
  late AnimationController _slideController;
  
  Stopwatch _workoutStopwatch = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController.forward();
    
    // Start workout session
    _planService.startWorkoutSession(widget.workout, 80); // Default readiness
  }

  @override
  void dispose() {
    _workoutStopwatch.stop();
    _restTimer?.cancel();
    _progressController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  PlannedExercise get _currentExercise => widget.workout.exercises[_currentExerciseIndex];
  
  bool get _isLastExercise => _currentExerciseIndex >= widget.workout.exercises.length - 1;
  
  double get _workoutProgress => (_currentExerciseIndex + (_isResting ? 0 : 1)) / widget.workout.exercises.length;

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isWorkoutComplete) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            if (_isResting) _buildRestTimer(),
            Expanded(child: _buildExerciseView()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.workout.workoutType.toUpperCase(),
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
            onPressed: () => _showCancelDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXERCISE ${_currentExerciseIndex + 1}/${widget.workout.exercises.length}',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _workoutProgress,
            backgroundColor: Colors.grey.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(LaconicTheme.spartanBronze),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
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

  Widget _buildExerciseView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Exercise name and video
          Container(
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  _currentExercise.exercise.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentExercise.exercise.targetMetaphor,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                // YouTube thumbnail
                if (_currentExercise.exercise.youtubeId.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _launchYouTube(_currentExercise.exercise.youtubeId),
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://img.youtube.com/vi/${_currentExercise.exercise.youtubeId}/hqdefault.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Exercise details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetail('SETS', '${_currentExercise.sets}'),
                    _buildDetail('REPS', _currentExercise.targetReps > 0 ? '${_currentExercise.targetReps}' : 'MAX'),
                    _buildDetail('REST', '${_currentExercise.restSeconds}s'),
                    _buildDetail('RPE', '${_currentExercise.targetRpe}'),
                  ],
                ),
                if (_currentExercise.exercise.primaryMuscles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _currentExercise.exercise.primaryMuscles
                        .map((muscle) => Chip(
                              label: Text(
                                muscle.toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: LaconicTheme.spartanBronze.withValues(alpha: 0.2),
                              labelStyle: const TextStyle(color: LaconicTheme.spartanBronze),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Set tracking
          SetTrackerWidget(
            exercise: _currentExercise,
            onSetsUpdated: (sets) {
              _exerciseSets[_currentExercise.exercise.name] = sets;
            },
            isResting: _isResting,
          ),
          
          const SizedBox(height: 32),
          
          // Navigation buttons
          if (!_isResting) ...[
            Row(
              children: [
                if (_currentExerciseIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousExercise,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text(
                        'PREVIOUS',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                if (_currentExerciseIndex > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canCompleteExercise() ? _completeExercise : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LaconicTheme.spartanBronze,
                      minimumSize: const Size(0, 50),
                    ),
                    child: Text(
                      _isLastExercise ? 'FINISH' : 'NEXT EXERCISE',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.7),
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: LaconicTheme.spartanBronze,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 100,
              color: LaconicTheme.spartanBronze,
            ),
            const SizedBox(height: 24),
            const Text(
              'WORKOUT COMPLETE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Duration: ${_formatTime(_workoutStopwatch.elapsed.inSeconds)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LaconicTheme.spartanBronze,
                minimumSize: const Size(200, 60),
              ),
              child: const Text(
                'CONTINUE',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canCompleteExercise() {
    final sets = _exerciseSets[_currentExercise.exercise.name] ?? [];
    if (sets.isEmpty) return false;
    return sets.where((set) => set.completed).length == _currentExercise.sets;
  }

  void _completeExercise() async {
    // Start rest if not last exercise
    if (!_isLastExercise) {
      setState(() {
        _isResting = true;
        _restSecondsRemaining = _currentExercise.restSeconds;
      });
      
      _startRestTimer();
    } else {
      // Finish workout
      await _finishWorkout();
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    Vibration.vibrate(duration: 100);
    
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restSecondsRemaining--;
        if (_restSecondsRemaining <= 0) {
          _isResting = false;
          timer.cancel();
          _nextExercise();
          Vibration.vibrate(duration: 200);
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
    });
    _nextExercise();
  }

  void _nextExercise() {
    if (!_isLastExercise) {
      setState(() {
        _currentExerciseIndex++;
      });
      _slideController.forward();
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });
    }
  }

  Future<void> _finishWorkout() async {
    final completedWorkout = await _planService.completeWorkoutSession();
    setState(() {
      _isWorkoutComplete = true;
    });
    
    if (completedWorkout != null) {
      // Show completion animation
      _progressController.forward();
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.deepBlack,
        title: const Text(
          "ABANDON WORKOUT?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "All progress will be lost. Are you sure?",
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
              _planService.cancelWorkoutSession();
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
            },
            child: const Text("ABANDON", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchYouTube(String videoId) async {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
