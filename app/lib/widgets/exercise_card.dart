import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/exercise.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int sets;
  final int reps;
  final int rest;
  final VoidCallback? onTap;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.rest,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Exercise icon/category indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: _getCategoryColor(),
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // Exercise details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.targetMetaphor,
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMetric('SETS', '$sets'),
                          const SizedBox(width: 16),
                          _buildMetric('REPS', reps > 0 ? '$reps' : 'MAX'),
                          const SizedBox(width: 16),
                          _buildMetric('REST', '${rest}s'),
                        ],
                      ),
                    ],
                  ),
                ),

                // YouTube indicator
                if (exercise.youtubeId.isNotEmpty) ...[
                  const Icon(
                    Icons.play_circle_outline,
                    color: LaconicTheme.spartanBronze,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                ],

                // Arrow
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.7),
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: LaconicTheme.spartanBronze,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return Colors.red;
      case ExerciseCategory.plyometric:
        return Colors.orange;
      case ExerciseCategory.combat:
        return LaconicTheme.spartanBronze;
      case ExerciseCategory.mobility:
        return Colors.blue;
      case ExerciseCategory.isometric:
        return Colors.purple;
      case ExerciseCategory.sprint:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon() {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return Icons.fitness_center;
      case ExerciseCategory.plyometric:
        return Icons.flash_on;
      case ExerciseCategory.combat:
        return Icons.sports_martial_arts;
      case ExerciseCategory.mobility:
        return Icons.accessibility_new;
      case ExerciseCategory.isometric:
        return Icons.pause_circle_filled;
      case ExerciseCategory.sprint:
        return Icons.directions_run;
    }
  }
}
