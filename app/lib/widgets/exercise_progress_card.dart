import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/workout_exercise.dart';
import '../models/workout_tracking.dart';

/// Progress tracking data for an exercise
class ExerciseProgress {
  int completedSets;
  final int totalSets;
  int completedReps;
  final int totalReps;
  double completedWeight;
  final double totalWeight;

  ExerciseProgress({
    required this.totalSets,
    required this.totalReps,
    required this.totalWeight,
    this.completedSets = 0,
    this.completedReps = 0,
    this.completedWeight = 0.0,
  });

  int get targetSets => totalSets;
  int get targetReps => totalReps;
  double get targetWeight => totalWeight;
}

class ExerciseProgressCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final ExerciseProgress progress;
  final List<SetPerformance> setPerformances;
  final bool isCompleted;
  final bool isCurrent;
  final Function(int setNumber, int reps, double? weight, double? rpe)?
  onSetCompleted;
  final Function(String substitutionId)? onExerciseSubstituted;

  const ExerciseProgressCard({
    super.key,
    required this.exercise,
    required this.progress,
    required this.setPerformances,
    required this.isCompleted,
    required this.isCurrent,
    this.onSetCompleted,
    this.onExerciseSubstituted,
  });

  @override
  State<ExerciseProgressCard> createState() => _ExerciseProgressCardState();
}

class _ExerciseProgressCardState extends State<ExerciseProgressCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<TextEditingController> _repControllers = [];
  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _rpeControllers = [];

  bool _showSubstitutions = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _repControllers) {
      controller.dispose();
    }
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    for (final controller in _rpeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isCurrent) {
      _animationController.forward();
    }
  }

  void _initializeControllers() {
    for (int i = 0; i < widget.exercise.sets; i++) {
      _repControllers.add(TextEditingController());
      _weightControllers.add(TextEditingController());
      _rpeControllers.add(TextEditingController());
    }
  }

  @override
  void didUpdateWidget(ExerciseProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isCurrent && !oldWidget.isCurrent) {
      _animationController.forward();
    } else if (!widget.isCurrent && oldWidget.isCurrent) {
      _animationController.reverse();
    }
  }

  Color get _cardColor {
    if (widget.isCompleted) {
      return LaconicTheme.successGreen.withValues(alpha: 0.1);
    } else if (widget.isCurrent) {
      return LaconicTheme.accentRed.withValues(alpha: 0.1);
    } else {
      return LaconicTheme.ironGray;
    }
  }

  Color get _borderColor {
    if (widget.isCompleted) {
      return LaconicTheme.successGreen;
    } else if (widget.isCurrent) {
      return LaconicTheme.accentRed;
    } else {
      return LaconicTheme.darkGray;
    }
  }

  void _logSet(int setNumber) {
    final reps = int.tryParse(_repControllers[setNumber - 1].text) ?? 0;
    final weight = double.tryParse(_weightControllers[setNumber - 1].text);
    final rpe = double.tryParse(_rpeControllers[setNumber - 1].text);

    if (reps > 0) {
      widget.onSetCompleted?.call(setNumber, reps, weight, rpe);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _cardColor,
                border: Border.all(color: _borderColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExerciseHeader(),
                  if (widget.exercise.hasSubstitutions)
                    _buildSubstitutionButton(),
                  _buildProgressIndicator(),
                  _buildSetsList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exercise.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: widget.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.exercise.sets} x ${widget.exercise.targetDisplay}',
                  style: const TextStyle(
                    color: LaconicTheme.silverGray,
                    fontSize: 14,
                  ),
                ),
                if (widget.exercise.hasProgressiveOverloadData)
                  _buildProgressiveOverloadIndicator(),
              ],
            ),
          ),
          if (widget.isCompleted)
            const Icon(
              Icons.check_circle,
              color: LaconicTheme.successGreen,
              size: 32,
            )
          else if (widget.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: LaconicTheme.accentRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'CURRENT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressiveOverloadIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up,
            color: LaconicTheme.accentRed,
            size: 16,
          ),
          const SizedBox(width: 4),
          if (widget.exercise.weightIncrease != null)
            Text(
              '+${widget.exercise.weightIncrease!.toStringAsFixed(1)}kg',
              style: const TextStyle(
                color: LaconicTheme.accentRed,
                fontSize: 12,
              ),
            ),
          if (widget.exercise.repIncrease != null)
            Text(
              '+${widget.exercise.repIncrease} reps',
              style: const TextStyle(
                color: LaconicTheme.accentRed,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubstitutionButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _showSubstitutions = !_showSubstitutions;
          });
        },
        icon: const Icon(
          Icons.swap_horiz,
          color: LaconicTheme.silverGray,
          size: 16,
        ),
        label: Text(
          _showSubstitutions ? 'Hide Alternatives' : 'Show Alternatives',
          style: const TextStyle(color: LaconicTheme.silverGray, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = widget.progress.targetSets > 0
        ? widget.progress.completedSets / widget.progress.targetSets
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: LaconicTheme.darkGray,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.isCompleted
              ? LaconicTheme.successGreen
              : LaconicTheme.accentRed,
        ),
      ),
    );
  }

  Widget _buildSetsList() {
    if (widget.isCompleted) {
      return _buildCompletedSets();
    } else {
      return _buildActiveSets();
    }
  }

  Widget _buildCompletedSets() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.setPerformances.map((set) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Set ${set.setNumber}',
                  style: const TextStyle(
                    color: LaconicTheme.silverGray,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    if (set.repsPerformed != null)
                      Text(
                        '${set.repsPerformed} reps',
                        style: const TextStyle(
                          color: Color.fromARGB(25, 255, 255, 255),
                          fontSize: 14,
                        ),
                      ),
                    if (set.loadUsed != null && set.loadUsed! > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${set.loadUsed!.toStringAsFixed(1)}kg',
                        style: const TextStyle(
                          color: Color.fromARGB(25, 255, 255, 255),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (set.actualRPE != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'RPE ${set.actualRPE!.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: LaconicTheme.silverGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveSets() {
    return Column(
      children: [
        if (_showSubstitutions && widget.exercise.hasSubstitutions)
          _buildSubstitutionOptions(),
        ...List.generate(widget.exercise.sets, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LaconicTheme.darkGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LaconicTheme.ironGray),
            ),
            child: _buildActiveSetRow(index + 1),
          );
        }),
      ],
    );
  }

  Widget _buildSubstitutionOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LaconicTheme.darkGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alternative Exercises:',
            style: TextStyle(
              color: LaconicTheme.silverGray,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.exercise.substitutionExerciseNames.map((name) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: LaconicTheme.silverGray,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Color.fromARGB(25, 255, 255, 255),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onExerciseSubstituted?.call(name);
                    },
                    child: const Text(
                      'Use',
                      style: TextStyle(
                        color: LaconicTheme.accentRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCompletedSetRow(int index) {
    final set = widget.setPerformances[index];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Set ${set.setNumber}',
          style: const TextStyle(
            color: LaconicTheme.successGreen,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Text(
              '${set.repsPerformed} reps',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            if (set.loadUsed != null && set.loadUsed! > 0) ...[
              const SizedBox(width: 16),
              Text(
                '${set.loadUsed!.toStringAsFixed(1)}kg',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
            if (set.actualRPE != null) ...[
              const SizedBox(width: 16),
              Text(
                'RPE ${set.actualRPE!.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: LaconicTheme.silverGray,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActiveSetRow(int setNumber) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Set $setNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (widget.exercise.isTimedExercise)
              Expanded(child: _buildTimedInput(setNumber))
            else
              Expanded(child: _buildRepInput(setNumber)),
            const SizedBox(width: 8),
            if (widget.exercise.suggestedWeight != null)
              Expanded(child: _buildWeightInput(setNumber)),
            const SizedBox(width: 8),
            Expanded(child: _buildRpeInput(setNumber)),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _logSet(setNumber),
              style: ElevatedButton.styleFrom(
                backgroundColor: LaconicTheme.accentRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Log',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepInput(int setNumber) {
    return TextField(
      controller: _repControllers[setNumber - 1],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Reps',
        hintStyle: const TextStyle(color: LaconicTheme.silverGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.ironGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.ironGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.accentRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _buildTimedInput(int setNumber) {
    return TextField(
      controller: _repControllers[setNumber - 1],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Seconds',
        hintStyle: const TextStyle(color: LaconicTheme.silverGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.ironGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.ironGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.accentRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _buildWeightInput(int setNumber) {
    return TextField(
      controller: _weightControllers[setNumber - 1],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Weight',
        hintStyle: const TextStyle(color: LaconicTheme.silverGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.ironGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.ironGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.accentRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _buildRpeInput(int setNumber) {
    return TextField(
      controller: _rpeControllers[setNumber - 1],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'RPE',
        hintStyle: const TextStyle(color: LaconicTheme.silverGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.ironGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.ironGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LaconicTheme.accentRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}
