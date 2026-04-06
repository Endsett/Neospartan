import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/workout_tracking.dart';
import '../models/workout_protocol.dart';
import '../services/ai_plan_service.dart';
import '../services/agoge_service.dart';
import '../services/supabase_database_service.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../models/user_profile.dart';
import 'pre_battle_primer_screen.dart';
import 'workout_session_screen.dart';
import 'package:provider/provider.dart';
import '../widgets/weekly_calendar.dart';

/// Weekly Schedule Screen - Shows workout history and allows scheduling
class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  // final _firebase = FirebaseSyncService(); // Removed
  final SupabaseDatabaseService _database = SupabaseDatabaseService();
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());
  List<CalendarDay> _weekDays = [];
  List<CompletedWorkout> _workouts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeekData();
  }

  static DateTime _getWeekStart(DateTime date) {
    // Get Monday of the week
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Future<void> _loadWeekData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await _database.getWorkoutSessions(
        startDate: _currentWeekStart,
        endDate: _currentWeekStart.add(const Duration(days: 6)),
        limit: 100,
      );
      final workouts = sessions.map((session) {
        final start =
            DateTime.tryParse(session['start_time']?.toString() ?? '') ??
            DateTime.tryParse(session['date']?.toString() ?? '') ??
            DateTime.now();
        final end =
            DateTime.tryParse(session['end_time']?.toString() ?? '') ?? start;

        return CompletedWorkout(
          id: session['id']?.toString() ?? '',
          protocolTitle: session['workout_type']?.toString() ?? 'Workout',
          exercises: const [],
          startTime: start,
          endTime: end,
          totalDurationMinutes: end.difference(start).inMinutes.clamp(0, 600),
          readinessScoreAtStart: 70,
        );
      }).toList();

      final calendarEntries = await _database.getWorkoutCalendarForWeek(
        _currentWeekStart,
      );
      final scheduled = <String, dynamic>{
        for (final row in calendarEntries) row['date']?.toString() ?? '': row,
      };

      // Build calendar days
      final days = _buildCalendarDays(workouts, scheduled);

      final completedCount = days
          .where(
            (d) =>
                d.status == DayStatus.completed ||
                d.status == DayStatus.partial,
          )
          .length;
      final plannedCount = days
          .where((d) => d.status != DayStatus.empty)
          .length;
      final totalVolume = days.fold<double>(
        0,
        (sum, d) => sum + (d.totalVolume ?? 0),
      );

      try {
        await _database.saveWeeklyProgress({
          'week_starting': _currentWeekStart.toIso8601String(),
          'workouts_completed': completedCount,
          'total_planned_workouts': plannedCount,
          'average_rpe': 0.0,
          'total_volume': totalVolume,
          'average_readiness': 70,
        });
      } catch (_) {}

      setState(() {
        _workouts = workouts;
        _weekDays = days;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CalendarDay> _buildCalendarDays(
    List<CompletedWorkout> workouts,
    Map<String, dynamic> scheduled,
  ) {
    final days = <CalendarDay>[];

    for (int i = 0; i < 7; i++) {
      final date = _currentWeekStart.add(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Check for completed workout
      final workout = workouts.firstWhere(
        (w) => _isSameDay(w.startTime, date),
        orElse: () => CompletedWorkout(
          id: '',
          protocolTitle: '',
          exercises: [],
          startTime: date,
          endTime: date,
          totalDurationMinutes: 0,
          readinessScoreAtStart: 0,
        ),
      );

      // Check for scheduled workout
      final scheduledData = scheduled[dateKey];

      DayStatus status;
      String? workoutName;
      Duration? duration;
      double? volume;

      if (workout.id.isNotEmpty) {
        // Completed workout
        status = workout.exercises.every((e) => e.completionRate >= 1.0)
            ? DayStatus.completed
            : DayStatus.partial;
        workoutName = workout.protocolTitle;
        duration = Duration(minutes: workout.totalDurationMinutes);
        volume = workout.exercises.fold<double>(0, (sum, e) {
          return sum +
              e.sets.fold<double>(0, (setSum, s) {
                return setSum + ((s.loadUsed ?? 0) * (s.repsPerformed ?? 0));
              });
        });
      } else if (scheduledData?['is_rest'] == true) {
        status = DayStatus.rest;
      } else if (scheduledData != null) {
        // Scheduled for future
        if (date.isAfter(DateTime.now()) || _isSameDay(date, DateTime.now())) {
          status = DayStatus.scheduled;
          workoutName = scheduledData['workout_name'];
        } else {
          // Missed (scheduled but not completed and date passed)
          status = DayStatus.missed;
          workoutName = scheduledData['workout_name'];
        }
      } else {
        status = DayStatus.empty;
      }

      days.add(
        CalendarDay(
          date: date,
          status: status,
          workoutName: workoutName,
          duration: duration,
          totalVolume: volume,
        ),
      );
    }

    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadWeekData();
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _loadWeekData();
  }

  void _onDayTap(CalendarDay day) {
    if (day.status == DayStatus.completed || day.status == DayStatus.partial) {
      _showWorkoutDetails(day);
    } else if (day.status == DayStatus.scheduled) {
      _showScheduledWorkoutOptions(day);
    } else if (day.date.isAfter(DateTime.now()) ||
        _isSameDay(day.date, DateTime.now())) {
      _showScheduleOptions(day);
    }
  }

  void _onDayLongPress(CalendarDay day) {
    _showDayContextMenu(day);
  }

  void _showWorkoutDetails(CalendarDay day) {
    final workout = _workouts.firstWhere(
      (w) => _isSameDay(w.startTime, day.date),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: LaconicTheme.deepBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day.workoutName ?? 'WORKOUT',
                  style: const TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${day.date.day} ${_getMonthName(day.date.month)}, ${day.date.year}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildDetailChip(
                  Icons.timer,
                  '${day.duration?.inMinutes ?? 0} min',
                ),
                const SizedBox(width: 12),
                _buildDetailChip(
                  Icons.scale,
                  '${day.totalVolume?.toStringAsFixed(0) ?? 0} kg',
                ),
                const SizedBox(width: 12),
                _buildDetailChip(
                  Icons.fitness_center,
                  '${workout.exercises.length} exercises',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'EXERCISES',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            ...workout.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      exercise.completionRate >= 1.0
                          ? Icons.check_circle
                          : Icons.timelapse,
                      color: exercise.completionRate >= 1.0
                          ? Colors.green
                          : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      exercise.exerciseName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      '${exercise.sets.where((s) => s.completed).length}/${exercise.targetSets} sets',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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

  void _showScheduledWorkoutOptions(CalendarDay day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LaconicTheme.deepBlack,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.workoutName ?? 'SCHEDULED WORKOUT',
              style: const TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (_isSameDay(day.date, DateTime.now()))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _startScheduledWorkout(day);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START WORKOUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LaconicTheme.spartanBronze,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _rescheduleWorkout(day);
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('RESCHEDULE'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelScheduledWorkout(day);
                },
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleOptions(CalendarDay day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LaconicTheme.deepBlack,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SCHEDULE FOR ${_getDayName(day.date.weekday)}',
              style: const TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _scheduleWorkout(day);
                },
                icon: const Icon(Icons.fitness_center),
                label: const Text('SCHEDULE WORKOUT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LaconicTheme.spartanBronze,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _markRestDay(day);
                },
                icon: const Icon(Icons.bedtime),
                label: const Text('MARK REST DAY'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayContextMenu(CalendarDay day) {
    _showScheduleOptions(day);
  }

  void _startScheduledWorkout(CalendarDay day) {
    final protocol = _resolveScheduledProtocol(day.workoutName);
    final readinessScore = _inferReadinessFromProtocol(protocol);
    final workoutProvider = context.read<WorkoutProvider>();

    // Get user profile from auth provider
    final authProvider = context.read<AuthProvider>();
    final userProfile = authProvider.userProfile;

    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreBattlePrimerScreen(
          userProfile: userProfile,
          readinessScore: readinessScore,
          onWorkoutLoaded: (loadedProtocol, loadedReadinessScore) {
            workoutProvider.startWorkout(loadedProtocol, loadedReadinessScore);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutSessionScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  WorkoutProtocol _resolveScheduledProtocol(String? workoutName) {
    final agogeService = AgogeService();
    final normalized = (workoutName ?? '').trim().toLowerCase();

    if (normalized.contains('spartan charge')) {
      return agogeService.generateProtocol(90);
    }
    if (normalized.contains('phalanx')) {
      return agogeService.generateProtocol(70);
    }
    if (normalized.contains('garrison')) {
      return agogeService.generateProtocol(50);
    }
    if (normalized.contains('stoic restoration') ||
        normalized.contains('recovery')) {
      return agogeService.generateProtocol(20);
    }

    final fallback = agogeService.generateProtocol(70);
    if ((workoutName ?? '').trim().isEmpty) {
      return fallback;
    }

    return WorkoutProtocol(
      title: workoutName!.trim(),
      subtitle: fallback.subtitle,
      tier: fallback.tier,
      entries: fallback.entries,
      estimatedDurationMinutes: fallback.estimatedDurationMinutes,
      mindsetPrompt: fallback.mindsetPrompt,
    );
  }

  int _inferReadinessFromProtocol(WorkoutProtocol protocol) {
    switch (protocol.tier) {
      case ProtocolTier.elite:
        return 90;
      case ProtocolTier.ready:
        return 75;
      case ProtocolTier.fatigued:
        return 50;
      case ProtocolTier.recovery:
        return 30;
    }
  }

  void _scheduleWorkout(CalendarDay day) {
    final controller = TextEditingController(
      text: day.workoutName ?? 'Training Session',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Workout'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Workout name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                await _database.saveWorkoutCalendarEntry(
                  date: day.date,
                  workoutName: controller.text.trim().isEmpty
                      ? 'Training Session'
                      : controller.text.trim(),
                  isRestDay: false,
                );
                if (!mounted) return;
                navigator.pop();
                _loadWeekData();
              } catch (e) {
                if (!mounted) return;
                _showOperationError('Could not schedule workout: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _rescheduleWorkout(CalendarDay day) {
    showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: day.date,
    ).then((newDate) async {
      if (newDate == null) return;

      try {
        await _database.deleteWorkoutCalendarEntry(day.date);
        await _database.saveWorkoutCalendarEntry(
          date: newDate,
          workoutName: day.workoutName ?? 'Training Session',
          isRestDay: false,
        );
        if (!mounted) return;
        _currentWeekStart = _getWeekStart(newDate);
        _loadWeekData();
      } catch (e) {
        if (!mounted) return;
        _showOperationError('Could not reschedule workout: $e');
      }
    });
  }

  void _cancelScheduledWorkout(CalendarDay day) {
    _database
        .deleteWorkoutCalendarEntry(day.date)
        .then((_) => _loadWeekData())
        .catchError((e) => _showOperationError('Could not cancel workout: $e'));
  }

  void _markRestDay(CalendarDay day) {
    _database
        .saveWorkoutCalendarEntry(date: day.date, isRestDay: true)
        .then((_) => _loadWeekData())
        .catchError((e) => _showOperationError('Could not mark rest day: $e'));
  }

  void _showOperationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LaconicTheme.spartanBronze),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
  }

  void _showCustomPlanDialog() {
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.userProfile;

    if (profile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.ironGray,
        title: const Text(
          'Generate Custom Plan',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create a personalized 4-week training plan based on your goals and experience level.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<TrainingGoal>(
              initialValue: TrainingGoal.generalCombat,
              decoration: const InputDecoration(
                labelText: 'Training Goal',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              dropdownColor: LaconicTheme.deepBlack,
              items: TrainingGoal.values.map((goal) {
                return DropdownMenuItem(
                  value: goal,
                  child: Text(
                    goal.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExperienceLevel>(
              initialValue: profile.experienceLevel ?? ExperienceLevel.novice,
              decoration: const InputDecoration(
                labelText: 'Experience Level',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              dropdownColor: LaconicTheme.deepBlack,
              items: ExperienceLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(
                    level.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: 4,
              decoration: const InputDecoration(
                labelText: 'Training Days per Week',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              dropdownColor: LaconicTheme.deepBlack,
              items: [3, 4, 5, 6].map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text(
                    '$days days',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _generateCustomPlan(
                goal: TrainingGoal.generalCombat,
                experienceLevel:
                    profile.experienceLevel ?? ExperienceLevel.novice,
                trainingDaysPerWeek: 4,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LaconicTheme.spartanBronze,
            ),
            child: const Text(
              'GENERATE',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateCustomPlan({
    required TrainingGoal goal,
    required ExperienceLevel experienceLevel,
    required int trainingDaysPerWeek,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: LaconicTheme.ironGray,
        content: Row(
          children: [
            CircularProgressIndicator(color: LaconicTheme.spartanBronze),
            SizedBox(width: 20),
            Text(
              'Generating your custom plan...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      final aiService = AIPlanService();

      // Get user profile for AI plan generation
      final authProvider = context.read<AuthProvider>();
      final profile = authProvider.userProfile;

      if (profile == null) {
        throw Exception('User profile not found');
      }

      // Generate AI-powered training plan
      final weeklyPlan = await aiService.generateInitialTrainingPlan(profile);

      if (!mounted) return;

      Navigator.of(context).pop(); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: LaconicTheme.ironGray,
          title: const Text(
            'AI Plan Generated!',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Your personalized ${profile.trainingGoalText} plan is ready!\n'
            'Duration: ${weeklyPlan?.dailyWorkouts.length ?? 0} days\n'
            'Focus: ${weeklyPlan?.intensityRecommendation ?? 'N/A'}',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: LaconicTheme.spartanBronze,
              ),
              child: const Text(
                'AWESOME!',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWeekData,
          color: LaconicTheme.spartanBronze,
          backgroundColor: LaconicTheme.ironGray,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WEEKLY SCHEDULE',
                          style: TextStyle(
                            color: LaconicTheme.spartanBronze,
                            fontSize: 12,
                            letterSpacing: 3.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentWeekStart.day} ${_getMonthName(_currentWeekStart.month)} - ${_currentWeekStart.add(const Duration(days: 6)).day} ${_getMonthName(_currentWeekStart.add(const Duration(days: 6)).month)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          onPressed: _previousWeek,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          onPressed: _nextWeek,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Error state
                if (_error != null)
                  Container(
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
                          'Failed to load schedule: $_error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadWeekData,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),

                // Calendar
                WeeklyCalendar(
                  days: _weekDays,
                  onDayTap: _onDayTap,
                  onDayLongPress: _onDayLongPress,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Weekly stats
                if (!_isLoading && _error == null)
                  WeeklyStatsSummary(
                    workoutsCompleted: _weekDays
                        .where((d) => d.status == DayStatus.completed)
                        .length,
                    workoutsScheduled: _weekDays
                        .where(
                          (d) =>
                              d.status == DayStatus.completed ||
                              d.status == DayStatus.scheduled ||
                              d.status == DayStatus.partial,
                        )
                        .length,
                    totalVolume: _weekDays.fold<double>(
                      0,
                      (sum, d) => sum + (d.totalVolume ?? 0),
                    ),
                    currentStreak: _calculateStreak(),
                  ),
                const SizedBox(height: 24),

                // Legend
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LaconicTheme.ironGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LEGEND',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildLegendItem(Colors.green, 'Completed'),
                          _buildLegendItem(Colors.orange, 'Partial'),
                          _buildLegendItem(
                            LaconicTheme.spartanBronze,
                            'Scheduled',
                          ),
                          _buildLegendItem(Colors.blue, 'Rest'),
                          _buildLegendItem(Colors.red, 'Missed'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: LaconicTheme.ironGray.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOW TO USE',
                        style: TextStyle(
                          color: LaconicTheme.spartanBronze,
                          fontSize: 12,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '• Tap any day to schedule or view details\n'
                        '• Long press to mark as rest day\n'
                        '• Swipe left/right to change weeks\n'
                        '• Green = Completed, Orange = Partial, Bronze = Scheduled',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomPlanDialog,
        backgroundColor: LaconicTheme.spartanBronze,
        icon: const Icon(Icons.fitness_center),
        label: const Text('Generate Plan'),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  int _calculateStreak() {
    // Simplified streak calculation
    int streak = 0;
    for (final day in _weekDays.reversed) {
      if (day.status == DayStatus.completed) {
        streak++;
      } else if (day.status != DayStatus.rest &&
          day.date.isBefore(DateTime.now())) {
        break;
      }
    }
    return streak;
  }
}

// Extension methods for FirebaseSyncService
extension WeeklyScheduleExtension on Object {
  /* FirebaseSyncService removed */
  Future<Map<String, dynamic>> getScheduledWorkoutsForWeek(
    DateTime weekStart,
  ) async {
    // This would be implemented in the actual FirebaseSyncService
    // For now, return empty map
    return {};
  }
}
