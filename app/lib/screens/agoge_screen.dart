// ignore_for_file: unused_field, unused_element, use_build_context_synchronously
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/agoge_service.dart';
import '../services/dom_rl_engine.dart';
import '../services/ephor_scrutiny_service.dart';
import '../services/tactical_retreat_service.dart';
import '../services/state_persistence_service.dart';
import '../services/ai_plan_service.dart';
import '../services/dom_rl_engine_v2.dart';
import '../services/supabase_database_service.dart';
import '../repositories/session_readiness_repository.dart';
import '../repositories/weekly_directive_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/biometrics_repository.dart';
import '../repositories/daily_readiness_repository.dart';
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

/// The Agoge Dashboard - Main Command Center
/// Following the Digital Agoge design system
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
  final BiometricsRepository _biometricsRepo = BiometricsRepository();
  final DailyReadinessRepository _readinessRepo = DailyReadinessRepository();
  final SupabaseDatabaseService _database = SupabaseDatabaseService();

  WorkoutProtocol? _protocol;
  int _readinessScore = 75;
  bool _isLoading = true;
  final bool _useDomRl = true;
  EphorAnalysis? _ephorAnalysis;
  DomRlResult? _domRlResult;
  TacticalRetreatCheck? _retreatCheck;
  WorkoutRecommendation? _structuredRecommendation;
  bool _isRecommendationLoading = false;
  AdaptiveWeeklyPeriodizationDecision? _weeklyDirective;
  bool _isWeeklyDirectiveLoading = false;
  String? _userId;

  // Recovery metrics from real data
  int _hrv = 70;
  int _rhr = 60;
  double _sleepHours = 7.0;
  String _restDuration = '7h 00m';
  double _hrvProgress = 0.70;
  double _restProgress = 0.70;

  SessionReadinessInput _sessionReadinessInput = const SessionReadinessInput(
    soreness: 5,
    motivation: 6,
    sleepQuality: 6,
    stress: 5,
  );

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<AuthProvider>(context, listen: false).userId;
    _loadBiometricsData();
    _loadReadinessData();
    _loadPersistedData();
    _loadProtocol();
  }

  Future<void> _loadBiometricsData() async {
    if (_userId == null) return;

    try {
      final latest = await _biometricsRepo.getLatestBiometrics(_userId!);
      if (latest != null && mounted) {
        setState(() {
          _hrv = latest.hrv ?? 70;
          _rhr = latest.rhr ?? 60;
          _sleepHours = latest.sleepHours ?? 7.0;
          _restDuration =
              '${_sleepHours.toInt()}h ${((_sleepHours % 1) * 60).toInt().toString().padLeft(2, '0')}m';
          _hrvProgress = ((_hrv - 40) / 60).clamp(0.3, 1.0);
          _restProgress = (_sleepHours / 9).clamp(0.3, 1.0);
        });
      }
    } catch (e) {
      developer.log('Error loading biometrics: $e', name: 'AgogeScreen');
    }
  }

  Future<void> _loadReadinessData() async {
    if (_userId == null) return;

    try {
      final today = await _readinessRepo.getReadinessForDate(
        _userId!,
        DateTime.now(),
      );
      if (today != null && mounted) {
        setState(() {
          _readinessScore = today.readinessScore;
          _sessionReadinessInput = SessionReadinessInput(
            soreness: today.soreness ?? 5,
            motivation: today.motivation ?? 6,
            sleepQuality: (today.sleepQuality ?? 0.7) * 10 ~/ 1,
            stress: today.stress ?? 5,
          );
        });
      }
    } catch (e) {
      developer.log('Error loading readiness: $e', name: 'AgogeScreen');
    }
  }

  Future<void> _loadPersistedData() async {
    try {
      final todayInput = await _readinessRepository.getTodayReadinessInput();
      if (todayInput != null && mounted) {
        setState(() {
          _sessionReadinessInput = todayInput;
        });
      }

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

  Future<void> _loadProtocol() async {
    setState(() => _isLoading = true);

    final todaysPlan = await _workoutRepository.getTodaysPlan();
    if (todaysPlan != null) {
      final protocol = _planToProtocol(todaysPlan);
      await _loadStructuredRecommendation(protocol);
      await _loadAdaptiveWeeklyDirective();
      if (mounted) {
        setState(() {
          _protocol = protocol;
          _readinessScore = todaysPlan['readiness_score'] ?? 88;
          _isLoading = false;
        });
      }
      return;
    }

    final savedProtocol = _persistence.loadDailyProtocol();
    if (savedProtocol != null && !_isNewDay()) {
      await _loadStructuredRecommendation(savedProtocol);
      await _loadAdaptiveWeeklyDirective();
      await _saveProtocolToSupabase(savedProtocol);
      if (mounted) {
        setState(() {
          _protocol = savedProtocol;
          _readinessScore = _persistence.getPreference(
            'last_readiness_score',
            88,
          );
          _isLoading = false;
        });
      }
      return;
    }

    await _generateNewProtocol();
  }

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
    final score = 88;
    _readinessScore = score;

    final baseProtocol = _agogeService.generateProtocol(score);
    WorkoutProtocol finalProtocol = baseProtocol;
    DomRlResult? domRlResult;

    if (_useDomRl) {
      // DOM-RL optimization placeholder
    }

    final jointStress = <String, int>{};
    final retreatCheck = _tacticalRetreat.checkRetreatStatus(
      currentReadiness: score,
      jointStress: jointStress,
    );

    if (retreatCheck.shouldRetreat && retreatCheck.enforcedProtocol != null) {
      finalProtocol = retreatCheck.enforcedProtocol!;
    }

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
    await _persistence.clearDailyProtocol();
    await _generateNewProtocol();
  }

  Future<void> _loadStructuredRecommendation(WorkoutProtocol protocol) async {
    setState(() => _isRecommendationLoading = true);

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
    if (_userId == null) return;

    setState(() => _isWeeklyDirectiveLoading = true);

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      // Get real weekly progress from Supabase
      final weeklyProgressData = await _database.getWeeklyProgress(weekStart);

      final workoutsCompleted =
          weeklyProgressData?['workouts_completed'] ??
          (_readinessScore >= 70 ? 4 : (_readinessScore >= 55 ? 3 : 2));
      final totalPlanned = weeklyProgressData?['total_planned_workouts'] ?? 4;
      final avgRpe = (weeklyProgressData?['average_rpe'] ?? 7.0).toDouble();

      final weeklyProgress = WeeklyProgress(
        weekStarting: weekStart,
        workoutsCompleted: workoutsCompleted,
        totalPlannedWorkouts: totalPlanned,
        averageRPE: avgRpe,
        totalVolume:
            weeklyProgressData?['total_volume'] ??
            ((_protocol?.entries.length ?? 0) * 180),
        averageReadiness: _sessionReadinessInput.applyToReadiness(
          _readinessScore,
        ),
        achievedGoals: _readinessScore >= 70,
      );

      final directive = await _domRlEngineV2.generateAdaptiveWeeklyDirective(
        userId: _userId!,
        weeklyProgress: weeklyProgress,
      );

      await _weeklyDirectiveRepository.saveWeeklyDirective(_userId!, directive);

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

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LaconicTheme.secondary),
            )
          : RefreshIndicator(
              onRefresh: _loadProtocol,
              color: LaconicTheme.secondary,
              backgroundColor: LaconicTheme.surfaceContainer,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shield Readiness Score Section
                    _buildShieldReadinessSection(),
                    const SizedBox(height: 32),

                    // Pre-Battle Primer
                    _buildPreBattlePrimer(),
                    const SizedBox(height: 32),

                    // Today's Directive
                    _buildTodayDirective(),
                    const SizedBox(height: 24),

                    // AI Recommendations
                    if (_isRecommendationLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: LaconicTheme.secondary,
                        ),
                      )
                    else if (_structuredRecommendation != null)
                      _buildAIRecommendationCard(),

                    const SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildEnterCrucibleButton(workoutProvider),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: LaconicTheme.background,
      elevation: 0,
      toolbarHeight: 64,
      title: Row(
        children: [
          const Icon(Icons.settings, color: LaconicTheme.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            'THE AGOGE',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LaconicTheme.primary,
              letterSpacing: -0.02,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: LaconicTheme.surfaceContainerHigh,
            border: Border.all(color: LaconicTheme.outlineVariant),
          ),
          child: const Icon(
            Icons.person,
            color: LaconicTheme.onSurface,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildShieldReadinessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shield Readiness Card
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: LaconicTheme.surfaceContainer,
                  border: Border(
                    left: BorderSide(color: LaconicTheme.secondary, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHIELD READINESS',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.secondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_readinessScore',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: LaconicTheme.secondary,
                            letterSpacing: -0.04,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '%',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: LaconicTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: Optimal / Battle Ready',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        color: LaconicTheme.onSurfaceVariant,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Recovery Metrics
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildMetricCard('Recovery (HRV)', '$_hrv ms', _hrvProgress),
                  const SizedBox(height: 8),
                  _buildMetricCard(
                    'Rest Duration',
                    _restDuration,
                    _restProgress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainerLow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 10,
              color: LaconicTheme.onSurfaceVariant,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: double.infinity,
            color: LaconicTheme.surfaceContainerHighest,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(color: LaconicTheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreBattlePrimer() {
    return Container(
      decoration: BoxDecoration(
        color: LaconicTheme.surfaceContainerHigh,
        border: Border.all(color: LaconicTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: LaconicTheme.surface,
          border: Border.all(
            color: LaconicTheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRE-BATTLE PRIMER',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.primary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '"The impediment to action advances action. What stands in the way becomes the way."',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '— Marcus Aurelius, Meditations',
              style: GoogleFonts.workSans(
                fontSize: 12,
                color: LaconicTheme.onSurfaceVariant,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(
                  'ACKNOWLEDGE ORDER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LaconicTheme.onSurface,
                  backgroundColor: LaconicTheme.surfaceBright,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: LaconicTheme.outlineVariant),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayDirective() {
    if (_protocol == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Phase',
                  style: GoogleFonts.workSans(
                    fontSize: 10,
                    color: LaconicTheme.onSurfaceVariant,
                    letterSpacing: 0.05,
                  ),
                ),
                Text(
                  "Today's Directive",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: LaconicTheme.onSurface,
                    letterSpacing: -0.02,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Agoge Cycle',
                  style: GoogleFonts.workSans(
                    fontSize: 10,
                    color: LaconicTheme.onSurfaceVariant,
                    letterSpacing: 0.05,
                  ),
                ),
                Text(
                  'III. PROMETHEUS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LaconicTheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Workout Card
        Container(
          decoration: const BoxDecoration(
            color: LaconicTheme.surfaceContainerLow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Training Image Placeholder
              Container(
                width: 120,
                height: 200,
                color: LaconicTheme.surfaceContainer,
                child: const Icon(
                  Icons.fitness_center,
                  color: LaconicTheme.outlineVariant,
                  size: 48,
                ),
              ),
              // Workout Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.stadium,
                            color: LaconicTheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Location: Stadion Track',
                            style: GoogleFonts.workSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: LaconicTheme.primary,
                              letterSpacing: 0.05,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _protocol!.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: LaconicTheme.onSurface,
                          letterSpacing: -0.02,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _protocol!.mindsetPrompt,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: LaconicTheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: LaconicTheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildWorkoutDetail(
                              'Estimated Duration',
                              '${_protocol!.estimatedDurationMinutes} MIN',
                            ),
                            const SizedBox(width: 24),
                            _buildWorkoutDetail('Intensity Score', '9.2 / 10'),
                            const SizedBox(width: 24),
                            _buildWorkoutDetail('Load Type', 'POWER'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 9,
              color: LaconicTheme.onSurfaceVariant,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendationCard() {
    final recommendation = _structuredRecommendation;
    if (recommendation == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: LaconicTheme.surfaceContainerLow,
        border: Border(left: BorderSide(color: LaconicTheme.primary, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI SESSION RECOMMENDATION',
            style: GoogleFonts.workSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.primary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.sessionFocus,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LaconicTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.progressionDirective,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: LaconicTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterCrucibleButton(WorkoutProvider workoutProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _protocol != null
            ? () => _showPreBattlePrimer(workoutProvider)
            : null,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: LaconicTheme.primary,
              foregroundColor: LaconicTheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              shadowColor: Colors.black.withValues(alpha: 0.5),
            ).copyWith(
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) return 0;
                return 8;
              }),
            ),
        child: Text(
          'ENTER THE CRUCIBLE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  void _showPreBattlePrimer(WorkoutProvider workoutProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile first'),
          backgroundColor: LaconicTheme.errorContainer,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreBattlePrimerScreen(
          userProfile: userProfile,
          readinessScore: _readinessScore,
          existingProtocol: _protocol,
          onWorkoutLoaded: (protocol, readinessScore) {
            workoutProvider.startWorkout(protocol, readinessScore);
            Navigator.pop(context);
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

  Future<void> _regeneratePlan() async {
    await _workoutRepository.deleteTodaysPlan();
    await _persistence.clearDailyProtocol();
    await _generateNewProtocol();
  }

  Future<void> _showCustomPlanPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

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

  Future<void> _generateCustomProtocol(
    WorkoutPreferences preferences,
    UserProfile profile,
  ) async {
    setState(() => _isLoading = true);

    try {
      final aiPlanService = AIPlanService();
      await aiPlanService.initialize();

      final exerciseRepo = ExerciseRepository();
      final allExercises = await exerciseRepo.getAllExercises();

      final availableExercises = preferences.preferredCategories.isNotEmpty
          ? allExercises
                .where(
                  (e) => preferences.preferredCategories.contains(e.category),
                )
                .toList()
          : allExercises;

      final protocol = await aiPlanService.generateCustomProtocol(
        profile,
        preferences,
        availableExercises: availableExercises.isNotEmpty
            ? availableExercises
            : null,
      );

      if (protocol != null) {
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
            backgroundColor: LaconicTheme.secondary,
          ),
        );
      } else {
        throw Exception('Failed to generate custom protocol');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: LaconicTheme.errorContainer,
        ),
      );
    }
  }
}
