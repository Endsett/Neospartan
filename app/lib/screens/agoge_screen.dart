import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/agoge_service.dart';
import '../services/dom_rl_engine.dart';
import '../services/ephor_scrutiny_service.dart';
import '../services/tactical_retreat_service.dart';
import '../services/firebase_sync_service.dart';
import '../models/workout_protocol.dart';
import '../providers/workout_provider.dart';
import 'workout_session_screen.dart';
import 'pre_battle_primer_screen.dart';

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
  final FirebaseSyncService _firebase = FirebaseSyncService();

  WorkoutProtocol? _protocol;
  int _readinessScore = 0;
  bool _isLoading = true;
  bool _useDomRl = true;
  EphorAnalysis? _ephorAnalysis;
  DomRlResult? _domRlResult;
  TacticalRetreatCheck? _retreatCheck;

  @override
  void initState() {
    super.initState();
    _loadProtocol();
  }

  Future<void> _loadProtocol() async {
    setState(() => _isLoading = true);

    // Fetch readiness data
    final data = await _healthService.fetchReadinessData();
    final score = data['score'] as int;

    // Build micro-cycle from Firebase
    final microCycle = await _firebase.buildMicroCycle();

    // Run Ephor Scrutiny analysis
    final ephorAnalysis = _ephorService.analyzeMicroCycle(microCycle);

    // Generate base protocol
    final baseProtocol = _agogeService.generateProtocol(score);

    // Apply DOM-RL optimization if enabled
    WorkoutProtocol finalProtocol = baseProtocol;
    DomRlResult? domRlResult;

    if (_useDomRl && microCycle.days.length >= 3) {
      domRlResult = _domRlEngine.optimize(microCycle, baseProtocol);
      finalProtocol = domRlResult.optimizedProtocol;
    }

    // Check for tactical retreat
    final jointStress = <String, int>{};
    for (final day in microCycle.days) {
      day.jointFatigue.forEach((joint, fatigue) {
        jointStress[joint] = (jointStress[joint] ?? 0) + fatigue;
      });
    }

    final retreatCheck = _tacticalRetreat.checkRetreatStatus(
      currentReadiness: score,
      jointStress: jointStress,
    );

    // Override protocol if retreat required
    if (retreatCheck.shouldRetreat && retreatCheck.enforcedProtocol != null) {
      finalProtocol = retreatCheck.enforcedProtocol!;
    }

    if (mounted) {
      setState(() {
        _readinessScore = score;
        _protocol = finalProtocol;
        _ephorAnalysis = ephorAnalysis;
        _domRlResult = domRlResult;
        _retreatCheck = retreatCheck;
        _isLoading = false;
      });
    }
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
            onPressed: _loadProtocol,
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
                    _buildAIGard(),
                    const SizedBox(height: 30),

                    // DOM-RL Action display
                    if (_domRlResult != null) _buildDomRlActionCard(),

                    const SizedBox(height: 20),
                    const Text(
                      "DAILY PROTOCOL",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...?_protocol?.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildWorkoutCard(
                          entry.exercise.name,
                          "${entry.sets} SETS × ${entry.reps > 0 ? entry.reps : 'MAX'} REPS",
                          "RPE ${entry.intensityRpe.toStringAsFixed(1)}",
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_protocol != null) {
                            _showPreBattlePrimer(workoutProvider);
                          }
                        },
                        child: const Text(
                          "INITIALIZE PROTOCOL",
                          style: TextStyle(letterSpacing: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  void _showPreBattlePrimer(WorkoutProvider workoutProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreBattlePrimerScreen(
          onAcknowledged: () {
            workoutProvider.startWorkout(_protocol!, _readinessScore);
            Navigator.pushReplacement(
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

  Widget _buildWorkoutCard(String title, String desc, String duration) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            duration,
            style: const TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
