import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/backend_api_service.dart';
import '../services/ai_plan_service.dart';
import '../models/user_profile.dart';
import '../models/workout_protocol.dart';

/// Pre-Battle Primer Screen
/// Displays Stoic philosophy quotes and requires acknowledgment before workout
/// Loads AI-generated workout with full details when acknowledged
class PreBattlePrimerScreen extends StatefulWidget {
  final VoidCallback? onAcknowledged;
  final Function(WorkoutProtocol protocol, int readinessScore)? onWorkoutLoaded;
  final UserProfile userProfile;
  final WeeklyPlan? existingWeeklyPlan;
  final int readinessScore;
  final WorkoutProtocol? existingProtocol; // Add this

  const PreBattlePrimerScreen({
    super.key,
    this.onAcknowledged,
    this.onWorkoutLoaded,
    required this.userProfile,
    this.existingWeeklyPlan,
    this.readinessScore = 80,
    this.existingProtocol, // Add this
  });

  @override
  State<PreBattlePrimerScreen> createState() => _PreBattlePrimerScreenState();
}

class _PreBattlePrimerScreenState extends State<PreBattlePrimerScreen> {
  final BackendApiService _api = BackendApiService();
  Map<String, dynamic>? _primerData;
  bool _isLoading = true;
  bool _acknowledged = false;

  @override
  void initState() {
    super.initState();
    _loadPrimer();
  }

  Future<void> _loadPrimer() async {
    final data = await _api.getStoicPrimer();
    setState(() {
      _primerData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          // Wrap in SingleChildScrollView
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: LaconicTheme.spartanBronze,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Spartan helmet icon
                      Icon(
                        Icons.shield_outlined,
                        size: 80,
                        color: LaconicTheme.spartanBronze.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Section title
                      const Text(
                        'PRE-BATTLE PRIMER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Stoic Quote
                      if (_primerData?['quote'] != null)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: LaconicTheme.spartanBronze.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '"${_primerData!['quote']['text']}"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.4,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '— ${_primerData!['quote']['author']}',
                                style: const TextStyle(
                                  color: LaconicTheme.spartanBronze,
                                  fontSize: 12,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 40),
                      // Spartan Metaphor
                      if (_primerData?['metaphor'] != null)
                        Text(
                          _primerData!['metaphor'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 60),
                      // Acknowledgment checkbox
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _acknowledged,
                            onChanged: (value) {
                              setState(() {
                                _acknowledged = value ?? false;
                              });
                            },
                            activeColor: LaconicTheme.spartanBronze,
                            checkColor: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'I acknowledge: I am master of my mind. External events do not control me.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Proceed button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _acknowledged
                              ? () async {
                                  setState(() => _isLoading = true);

                                  WorkoutProtocol? protocol;

                                  // Use existing protocol if provided, otherwise generate new one
                                  if (widget.existingProtocol != null) {
                                    protocol = widget.existingProtocol!;
                                  } else {
                                    // Load AI workout with full details
                                    final aiService = AIPlanService();
                                    protocol = await aiService
                                        .getTodaysProtocol(
                                          profile: widget.userProfile,
                                          existingWeeklyPlan:
                                              widget.existingWeeklyPlan,
                                        );
                                  }

                                  if (!mounted) return;

                                  setState(() => _isLoading = false);

                                  // Call the callback with loaded protocol
                                  if (widget.onWorkoutLoaded != null &&
                                      protocol != null) {
                                    widget.onWorkoutLoaded!(
                                      protocol,
                                      widget.readinessScore,
                                    );
                                  }

                                  // Also call legacy callback if provided
                                  widget.onAcknowledged?.call();

                                  // Don't pop here - let the callback handle navigation
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LaconicTheme.spartanBronze,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor: Colors.grey.shade800,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'ACKNOWLEDGE & PROCEED',
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
        ),
      ),
    );
  }
}
