import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/workout_tracking.dart';
import '../services/workout_plan_storage_service.dart';

class SetTrackerWidget extends StatefulWidget {
  final PlannedExercise exercise;
  final Function(List<SetPerformance>) onSetsUpdated;
  final bool isResting;

  const SetTrackerWidget({
    super.key,
    required this.exercise,
    required this.onSetsUpdated,
    this.isResting = false,
  });

  @override
  State<SetTrackerWidget> createState() => _SetTrackerWidgetState();
}

class _SetTrackerWidgetState extends State<SetTrackerWidget> {
  late List<SetPerformance> _sets;
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _rpeControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeSets();
  }

  void _initializeSets() {
    _sets = List.generate(
      widget.exercise.sets,
      (index) => SetPerformance(
        setNumber: index + 1,
        repsPerformed: widget.exercise.targetReps,
        actualRPE: widget.exercise.targetRpe,
        loadUsed: 0.0,
        completed: false,
      ),
    );

    // Initialize controllers
    for (int i = 0; i < _sets.length; i++) {
      _repsControllers[i] = TextEditingController(
        text: widget.exercise.targetReps > 0
            ? widget.exercise.targetReps.toString()
            : '',
      );
      _weightControllers[i] = TextEditingController(text: '0');
      _rpeControllers[i] = TextEditingController(
        text: widget.exercise.targetRpe.toString(),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _repsControllers.values) {
      controller.dispose();
    }
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    for (final controller in _rpeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SET TRACKING',
          style: TextStyle(
            color: LaconicTheme.spartanBronze,
            fontSize: 16,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_sets.length, (index) => _buildSetCard(index)),
      ],
    );
  }

  Widget _buildSetCard(int index) {
    final set = _sets[index];
    final isCompleted = set.completed;
    final isCurrent =
        !isCompleted &&
        !_sets.any((s) => s.completed && s.setNumber > set.setNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCompleted
              ? LaconicTheme.spartanBronze
              : isCurrent
              ? Colors.white
              : Colors.grey.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: isCompleted
            ? LaconicTheme.spartanBronze.withValues(alpha: 0.1)
            : isCurrent
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Checkbox
              Checkbox(
                value: isCompleted,
                onChanged: widget.isResting
                    ? null
                    : (value) => _toggleSetComplete(index),
                activeColor: LaconicTheme.spartanBronze,
              ),

              // Set number
              Text(
                'SET ${set.setNumber}',
                style: TextStyle(
                  color: isCompleted
                      ? LaconicTheme.spartanBronze
                      : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // Status indicator
              if (isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: LaconicTheme.spartanBronze,
                  size: 20,
                )
              else if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: LaconicTheme.spartanBronze,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Input fields
          Row(
            children: [
              // Reps
              Expanded(
                child: TextField(
                  controller: _repsControllers[index],
                  enabled: !widget.isResting,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'REPS',
                    labelStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: LaconicTheme.spartanBronze),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => _updateSetData(index),
                ),
              ),

              const SizedBox(width: 12),

              // Weight
              Expanded(
                child: TextField(
                  controller: _weightControllers[index],
                  enabled: !widget.isResting,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'WEIGHT (kg)',
                    labelStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: LaconicTheme.spartanBronze),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => _updateSetData(index),
                ),
              ),

              const SizedBox(width: 12),

              // RPE
              Expanded(
                child: TextField(
                  controller: _rpeControllers[index],
                  enabled: !widget.isResting,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'RPE',
                    labelStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: LaconicTheme.spartanBronze),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => _updateSetData(index),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleSetComplete(int index) {
    setState(() {
      _sets[index] = _sets[index].copyWith(completed: !_sets[index].completed);
    });
    widget.onSetsUpdated(_sets);
  }

  void _updateSetData(int index) {
    final reps = int.tryParse(_repsControllers[index]?.text ?? '');
    final weight = double.tryParse(_weightControllers[index]?.text ?? '');
    final rpe = double.tryParse(_rpeControllers[index]?.text ?? '');

    setState(() {
      _sets[index] = _sets[index].copyWith(
        repsPerformed: reps,
        loadUsed: weight,
        actualRPE: rpe,
      );
    });
    widget.onSetsUpdated(_sets);
  }
}

// Extension to help with copying SetPerformance
extension SetPerformanceCopy on SetPerformance {
  SetPerformance copyWith({
    int? setNumber,
    int? repsPerformed,
    double? actualRPE,
    double? loadUsed,
    bool? completed,
    String? notes,
  }) {
    return SetPerformance(
      setNumber: setNumber ?? this.setNumber,
      repsPerformed: repsPerformed ?? this.repsPerformed,
      actualRPE: actualRPE ?? this.actualRPE,
      loadUsed: loadUsed ?? this.loadUsed,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
    );
  }
}
