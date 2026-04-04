import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/workout_protocol.dart';
import '../models/workout_tracking.dart';
import '../services/firebase_sync_service.dart';
import '../providers/workout_provider.dart';
import '../widgets/weekly_calendar.dart';
import 'workout_session_screen.dart';

/// Weekly Schedule Screen - Shows workout history and allows scheduling
class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  final _firebase = FirebaseSyncService();
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());
  List<CalendarDay> _weekDays = [];
  List<CompletedWorkout> _workouts = [];
  Map<String, dynamic> _scheduledWorkouts = {};
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
      // Calculate week range
      final weekEnd = _currentWeekStart.add(const Duration(days: 6));
      
      // Load workouts for the week
      final workouts = await _firebase.getWorkoutsForDateRange(_currentWeekStart, weekEnd);
      
      // Load scheduled workouts
      final scheduled = await _firebase.getScheduledWorkoutsForWeek(_currentWeekStart);
      
      // Build calendar days
      final days = _buildCalendarDays(workouts, scheduled);

      setState(() {
        _workouts = workouts;
        _scheduledWorkouts = scheduled;
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
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
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
          return sum + e.sets.fold<double>(0, (setSum, s) {
            return setSum + ((s.loadUsed ?? 0) * (s.repsPerformed ?? 0));
          });
        });
      } else if (scheduledData != null) {
        // Scheduled for future
        if (date.isAfter(DateTime.now())) {
          status = DayStatus.scheduled;
          workoutName = scheduledData['workout_name'];
        } else {
          // Missed (scheduled but not completed and date passed)
          status = DayStatus.missed;
          workoutName = scheduledData['workout_name'];
        }
      } else if (scheduledData?['is_rest'] == true) {
        status = DayStatus.rest;
      } else {
        status = DayStatus.empty;
      }

      days.add(CalendarDay(
        date: date,
        status: status,
        workoutName: workoutName,
        duration: duration,
        totalVolume: volume,
      ));
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
    } else if (day.date.isAfter(DateTime.now()) || _isSameDay(day.date, DateTime.now())) {
      _showScheduleOptions(day);
    }
  }

  void _onDayLongPress(CalendarDay day) {
    _showDayContextMenu(day);
  }

  void _showWorkoutDetails(CalendarDay day) {
    final workout = _workouts.firstWhere((w) => _isSameDay(w.startTime, day.date));
    
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
                _buildDetailChip(Icons.timer, '${day.duration?.inMinutes ?? 0} min'),
                const SizedBox(width: 12),
                _buildDetailChip(Icons.scale, '${day.totalVolume?.toStringAsFixed(0) ?? 0} kg'),
                const SizedBox(width: 12),
                _buildDetailChip(Icons.fitness_center, '${workout.exercises.length} exercises'),
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
            ...workout.exercises.map((exercise) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    exercise.completionRate >= 1.0 ? Icons.check_circle : Icons.timelapse,
                    color: exercise.completionRate >= 1.0 ? Colors.green : Colors.orange,
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
            )),
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
                label: const Text('CANCEL', style: TextStyle(color: Colors.red)),
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
    // Implementation for long-press menu
  }

  void _startScheduledWorkout(CalendarDay day) {
    // Navigate to workout session
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    // Load the scheduled protocol and start
  }

  void _scheduleWorkout(CalendarDay day) {
    // Show workout selection dialog
  }

  void _rescheduleWorkout(CalendarDay day) {
    // Show date picker and reschedule
  }

  void _cancelScheduledWorkout(CalendarDay day) {
    // Remove from schedule
  }

  void _markRestDay(CalendarDay day) {
    // Mark as rest day
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
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
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
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: _previousWeek,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
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
                    workoutsCompleted: _weekDays.where((d) => d.status == DayStatus.completed).length,
                    workoutsScheduled: _weekDays.where((d) => 
                      d.status == DayStatus.completed || 
                      d.status == DayStatus.scheduled ||
                      d.status == DayStatus.partial
                    ).length,
                    totalVolume: _weekDays.fold<double>(0, (sum, d) => sum + (d.totalVolume ?? 0)),
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
                          _buildLegendItem(LaconicTheme.spartanBronze, 'Scheduled'),
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
                    border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.3)),
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
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  int _calculateStreak() {
    // Simplified streak calculation
    int streak = 0;
    for (final day in _weekDays.reversed) {
      if (day.status == DayStatus.completed) {
        streak++;
      } else if (day.status != DayStatus.rest && day.date.isBefore(DateTime.now())) {
        break;
      }
    }
    return streak;
  }
}

// Extension methods for FirebaseSyncService
extension WeeklyScheduleExtension on FirebaseSyncService {
  Future<Map<String, dynamic>> getScheduledWorkoutsForWeek(DateTime weekStart) async {
    // This would be implemented in the actual FirebaseSyncService
    // For now, return empty map
    return {};
  }
}
