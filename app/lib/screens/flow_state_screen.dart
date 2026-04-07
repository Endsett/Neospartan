import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/workout_tracking.dart';
import '../services/supabase_database_service.dart';
import '../providers/auth_provider.dart';

/// Flow State Assessment Model
class FlowStateAssessment {
  final String? id;
  final String userId;
  final String? workoutSessionId;
  final int mentalEngagement;
  final int focusClarity;
  final int formDiscipline;
  final int overallFlow;
  final String? notes;
  final DateTime timestamp;

  FlowStateAssessment({
    this.id,
    required this.userId,
    this.workoutSessionId,
    required this.mentalEngagement,
    required this.focusClarity,
    required this.formDiscipline,
    required this.overallFlow,
    this.notes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'workout_session_id': workoutSessionId,
      'mental_engagement': mentalEngagement,
      'focus_clarity': focusClarity,
      'form_discipline': formDiscipline,
      'overall_flow': overallFlow,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FlowStateAssessment.fromMap(Map<String, dynamic> map) {
    return FlowStateAssessment(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      workoutSessionId: map['workout_session_id']?.toString(),
      mentalEngagement: map['mental_engagement'] ?? 5,
      focusClarity: map['focus_clarity'] ?? 5,
      formDiscipline: map['form_discipline'] ?? 5,
      overallFlow: map['overall_flow'] ?? 5,
      notes: map['notes'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }

  double get averageScore =>
      (mentalEngagement + focusClarity + formDiscipline + overallFlow) / 4;
}

/// Flow State Assessment Screen
/// Post-workout mental engagement tracking
class FlowStateScreen extends StatefulWidget {
  final CompletedWorkout workout;
  final VoidCallback onComplete;

  const FlowStateScreen({
    super.key,
    required this.workout,
    required this.onComplete,
  });

  @override
  State<FlowStateScreen> createState() => _FlowStateScreenState();
}

class _FlowStateScreenState extends State<FlowStateScreen> {
  int _mentalEngagement = 5;
  int _focusClarity = 5;
  int _formDiscipline = 5;
  int _overallFlow = 5;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      appBar: AppBar(
        title: const Text('FLOW STATE LOG'),
        backgroundColor: LaconicTheme.deepBlack,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MIND OVER MATTER ASSESSMENT',
              style: TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rate your mental state during this session. Honesty sharpens the blade.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 40),

            // Mental Engagement
            _buildRatingSlider(
              'MENTAL PRESENCE',
              'How present were you during the session?',
              _mentalEngagement,
              (value) => setState(() => _mentalEngagement = value),
            ),
            const SizedBox(height: 30),

            // Focus Clarity
            _buildRatingSlider(
              'FOCUS CLARITY',
              'Did external thoughts intrude? (Higher = fewer intrusions)',
              _focusClarity,
              (value) => setState(() => _focusClarity = value),
            ),
            const SizedBox(height: 30),

            // Form Discipline
            _buildRatingSlider(
              'FORM DISCIPLINE',
              'Rate your discipline in maintaining perfect form.',
              _formDiscipline,
              (value) => setState(() => _formDiscipline = value),
            ),
            const SizedBox(height: 30),

            // Overall Flow
            _buildRatingSlider(
              'OVERALL FLOW STATE',
              'Were you in the zone? Fully immersed and focused?',
              _overallFlow,
              (value) => setState(() => _overallFlow = value),
            ),
            const SizedBox(height: 40),

            // Notes
            const Text(
              'NOTES (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'What affected your focus? Distractions? Breakthroughs?',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: LaconicTheme.ironGray.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Average score display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LaconicTheme.spartanBronze.withValues(alpha: 0.1),
                border: Border.all(
                  color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'AVERAGE FLOW SCORE',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ((_mentalEngagement +
                                _focusClarity +
                                _formDiscipline +
                                _overallFlow) /
                            4)
                        .toStringAsFixed(1),
                    style: const TextStyle(
                      color: LaconicTheme.spartanBronze,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFlowLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAssessment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'LOG & COMPLETE',
                        style: TextStyle(
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSlider(
    String title,
    String description,
    int value,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: LaconicTheme.spartanBronze,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: LaconicTheme.spartanBronze,
            inactiveTrackColor: LaconicTheme.ironGray,
            thumbColor: LaconicTheme.spartanBronze,
            overlayColor: LaconicTheme.spartanBronze.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Distracted',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
            Text(
              'Fully Present',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  String _getFlowLabel() {
    final avg =
        (_mentalEngagement + _focusClarity + _formDiscipline + _overallFlow) /
        4;
    if (avg >= 9) return 'TRANSCENDENT';
    if (avg >= 7) return 'DEEP FLOW';
    if (avg >= 5) return 'PRESENT';
    if (avg >= 3) return 'FRAGMENTED';
    return 'DISTRACTED';
  }

  void _submitAssessment() async {
    if (_isSubmitting) return;

    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create assessment
      final assessment = FlowStateAssessment(
        userId: userId,
        workoutSessionId: widget.workout.id,
        mentalEngagement: _mentalEngagement,
        focusClarity: _focusClarity,
        formDiscipline: _formDiscipline,
        overallFlow: _overallFlow,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Save to Supabase
      await _database.saveFlowStateAssessment(assessment.toMap());

      // Update workout session with flow data
      await _database.updateWorkoutSessionWithFlow(
        widget.workout.id,
        _overallFlow,
      );

      debugPrint('Flow state assessment saved successfully');

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      debugPrint('Error saving flow assessment: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save assessment: $e')),
        );
      }
    }
  }
}
