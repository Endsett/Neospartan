import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../services/agoge_service.dart';
import '../services/dom_rl_engine.dart';
import '../services/ephor_scrutiny_service.dart';
import '../services/tactical_retreat_service.dart';
import '../services/state_persistence_service.dart';
import '../services/ai_plan_service.dart';
import '../services/dom_rl_engine_v2.dart';
import '../repositories/session_readiness_repository.dart';
import '../repositories/weekly_directive_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/exercise_repository.dart';
import '../models/workout_protocol.dart';
import '../models/user_profile.dart';
import '../models/session_readiness_input.dart';
import '../models/workout_tracking.dart';
import '../models/workout_preferences.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import 'workout_session_screen.dart';
import 'pre_battle_primer_screen.dart';
import 'workout_preferences_screen.dart';

class AgogeScreen extends StatefulWidget {
  const AgogeScreen({super.key});

  @override
  State<AgogeScreen> createState() => _AgogeScreenState();
}

class _AgogeScreenState extends State<AgogeScreen> {
  final AgogeService _agogeService = AgogeService();
  final DomRlEngine _domRlEngine = DomRlEngine();
  final EphorScrutinyService _ephorService = EphorScrutinyService();
  final TacticalRetreatService _tacticalRetreat = TacticalRetreatService();
  final StatePersistenceService _persistence = StatePersistenceService();
  final AIPlanService _aiPlanService = AIPlanService();
  final DomRlEngineV2 _domRlEngineV2 = DomRlEngineV2();
  final SessionReadinessRepository _readinessRepository =
      SessionReadinessRepository();
  final WeeklyDirectiveRepository _weeklyDirectiveRepository =
      WeeklyDirectiveRepository();
  final WorkoutRepository _workoutRepository = WorkoutRepository();

  WorkoutProtocol? _protocol;
  int _readinessScore = 0;
  bool _isLoading = true;
  bool _useDomRl = true;
  EphorAnalysis? _ephorAnalysis;
  DomRlResult? _domRlResult;
  TacticalRetreatCheck? _retreatCheck;
  WorkoutRecommendation? _structuredRecommendation;
  bool _isRecommendationLoading = false;
  AdaptiveWeeklyPeriodizationDecision? _weeklyDirective;
  bool _isWeeklyDirectiveLoading = false;
  SessionReadinessInput _sessionReadinessInput = const SessionReadinessInput(
    soreness: 5,
    motivation: 6,
    sleepQuality: 6,
    stress: 5,
  );

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
    _loadProtocol();
  }

  /// Load persisted readiness input and weekly directive from Supabase
  Future<void> _loadPersistedData() async {
    try {
      // Load today's readiness input if exists
      final todayInput = await _readinessRepository.getTodayReadinessInput();
      if (todayInput != null && mounted) {
        setState(() {
          _sessionReadinessInput = todayInput;
        });
      }

      // Load current weekly directive if exists
      final currentDirective = await _weeklyDirectiveRepository
          .getCurrentWeeklyDirective();
      if (currentDirective != null && mounted) {
        setState(() {
          _weeklyDirective = currentDirective;
        });
      }
    } catch (e) {
      developer.log('Error loading persisted data: $e', name: 'AgogeScreen');
    }
  }

  Widget _buildSessionReadinessQuestionnaire() {
    return GlassCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LaconicTheme.spartanBronze, LaconicTheme.warmGold],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: LaconicTheme.deepBlack,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'READINESS CHECK',
                style: TextStyle(
                  color: LaconicTheme.warmGold,
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            'Soreness',
            _sessionReadinessInput.soreness,
            (v) => _updateSessionInput(soreness: v),
          ),
          _buildSliderRow(
            'Motivation',
            _sessionReadinessInput.motivation,
            (v) => _updateSessionInput(motivation: v),
          ),
          _buildSliderRow(
            'Sleep',
            _sessionReadinessInput.sleepQuality,
            (v) => _updateSessionInput(sleepQuality: v),
          ),
          _buildSliderRow(
            'Stress',
            _sessionReadinessInput.stress,
            (v) => _updateSessionInput(stress: v),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'APPLY TO RECOMMENDATIONS',
            onPressed: _protocol == null
                ? null
                : () async {
                    final adjustedReadiness = _sessionReadinessInput
                        .applyToReadiness(_readinessScore);
                    await _readinessRepository.saveSessionReadinessInput(
                      'local_user',
                      _sessionReadinessInput,
                      baselineReadiness: _readinessScore,
                      adjustedReadiness: adjustedReadiness,
                    );
                    await _loadStructuredRecommendation(_protocol!);
                    await _loadAdaptiveWeeklyDirective();
                  },
            isSecondary: true,
            width: double.infinity,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $value/10',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: LaconicTheme.spartanBronze,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  void _updateSessionInput({
    int? soreness,
    int? motivation,
    int? sleepQuality,
    int? stress,
  }) {
    setState(() {
      _sessionReadinessInput = SessionReadinessInput(
        soreness: soreness ?? _sessionReadinessInput.soreness,
        motivation: motivation ?? _sessionReadinessInput.motivation,
        sleepQuality: sleepQuality ?? _sessionReadinessInput.sleepQuality,
        stress: stress ?? _sessionReadinessInput.stress,
      );
    });
  }

  Widget _buildWeeklyDirectiveCard() {
    final directive = _weeklyDirective;
    if (directive == null) return const SizedBox.shrink();

    final color = directive.directive == WeeklyDirective.overload
        ? Colors.green
        : directive.directive == WeeklyDirective.deload
        ? Colors.orange
        : LaconicTheme.spartanBronze;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY DIRECTIVE: ${directive.directive.name.toUpperCase()}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            directive.summary,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            'Volume: ${directive.volumeAdjustmentPercent > 0 ? '+' : ''}${directive.volumeAdjustmentPercent}% • Intensity: ${directive.intensityAdjustmentPercent > 0 ? '+' : ''}${directive.intensityAdjustmentPercent}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...directive.reasons
              .take(2)
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• $r',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _loadStructuredRecommendation(WorkoutProtocol protocol) async {
    setState(() {
      _isRecommendationLoading = true;
    });

    try {
      final profile = _buildRecommendationProfile(protocol);
      final log = _buildRecommendationLog(protocol);
      final recommendation = await _aiPlanService
          .getStructuredWorkoutRecommendations(
            profile,
            log,
            readinessInput: _sessionReadinessInput,
          );

      if (mounted) {
        setState(() {
          _structuredRecommendation = recommendation;
          _isRecommendationLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _structuredRecommendation = null;
          _isRecommendationLoading = false;
        });
      }
    }
  }

  UserProfile _buildRecommendationProfile(WorkoutProtocol protocol) {
    return UserProfile(
      userId: 'local_user',
      displayName: 'Warrior',
      bodyComposition: const BodyComposition(weight: 75, height: 175, age: 25),
      fitnessLevel: FitnessLevel.intermediate,
      trainingGoal: _inferGoalFromProtocol(protocol),
      trainingDaysPerWeek: 4,
      preferredWorkoutDuration: protocol.estimatedDurationMinutes,
      createdAt: DateTime.now(),
      hasCompletedOnboarding: true,
    );
  }

  DailyLog _buildRecommendationLog(WorkoutProtocol protocol) {
    final rpeEntries = protocol.entries.map((e) => e.intensityRpe).toList();

    return DailyLog(
      date: DateTime.now(),
      rpeEntries: rpeEntries,
      sleepQuality: _readinessScore >= 75 ? 8 : (_readinessScore >= 55 ? 7 : 5),
      sleepHours: _readinessScore >= 75
          ? 7.8
          : (_readinessScore >= 55 ? 7.0 : 5.8),
      jointFatigue: const {},
      flowState: _readinessScore >= 75 ? 8 : 6,
      readinessScore: _readinessScore,
    );
  }

  TrainingGoal _inferGoalFromProtocol(WorkoutProtocol protocol) {
    final title = protocol.title.toLowerCase();
    if (title.contains('boxing')) return TrainingGoal.boxing;
    if (title.contains('muay')) return TrainingGoal.muayThai;
    if (title.contains('wrestling')) return TrainingGoal.wrestling;
    if (title.contains('bjj') || title.contains('jiu')) return TrainingGoal.bjj;
    if (title.contains('mma')) return TrainingGoal.mma;
    if (title.contains('strength')) return TrainingGoal.strength;
    if (title.contains('conditioning')) return TrainingGoal.conditioning;
    return TrainingGoal.generalCombat;
  }

  Future<void> _loadAdaptiveWeeklyDirective() async {
    setState(() {
      _isWeeklyDirectiveLoading = true;
    });

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weeklyProgress = WeeklyProgress(
        weekStarting: weekStart,
        workoutsCompleted: (_readinessScore >= 70
            ? 4
            : (_readinessScore >= 55 ? 3 : 2)),
        totalPlannedWorkouts: 4,
        averageRPE: (_protocol?.entries.isNotEmpty ?? false)
            ? _protocol!.entries
                      .map((e) => e.intensityRpe)
                      .reduce((a, b) => a + b) /
                  _protocol!.entries.length
            : 7.0,
        totalVolume: (_protocol?.entries.length ?? 0) * 180,
        averageReadiness: _sessionReadinessInput.applyToReadiness(
          _readinessScore,
        ),
        achievedGoals: _readinessScore >= 70,
      );

      final directive = await _domRlEngineV2.generateAdaptiveWeeklyDirective(
        userId: 'local_user',
        weeklyProgress: weeklyProgress,
      );

      // Persist the weekly directive to Supabase
      await _weeklyDirectiveRepository.saveWeeklyDirective(
        'local_user',
        directive,
      );

      if (mounted) {
        setState(() {
          _weeklyDirective = directive;
          _isWeeklyDirectiveLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _weeklyDirective = null;
          _isWeeklyDirectiveLoading = false;
        });
      }
    }
  }

  Future<void> _loadProtocol() async {
    setState(() => _isLoading = true);

    // First, check if we have a saved plan in Supabase for today
    final todaysPlan = await _workoutRepository.getTodaysPlan();
    if (todaysPlan != null) {
      // Convert saved plan back to WorkoutProtocol
      final protocol = _planToProtocol(todaysPlan);
      await _loadStructuredRecommendation(protocol);
      await _loadAdaptiveWeeklyDirective();
      if (mounted) {
        setState(() {
          _protocol = protocol;
          _readinessScore = todaysPlan['readiness_score'] ?? 80;
          _isLoading = false;
        });
      }
      return;
    }

    // Check local persistence as fallback
    final savedProtocol = _persistence.loadDailyProtocol();
    if (savedProtocol != null && !_isNewDay()) {
      await _loadStructuredRecommendation(savedProtocol);
      await _loadAdaptiveWeeklyDirective();
      // Save to Supabase for future loads
      await _saveProtocolToSupabase(savedProtocol);
      if (mounted) {
        setState(() {
          _protocol = savedProtocol;
          _readinessScore = _persistence.getPreference(
            'last_readiness_score',
            80,
          );
          _isLoading = false;
        });
      }
      return;
    }

    // No saved protocol or new day - generate new one
    await _generateNewProtocol();
  }

  /// Convert saved plan to WorkoutProtocol
  WorkoutProtocol _planToProtocol(Map<String, dynamic> plan) {
    final exercises = (plan['exercises'] as List<dynamic>?) ?? [];
    final entries = exercises.map((e) {
      return ProtocolEntry(
        exercise: Exercise(
          id: e['exerciseId'] ?? e['name'] ?? 'unknown',
          name: e['name'] ?? 'Unknown Exercise',
          category: ExerciseCategory.values.firstWhere(
            (c) => c.name == (e['category'] ?? 'strength'),
            orElse: () => ExerciseCategory.strength,
          ),
          youtubeId: e['youtubeId'] ?? '',
          targetMetaphor: e['targetMetaphor'] ?? '',
          instructions: e['instructions'] ?? '',
        ),
        sets: e['sets'] ?? 3,
        reps: e['reps'] ?? 10,
        intensityRpe: (e['intensityRpe'] ?? 7.0).toDouble(),
        restSeconds: e['restSeconds'] ?? 60,
      );
    }).toList();

    return WorkoutProtocol(
      title: plan['title'] ?? 'Daily Protocol',
      subtitle: plan['subtitle'] ?? 'Agoge Training',
      tier: ProtocolTier.values.firstWhere(
        (t) => t.name == (plan['tier'] ?? 'ready'),
        orElse: () => ProtocolTier.ready,
      ),
      entries: entries,
      estimatedDurationMinutes: plan['estimated_duration_minutes'] ?? 45,
      mindsetPrompt:
          plan['mindsetPrompt'] ?? 'Forge your body, sharpen your mind.',
    );
  }

  /// Save protocol to Supabase
  Future<void> _saveProtocolToSupabase(WorkoutProtocol protocol) async {
    final exercises = protocol.entries
        .map(
          (e) => {
            'exerciseId': e.exercise.id,
            'name': e.exercise.name,
            'category': e.exercise.category.name,
            'youtubeId': e.exercise.youtubeId,
            'targetMetaphor': e.exercise.targetMetaphor,
            'instructions': e.exercise.instructions,
            'sets': e.sets,
            'reps': e.reps,
            'intensityRpe': e.intensityRpe,
            'restSeconds': e.restSeconds,
          },
        )
        .toList();

    await _workoutRepository.saveTodaysPlan({
      'title': protocol.title,
      'subtitle': protocol.subtitle,
      'tier': protocol.tier.name,
      'exercises': exercises,
      'estimatedDurationMinutes': protocol.estimatedDurationMinutes,
      'mindsetPrompt': protocol.mindsetPrompt,
      'readinessScore': _readinessScore,
    });
  }

  bool _isNewDay() {
    final lastProtocolDate = _persistence.getPreference(
      'last_protocol_date',
      '',
    );
    final today =
        '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    return lastProtocolDate != today;
  }

  Future<void> _generateNewProtocol() async {
    // Fetch readiness data
    final score = 80; // Default readiness score - TODO: get from actual source
    _readinessScore = score;

    // Generate base protocol
    final baseProtocol = _agogeService.generateProtocol(score);

    // Apply DOM-RL optimization if enabled
    WorkoutProtocol finalProtocol = baseProtocol;
    DomRlResult? domRlResult;
    if (_useDomRl) {
      // TODO: Implement DOM-RL with proper MicroCycle
    }

    // Check for tactical retreat
    final jointStress = <String, int>{};
    final retreatCheck = _tacticalRetreat.checkRetreatStatus(
      currentReadiness: score,
      jointStress: jointStress,
    );

    // Override protocol if retreat required
    if (retreatCheck.shouldRetreat && retreatCheck.enforcedProtocol != null) {
      finalProtocol = retreatCheck.enforcedProtocol!;
    }

    // Save the new protocol
    await _persistence.saveDailyProtocol(finalProtocol);
    await _saveProtocolToSupabase(finalProtocol);
    await _persistence.setPreference('last_readiness_score', score);
    await _persistence.setPreference(
      'last_protocol_date',
      '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
    );

    await _loadStructuredRecommendation(finalProtocol);
    await _loadAdaptiveWeeklyDirective();

    if (mounted) {
      setState(() {
        _protocol = finalProtocol;
        _domRlResult = domRlResult;
        _retreatCheck = retreatCheck;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProtocol() async {
    // Clear saved protocol and generate new one
    await _persistence.clearDailyProtocol();
    await _generateNewProtocol();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("A G O G E"),
        actions: [
          // Phalanx import button
          IconButton(
            icon: const Icon(
              Icons.upload_file,
              color: LaconicTheme.spartanBronze,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/phalanx');
            },
            tooltip: 'Import Plan (Phalanx)',
          ),
          // DOM-RL toggle
          IconButton(
            icon: Icon(
              _useDomRl ? Icons.psychology : Icons.psychology_outlined,
              color: _useDomRl ? LaconicTheme.spartanBronze : Colors.grey,
            ),
            onPressed: () {
              setState(() => _useDomRl = !_useDomRl);
              _loadProtocol();
            },
            tooltip: 'DOM-RL Optimization',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: LaconicTheme.spartanBronze),
            onPressed: _refreshProtocol,
            tooltip: 'Generate New Protocol',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: LaconicTheme.spartanBronze,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProtocol,
              color: LaconicTheme.spartanBronze,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Readiness score with label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "READINESS: $_readinessScore",
                          style: const TextStyle(
                            color: LaconicTheme.spartanBronze,
                            fontSize: 12,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_domRlResult != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: LaconicTheme.spartanBronze.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DOM-RL ACTIVE',
                              style: TextStyle(
                                color: LaconicTheme.spartanBronze,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tactical Retreat warning
                    if (_retreatCheck?.shouldRetreat ?? false)
                      _buildRetreatBanner(),

                    // Ephor Analysis
                    if (_ephorAnalysis != null) _buildEphorCard(),

                    const SizedBox(height: 20),
                    _buildSessionReadinessQuestionnaire(),
                    const SizedBox(height: 16),
                    if (_isWeeklyDirectiveLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: LaconicTheme.spartanBronze,
                          ),
                        ),
                      )
                    else if (_weeklyDirective != null)
                      _buildWeeklyDirectiveCard(),
                    const SizedBox(height: 20),
                    _buildAIGard(),
                    const SizedBox(height: 16),
                    if (_isRecommendationLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: LaconicTheme.spartanBronze,
                          ),
                        ),
                      )
                    else if (_structuredRecommendation != null)
                      _buildStructuredRecommendationCard(),
                    const SizedBox(height: 30),

                    // DOM-RL Action display
                    if (_domRlResult != null) _buildDomRlActionCard(),

                    const SizedBox(height: 20),
                    // Plan Header with Regenerate and Custom buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "TODAY'S WORKOUT PLAN",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _regeneratePlan,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text(
                                'NEW',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: LaconicTheme.spartanBronze,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _showCustomPlanPreferences,
                              icon: const Icon(Icons.tune, size: 16),
                              label: const Text(
                                'CUSTOM',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: LaconicTheme.spartanBronze,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_protocol != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_protocol!.title} • ${_protocol!.estimatedDurationMinutes} min • ${_protocol!.entries.length} exercises',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Exercise cards with set counters
                    ...?_protocol?.entries.asMap().entries.map((mapEntry) {
                      final index = mapEntry.key;
                      final entry = mapEntry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildExercisePlanCard(
                          index: index,
                          entry: entry,
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                    GradientButton(
                      label: 'INITIALIZE PROTOCOL',
                      onPressed: _protocol != null
                          ? () => _showPreBattlePrimer(workoutProvider)
                          : null,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  void _showPreBattlePrimer(WorkoutProvider workoutProvider) {
    // Get user profile from auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
          readinessScore: _readinessScore,
          existingProtocol: _protocol, // Pass the existing protocol
          onWorkoutLoaded: (protocol, readinessScore) {
            workoutProvider.startWorkout(protocol, readinessScore);
            Navigator.pop(context); // Close primer
            Navigator.push(
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

  Widget _buildRetreatBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              const Text(
                'TACTICAL RETREAT ENFORCED',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _retreatCheck?.reasons.join('\n') ?? '',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...?_retreatCheck?.recommendations.map(
            (r) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• $r',
                style: TextStyle(color: Colors.red.shade300, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEphorCard() {
    final recommendation = _ephorAnalysis?.recommendation.name ?? 'steadyState';
    final isPositive =
        recommendation == 'progressiveOverload' ||
        recommendation == 'steadyState';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPositive
            ? LaconicTheme.spartanBronze.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        border: Border.all(
          color: isPositive
              ? LaconicTheme.spartanBronze.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_flat,
                color: isPositive ? LaconicTheme.spartanBronze : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'EPHOR SCRUTINY: ${recommendation.toUpperCase()}',
                style: TextStyle(
                  color: isPositive
                      ? LaconicTheme.spartanBronze
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _ephorAnalysis?.message ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...?_ephorAnalysis?.trainingPrinciples
              .take(2)
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• $p',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildDomRlActionCard() {
    final action = _domRlResult?.action;
    if (action == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(
          color: LaconicTheme.spartanBronze.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DOM-RL OPTIMIZATIONS',
            style: TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 10,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionRow('Focus', action.focusArea.name.toUpperCase()),
          _buildActionRow(
            'Volume',
            '${(action.volumeAdjustment * 100).toStringAsFixed(0)}%',
          ),
          _buildActionRow(
            'Intensity',
            '${(action.intensityAdjustment * 100).toStringAsFixed(0)}%',
          ),
          _buildActionRow(
            'Rest',
            '${action.restAdjustment > 0 ? '+' : ''}${action.restAdjustment}s',
          ),
          if (action.exerciseSubstitutions.isNotEmpty)
            ...action.exerciseSubstitutions.map(
              (sub) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• ${sub.fromExerciseId} → ${sub.toExerciseId}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIGard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.2),
        border: Border.all(
          color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: LaconicTheme.spartanBronze),
              const SizedBox(width: 12),
              Text(
                _protocol?.title ?? "AGOGE ENGINE",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "\"${_protocol?.mindsetPrompt ?? "Analyzing state..."}\"",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Regenerate today's workout plan
  Future<void> _regeneratePlan() async {
    // Delete current plan and generate new one
    await _workoutRepository.deleteTodaysPlan();
    await _persistence.clearDailyProtocol();
    await _generateNewProtocol();
  }

  /// Show custom workout preferences screen
  Future<void> _showCustomPlanPreferences() async {
    // Get user profile from auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

    // Navigate to preferences screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPreferencesScreen(
          profile: userProfile,
          onGenerate: (preferences) async {
            await _generateCustomProtocol(preferences, userProfile);
          },
        ),
      ),
    );
  }

  /// Generate custom workout protocol based on user preferences
  Future<void> _generateCustomProtocol(
    WorkoutPreferences preferences,
    UserProfile profile,
  ) async {
    setState(() => _isLoading = true);

    try {
      // Initialize AI plan service
      final aiPlanService = AIPlanService();
      await aiPlanService.initialize();

      // Get available exercises matching preferences
      final exerciseRepo = ExerciseRepository();
      final allExercises = await exerciseRepo.getAllExercises();

      // Filter exercises by preferred categories if specified
      final availableExercises = preferences.preferredCategories.isNotEmpty
          ? allExercises
                .where(
                  (e) => preferences.preferredCategories.contains(e.category),
                )
                .toList()
          : allExercises;

      // Generate custom protocol
      final protocol = await aiPlanService.generateCustomProtocol(
        profile,
        preferences,
        availableExercises: availableExercises.isNotEmpty
            ? availableExercises
            : null,
      );

      if (protocol != null) {
        // Save the custom protocol
        await _persistence.saveDailyProtocol(protocol);
        await _saveProtocolToSupabase(protocol);

        setState(() {
          _protocol = protocol;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI-generated ${preferences.trainingFocusLabel} workout ready!',
            ),
            backgroundColor: LaconicTheme.spartanBronze,
          ),
        );
      } else {
        throw Exception('Failed to generate custom protocol');
      }
    } catch (e) {
      debugPrint('Error generating custom protocol: $e');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Build exercise plan card with set counter
  Widget _buildExercisePlanCard({
    required int index,
    required ProtocolEntry entry,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise number and name
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: LaconicTheme.spartanBronze.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: LaconicTheme.spartanBronze,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Set counter visualization
          Row(
            children: [
              Text(
                'SETS:',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.8),
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              // Set counter circles
              Row(
                children: List.generate(entry.sets, (setIndex) {
                  return Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: LaconicTheme.spartanBronze,
                        width: 2,
                      ),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        '${setIndex + 1}',
                        style: TextStyle(
                          color: LaconicTheme.spartanBronze,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Exercise details row
          Row(
            children: [
              _buildDetailChip(
                '${entry.reps > 0 ? entry.reps : 'MAX'} REPS',
                Icons.fitness_center,
              ),
              const SizedBox(width: 12),
              _buildDetailChip(
                'RPE ${entry.intensityRpe.toStringAsFixed(1)}',
                Icons.speed,
              ),
              const SizedBox(width: 12),
              _buildDetailChip('${entry.restSeconds}s REST', Icons.timer),
            ],
          ),
        ],
      ),
    );
  }

  /// Build detail chip for exercise card
  Widget _buildDetailChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: LaconicTheme.spartanBronze, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredRecommendationCard() {
    final recommendation = _structuredRecommendation;
    if (recommendation == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.15),
        border: Border.all(
          color: LaconicTheme.spartanBronze.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI NEXT SESSION RECOMMENDATION',
            style: TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 10,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            recommendation.sessionFocus,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.progressionDirective,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...recommendation.exercises
              .take(4)
              .map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${exercise.name} (${exercise.category.name.toUpperCase()})',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          ...recommendation.recoveryGuidance
              .take(2)
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '- $line',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
