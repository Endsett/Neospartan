import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/workout_plan_storage_service.dart';
import '../models/exercise.dart';
import '../widgets/exercise_card.dart';
import 'workout_execution_screen.dart';

class StartWorkoutScreen extends StatefulWidget {
  const StartWorkoutScreen({super.key});

  @override
  State<StartWorkoutScreen> createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends State<StartWorkoutScreen> {
  final WorkoutPlanStorageService _planService = WorkoutPlanStorageService();
  DailyWorkoutPlan? _todaysWorkout;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodaysWorkout();
  }

  Future<void> _loadTodaysWorkout() async {
    final workout = await _planService.getTodaysWorkout();
    setState(() {
      _todaysWorkout = workout;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'TODAY\'S WORKOUT',
          style: TextStyle(
            color: LaconicTheme.spartanBronze,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(LaconicTheme.spartanBronze),
              ),
            )
          : _todaysWorkout == null || _todaysWorkout!.isRestDay
              ? _buildRestDayView()
              : _buildWorkoutView(),
    );
  }

  Widget _buildRestDayView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.self_improvement,
            size: 80,
            color: LaconicTheme.spartanBronze,
          ),
          const SizedBox(height: 24),
          const Text(
            'REST DAY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _todaysWorkout?.mindsetPrompt ?? 'Recovery is essential for growth.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Use this day to focus on mobility, nutrition, and mental preparation. Return tomorrow ready for battle.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutView() {
    final workout = _todaysWorkout!;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LaconicTheme.spartanBronze.withValues(alpha: 0.1),
              border: Border.all(color: LaconicTheme.spartanBronze.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutType.toUpperCase(),
                  style: const TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  workout.focus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.estimatedDurationMinutes} min',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.fitness_center,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.exercises.length} exercises',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Mindset Prompt
          if (workout.mindsetPrompt.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MINDSET',
                    style: TextStyle(
                      color: LaconicTheme.spartanBronze,
                      fontSize: 12,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workout.mindsetPrompt,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Exercise List
          const Text(
            'EXERCISES',
            style: TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 16,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: workout.exercises.length,
              itemBuilder: (context, index) {
                final plannedExercise = workout.exercises[index];
                return ExerciseCard(
                  exercise: plannedExercise.exercise,
                  sets: plannedExercise.sets,
                  reps: plannedExercise.targetReps,
                  rest: plannedExercise.restSeconds,
                  onTap: () => _showExerciseDetails(plannedExercise.exercise),
                );
              },
            ),
          ),
          
          // Start Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => _startWorkout(workout),
              style: ElevatedButton.styleFrom(
                backgroundColor: LaconicTheme.spartanBronze,
                minimumSize: const Size(double.infinity, 60),
                shape: const BeveledRectangleBorder(),
              ),
              child: const Text(
                'START WORKOUT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetails(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.deepBlack,
        title: Text(
          exercise.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // YouTube thumbnail
              if (exercise.youtubeId.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _launchYouTube(exercise.youtubeId),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://img.youtube.com/vi/${exercise.youtubeId}/hqdefault.jpg',
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
                const SizedBox(height: 16),
              ],
              
              // Instructions
              const Text(
                'INSTRUCTIONS',
                style: TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.instructions,
                style: const TextStyle(color: Colors.white),
              ),
              
              const SizedBox(height: 16),
              
              // Target Metaphor
              if (exercise.targetMetaphor.isNotEmpty) ...[
                const Text(
                  'TARGET METAPHOR',
                  style: TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 12,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.targetMetaphor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Primary Muscles
              if (exercise.primaryMuscles.isNotEmpty) ...[
                const Text(
                  'PRIMARY MUSCLES',
                  style: TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 12,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: exercise.primaryMuscles
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: LaconicTheme.spartanBronze),
            ),
          ),
          if (exercise.youtubeId.isNotEmpty)
            TextButton(
              onPressed: () => _launchYouTube(exercise.youtubeId),
              child: const Text(
                'WATCH VIDEO',
                style: TextStyle(color: LaconicTheme.spartanBronze),
              ),
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

  void _startWorkout(DailyWorkoutPlan workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExecutionScreen(workout: workout),
      ),
    );
  }
}
