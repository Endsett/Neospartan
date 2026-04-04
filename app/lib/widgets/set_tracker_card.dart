import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/workout_tracking.dart';

/// Detailed set tracking card with reps, weight, and RPE inputs
class SetTrackerCard extends StatefulWidget {
  final int setNumber;
  final int targetReps;
  final double targetRPE;
  final bool isCompleted;
  final bool isCurrent;
  final SetPerformance? previousPerformance;
  final Function(SetPerformance) onComplete;
  final VoidCallback? onEdit;

  const SetTrackerCard({
    super.key,
    required this.setNumber,
    required this.targetReps,
    required this.targetRPE,
    required this.isCompleted,
    required this.isCurrent,
    this.previousPerformance,
    required this.onComplete,
    this.onEdit,
  });

  @override
  State<SetTrackerCard> createState() => _SetTrackerCardState();
}

class _SetTrackerCardState extends State<SetTrackerCard> {
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  double? _selectedRPE;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.previousPerformance != null) {
      _repsController.text = widget.previousPerformance!.repsPerformed?.toString() ?? '';
      _weightController.text = widget.previousPerformance!.loadUsed?.toString() ?? '';
      _selectedRPE = widget.previousPerformance!.actualRPE;
      _notesController.text = widget.previousPerformance!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
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

    // Haptic feedback
    HapticFeedback.mediumImpact();

    final performance = SetPerformance(
      setNumber: widget.setNumber,
      repsPerformed: reps,
      actualRPE: _selectedRPE,
      loadUsed: weight,
      completed: true,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    widget.onComplete(performance);
    
    // Clear for next set
    _repsController.clear();
    _notesController.clear();
    setState(() => _selectedRPE = null);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isCompleted 
            ? LaconicTheme.spartanBronze.withValues(alpha: 0.1)
            : widget.isCurrent 
                ? LaconicTheme.ironGray.withValues(alpha: 0.2)
                : LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(
          color: widget.isCompleted 
              ? LaconicTheme.spartanBronze.withValues(alpha: 0.5)
              : widget.isCurrent 
                  ? LaconicTheme.spartanBronze
                  : LaconicTheme.ironGray.withValues(alpha: 0.3),
          width: widget.isCurrent ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: widget.isCompleted ? () => setState(() => _isExpanded = !_isExpanded) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.isCompleted 
                              ? LaconicTheme.spartanBronze
                              : widget.isCurrent 
                                  ? LaconicTheme.spartanBronze.withValues(alpha: 0.3)
                                  : LaconicTheme.ironGray,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: widget.isCompleted
                              ? const Icon(Icons.check, color: Colors.black, size: 18)
                              : Text(
                                  '${widget.setNumber}',
                                  style: TextStyle(
                                    color: widget.isCurrent ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SET ${widget.setNumber}',
                        style: TextStyle(
                          color: widget.isCompleted || widget.isCurrent 
                              ? LaconicTheme.spartanBronze 
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isCompleted && widget.previousPerformance != null)
                    Row(
                      children: [
                        Text(
                          '${widget.previousPerformance!.repsPerformed} reps',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (widget.previousPerformance!.loadUsed != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '@ ${widget.previousPerformance!.loadUsed!.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          'RPE ${widget.previousPerformance!.actualRPE?.toStringAsFixed(1) ?? '-'}',
                          style: const TextStyle(color: LaconicTheme.spartanBronze, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // Input section (only for current set)
          if (widget.isCurrent) ...[
            const Divider(color: LaconicTheme.ironGray, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target info
                  Row(
                    children: [
                      _buildTargetChip('Target: ${widget.targetReps} reps'),
                      const SizedBox(width: 8),
                      _buildTargetChip('Target RPE: ${widget.targetRPE.toStringAsFixed(1)}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Reps input
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildNumberInput(
                          controller: _repsController,
                          label: 'REPS',
                          hint: '${widget.targetReps}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildNumberInput(
                          controller: _weightController,
                          label: 'WEIGHT (kg)',
                          hint: '0.0',
                          decimal: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // RPE selector
                  const Text(
                    'ACTUAL RPE',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(8, (i) {
                      final rpe = i + 3; // 3-10 scale
                      final isSelected = _selectedRPE == rpe;
                      final isTarget = rpe == widget.targetRPE.round();
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRPE = rpe.toDouble()),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? LaconicTheme.spartanBronze
                                : isTarget
                                    ? LaconicTheme.spartanBronze.withValues(alpha: 0.2)
                                    : LaconicTheme.ironGray.withValues(alpha: 0.3),
                            border: Border.all(
                              color: isSelected 
                                  ? LaconicTheme.spartanBronze
                                  : isTarget
                                      ? LaconicTheme.spartanBronze.withValues(alpha: 0.5)
                                      : Colors.transparent,
                              width: isTarget ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '$rpe',
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notes input
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Notes (optional)',
                      hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: LaconicTheme.ironGray.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Complete button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitSet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LaconicTheme.spartanBronze,
                        foregroundColor: Colors.black,
                        shape: const BeveledRectangleBorder(),
                      ),
                      child: const Text(
                        'LOG SET',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Expanded view for completed sets
          if (widget.isCompleted && _isExpanded && widget.previousPerformance != null) ...[
            const Divider(color: LaconicTheme.ironGray, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.previousPerformance!.notes != null) ...[
                    const Text(
                      'NOTES',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.previousPerformance!.notes!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('EDIT'),
                        style: TextButton.styleFrom(
                          foregroundColor: LaconicTheme.spartanBronze,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool decimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.withValues(alpha: 0.3),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: LaconicTheme.ironGray.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
