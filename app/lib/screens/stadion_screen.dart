import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/workout_plan_storage_service.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';

/// Stadion Screen - Professional Fitness Trainer Dashboard
/// Displays today's AI-generated workout with full exercise details
class StadionScreen extends StatefulWidget {
  const StadionScreen({super.key});

  @override
  State<StadionScreen> createState() => _StadionScreenState();
}

class _StadionScreenState extends State<StadionScreen> {
  final WorkoutPlanStorageService _planStorage = WorkoutPlanStorageService();
  DailyWorkoutPlan? _todayWorkout;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTodaysWorkout();
  }

  Future<void> _loadTodaysWorkout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _planStorage.initialize();
      final workout = await _planStorage.getTodaysWorkout();

      setState(() {
        _todayWorkout = workout;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load workout: $e';
        _isLoading = false;
      });
    }
  }

  void _startWorkout() {
    if (_todayWorkout == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExecutionScreen(
          workout: _todayWorkout!,
          onComplete: () {
            _loadTodaysWorkout();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.userProfile;

    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTodaysWorkout,
          color: LaconicTheme.spartanBronze,
          backgroundColor: LaconicTheme.ironGray,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(profile),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: LaconicTheme.spartanBronze,
                    ),
                  )
                else if (_error != null)
                  _buildErrorState()
                else if (_todayWorkout == null || _todayWorkout!.isRestDay)
                  _buildRestDayState()
                else
                  _buildWorkoutContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserProfile? profile) {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY\'S BATTLE',
                  style: TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: LaconicTheme.spartanBronze.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LaconicTheme.spartanBronze),
              ),
              child: Text(
                '${_todayWorkout?.exercises.length ?? 0} EXERCISES',
                style: TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (_todayWorkout != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LaconicTheme.ironGray.withOpacity(0.5),
                  LaconicTheme.ironGray.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: LaconicTheme.spartanBronze.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _todayWorkout!.workoutType.toUpperCase(),
                  style: TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _todayWorkout!.focus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.timer,
                      '${_todayWorkout!.estimatedDurationMinutes} min',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.fitness_center,
                      '${_calculateTotalSets()} sets',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.local_fire_department,
                      _calculateIntensity(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LaconicTheme.deepBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  int _calculateTotalSets() {
    if (_todayWorkout == null) return 0;
    return _todayWorkout!.exercises.fold(0, (sum, e) => sum + e.sets);
  }

  String _calculateIntensity() {
    if (_todayWorkout == null || _todayWorkout!.exercises.isEmpty)
      return 'Medium';
    final avgRpe =
        _todayWorkout!.exercises.fold<double>(
          0,
          (sum, e) => sum + e.targetRpe,
        ) /
        _todayWorkout!.exercises.length;
    if (avgRpe >= 8) return 'High';
    if (avgRpe >= 6) return 'Medium';
    return 'Low';
  }

  Widget _buildWorkoutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_todayWorkout?.mindsetPrompt != null &&
            _todayWorkout!.mindsetPrompt.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: LaconicTheme.spartanBronze.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: LaconicTheme.spartanBronze.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: LaconicTheme.spartanBronze,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MINDSET',
                      style: TextStyle(
                        color: LaconicTheme.spartanBronze,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _todayWorkout!.mindsetPrompt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        Text(
          'EXERCISES',
          style: TextStyle(
            color: LaconicTheme.spartanBronze,
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._todayWorkout!.exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return _buildExerciseCard(exercise, index + 1);
        }),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startWorkout,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text(
              'BEGIN WORKOUT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: LaconicTheme.spartanBronze,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(PlannedExercise exercise, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LaconicTheme.ironGray.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LaconicTheme.ironGray.withOpacity(0.5),
                  LaconicTheme.ironGray.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: LaconicTheme.spartanBronze.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: LaconicTheme.spartanBronze,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.exercise.targetMetaphor,
                        style: TextStyle(
                          color: LaconicTheme.spartanBronze.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      exercise.exercise.category,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    exercise.exercise.category.name.toUpperCase(),
                    style: TextStyle(
                      color: _getCategoryColor(exercise.exercise.category),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildDetailBox('SETS', '${exercise.sets}', Icons.repeat),
                    const SizedBox(width: 12),
                    _buildDetailBox(
                      'REPS',
                      '${exercise.targetReps}',
                      Icons.format_list_numbered,
                    ),
                    const SizedBox(width: 12),
                    _buildDetailBox(
                      'REST',
                      '${exercise.restSeconds}s',
                      Icons.timer,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDetailBox(
                      'TARGET RPE',
                      '${exercise.targetRpe.toStringAsFixed(1)}/10',
                      Icons.speed,
                    ),
                    const SizedBox(width: 12),
                    if (exercise.suggestedWeight != null)
                      _buildDetailBox(
                        'WEIGHT',
                        '${exercise.suggestedWeight}kg',
                        Icons.fitness_center,
                      ),
                  ],
                ),
                if (exercise.exercise.instructions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LaconicTheme.deepBlack.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.exercise.instructions,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                if (exercise.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Coach Notes: ${exercise.notes}',
                    style: TextStyle(
                      color: LaconicTheme.spartanBronze.withOpacity(0.8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: LaconicTheme.deepBlack.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: LaconicTheme.spartanBronze),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        return Colors.red;
      case ExerciseCategory.plyometric:
        return Colors.orange;
      case ExerciseCategory.combat:
        return LaconicTheme.spartanBronze;
      case ExerciseCategory.sprint:
        return Colors.blue;
      case ExerciseCategory.isometric:
        return Colors.purple;
      case ExerciseCategory.mobility:
        return Colors.green;
    }
  }

  Widget _buildRestDayState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.bedtime,
            size: 64,
            color: LaconicTheme.spartanBronze.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'RECOVERY DAY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rest is when you grow stronger.\nFocus on sleep, nutrition, and light movement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.self_improvement),
            label: const Text('RECOVERY ROUTINE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LaconicTheme.spartanBronze.withOpacity(0.3),
              foregroundColor: LaconicTheme.spartanBronze,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTodaysWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: LaconicTheme.spartanBronze,
            ),
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}

/// Workout Execution Screen with rest timer
class WorkoutExecutionScreen extends StatefulWidget {
  final DailyWorkoutPlan workout;
  final VoidCallback? onComplete;

  const WorkoutExecutionScreen({
    super.key,
    required this.workout,
    this.onComplete,
  });

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  int _restSecondsRemaining = 0;

  void _startRest(int seconds) {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
    });
    _runRestTimer();
  }

  void _runRestTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isResting) return false;
      setState(() {
        _restSecondsRemaining--;
        if (_restSecondsRemaining <= 0) _isResting = false;
      });
      return _restSecondsRemaining > 0 && _isResting;
    });
  }

  void _skipRest() => setState(() => _isResting = false);

  void _completeSet() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    setState(() {
      if (_currentSet >= exercise.sets) {
        if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
          _currentExerciseIndex++;
          _currentSet = 1;
        } else {
          _completeWorkout();
          return;
        }
      } else {
        _currentSet++;
      }
      _startRest(exercise.restSeconds);
    });
  }

  void _completeWorkout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.ironGray,
        title: const Text(
          'WORKOUT COMPLETE!',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: LaconicTheme.spartanBronze,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Victory belongs to the most persevering.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onComplete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LaconicTheme.spartanBronze,
            ),
            child: const Text('FINISH'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: LaconicTheme.deepBlack,
        elevation: 0,
        title: Text(
          '${_currentExerciseIndex + 1}/${widget.workout.exercises.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isResting
          ? _buildRestScreen()
          : _buildExerciseScreen(currentExercise),
    );
  }

  Widget _buildRestScreen() {
    final minutes = _restSecondsRemaining ~/ 60;
    final seconds = _restSecondsRemaining % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'REST',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            timeString,
            style: TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Breathe. Recover. Prepare.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _skipRest,
            icon: const Icon(Icons.skip_next),
            label: const Text('SKIP REST'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LaconicTheme.spartanBronze.withOpacity(0.3),
              foregroundColor: LaconicTheme.spartanBronze,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseScreen(PlannedExercise exercise) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LaconicTheme.spartanBronze.withOpacity(0.3),
                  LaconicTheme.spartanBronze.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set $_currentSet of ${exercise.sets}',
                  style: TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildTargetBox('TARGET REPS', '${exercise.targetReps}'),
              const SizedBox(width: 12),
              _buildTargetBox('TARGET RPE', '${exercise.targetRpe.toInt()}/10'),
              const SizedBox(width: 12),
              _buildTargetBox('REST', '${exercise.restSeconds}s'),
            ],
          ),
          const SizedBox(height: 24),
          if (exercise.exercise.instructions.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LaconicTheme.ironGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INSTRUCTIONS',
                    style: TextStyle(
                      color: LaconicTheme.spartanBronze,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise.exercise.instructions,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Text(
            'How many reps did you complete?',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i <= 5; i++)
                ElevatedButton(
                  onPressed: _completeSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: i == 2
                        ? LaconicTheme.spartanBronze
                        : LaconicTheme.ironGray,
                    foregroundColor: i == 2 ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text('${exercise.targetReps - 2 + i}'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _completeSet,
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'COMPLETE SET',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: LaconicTheme.spartanBronze,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LaconicTheme.ironGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LaconicTheme.spartanBronze.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
