import 'package:flutter/material.dart';
import '../theme.dart';

/// Day status for calendar
enum DayStatus {
  completed, // Workout completed
  partial, // Partial completion
  scheduled, // Workout scheduled
  rest, // Rest day
  missed, // Scheduled but not done
  empty, // No activity
}

/// Calendar day data
class CalendarDay {
  final DateTime date;
  final DayStatus status;
  final String? workoutName;
  final String?
  workoutType; // e.g., 'strength', 'conditioning', 'power', 'recovery'
  final String? workoutId;
  final Duration? duration;
  final double? totalVolume;
  final bool isAiGenerated; // Whether this was auto-scheduled from a plan

  CalendarDay({
    required this.date,
    this.status = DayStatus.empty,
    this.workoutName,
    this.workoutType,
    this.workoutId,
    this.duration,
    this.totalVolume,
    this.isAiGenerated = false,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// Weekly calendar widget with day tiles
class WeeklyCalendar extends StatelessWidget {
  final List<CalendarDay> days;
  final Function(CalendarDay)? onDayTap;
  final Function(CalendarDay)? onDayLongPress;
  final bool isLoading;

  const WeeklyCalendar({
    super.key,
    required this.days,
    this.onDayTap,
    this.onDayLongPress,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        // Day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        // Day tiles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days
              .map((day) => Expanded(child: _buildDayTile(day)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            7,
            (_) => Expanded(
              child: Center(
                child: Container(
                  width: 30,
                  height: 12,
                  decoration: BoxDecoration(
                    color: LaconicTheme.ironGray.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            7,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 60,
                decoration: BoxDecoration(
                  color: LaconicTheme.ironGray.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayTile(CalendarDay day) {
    Color statusColor;
    IconData? statusIcon;
    IconData? workoutTypeIcon;
    Color? workoutTypeColor;

    // Determine workout type icon and color for scheduled workouts
    if (day.status == DayStatus.scheduled && day.workoutType != null) {
      switch (day.workoutType!.toLowerCase()) {
        case 'strength':
          workoutTypeIcon = Icons.fitness_center;
          workoutTypeColor = Colors.orange;
          break;
        case 'conditioning':
          workoutTypeIcon = Icons.directions_run;
          workoutTypeColor = Colors.blue;
          break;
        case 'power':
          workoutTypeIcon = Icons.bolt;
          workoutTypeColor = Colors.yellow;
          break;
        case 'recovery':
          workoutTypeIcon = Icons.spa;
          workoutTypeColor = Colors.green;
          break;
        default:
          workoutTypeIcon = Icons.fitness_center;
          workoutTypeColor = LaconicTheme.spartanBronze;
      }
    }

    switch (day.status) {
      case DayStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check;
        break;
      case DayStatus.partial:
        statusColor = Colors.orange;
        statusIcon = Icons.timelapse;
        break;
      case DayStatus.scheduled:
        statusColor = workoutTypeColor ?? LaconicTheme.spartanBronze;
        statusIcon = workoutTypeIcon ?? Icons.schedule;
        break;
      case DayStatus.rest:
        statusColor = Colors.blue;
        statusIcon = Icons.bedtime;
        break;
      case DayStatus.missed:
        statusColor = Colors.red;
        statusIcon = Icons.close;
        break;
      case DayStatus.empty:
        statusColor = LaconicTheme.ironGray;
        statusIcon = null;
        break;
    }

    return GestureDetector(
      onTap: onDayTap != null ? () => onDayTap!(day) : null,
      onLongPress: onDayLongPress != null ? () => onDayLongPress!(day) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: day.isToday
              ? LaconicTheme.spartanBronze.withValues(alpha: 0.15)
              : statusColor.withValues(
                  alpha: day.status == DayStatus.empty ? 0.05 : 0.1,
                ),
          border: Border.all(
            color: day.isToday
                ? LaconicTheme.spartanBronze
                : statusColor.withValues(
                    alpha: day.status == DayStatus.empty ? 0.2 : 0.5,
                  ),
            width: day.isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Date number
            Text(
              '${day.date.day}',
              style: TextStyle(
                color: day.isToday ? LaconicTheme.spartanBronze : Colors.white,
                fontSize: 18,
                fontWeight: day.isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            // Status / Workout type indicator
            if (statusIcon != null)
              Icon(statusIcon, color: statusColor, size: 16)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            // AI generated indicator
            if (day.isAiGenerated && day.status == DayStatus.scheduled)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.auto_awesome,
                  color: statusColor.withValues(alpha: 0.6),
                  size: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Weekly stats summary widget
class WeeklyStatsSummary extends StatelessWidget {
  final int workoutsCompleted;
  final int workoutsScheduled;
  final double totalVolume;
  final int currentStreak;

  const WeeklyStatsSummary({
    super.key,
    required this.workoutsCompleted,
    required this.workoutsScheduled,
    required this.totalVolume,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            'COMPLETED',
            '$workoutsCompleted/$workoutsScheduled',
            Icons.fitness_center,
          ),
          _buildDivider(),
          _buildStatColumn(
            'VOLUME',
            '${totalVolume.toStringAsFixed(0)} kg',
            Icons.scale,
          ),
          _buildDivider(),
          _buildStatColumn(
            'STREAK',
            '$currentStreak days',
            Icons.local_fire_department,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: LaconicTheme.spartanBronze, size: 20),
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
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: LaconicTheme.ironGray.withValues(alpha: 0.3),
    );
  }
}
