import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/workout_tracking.dart';

/// Enhanced Set Tracker Card with Rest Timer
/// Features:
/// - Rest timer countdown between sets
/// - Form quality rating
/// - Tempo tracking
/// - Auto-suggest next set weight
/// - PR notifications
class SetTrackerCardV2 extends StatefulWidget {
  final int setNumber;
  final int targetReps;
  final double targetRPE;
  final int targetRestSeconds;
  final bool isCompleted;
  final bool isCurrent;
  final SetPerformance? previousPerformance;
  final SetPerformance? lastWeekPerformance;
  final double? suggestedWeight;
  final Function(SetPerformance, FormRating?) onComplete;
  final VoidCallback? onStartRest;
  final VoidCallback? onSkipRest;

  const SetTrackerCardV2({
    super.key,
    required this.setNumber,
    required this.targetReps,
    required this.targetRPE,
    this.targetRestSeconds = 60,
    required this.isCompleted,
    required this.isCurrent,
    this.previousPerformance,
    this.lastWeekPerformance,
    this.suggestedWeight,
    required this.onComplete,
    this.onStartRest,
    this.onSkipRest,
  });

  @override
  State<SetTrackerCardV2> createState() => _SetTrackerCardV2State();
}

class _SetTrackerCardV2State extends State<SetTrackerCardV2> {
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _eccentricController = TextEditingController(text: '2');
  final _concentricController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  
  double? _selectedRPE;
  FormRating? _formRating;
  bool _isExpanded = false;
  bool _showRestTimer = false;
  int _remainingRestSeconds = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    if (widget.previousPerformance != null) {
      _repsController.text = widget.previousPerformance!.repsPerformed?.toString() ?? '';
      _weightController.text = widget.previousPerformance!.loadUsed?.toString() ?? '';
      _selectedRPE = widget.previousPerformance!.actualRPE;
      _notesController.text = widget.previousPerformance!.notes ?? '';
    } else if (widget.suggestedWeight != null) {
      _weightController.text = widget.suggestedWeight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _eccentricController.dispose();
    _concentricController.dispose();
    _notesController.dispose();
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer() {
    setState(() {
      _showRestTimer = true;
      _remainingRestSeconds = widget.targetRestSeconds;
    });
    
    widget.onStartRest?.call();
    
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRestSeconds > 0) {
        setState(() => _remainingRestSeconds--);
      } else {
        timer.cancel();
        _onRestComplete();
      }
    });
  }

  void _onRestComplete() {
    HapticFeedback.heavyImpact();
    setState(() => _showRestTimer = false);
    // Could show a notification or play a sound
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _showRestTimer = false);
    widget.onSkipRest?.call();
  }

  void _submitSet() {
    final reps = int.tryParse(_repsController.text);
    final weight = double.tryParse(_weightController.text);
    
    if (reps == null || reps < 0) {
      _showError('Please enter valid reps');
      return;
    }
    
    if (_selectedRPE == null) {
      _showError('Please select RPE');
      return;
    }

    HapticFeedback.mediumImpact();

    final performance = SetPerformance(
      setNumber: widget.setNumber,
      repsPerformed: reps,
      actualRPE: _selectedRPE,
      loadUsed: weight,
      completed: true,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    widget.onComplete(performance, _formRating);
    
    // Start rest timer for next set
    if (!widget.isCompleted) {
      _startRestTimer();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: widget.isCompleted
            ? LaconicTheme.spartanBronze.withValues(alpha: 0.1)
            : widget.isCurrent
                ? Colors.grey[850]
                : Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isCompleted
              ? LaconicTheme.spartanBronze
              : widget.isCurrent
                  ? LaconicTheme.spartanBronze.withValues(alpha: 0.5)
                  : Colors.transparent,
          width: widget.isCurrent || widget.isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          _buildMainCard(),
          if (_showRestTimer) _buildRestTimer(),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildInputs(),
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              _buildExpandedDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.isCompleted
                ? LaconicTheme.spartanBronze
                : widget.isCurrent
                    ? LaconicTheme.spartanBronze.withValues(alpha: 0.3)
                    : Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: widget.isCompleted
                ? const Icon(Icons.check, color: Colors.black, size: 24)
                : Text(
                    '${widget.setNumber}',
                    style: TextStyle(
                      color: widget.isCurrent ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                'SET ${widget.setNumber}',
                style: TextStyle(
                  color: widget.isCurrent ? Colors.white : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              if (widget.previousPerformance != null)
                Text(
                  'Previous: ${widget.previousPerformance!.repsPerformed} reps @ ${widget.previousPerformance!.loadUsed?.toStringAsFixed(1) ?? '0'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (widget.suggestedWeight != null && !widget.isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: LaconicTheme.spartanBronze.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Suggested: ${widget.suggestedWeight!.toStringAsFixed(1)}',
              style: const TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildInputs() {
    return Row(
      children: [
        // Reps input
        Expanded(
          child: _buildInputField(
            controller: _repsController,
            label: 'REPS',
            hint: '${widget.targetReps}',
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        // Weight input
        Expanded(
          child: _buildInputField(
            controller: _weightController,
            label: 'WEIGHT',
            hint: '0.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffix: 'kg',
          ),
        ),
        const SizedBox(width: 12),
        // RPE selector
        Expanded(
          child: _buildRPESelector(),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700]),
            suffixText: suffix,
            suffixStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
          onSubmitted: (_) => _submitSet(),
        ),
      ],
    );
  }

  Widget _buildRPESelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RPE',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showRPEDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              border: _selectedRPE != null
                  ? Border.all(color: LaconicTheme.spartanBronze)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedRPE?.toStringAsFixed(1) ?? '${widget.targetRPE}',
                  style: TextStyle(
                    color: _selectedRPE != null ? Colors.white : Colors.grey[700],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form rating
        Text(
          'FORM QUALITY',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: FormRating.values.map((rating) {
            final isSelected = _formRating == rating;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _formRating = rating),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? LaconicTheme.spartanBronze : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.star,
                      color: isSelected ? Colors.black : Colors.grey[600],
                      size: 16,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Tempo tracking
        Row(
          children: [
            Expanded(
              child: _buildTempoField('ECCENTRIC', _eccentricController),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTempoField('CONCENTRIC', _concentricController),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Notes
        TextField(
          controller: _notesController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Notes (optional)...',
            hintStyle: TextStyle(color: Colors.grey[700]),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Complete button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitSet,
            style: ElevatedButton.styleFrom(
              backgroundColor: LaconicTheme.spartanBronze,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'COMPLETE SET',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTempoField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            suffixText: 's',
            suffixStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRestTimer() {
    final progress = 1 - (_remainingRestSeconds / widget.targetRestSeconds);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.spartanBronze.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LaconicTheme.spartanBronze.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer,
                color: LaconicTheme.spartanBronze,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(_remainingRestSeconds),
                style: const TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(LaconicTheme.spartanBronze),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _skipRest,
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('SKIP'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[500],
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() => _remainingRestSeconds += 30);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('+30s'),
                style: TextButton.styleFrom(
                  foregroundColor: LaconicTheme.spartanBronze,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRPEDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Select RPE',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 16,
              itemBuilder: (context, index) {
                final rpe = 4.0 + (index * 0.5);
                final isSelected = _selectedRPE == rpe;
                return ListTile(
                  title: Text(
                    rpe.toStringAsFixed(1),
                    style: TextStyle(
                      color: isSelected ? LaconicTheme.spartanBronze : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: LaconicTheme.spartanBronze)
                      : null,
                  onTap: () {
                    setState(() => _selectedRPE = rpe);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

enum FormRating {
  poor,
  fair,
  good,
  great,
  excellent,
}

extension FormRatingExtension on FormRating {
  String get label {
    switch (this) {
      case FormRating.poor:
        return 'Poor';
      case FormRating.fair:
        return 'Fair';
      case FormRating.good:
        return 'Good';
      case FormRating.great:
        return 'Great';
      case FormRating.excellent:
        return 'Excellent';
    }
  }
}
